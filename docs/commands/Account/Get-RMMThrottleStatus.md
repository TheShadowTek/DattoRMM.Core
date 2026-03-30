# Get-RMMThrottleStatus

## SYNOPSIS
Retrieves a detailed snapshot of the current API rate limits, counts, and local throttle state.

## SYNTAX

```
Get-RMMThrottleStatus [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMThrottleStatus function provides a combined view of the Datto RMM API rate-status
endpoint data and the local sliding-window throttle model.
It calls the rate-status API to
fetch fresh read and write counts, limits, and per-operation bucket status, then merges
this with the local throttle tracking state (timestamps, utilisation, flags, thresholds).

The Datto RMM API tracks reads and writes as independent quotas:
- accountCount / accountRateLimit   → read (GET) operations only
- accountWriteCount / accountWriteRateLimit → write (PUT/POST/DELETE) operations only

The returned DRMMThrottleStatus object includes:
- Active throttle profile and configured thresholds
- Independent read and write utilisation (both API-reported and locally tracked)
- Throttle and pause flags reflecting the current state before drift adjustment
- Independent read and write delay values in milliseconds
- Calibration metadata for both read and write tracks
- A Buckets collection of DRMMThrottleBucket objects covering the read bucket,
  write bucket, and all per-operation write buckets (both mapped and unidentified)

Each bucket reports its Type (Read, Write, or Operation), Name, Limit, ApiCount,
LocalCount, and computed Utilisation ratio.

This function is designed for monitoring, diagnostics, and sample capture during long-running
load tests.
It does not modify any throttle state.
For the raw API response without local
enrichment, use Get-RMMRequestRate instead.

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMThrottleStatus
```

Retrieves the current combined throttle status snapshot.

EXAMPLE 2
```powershell
$Status = Get-RMMThrottleStatus
$Status.GetSummary()
```

Retrieves throttle status and displays a summary of utilisation, flags, and delay.

EXAMPLE 3
```powershell
Get-RMMThrottleStatus | Select-Object -ExpandProperty Buckets | Format-Table
```

Retrieves throttle status and displays all rate-limit buckets in a table.

EXAMPLE 4
```powershell
(Get-RMMThrottleStatus).Buckets | Where-Object Type -eq 'Operation' | Sort-Object Utilisation -Descending
```

Retrieves and filters only per-operation buckets, sorted by utilisation.

EXAMPLE 5
```powershell
$Status = Get-RMMThrottleStatus
$Status.Buckets | Where-Object {$_.Utilisation -gt 0}
```

Shows only buckets with active utilisation for quick load test monitoring.

## PARAMETERS

## INPUTS

None. You cannot pipe objects to Get-RMMThrottleStatus.
## OUTPUTS

DRMMThrottleStatus. Returns a throttle status object with the following properties:
- Profile (string): Active throttle profile name
- AccountUid (string): Account unique identifier from the API
- WindowSizeSeconds (int): Rolling window size in seconds
- ReadUtilisation (double): Read utilisation ratio (higher of API or local)
- WriteUtilisation (double): Write utilisation ratio (higher of API or local)
- AccountCutOffRatio (double): API-reported account cut-off ratio
- ThrottleUtilisationThreshold (double): Configured threshold at which throttling activates
- PauseThreshold (double): Computed threshold at which hard pause activates
- Throttle (bool): Whether soft throttling is currently active
- Pause (bool): Whether hard pause is currently active
- ReadDelayMs (double): Current computed read delay in milliseconds
- WriteDelayMs (double): Current computed write delay in milliseconds
- DelayMultiplier (double): Configured read delay multiplier
- WriteDelayMultiplier (double): Configured write delay multiplier
- ReadLastCalibrationUtc (datetime): UTC time of the last read calibration
- WriteLastCalibrationUtc (datetime): UTC time of the last write calibration
- ReadSamplesAtLastCalibration (int): Local read samples at last calibration
- WriteSamplesAtLastCalibration (int): Local write samples at last calibration
- Buckets (DRMMThrottleBucket[]): Collection of all tracked rate-limit buckets
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

This function calls the rate-status API endpoint to fetch fresh data, which itself
counts as a read request against the account rate limit.

The throttle state reported is a pre-drift-adjustment snapshot.
The actual throttle
engine may adjust utilisation values during calibration cycles.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMThrottleStatus.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMThrottleStatus.md))
- [Get-RMMRequestRate](./Get-RMMRequestRate.md)
- [Connect-DattoRMM](../Auth/Connect-DattoRMM.md)
- [about_DattoRMM.CoreThrottling](../../about/about_DattoRMM.CoreThrottling.md)
- [about_DRMMThrottleStatus](../../about/classes/DRMMThrottleStatus/about_DRMMThrottleStatus.md)
