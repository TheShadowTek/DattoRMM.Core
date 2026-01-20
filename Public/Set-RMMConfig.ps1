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

    .PARAMETER ThrottleProfile
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
        Set-RMMConfig -ThrottleProfile Cautious -TokenExpireHours 50

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
        $ThrottleProfile,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 100)]
        [int]
        $TokenExpireHours
    )

    # Ensure at least one parameter is provided

    if (-not ($PSBoundParameters.ContainsKey('DefaultPlatform') -or 
              $PSBoundParameters.ContainsKey('DefaultPageSize') -or 
              $PSBoundParameters.ContainsKey('ThrottleProfile') -or 
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

    if ($PSBoundParameters.ContainsKey('ThrottleCutOffOverhead')) {

        $Config['ThrottleCutOffOverhead'] = $ThrottleCutOffOverhead
        Write-Verbose "Set ThrottleCutOffOverhead to: $ThrottleCutOffOverhead"

        if ($Script:RMMThrottle) {

            $Script:RMMThrottle.ThrottleCutOffOverhead = $ThrottleCutOffOverhead
            
        }
    }

    if ($PSBoundParameters.ContainsKey('ThrottleProfile')) {

        $Config['ThrottleProfile'] = $ThrottleProfile
        Write-Verbose "Set ThrottleProfile to: $ThrottleProfile"

        switch ($ThrottleProfile) {

            'Cautious' {
                $DelayMultiplier = $Script:ThrottleProfileDefaults[$_].DelayMultiplier
                $LowUtilCheckInterval = $Script:ThrottleProfileDefaults[$_].LowUtilCheckInterval
                $ThrottleUtilisationThreshold = $Script:ThrottleProfileDefaults[$_].ThrottleUtilisationThreshold
                $ThrottleCutOffOverhead = $Script:ThrottleProfileDefaults[$_].ThrottleCutOffOverhead
            }

            'Medium' {
                $DelayMultiplier = $Script:ThrottleProfileDefaults[$_].DelayMultiplier
                $LowUtilCheckInterval = $Script:ThrottleProfileDefaults[$_].LowUtilCheckInterval
                $ThrottleUtilisationThreshold = $Script:ThrottleProfileDefaults[$_].ThrottleUtilisationThreshold
                $ThrottleCutOffOverhead = $Script:ThrottleProfileDefaults[$_].ThrottleCutOffOverhead
            }

            'Aggressive' {
                $DelayMultiplier = $Script:ThrottleProfileDefaults[$_].DelayMultiplier
                $LowUtilCheckInterval = $Script:ThrottleProfileDefaults[$_].LowUtilCheckInterval
                $ThrottleUtilisationThreshold = $Script:ThrottleProfileDefaults[$_].ThrottleUtilisationThreshold
                $ThrottleCutOffOverhead = $Script:ThrottleProfileDefaults[$_].ThrottleCutOffOverhead
            }

            default {
                $DelayMultiplier = $Script:ThrottleProfileDefaults['Default'].DelayMultiplier
                $LowUtilCheckInterval = $Script:ThrottleProfileDefaults['Default'].LowUtilCheckInterval
                $ThrottleUtilisationThreshold = $Script:ThrottleProfileDefaults['Default'].ThrottleUtilisationThreshold
                $ThrottleCutOffOverhead = $Script:ThrottleProfileDefaults['Default'].ThrottleCutOffOverhead
            }
        }

        $Config['DelayMultiplier'] = $DelayMultiplier
        $Config['LowUtilCheckInterval'] = $LowUtilCheckInterval
        $Config['ThrottleUtilisationThreshold'] = $ThrottleUtilisationThreshold
        $Config['ThrottleCutOffOverhead'] = $ThrottleCutOffOverhead
        Write-Verbose "Set DelayMultiplier to: $DelayMultiplier"
        Write-Verbose "Set LowUtilCheckInterval to: $LowUtilCheckInterval"
        Write-Verbose "Set ThrottleUtilisationThreshold to: $ThrottleUtilisationThreshold"
        Write-Verbose "Set ThrottleCutOffOverhead to: $ThrottleCutOffOverhead"

        # Update current session variables and active throttle settings
        $Script:RMMThrottle.DelayMultiplier = $DelayMultiplier
        $Script:RMMThrottle.LowUtilCheckInterval = $LowUtilCheckInterval
        $Script:RMMThrottle.ThrottleUtilisationThreshold = $ThrottleUtilisationThreshold
        $Script:RMMThrottle.ThrottleCutOffOverhead = $ThrottleCutOffOverhead

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

