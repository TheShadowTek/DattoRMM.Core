function Set-RMMThrottle {
    <#
    .SYNOPSIS
        Sets throttling behavior for the current Datto-RMM session.

    .DESCRIPTION
        Set-RMMThrottle allows you to adjust the throttling aggressiveness for the active session.
        Optionally, use -Persist to save the setting for future sessions (calls Set-RMMConfig).

    .PARAMETER ThrottleAggressiveness
        Controls how aggressively the module throttles API requests when nearing rate limits.
        Cautious: Maximum delay, checks rate limit frequently (safest, slowest).
        Medium: Balanced delay and check frequency.
        Aggressive: Minimal delay, checks rate limit less often (fastest, riskier).
        Valid values: Cautious, Medium, Aggressive. Default is Medium.

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

        [Parameter(
            Mandatory = $false
        )]
        [switch]
        $Persist
    )

    switch ($ThrottleAggressiveness) {

        'Cautious'   {$DelayMultiplier = 1000; $LowUtilCheckInterval = 10; $ThrottleUtilisationThreshold = 0.25}
        'Medium'     {$DelayMultiplier = 750;  $LowUtilCheckInterval = 25; $ThrottleUtilisationThreshold = 0.5}
        'Aggressive' {$DelayMultiplier = 500;  $LowUtilCheckInterval = 50; $ThrottleUtilisationThreshold = 0.85}
        default      {$DelayMultiplier = 750;  $LowUtilCheckInterval = 25; $ThrottleUtilisationThreshold = 0.5}

    }

    $Script:ConfigDelayMultiplier = $DelayMultiplier
    $Script:ConfigLowUtilCheckInterval = $LowUtilCheckInterval
    $Script:ConfigThrottleUtilisationThreshold = $ThrottleUtilisationThreshold

    if ($Script:RMMThrottle) {
        $Script:RMMThrottle.DelayMultiplier = $DelayMultiplier
        $Script:RMMThrottle.LowUtilCheckInterval = $LowUtilCheckInterval
        $Script:RMMThrottle.ThrottleUtilisationThreshold = $ThrottleUtilisationThreshold
    }

    if ($Persist) {

        Set-RMMConfig -ThrottleAggressiveness $ThrottleAggressiveness
        
    }

    Write-Host "ThrottleAggressiveness set to: $ThrottleAggressiveness (DelayMultiplier: $DelayMultiplier, LowUtilCheckInterval: $LowUtilCheckInterval, ThrottleUtilisationThreshold: $ThrottleUtilisationThreshold)" -ForegroundColor Green
}
