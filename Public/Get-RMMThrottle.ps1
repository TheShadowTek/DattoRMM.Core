function Get-RMMThrottle {
    <#
    .SYNOPSIS
        Gets the current and configured throttling settings for Datto-RMM.

    .DESCRIPTION
        Returns the current session's ThrottleAggressiveness (Cautious, Medium, Aggressive),
        the corresponding DelayMultiplier and LowUtilCheckInterval, and if available,
        the persisted configuration values from Get-RMMConfig.

    .EXAMPLE
        Get-RMMThrottle

        Returns the current and configured throttling settings.
    #>

    [CmdletBinding()]
    param()

    function Get-Level {
        param(
            [int]$DelayMultiplier,
            [int]$LowUtilCheckInterval
        )

        if ($DelayMultiplier -eq 1000 -and $LowUtilCheckInterval -eq 15) {
            
            return 'Cautious'
        
        }

        if ($DelayMultiplier -eq 750  -and $LowUtilCheckInterval -eq 25) {
            
            return 'Medium'
        
        }

        if ($DelayMultiplier -eq 500  -and $LowUtilCheckInterval -eq 50) {
            
            return 'Aggressive'
        
        }

        return 'Custom'

    }

    $sessionDelay = $Script:RMMThrottle.DelayMultiplier
    $sessionCheck = $Script:RMMThrottle.LowUtilCheckInterval
    $sessionLevel = Get-Level -DelayMultiplier $sessionDelay -LowUtilCheckInterval $sessionCheck

    $config      = $null
    $configLevel = $null
    $configDelay = $null
    $configCheck = $null

    try {

        $config = Get-RMMConfig

        if ($config -and $config.ThrottleAggressiveness) {

            $configLevel = $config.ThrottleAggressiveness
            $configDelay = $config.DelayMultiplier
            $configCheck = $config.LowUtilCheckInterval
            
        }

    } catch {
        # Ignore errors retrieving config
    }

    $rateInfo = $null
    $utilisation = $null
    $accountCount = $null
    $accountRateLimit = $null
    $accountCutOffRatio = $null

    try {

        $rateInfo = Get-RMMRequestRate

        if ($rateInfo) {

            $accountCount = $rateInfo.accountCount
            $accountRateLimit = $rateInfo.accountRateLimit
            $accountCutOffRatio = $rateInfo.accountCutOffRatio

            if ($accountRateLimit -gt 0) {

                $utilisation = [math]::Round(($accountCount / $accountRateLimit) * 100, 2)

            }
        }
        
    } catch {
        # Ignore errors retrieving rate info
    }

    [PSCustomObject]@{
        SessionThrottleAggressiveness = $sessionLevel
        SessionDelayMultiplier        = $sessionDelay
        SessionLowUtilCheckInterval   = $sessionCheck
        ConfigThrottleAggressiveness  = $configLevel
        ConfigDelayMultiplier         = $configDelay
        ConfigLowUtilCheckInterval    = $configCheck
        AccountCount                  = $accountCount
        AccountRateLimit              = $accountRateLimit
        AccountCutOffRatio            = $accountCutOffRatio
        UtilisationPercent            = $utilisation
    }
}
