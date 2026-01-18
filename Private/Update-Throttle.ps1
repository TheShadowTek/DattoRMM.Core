function Update-Throttle {
    param ()
    
    $RateInfo = Get-RMMRequestRate
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
        $PauseThreshold = $RateInfo.accountRateLimit - $script:Throttle.ThrottleOverhead

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
`tUtilisation=$([math]::Round($Script:RMMThrottle.Utilisation * 100, 2))%
`tThrottleUtilisationThreshold=$($Script:RMMThrottle.ThrottleUtilisationThreshold)
`tLowUtilCheckInterval=$($Script:RMMThrottle.LowUtilCheckInterval)
`tCheckInterval=$($script:RMMThrottle.CheckInterval)
`tRequestCount=$($RateInfo.accountCount)
`tRemaining=$($RateInfo.accountRateLimit - $RateInfo.accountCount)
`tDelayMS=$($Script:RMMThrottle.DelayMS)
`tPause=$($Script:RMMThrottle.Pause)
"@

}