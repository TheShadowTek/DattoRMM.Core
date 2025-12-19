function Update-Throttle {
    param ()
    
    $RateInfo = Get-RMMRequestRate
    $Script:RMMThrottle.Utilisation = $RateInfo.accountCount / [math]::Max($RateInfo.accountRateLimit, 1)
    $script:RMMThrottle.CheckInterval = if ($Script:RMMThrottle.Utilisation -le 0.5) {$script:RMMThrottle.LowUtilCheckInterval} else {[math]::Max(1, [int](50 * (1 - $Script:RMMThrottle.Utilisation)))}

    if ($Script:RMMThrottle.Utilisation -gt 0.5) {

        $Script:RMMThrottle.Throttle = $true
        $Script:RMMThrottle.DelayMS = $Script:RMMThrottle.Utilisation * 250

        # Determine if we need to pause requests entirely to avoid throttling
        if ($Script:RMMThrottle.Utilisation -gt 0.85) {

            $Script:RMMThrottle.Pause = $true

        } else {

            $Script:RMMThrottle.Pause = $false

        }

    } else {

        $Script:RMMThrottle.Throttle = $false

    }

    Write-Debug "`n`tThrottling: Utilisation=$([math]::Round($Script:RMMThrottle.Utilisation * 100, 2))%`n`tCheckInterval=$($script:RMMThrottle.CheckInterval)`n`tRequestCount=$($RateInfo.accountCount)`n`tRemaining=$($RateInfo.accountRateLimit - $RateInfo.accountCount)`n`tDelayMS=$($Script:RMMThrottle.DelayMS)`n`tPause=$($Script:RMMThrottle.Pause)"

}