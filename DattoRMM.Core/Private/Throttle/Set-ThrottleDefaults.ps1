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

    - Runtime state fields (AccountLimit, WriteLimit, timestamps, etc.) provide safe
      pre-connect fallback values. These are replaced with live-discovered values by
      Initialize-ThrottleState when Connect-DattoRMM is called.

    LastCalibrationUtc is set to [datetime]::MinValue as a pre-connect safe default only.
    Calibration is driven by Connect-DattoRMM via Initialize-ThrottleState and Update-Throttle,
    not by this sentinel value.
#>
function Set-ThrottleDefaults {
    [CmdletBinding()]
    param ()

    $Script:RMMThrottle = [ordered]@{
        Profile = 'DefaultProfile'                                                      # Active throttle profile name
        DelayMultiplier = 750                                                           # Delay multiplier for global account bucket throttling
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
        AccountLimit = 600                                                              # Global account rate limit (discovered from API)
        AccountCutOffRatio = 0.9                                                        # Account cut-off ratio (discovered from API)
        WriteLimit = 600                                                                # Global write rate limit (discovered from API)
        AccountLocalTimestamps = [System.Collections.Generic.List[datetime]]::new()     # Local timestamps for global account bucket
        WriteLocalTimestamps = [System.Collections.Generic.List[datetime]]::new()       # Local timestamps for global write bucket
        OperationBuckets = @{}                                                          # Per-operation write buckets (discovered from API)
        LastCalibrationUtc = [datetime]::MinValue                                       # Pre-connect safe default; overwritten by Initialize-ThrottleState on connect
        SamplesAtLastCalibration = 0                                                    # Local account sample count at last calibration (for request gate)
        AccountUtilisation = 0.0                                                        # Computed global account utilisation
        WriteUtilisation = 0.0                                                          # Computed global write utilisation
        DelayMS = 0                                                                     # Current computed delay in milliseconds
        Pause = $false                                                                  # Hard pause flag
        Throttle = $false                                                               # Soft throttle flag
    }
}
