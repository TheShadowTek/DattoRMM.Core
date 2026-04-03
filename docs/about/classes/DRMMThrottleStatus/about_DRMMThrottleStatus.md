# about_DRMMThrottleStatus

## SHORT DESCRIPTION

Represents the combined throttle and rate-limit status for a DRMM account, merging API-reported data with local tracking state.

## LONG DESCRIPTION

The DRMMThrottleStatus class provides a detailed snapshot of the current API rate-limit state, combining fresh data from the Datto RMM rate-status endpoint with the local sliding-window throttle model. It includes the active throttle profile, read and write utilisation (tracked independently), throttle and pause flags, current computed delays for each track, calibration metadata, configured thresholds, the rolling window size, and a collection of DRMMThrottleBucket objects representing every tracked bucket (read, write, and per-operation). This class is designed for monitoring, diagnostics, and long-running load test analysis, providing the complete throttle picture before any drift adjustment is applied. The Datto RMM API tracks reads and writes as independent quotas: - accountCount / accountRateLimit → read (GET) operations only - accountWriteCount / accountWriteRateLimit → write (PUT/POST/DELETE) operations only

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMThrottleStatus class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Profile                       | string               | The name of the active throttle profile (e.g., DefaultProfile, ConservativeProfile). |
| AccountUid                    | string               | The unique identifier (UID) of the account from the API response. |
| WindowSizeSeconds             | int                  | The rolling window size in seconds for the throttle model, as reported by the API. |
| ReadUtilisation               | double               | The global read utilisation ratio (0.0 to 1.0+), calculated as the higher of API-reported or locally-tracked utilisation for read (GET) operations. Represents the portion of the account read rate limit currently in use. |
| WriteUtilisation              | double               | The global write utilisation ratio (0.0 to 1.0+), calculated as the higher of API-reported or locally-tracked utilisation for write operations. |
| AccountCutOffRatio            | double               | The account cut-off ratio from the API, representing the utilisation threshold at which the system enforces a hard pause to prevent exceeding the rate limit. |
| ThrottleUtilisationThreshold  | double               | The configured utilisation threshold (e.g., 0.3 for 30%) at which soft throttling activates, introducing delays to reduce request rate. |
| PauseThreshold                | double               | The computed utilisation threshold at which hard pause activates, calculated as AccountCutOffRatio minus a safety margin (ThrottleCutOffOverhead). |
| Throttle                      | bool                 | Boolean indicating whether soft throttling is currently active. True when either ReadUtilisation or WriteUtilisation exceeds ThrottleUtilisationThreshold. |
| Pause                         | bool                 | Boolean indicating whether hard pause is currently active. True when either ReadUtilisation or WriteUtilisation exceeds PauseThreshold, causing all API requests to be blocked. |
| ReadDelayMs                   | double               | The current computed delay in milliseconds for read (GET) requests. When throttling is active, this value increases proportionally with read utilisation to slow request rates. |
| WriteDelayMs                  | double               | The current computed delay in milliseconds for write (POST/PUT/DELETE) requests. When throttling is active, this value increases proportionally with write utilisation to slow request rates. |
| DelayMultiplier               | double               | The configured multiplier (e.g., 750) used to calculate delay from read utilisation: ReadDelayMs = ReadUtilisation * DelayMultiplier. |
| WriteDelayMultiplier          | double               | The configured multiplier (e.g., 1000) used to calculate delay from write utilisation: WriteDelayMs = WriteUtilisation * WriteDelayMultiplier. |
| ReadLastCalibrationUtc        | Nullable[datetime]   | The UTC datetime of the last read-track throttle calibration, when local read state was synchronized with API-reported values. |
| WriteLastCalibrationUtc       | Nullable[datetime]   | The UTC datetime of the last write-track throttle calibration, when local write state was synchronized with API-reported values. |
| ReadSamplesAtLastCalibration  | int                  | The number of local read request samples recorded at the time of the last read-track calibration, used to track read state stability. |
| WriteSamplesAtLastCalibration | int                  | The number of local write request samples recorded at the time of the last write-track calibration, used to track write state stability. |
| Buckets                       | DRMMThrottleBucket[] | A collection of DRMMThrottleBucket objects representing all tracked rate-limit buckets: the global read bucket, the global write bucket, and all monitored per-operation write buckets (both API-reported and locally-tracked unidentified operations). |

## METHODS

The DRMMThrottleStatus class provides the following methods:

### GetSummary()

Generates a summary string for the throttle status, including key utilisation metrics and flags.

**Returns:** `string` - Returns string

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMThrottleStatus/about_DRMMThrottleStatus.md)

