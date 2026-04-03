using module '..\DRMMObject\DRMMObject.psm1'

<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Represents a single rate-limit bucket in the DRMM throttle system, covering read, write, or per-operation buckets.
.DESCRIPTION
    The DRMMThrottleBucket class models one rate-limit bucket from the combined view of API-reported
    and locally tracked throttle state. Each bucket has a Type (Read, Write, or Operation), a Name
    that identifies it (e.g. 'Read', 'Write', 'site-create', 'device-move'), the configured Limit,
    the API-reported Count, the locally tracked LocalCount, and a computed Utilisation ratio. This class
    is used as an element in the Buckets collection of DRMMThrottleStatus, providing a uniform structure
    for all bucket types so they can be filtered, sorted, and analysed consistently.

    The Datto RMM API tracks reads and writes as independent quotas:
    - accountCount / accountRateLimit   → read (GET) operations only
    - accountWriteCount / accountWriteRateLimit → write (PUT/POST/DELETE) operations only
#>
class DRMMThrottleBucket : DRMMObject {

    # The bucket type: Read (global read/GET requests), Write (global write operations), or Operation (per-operation write buckets).
    [string]$Type
    # The name that identifies the bucket. For Read and Write buckets, this is the bucket type name. For Operation buckets, this is the operation name (e.g., site-create, device-move).
    [string]$Name
    # The configured rate limit for this bucket, indicating the maximum number of requests allowed within the rolling window.
    [int]$Limit
    # The current request count reported by the Datto RMM API for this bucket.
    [int]$ApiCount
    # The number of requests tracked locally in the sliding-window model for this bucket.
    [int]$LocalCount
    # The computed utilisation ratio for this bucket, calculated as the higher of API-reported utilisation or local-tracked utilisation. Ratio ranges from 0.0 (empty) to 1.0 or higher (over-limit).
    [double]$Utilisation

    DRMMThrottleBucket() : base() {

    }

    <#
    .SYNOPSIS
        Generates a summary string for the throttle bucket, including type, name, utilisation, and counts.
    .DESCRIPTION
        The GetSummary method returns a formatted string that summarises the bucket's current state,
        showing the type, name, utilisation percentage, and both API and local counts against the limit.
    #>
    [string] GetSummary() {

        $UtilPct = [math]::Round($this.Utilisation * 100, 2)

        return "$($this.Type)/$($this.Name): $UtilPct% (API=$($this.ApiCount), Local=$($this.LocalCount), Limit=$($this.Limit))"

    }
}

<#
.SYNOPSIS
    Represents the combined throttle and rate-limit status for a DRMM account, merging API-reported data with local tracking state.
.DESCRIPTION
    The DRMMThrottleStatus class provides a detailed snapshot of the current API rate-limit state,
    combining fresh data from the Datto RMM rate-status endpoint with the local sliding-window
    throttle model. It includes the active throttle profile, read and write utilisation (tracked
    independently), throttle and pause flags, current computed delays for each track, calibration
    metadata, configured thresholds, the rolling window size, and a collection of DRMMThrottleBucket
    objects representing every tracked bucket (read, write, and per-operation). This class is designed
    for monitoring, diagnostics, and long-running load test analysis, providing the complete throttle
    picture before any drift adjustment is applied.

    The Datto RMM API tracks reads and writes as independent quotas:
    - accountCount / accountRateLimit   → read (GET) operations only
    - accountWriteCount / accountWriteRateLimit → write (PUT/POST/DELETE) operations only
#>
class DRMMThrottleStatus : DRMMObject {

    # The name of the active throttle profile (e.g., DefaultProfile, ConservativeProfile).
    [string]$Profile
    # The unique identifier (UID) of the account from the API response.
    [string]$AccountUid
    # The rolling window size in seconds for the throttle model, as reported by the API.
    [int]$WindowSizeSeconds
    # The global read utilisation ratio (0.0 to 1.0+), calculated as the higher of API-reported or locally-tracked utilisation for read (GET) operations. Represents the portion of the account read rate limit currently in use.
    [double]$ReadUtilisation
    # The global write utilisation ratio (0.0 to 1.0+), calculated as the higher of API-reported or locally-tracked utilisation for write operations.
    [double]$WriteUtilisation
    # The account cut-off ratio from the API, representing the utilisation threshold at which the system enforces a hard pause to prevent exceeding the rate limit.
    [double]$AccountCutOffRatio
    # The configured utilisation threshold (e.g., 0.3 for 30%) at which soft throttling activates, introducing delays to reduce request rate.
    [double]$ThrottleUtilisationThreshold
    # The computed utilisation threshold at which hard pause activates, calculated as AccountCutOffRatio minus a safety margin (ThrottleCutOffOverhead).
    [double]$PauseThreshold
    # Boolean indicating whether soft throttling is currently active. True when either ReadUtilisation or WriteUtilisation exceeds ThrottleUtilisationThreshold.
    [bool]$Throttle
    # Boolean indicating whether hard pause is currently active. True when either ReadUtilisation or WriteUtilisation exceeds PauseThreshold, causing all API requests to be blocked.
    [bool]$Pause
    # The current computed delay in milliseconds for read (GET) requests. When throttling is active, this value increases proportionally with read utilisation to slow request rates.
    [double]$ReadDelayMs
    # The current computed delay in milliseconds for write (POST/PUT/DELETE) requests. When throttling is active, this value increases proportionally with write utilisation to slow request rates.
    [double]$WriteDelayMs
    # The configured multiplier (e.g., 750) used to calculate delay from read utilisation: ReadDelayMs = ReadUtilisation * DelayMultiplier.
    [double]$DelayMultiplier
    # The configured multiplier (e.g., 1000) used to calculate delay from write utilisation: WriteDelayMs = WriteUtilisation * WriteDelayMultiplier.
    [double]$WriteDelayMultiplier
    # The UTC datetime of the last read-track throttle calibration, when local read state was synchronized with API-reported values.
    [Nullable[datetime]]$ReadLastCalibrationUtc
    # The UTC datetime of the last write-track throttle calibration, when local write state was synchronized with API-reported values.
    [Nullable[datetime]]$WriteLastCalibrationUtc
    # The number of local read request samples recorded at the time of the last read-track calibration, used to track read state stability.
    [int]$ReadSamplesAtLastCalibration
    # The number of local write request samples recorded at the time of the last write-track calibration, used to track write state stability.
    [int]$WriteSamplesAtLastCalibration
    # A collection of DRMMThrottleBucket objects representing all tracked rate-limit buckets: the global read bucket, the global write bucket, and all monitored per-operation write buckets (both API-reported and locally-tracked unidentified operations).
    [DRMMThrottleBucket[]]$Buckets

    DRMMThrottleStatus() : base() {

        $this.Buckets = @()

    }

    <#
    .SYNOPSIS
        Generates a summary string for the throttle status, including key utilisation metrics and flags.
    .DESCRIPTION
        The GetSummary method returns a formatted string summarising the overall throttle state,
        including read and write utilisation percentages, whether throttling or pausing is active,
        the current delays, and the number of tracked buckets.
    #>
    [string] GetSummary() {

        $ReadPct = [math]::Round($this.ReadUtilisation * 100, 2)
        $WritePct = [math]::Round($this.WriteUtilisation * 100, 2)

        return "Read=$($ReadPct)%, Write=$($WritePct)%, Throttle=$($this.Throttle), Pause=$($this.Pause), ReadDelay=$([math]::Round($this.ReadDelayMs, 2))ms, WriteDelay=$([math]::Round($this.WriteDelayMs, 2))ms, Buckets=$($this.Buckets.Count)"

    }
}