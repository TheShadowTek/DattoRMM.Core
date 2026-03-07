<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Loads throttle profile settings from a configuration hashtable into the session throttle state.
.DESCRIPTION
    Applies throttle profile settings from a saved or custom configuration to the session's
    $Script:RMMThrottle state. For standard profiles (Cautious, Medium, Aggressive), all profile
    properties are loaded from the ThrottleProfileDefaults data file. For Custom profiles,
    DefaultProfile values are loaded first, then any custom overrides from the configuration are
    applied on top.

    This function is called during module initialisation when loading saved configuration, and
    encapsulates all throttle profile loading logic to keep the main psm1 clean.
#>
function Import-ThrottleProfile {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true
        )]
        [hashtable]
        $Config
    )

    if ($Config.ThrottleProfile -ne 'Custom') {

        # Standard profile — apply all profile defaults
        $ProfileName = $Config.ThrottleProfile

        if ($ProfileName -notin @('Cautious', 'Medium', 'Aggressive')) {

            Write-Warning "Invalid ThrottleProfile '$ProfileName' — defaulting to 'DefaultProfile'."
            $ProfileName = 'DefaultProfile'

        }

        $Script:RMMThrottle.Profile = $ProfileName
        $Script:ConfigThrottleProfile = $ProfileName
        $ProfileDefaults = $Script:ThrottleProfileDefaults[$ProfileName]

        foreach ($Key in $ProfileDefaults.Keys) {

            $Script:RMMThrottle[$Key] = $ProfileDefaults[$Key]

        }

        Write-Verbose "ThrottleProfile: $ProfileName"

    } else {

        # Custom profile — load DefaultProfile as base, then overlay custom values
        Write-Warning "Loading custom throttle configuration from $($Script:ConfigPath) — session behaviour may be unpredictable..."
        $Script:RMMThrottle.Profile = 'Custom'
        $Script:ConfigThrottleProfile = 'Custom'
        $DefaultProfile = $Script:ThrottleProfileDefaults['DefaultProfile']

        foreach ($Key in $DefaultProfile.Keys) {

            $Script:RMMThrottle[$Key] = $DefaultProfile[$Key]

        }

        # Override with any custom values present in configuration
        $CustomKeys = @(
            'DelayMultiplier'
            'CalibrationBaseSeconds'
            'CalibrationMinSeconds'
            'CalibrationConfidenceCount'
            'DriftThresholdPercent'
            'DriftScalingFactor'
            'ThrottleCutOffOverhead'
            'ThrottleUtilisationThreshold'
            'WriteDelayMultiplier'
            'UnknownOperationSafetyFactor'
        )

        foreach ($Key in $CustomKeys) {

            if ($Config.ContainsKey($Key)) {

                $Script:RMMThrottle[$Key] = $Config[$Key]
                Write-Warning "`tCUSTOM $($Key): $($Config[$Key])"

            }
        }
    }
}
