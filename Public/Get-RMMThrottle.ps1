function Get-RMMThrottle {
    <#
    .SYNOPSIS
        Gets the current and configured throttling settings for DattoRMM.Core.

    .DESCRIPTION
        Returns the current session's ThrottleAggressiveness (Cautious, Medium, Aggressive),
        the corresponding DelayMultiplier and LowUtilCheckInterval, and if available,
        the persisted configuration values from Get-RMMConfig.

    .EXAMPLE
        Get-RMMThrottle

        Returns the current and configured throttling settings.

    .LINK
        Set-RMMConfig
        Get-RMMThrottle
        about_DattoRMM.CoreThrottling


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
        
        } elseif ($DelayMultiplier -eq 750  -and $LowUtilCheckInterval -eq 25) {
            
            return 'Medium'
        
        } elseif ($DelayMultiplier -eq 500  -and $LowUtilCheckInterval -eq 50) {
            
            return 'Aggressive'
        
        } else {

            return 'Custom'

        }
    }

    # Get current session throttle settings
    $SessionDelay = $Script:RMMThrottle.DelayMultiplier
    $SessionCheck = $Script:RMMThrottle.LowUtilCheckInterval
    $SessionLevel = Get-Level -DelayMultiplier $SessionDelay -LowUtilCheckInterval $SessionCheck

    # Get configured throttle settings from config
    $Config = $null
    $ConfigLevel = $null
    $ConfigDelay = $null
    $ConfigCheck = $null

    # Attempt to get config values
    try {

        $Config = Get-RMMConfig

        if ($Config -and $Config.ThrottleAggressiveness) {

            $ConfigLevel = $Config.ThrottleAggressiveness
            $ConfigDelay = $Config.DelayMultiplier
            $ConfigCheck = $Config.LowUtilCheckInterval
            
        }

    } catch {
        # Ignore errors retrieving config
    }

    $RateInfo = $null
    $Utilisation = $null
    $AccountCount = $null
    $AccountRateLimit = $null
    $AccountCutOffRatio = $null

    try {

        $RateInfo = Get-RMMRequestRate

        if ($RateInfo) {

            $AccountCount = $RateInfo.AccountCount
            $AccountRateLimit = $RateInfo.AccountRateLimit
            $AccountCutOffRatio = $RateInfo.AccountCutOffRatio

            if ($AccountRateLimit -gt 0) {

                $Utilisation = [math]::Round(($AccountCount / $AccountRateLimit) * 100, 2)

            }
        }
        
    } catch {
        # Ignore errors retrieving rate info
    }

    [PSCustomObject]@{
        SessionThrottleAggressiveness = $SessionLevel
        SessionDelayMultiplier = $SessionDelay
        SessionLowUtilCheckInterval = $SessionCheck
        ConfigThrottleAggressiveness = $ConfigLevel
        ConfigDelayMultiplier = $ConfigDelay
        ConfigLowUtilCheckInterval = $ConfigCheck
        AccountCount = $AccountCount
        AccountRateLimit = $AccountRateLimit
        AccountCutOffRatio = $AccountCutOffRatio
        UtilisationPercent = $Utilisation
    }
}
