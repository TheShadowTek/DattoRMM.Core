# about_DattoRMM.CoreThrottling

## SHORT DESCRIPTION

Describes the throttling system in the DattoRMM.Core PowerShell module, including how rate limits are tracked, how delays are applied, and how to configure throttling for single and concurrent API use.

## LONG DESCRIPTION

The DattoRMM.Core module implements an adaptive throttling system to manage API request rates against Datto RMM's account-wide rate limits. Rather than reacting to errors, the system proactively paces requests using local sliding-window tracking combined with periodic calibration against the live API. This allows it to respond to external pressure — such as other concurrent sessions — and adjust delay behaviour accordingly.

### Rate Limit Tiers

Datto RMM enforces rate limits at multiple levels within a rolling 60-second window. Reads and writes are tracked as **independent quotas** — they do not overlap:

- **Read limit** — all GET requests across the account share a read quota (reported as `accountCount` / `accountRateLimit` by the API)
- **Write limit** — all non-GET requests (PUT, POST, DELETE) across the account share a separate write quota (reported as `accountWriteCount` / `accountWriteRateLimit`)
- **Per-operation write limits** — individual write operations each have their own quota within the global write allowance

A read request only counts against the read limit. A write request only counts against the write limit and its per-operation bucket. The two quotas are completely independent.

> [!NOTE]
> Per-operation write limit values are returned by the Datto RMM API. How those limits are applied and enforced by the platform has been determined through testing and evaluation, as this behaviour is not formally documented. The write tier of the throttling system errs on the side of caution as a result.

### Architecture

Every API request flows through a layered pipeline. The throttle gate sits inside the retry engine, evaluating pressure against the appropriate bucket(s) based on HTTP method before each attempt.

```
  ┌─────────────────────────────────────────────────────────────┐
  │                  Public Function Layer                      │
  │           (Get-RMMDevice, Set-RMMDeviceUdf, ...)            │
  └──────────────────────────┬──────────────────────────────────┘
                             │
  ┌──────────────────────────▼──────────────────────────────────┐
  │                     Invoke-ApiMethod                        │
  │  • Proactive token refresh (5-min buffer before expiry)     │
  │  • URI + header + body assembly                             │
  │  • Operation classification (Resolve-ThrottleOperationName) │
  │  • Pagination loop (follows nextPageUrl until exhausted)    │
  └──────────────────────────┬──────────────────────────────────┘
                             │  (per page / per request)
  ┌──────────────────────────▼──────────────────────────────────┐
  │                   Invoke-ApiRestMethod                      │
  │  ┌───────────────── Retry Loop ──────────────────────┐      │
  │  │                                                   │      │
  │  │  1. Invoke-ApiThrottle ◄── PRE-REQUEST GATE       │      │
  │  │  2. Invoke-RestMethod  ◄── HTTP call              │      │
  │  │  3. Add-ThrottleRequest ◄── record in window      │      │
  │  │                                                   │      │
  │  │  On error: retry / token refresh / 429 handling   │      │
  │  └───────────────────────────────────────────────────┘      │
  └─────────────────────────────────────────────────────────────┘
                             │
  ┌──────────────────────────▼──────────────────────────────────┐
  │                    Invoke-ApiThrottle                       │
  │               (Pre-Request Throttle Gate)                   │
  │                                                             │
  │  • Route by HTTP method (GET vs PUT/POST/DELETE)            │
  │  • Evaluate calibration interval (confidence + drift)       │
  │  • Trigger Update-Throttle when interval expires            │
  │  • Evaluate all applicable buckets:                         │
  │                                                             │
  │     GET only           PUT/POST/DELETE only                 │
  │    ┌──────────┐       ┌──────────────────────────────────┐  │
  │    │  Read    │       │        Write (non-GET only)      │  │
  │    │  Bucket  │       ├──────────────┬───────────────────┤  │
  │    │          │       │ Global Write │ Per-Operation     │  │
  │    └──────────┘       └──────────────┴───────────────────┘  │
  │                                                             │
  │  • Highest pressure across all applicable buckets           │
  │    → delay (scaled by utilisation × DelayMultiplier)        │
  │    → or pause if any bucket exceeds hard cutoff             │
  └─────────────────────────────────────────────────────────────┘
```

The throttle gate and the retry engine are deliberately separate concerns. The gate paces requests; the retry engine handles transient failures and token refresh. On HTTP 429 (rate limit exceeded), the retry engine triggers a calibration via `Update-Throttle` and waits 120 seconds before retrying.

### Local Tracking and Calibration

