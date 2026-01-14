function Update-Throttle {
    param ()
    
    $RateInfo = Get-RMMRequestRate
    $Script:RMMThrottle.Utilisation = $RateInfo.accountCount / [math]::Max($RateInfo.accountRateLimit, 1)

    # Ensure LowUtilCheckInterval, DelayMultiplier, and ThrottleUtilisationThreshold are set
    if (-not $Script:RMMThrottle.LowUtilCheckInterval) {

        $Script:RMMThrottle.LowUtilCheckInterval = if ($Script:ConfigLowUtilCheckInterval) {$Script:ConfigLowUtilCheckInterval} else {25}

    }

    if (-not $Script:RMMThrottle.DelayMultiplier) {

        $Script:RMMThrottle.DelayMultiplier = if ($Script:ConfigDelayMultiplier) {$Script:ConfigDelayMultiplier} else {750}
        
    }

    if (-not $Script:RMMThrottle.ThrottleUtilisationThreshold) {

        $Script:RMMThrottle.ThrottleUtilisationThreshold = if ($Script:ConfigThrottleUtilisationThreshold) {$Script:ConfigThrottleUtilisationThreshold} else {0.5}

    }

    $script:RMMThrottle.CheckInterval = if ($Script:RMMThrottle.Utilisation -le $Script:RMMThrottle.ThrottleUtilisationThreshold) {

        $script:RMMThrottle.LowUtilCheckInterval

    } else {

        [math]::Max(1, [int]($script:RMMThrottle.LowUtilCheckInterval * (1 - $Script:RMMThrottle.Utilisation)))

    }

    if ($Script:RMMThrottle.Utilisation -gt $Script:RMMThrottle.ThrottleUtilisationThreshold) {

        $Script:RMMThrottle.Throttle = $true
        $Script:RMMThrottle.DelayMS = $Script:RMMThrottle.Utilisation * $Script:RMMThrottle.DelayMultiplier

        # Determine if we need to pause requests entirely to avoid throttling
        if ($Script:RMMThrottle.Utilisation -gt 0.85) {

            $Script:RMMThrottle.Pause = $true

        }
        else {

            $Script:RMMThrottle.Pause = $false

        }

    }
    else {

        $Script:RMMThrottle.Pause = $false
        $Script:RMMThrottle.Throttle = $false

    }

    Write-Debug "Throttling:`n   Utilisation=$([math]::Round($Script:RMMThrottle.Utilisation * 100, 2))%`n   ThrottleUtilisationThreshold=$($Script:RMMThrottle.ThrottleUtilisationThreshold)`n   LowUtilCheckInterval=$($Script:RMMThrottle.LowUtilCheckInterval)`n   CheckInterval=$($script:RMMThrottle.CheckInterval)`n   RequestCount=$($RateInfo.accountCount)`n   Remaining=$($RateInfo.accountRateLimit - $RateInfo.accountCount)`n   DelayMS=$($Script:RMMThrottle.DelayMS)`n   Pause=$($Script:RMMThrottle.Pause)"

}