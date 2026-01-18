function Set-RMMThrottle {
    <#
    .SYNOPSIS
        Sets throttling behavior for the current DattoRMM.Core session.

    .DESCRIPTION
        Set-RMMThrottle allows you to adjust the throttling aggressiveness for the active session.
        Optionally, use -Persist to save the setting for future sessions (calls Set-RMMConfig).

    .PARAMETER ThrottleAggressiveness
        Controls how aggressively the module throttles API requests when nearing rate limits.
        Cautious: Maximum delay, checks rate limit frequently (safest, slowest).
        Medium: Balanced delay and check frequency.
        Aggressive: Minimal delay, checks rate limit less often (fastest, riskier).
        Valid values: Cautious, Medium, Aggressive. Module default is Medium.

        .PARAMETER Persist
        If specified, also saves the setting to the persistent configuration (calls Set-RMMConfig).

    .EXAMPLE
        Set-RMMThrottle -ThrottleAggressiveness Aggressive

        Sets throttling to aggressive for the current session only.

    .EXAMPLE
        Set-RMMThrottle -ThrottleAggressiveness Cautious -Persist

        Sets throttling to cautious for the current session and persists it for future sessions.

    .INPUTS
        None. You cannot pipe objects to Set-RMMThrottle.

    .OUTPUTS
        None. This function updates session variables and optionally persistent config.

    .NOTES
        Use Set-RMMConfig to configure other persistent settings.
    
    .LINK
        Set-RMMConfig
        Get-RMMThrottle
        about_DattoRMM.CoreThrottling

    #>

    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true
        )]
        [ValidateSet(
            'Cautious',
            'Medium',
            'Aggressive'
        )]
        [string]
        $ThrottleAggressiveness,

        [Parameter(Mandatory = $false)]
        [switch] $Persist
    )

    switch ($ThrottleAggressiveness) {

        'Cautious'   {
            
            $DelayMultiplier = $Script:ThrottleAggressionDefaults[$_].DelayMultiplier
            $LowUtilCheckInterval = $Script:ThrottleAggressionDefaults[$_].LowUtilCheckInterval
            $ThrottleUtilisationThreshold = $Script:ThrottleAggressionDefaults[$_].ThrottleUtilisationThreshold
            $ThrottleOverhead = $Script:ThrottleAggressionDefaults[$_].ThrottleOverhead
        }

        'Medium'     {
            
            $DelayMultiplier = $Script:ThrottleAggressionDefaults[$_].DelayMultiplier
            $LowUtilCheckInterval = $Script:ThrottleAggressionDefaults[$_].LowUtilCheckInterval
            $ThrottleUtilisationThreshold = $Script:ThrottleAggressionDefaults[$_].ThrottleUtilisationThreshold
            $ThrottleOverhead = $Script:ThrottleAggressionDefaults[$_].ThrottleOverhead
        }

        'Aggressive' {
            
            $DelayMultiplier = $Script:ThrottleAggressionDefaults[$_].DelayMultiplier
            $LowUtilCheckInterval = $Script:ThrottleAggressionDefaults[$_].LowUtilCheckInterval
            $ThrottleUtilisationThreshold = $Script:ThrottleAggressionDefaults[$_].ThrottleUtilisationThreshold
            $ThrottleOverhead = $Script:ThrottleAggressionDefaults[$_].ThrottleOverhead

        }

        default      {
            
            $DelayMultiplier = $Script:ThrottleAggressionDefaults['Default'].DelayMultiplier
            $LowUtilCheckInterval = $Script:ThrottleAggressionDefaults['Default'].LowUtilCheckInterval
            $ThrottleUtilisationThreshold = $Script:ThrottleAggressionDefaults['Default'].ThrottleUtilisationThreshold
            $ThrottleOverhead = $Script:ThrottleAggressionDefaults['Default'].ThrottleOverhead

        }
    }

    # Update current session throttle settings
    $Script:RMMThrottle.DelayMultiplier = $DelayMultiplier
    $Script:RMMThrottle.LowUtilCheckInterval = $LowUtilCheckInterval
    $Script:RMMThrottle.ThrottleUtilisationThreshold = $ThrottleUtilisationThreshold
    $Script:RMMThrottle.ThrottleOverhead = $ThrottleOverhead

    if ($Persist) {

        $SetRMMConfig = @{
            ThrottleAggressiveness = $ThrottleAggressiveness
        }

        if ($PSBoundParameters.Keys -contains 'ThrottleOverhead') {

            $SetRMMConfig['ThrottleOverhead'] = $ThrottleOverhead

        }

        Set-RMMConfig @SetRMMConfig
        
    }

    Get-RMMThrottle
    
}