The module maintains local sliding-window counters for each bucket. These are the primary control mechanism — requests are paced in real time without waiting for an API round-trip on every call.

Periodically, the system calibrates against the live API to reconcile the local picture with actual platform utilisation. This is necessary because other sessions, users, or external callers consume shared quota that local tracking cannot see.

Read and write tracks maintain **independent calibration state** (confidence, drift, interval, sample counts). When either track triggers a calibration, both tracks receive fresh data from the single API call. This means:

- A read-heavy session calibrates based on read pressure; writes benefit from the shared data.
- A write-heavy session calibrates based on write pressure; reads benefit from the shared data.
- If both tracks are active, whichever is under more pressure triggers calibration more frequently.

Calibration frequency per track adapts based on three competing floors (highest wins):

1. **Absolute minimum** (`CalibrationMinSeconds`) — prevents API spam regardless of other factors.
2. **Confidence × Drift formula** (`CalibrationBaseSeconds × ConfidenceFactor × DriftFactor`) — few local samples or high drift produce shorter intervals; full confidence and low drift produce the full base interval.
3. **Delay-pacing floor** (`CurrentDelayMS × 10`) — when delays are active, the calibration interval scales proportionally so enough paced requests pass between calibrations.

A **request-count gate** also triggers early calibration when enough requests have passed since the last calibration, even if the time interval has not elapsed. This ensures the system detects concurrent sessions early in the session lifecycle when confidence is still building.

Together these mechanisms mean a session under sustained load self-regulates naturally — delays pace the requests, calibration intervals extend proportionally, and the system avoids wasting API budget on calibration calls it doesn't need.

### Delay Behaviour

When utilisation crosses the configured threshold, a delay is applied before each request. The delay scales linearly with utilisation — higher utilisation produces a longer delay. The threshold and a single unified `DelayMultiplier` are controlled by the selected profile. Both reads and writes use the same multiplier.

Read and write delays are computed independently against their respective buckets. Each track carries a **calibration floor** forward between calibrations — the last API-reported delay is held flat until the next calibration fires. This prevents sessions with low local sample counts from being undercharged when concurrent sessions are consuming shared quota. The floor is reset on every calibration, so it always reflects the most recent API-reported pressure.

For write operations, the delay is calculated independently per applicable bucket (global write and per-operation), and the **highest value** across all write buckets governs the actual delay applied.

#### Per-Operation Limit-Ratio Scaling

Per-operation write delays are scaled by the ratio of the account write limit to the operation's own limit. This ensures that low-limit operations (e.g. site-create at 100) receive proportionally larger delays than high-limit operations (e.g. device-udf at 600), preventing small buckets from racing toward pause.

```
LimitRatio = Max(1.0, AccountWriteLimit / OperationLimit)
Delay      = OperationUtilisation × DelayMultiplier × LimitRatio
```

The ratio is derived from live API-reported limits, so it self-tunes if Datto adjusts operation limits in future.

#### Pause Behaviour

If utilisation on any applicable bucket reaches the hard cutoff threshold (platform cutoff minus a configurable safety overhead), requests of that type are paused entirely. The system sleeps for 30 seconds, recalibrates via `Update-Throttle`, and re-evaluates all applicable buckets. The pause loop continues until every relevant bucket drops below the threshold. This is a last-resort protection mechanism and should rarely trigger under normal operation with an appropriate profile selected.

## PROFILES

Three built-in profiles are available, tuned for different concurrency levels:

| Profile    | Best For                         | Delay Onset | DelayMultiplier | Calibration Base | Target Utilisation |
|------------|----------------------------------|-------------|-----------------|------------------|--------------------|
| Aggressive | Single session, high throughput  | ~45%        | 250             | 5s               | 60–70%             |
| Medium     | 2–3 concurrent sessions          | ~30%        | 500             | 8s               | 70–80%             |
| Cautious   | 3–5 concurrent sessions          | ~20%        | 1000            | 5s               | Below 60%          |

The `Medium` profile is the default. It provides a reasonable balance for interactive and lightly automated use.

The `Aggressive` profile uses a shorter calibration base interval and lower confidence count, allowing it to react quickly to utilisation dips and win bandwidth in mixed-profile scenarios. Its lower `DelayMultiplier` produces shorter delays per percentage point of utilisation, pushing throughput higher.

Choose `Cautious` for long-running automation, scheduled tasks, or any scenario where multiple sessions may be active simultaneously. It introduces delays earlier, uses a high `DelayMultiplier` for steeper delay curves, and detects shared quota contention more aggressively — keeping overall utilisation well below the platform limit to leave headroom for other workloads.

