<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Set-RMMConfig {
    <#
    .SYNOPSIS
        Configures persistent settings for the DattoRMM.Core module.

    .DESCRIPTION
        The Set-RMMConfig function allows you to configure persistent settings that will be 
        preserved across PowerShell sessions. These settings are stored in a configuration file
        at $HOME/.DattoRMM.Core/config.json.

    .PARAMETER DefaultPlatform
        Sets the default Datto RMM platform region for connections.
        Valid values: Pinotage, Concord, Vidal, Merlot, Zinfandel, Syrah

    .PARAMETER DefaultPageSize
        Sets the default page size for API requests. This will be used when connecting to the API,
        but will be capped at the account's maximum page size limit.
        Valid range: 1-250. The actual limit depends on your Datto RMM account settings.

    .PARAMETER ThrottleAggressiveness
        Controls how aggressively the module throttles API requests when nearing rate limits.
        Cautious: Maximum delay, checks rate limit frequently (safest, slowest).
        Medium: Balanced delay and check frequency.
        Aggressive: Minimal delay, checks rate limit less often (fastest, riskier).
        Valid values: Cautious, Medium, Aggressive. Default is Medium.

    .PARAMETER TokenExpireHours
        Sets the token refresh interval in hours.
        Valid range: 1-100. Default is 100.
        Lower values refresh tokens more frequently, reducing risk of expiration but increasing API overhead.
        Higher values reduce API calls but may risk token expiration in long-running sessions.

    .EXAMPLE
        Set-RMMConfig -DefaultPlatform Merlot

        Sets the default platform to Merlot. Future calls to Connect-DattoRMM will use this platform
        unless explicitly overridden.

    .EXAMPLE
        Set-RMMConfig -DefaultPlatform Pinotage -DefaultPageSize 100

        Sets both the default platform and page size.


    .EXAMPLE
        Set-RMMConfig -ThrottleAggressiveness Cautious -TokenExpireHours 50

        Configures advanced throttling and token refresh settings for maximum safety.

    .INPUTS
        None. You cannot pipe objects to Set-RMMConfig.

    .OUTPUTS
        None. This function updates the persistent configuration file.

    .NOTES
        Configuration is stored at: $HOME/.DattoRMM.Core/config.json
        At least one parameter must be specified.
        Settings take effect immediately and persist across sessions.

    .LINK
        Connect-DattoRMM
        Set-RMMPageSize
        Get-RMMPageSize
        Get-RMMConfig
        Reset-RMMConfig
        Set-RMMPageSize
        about_DattoRMM.CoreThrottling
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [RMMPlatform]
        $DefaultPlatform,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 250)]
        [int]
        $DefaultPageSize,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Cautious', 'Medium', 'Aggressive')]
        [string]
        $ThrottleAggressiveness,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 100)]
        [int]
        $TokenExpireHours
    )

    # Ensure at least one parameter is provided

    if (-not ($PSBoundParameters.ContainsKey('DefaultPlatform') -or 
              $PSBoundParameters.ContainsKey('DefaultPageSize') -or 
              $PSBoundParameters.ContainsKey('ThrottleAggressiveness') -or 
              $PSBoundParameters.ContainsKey('TokenExpireHours'))) {

        throw "At least one configuration parameter must be specified."
        
    }

    # Read existing config or create new one
    $Config = Read-ConfigFile

    if ($null -eq $Config) {

        $Config = @{}

    } else {

        # Convert PSCustomObject to hashtable
        $ConfigHash = @{}

        $Config.PSObject.Properties | ForEach-Object {

            $ConfigHash[$_.Name] = $_.Value

        }

        $Config = $ConfigHash
    }

    # Update provided parameters
    if ($PSBoundParameters.ContainsKey('DefaultPlatform')) {

        $Config['DefaultPlatform'] = $DefaultPlatform.ToString()
        Write-Verbose "Set DefaultPlatform to: $DefaultPlatform"
        
        # Update current session variable
        $Script:ConfigDefaultPlatform = $DefaultPlatform

    }

    if ($PSBoundParameters.ContainsKey('DefaultPageSize')) {

        $Config['DefaultPageSize'] = $DefaultPageSize
        Write-Verbose "Set DefaultPageSize to: $DefaultPageSize"
        
        # Update current session variable
        $Script:ConfigDefaultPageSize = $DefaultPageSize

    }

    if ($PSBoundParameters.ContainsKey('ThrottleOverhead')) {

        $Config['ThrottleOverhead'] = $ThrottleOverhead
        Write-Verbose "Set ThrottleOverhead to: $ThrottleOverhead"

        if ($Script:RMMThrottle) {

            $Script:RMMThrottle.ThrottleOverhead = $ThrottleOverhead
            
        }
    }

    if ($PSBoundParameters.ContainsKey('ThrottleAggressiveness')) {

        $Config['ThrottleAggressiveness'] = $ThrottleAggressiveness
        Write-Verbose "Set ThrottleAggressiveness to: $ThrottleAggressiveness"

        switch ($ThrottleAggressiveness) {

            'Cautious' {
                $DelayMultiplier = $Script:ThrottleAggressionDefaults[$_].DelayMultiplier
                $LowUtilCheckInterval = $Script:ThrottleAggressionDefaults[$_].LowUtilCheckInterval
                $ThrottleUtilisationThreshold = $Script:ThrottleAggressionDefaults[$_].ThrottleUtilisationThreshold
                $ThrottleOverhead = $Script:ThrottleAggressionDefaults[$_].ThrottleOverhead
            }

            'Medium' {
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

            default {
                $DelayMultiplier = $Script:ThrottleAggressionDefaults['Default'].DelayMultiplier
                $LowUtilCheckInterval = $Script:ThrottleAggressionDefaults['Default'].LowUtilCheckInterval
                $ThrottleUtilisationThreshold = $Script:ThrottleAggressionDefaults['Default'].ThrottleUtilisationThreshold
                $ThrottleOverhead = $Script:ThrottleAggressionDefaults['Default'].ThrottleOverhead
            }
        }

        $Config['DelayMultiplier'] = $DelayMultiplier
        $Config['LowUtilCheckInterval'] = $LowUtilCheckInterval
        $Config['ThrottleUtilisationThreshold'] = $ThrottleUtilisationThreshold
        $Config['ThrottleOverhead'] = $ThrottleOverhead
        Write-Verbose "Set DelayMultiplier to: $DelayMultiplier"
        Write-Verbose "Set LowUtilCheckInterval to: $LowUtilCheckInterval"
        Write-Verbose "Set ThrottleUtilisationThreshold to: $ThrottleUtilisationThreshold"
        Write-Verbose "Set ThrottleOverhead to: $ThrottleOverhead"

        # Update current session variables and active throttle settings
        $Script:RMMThrottle.DelayMultiplier = $DelayMultiplier
        $Script:RMMThrottle.LowUtilCheckInterval = $LowUtilCheckInterval
        $Script:RMMThrottle.ThrottleUtilisationThreshold = $ThrottleUtilisationThreshold
        $Script:RMMThrottle.ThrottleOverhead = $ThrottleOverhead

    }

    if ($PSBoundParameters.ContainsKey('TokenExpireHours')) {

        $Config['TokenExpireHours'] = $TokenExpireHours
        Write-Verbose "Set TokenExpireHours to: $TokenExpireHours"
        
        # Update current session variable
        $Script:TokenExpireHours = $TokenExpireHours

    }

    # Write config file
    $Success = Write-ConfigFile -Config $Config

    if ($Success) {

        Write-Host "Configuration saved successfully." -ForegroundColor Green

    } else {

        throw "Failed to save configuration."

    }
}

