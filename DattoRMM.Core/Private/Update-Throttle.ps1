<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Update-Throttle {
    param ()
    
    $RateInfo = Get-RMMRequestRate
    $PauseThreshold = $RateInfo.accountCutOffRatio - $Script:RMMThrottle.ThrottleCutOffOverhead
    $Script:RMMThrottle.Utilisation = $RateInfo.accountCount / [math]::Max($RateInfo.accountRateLimit, 1)

    # Ensure LowUtilCheckInterval, DelayMultiplier, and ThrottleUtilisationThreshold are set
    if ($Script:RMMThrottle.Utilisation -le $Script:RMMThrottle.ThrottleUtilisationThreshold) {

        $script:RMMThrottle.CheckInterval = $script:RMMThrottle.LowUtilCheckInterval

    } else {

        $script:RMMThrottle.CheckInterval = [math]::Max(1, [int]($script:RMMThrottle.LowUtilCheckInterval * (1 - $Script:RMMThrottle.Utilisation)))

    }

    if ($Script:RMMThrottle.Utilisation -ge $Script:RMMThrottle.ThrottleUtilisationThreshold) {

        $Script:RMMThrottle.Throttle = $true
        $Script:RMMThrottle.DelayMS = $Script:RMMThrottle.Utilisation * $Script:RMMThrottle.DelayMultiplier

        # Determine if we need to pause requests entirely to avoid throttling
        if ($Script:RMMThrottle.Utilisation -ge $PauseThreshold) {

            $Script:RMMThrottle.Pause = $true

        } else {

            $Script:RMMThrottle.Pause = $false

        }

    } else {

        $Script:RMMThrottle.Pause = $false
        $Script:RMMThrottle.Throttle = $false

    }

    Write-Debug @"
Throttling:
`tUtilisation: $([math]::Round($Script:RMMThrottle.Utilisation * 100, 2))%
`tThrottle Utilisation Threshold: $([math]::Round($Script:RMMThrottle.ThrottleUtilisationThreshold * 100, 2))%
`tPause Utilisation Threshold: $([math]::Round($PauseThreshold * 100, 2))%
`tAccount Cut Off: $([math]::Round($RateInfo.accountCutOffRatio * 100, 2))%
`tThrottle Cut Off Overhead: $([math]::Round($Script:RMMThrottle.ThrottleCutOffOverhead * 100, 2))%
`tLowUtilCheckInterval: $($Script:RMMThrottle.LowUtilCheckInterval)
`tCheck Interval: $($script:RMMThrottle.CheckInterval)
`tRequest Count: $($RateInfo.accountCount)
`tRemaining: $($RateInfo.accountRateLimit - $RateInfo.accountCount)
`tDelay MS: $([math]::Round($Script:RMMThrottle.DelayMS, 2))
`tPause: $($Script:RMMThrottle.Pause)
"@

}