## CONFIGURATION

Set the throttling profile for the current session:

```powershell
Set-RMMConfig -ThrottleProfile Cautious
```

Persist the setting for future sessions:

```powershell
Set-RMMConfig -ThrottleProfile Cautious -Persist
```

Or save the current session configuration:

```powershell
Set-RMMConfig -ThrottleProfile Medium
Save-RMMConfig
```

## CONCURRENT USE

All sessions using the same Datto RMM account share the same read and write quotas. The throttling system detects pressure from other sessions through calibration drift — when API-reported utilisation exceeds what local tracking expects, the system tightens its calibration cadence. A flat calibration floor carries the API-reported delay forward between calibrations, preventing undercharging when local sample counts are low. The floor is held at the calibration-determined value and reset on each calibration. Read and write tracks detect drift independently.

Recommended profiles by concurrency:

| Sessions | Recommended Profile |
|----------|---------------------|
| 1        | Aggressive or Medium |
| 2-3      | Medium               |
| 3-5      | Cautious             |
| 5+       | Cautious (test and monitor) |

For long-running or unattended tasks, always prefer a more conservative profile than you think you need. A small per-request delay has minimal impact on total execution time over thousands of requests, while exceeding the rate limit stops all sessions entirely.

## DATTO RMM API RATE LIMIT DETAILS

Datto RMM enforces a rolling 60-second window for all rate limits. Counts are account-wide — all users and scripts share the same quotas. Reads and writes are independent quotas:

- **Read quota** (`accountCount` / `accountRateLimit`): tracks GET requests only
- **Write quota** (`accountWriteCount` / `accountWriteRateLimit`): tracks PUT/POST/DELETE requests only

A read never counts against the write quota, and a write never counts against the read quota.

- At ~90% utilisation on either quota, the platform may introduce a 1-second response delay.
- If the platform returns HTTP 429 (Too Many Requests), the module will automatically wait 120 seconds before retrying and will perform a throttle calibration to reassess utilisation. This automatic backoff helps when an uncontrolled or concurrent workload is consuming shared quota.
- Sustained requests after a 429 can trigger HTTP 403 (Forbidden) with a temporary IP block. Wait at least 5 minutes before retrying. In most cases the module's automatic 120s backoff and recalibration will prevent repeated overage.

> [!NOTE]
> Both quotas are account-wide. Concurrent users, scripts, and background processes all contribute to the same limits.

## CUSTOM THROTTLING SETTINGS (ADVANCED)

For advanced users, the `Custom` profile setting allows direct control over all throttle parameters via the configuration file.

> [!IMPORTANT]
> Custom settings are unsupported and intended for informed experimentation only. Incorrect values can result in API errors, 429/403 responses, or temporary IP blocks. Back up your config file before making manual changes.

Settings are stored at: `$HOME/.DattoRMM.Core/config.json`

## NOTES

- The throttle gate operates pre-request, proactively pacing requests before they are sent
- If a 429 does occur, the retry engine triggers a calibration and waits 120 seconds before retrying
- The pause threshold defaults to the platform cutoff minus a configurable safety overhead
- Pause sleep is 30 seconds per loop iteration, with recalibration after each sleep
- All profile settings can be adjusted at runtime without reconnecting
- For best results across concurrent sessions, use the same profile on all active sessions targeting the same account

## LEGACY SINGLE-BUCKET MODE

Some Datto RMM accounts use a legacy rate-limit model with a single shared bucket instead of the modern read/write/operation model. If your account uses the legacy model, the default multi-bucket throttle engine will misclassify requests.

To enable legacy compatibility, use the `-LegacyThrottle` switch when connecting:

```powershell
Connect-DattoRMM -Key "your-api-key" -Secret $Secret -LegacyThrottle
```

When enabled:

- All API requests (including PUT, POST, DELETE) are tracked against the **read bucket only**
- Write-specific counters, per-operation buckets, and write decay logic are bypassed
- A single shared bucket is used for all rate-limit calculations
- A diagnostic message is emitted confirming legacy mode is active

Default behaviour (modern multi-bucket model) is unchanged when `-LegacyThrottle` is not specified.

> [!NOTE]
> This is a temporary compatibility mechanism. It will be deprecated once automatic detection of the rate-limit model is implemented. See Issue [#7](https://github.com/TheShadowTek/DattoRMM.Core/issues/7) and Issue [#33](https://github.com/TheShadowTek/DattoRMM.Core/issues/33) for details.
