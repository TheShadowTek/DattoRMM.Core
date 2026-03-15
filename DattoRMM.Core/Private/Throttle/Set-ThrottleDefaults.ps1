<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Initialises the RMMThrottle script-scoped variable with safe static defaults.
.DESCRIPTION
    Populates $Script:RMMThrottle with default values for the multi-bucket throttle model.
    Called once at module load, before dot-sourcing private and public functions.

    The hash table serves two purposes:

    - Behaviour settings (DelayMultiplier, CalibrationBaseSeconds, etc.) provide working
      defaults that are overridden by Import-ThrottleProfile when a saved config is loaded.

    - Runtime state fields (ReadLimit, WriteLimit, timestamps, etc.) provide safe
      pre-connect fallback values. These are replaced with live-discovered values by
      Initialize-ThrottleState when Connect-DattoRMM is called.

    Read and write calibration timestamps are set to [datetime]::MinValue as pre-connect
    safe defaults only. Calibration is driven by Connect-DattoRMM via Initialize-ThrottleState
    and Update-Throttle, not by these sentinel values.

    The Datto RMM API tracks reads and writes as independent quotas:
    - accountCount / accountRateLimit   → read (GET) operations only
    - accountWriteCount / accountWriteRateLimit → write (PUT/POST/DELETE) operations only
    Read requests are evaluated against the read bucket; write requests are evaluated against
    write buckets (global write + per-operation). They do not overlap.
#>
function Set-ThrottleDefaults {
    [CmdletBinding()]
    param ()

    $Script:RMMThrottle = [ordered]@{
        Profile = 'DefaultProfile'                                                      # Active throttle profile name
        DelayMultiplier = 750                                                           # Delay multiplier for read bucket throttling
        ThrottleCutOffOverhead = 0.05                                                   # Safety margin below accountCutOffRatio for pause trigger
        ThrottleUtilisationThreshold = 0.3                                              # Utilisation ratio at which throttling activates
        CalibrationBaseSeconds = 8                                                      # Ceiling interval at high confidence and zero drift
        CalibrationMinSeconds = 0.5                                                     # Absolute floor to prevent excessive API calibration calls
        CalibrationConfidenceCount = 50                                                 # Local samples needed before interval reaches full base
        DriftThresholdPercent = 0.02                                                    # Drift gap at which accelerated calibration begins (2%)
        DriftScalingFactor = 2                                                          # How aggressively interval shrinks as drift exceeds threshold
        WriteDelayMultiplier = 1000                                                     # Delay multiplier for write bucket throttling
        UnknownOperationSafetyFactor = 0.3                                              # Fractional delay for unmapped write operations
        WindowSizeSeconds = 60                                                          # Rolling window size (discovered from API)
        ReadLimit = 600                                                                 # Read (GET) rate limit (discovered from API as accountRateLimit)
        AccountCutOffRatio = 0.9                                                        # Account cut-off ratio (discovered from API)
        WriteLimit = 600                                                                # Write rate limit (discovered from API as accountWriteRateLimit)
        ReadLocalTimestamps = [System.Collections.Generic.List[datetime]]::new()        # Local timestamps for read (GET) requests
        WriteLocalTimestamps = [System.Collections.Generic.List[datetime]]::new()       # Local timestamps for write (PUT/POST/DELETE) requests
        OperationBuckets = @{}                                                          # Per-operation write buckets (discovered from API)
        ReadLastCalibrationUtc = [datetime]::MinValue                                   # Pre-connect safe default; overwritten by Initialize-ThrottleState on connect
        WriteLastCalibrationUtc = [datetime]::MinValue                                  # Pre-connect safe default; overwritten by Initialize-ThrottleState on connect
        ReadSamplesAtLastCalibration = 0                                                # Local read sample count at last calibration (for request gate)
        WriteSamplesAtLastCalibration = 0                                               # Local write sample count at last calibration (for request gate)
        ReadUtilisation = 0.0                                                           # Computed read utilisation (accountCount / accountRateLimit)
        WriteUtilisation = 0.0                                                          # Computed write utilisation (accountWriteCount / accountWriteRateLimit)
        ReadDelayMS = 0                                                                 # Current computed read delay in milliseconds
        WriteDelayMS = 0                                                                # Current computed write delay in milliseconds
        Pause = $false                                                                  # Hard pause flag
        Throttle = $false                                                               # Soft throttle flag
    }
}
