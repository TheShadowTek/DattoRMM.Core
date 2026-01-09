function Set-RMMConfig {
    <#
    .SYNOPSIS
        Configures persistent settings for the Datto-RMM module.

    .DESCRIPTION
        The Set-RMMConfig function allows you to configure persistent settings that will be 
        preserved across PowerShell sessions. These settings are stored in a configuration file
        at $HOME/.datto-rmm/config.json.

    .PARAMETER DefaultPlatform
        Sets the default Datto RMM platform region for connections.
        Valid values: Pinotage, Concord, Vidal, Merlot, Zinfandel, Syrah

    .PARAMETER DefaultPageSize
        Sets the default page size for API requests. This will be used when connecting to the API,
        but will be capped at the account's maximum page size limit.
        Valid range: 1-250. The actual limit depends on your Datto RMM account settings.

    .PARAMETER LowUtilCheckInterval
        Sets how often (in requests) to check the API rate limit when utilization is low (<=50%).
        Valid range: 10-100. Default is 50.
        Higher values reduce overhead but may be less responsive to rate limit changes.
        Lower values check more frequently for better rate limit awareness.

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
        Set-RMMConfig -LowUtilCheckInterval 100 -TokenExpireHours 50

        Configures advanced throttling and token refresh settings.

    .INPUTS
        None. You cannot pipe objects to Set-RMMConfig.

    .OUTPUTS
        None. This function updates the persistent configuration file.

    .NOTES
        Configuration is stored at: $HOME/.datto-rmm/config.json
        At least one parameter must be specified.
        Settings take effect immediately and persist across sessions.

    .LINK
        Connect-DattoRMM
        Set-RMMPageSize
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
        [ValidateRange(10, 100)]
        [int]
        $LowUtilCheckInterval,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 100)]
        [int]
        $TokenExpireHours
    )

    # Ensure at least one parameter is provided
    if (-not ($PSBoundParameters.ContainsKey('DefaultPlatform') -or 
              $PSBoundParameters.ContainsKey('DefaultPageSize') -or 
              $PSBoundParameters.ContainsKey('LowUtilCheckInterval') -or 
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

    if ($PSBoundParameters.ContainsKey('LowUtilCheckInterval')) {

        $Config['LowUtilCheckInterval'] = $LowUtilCheckInterval
        Write-Verbose "Set LowUtilCheckInterval to: $LowUtilCheckInterval"
        
        # Update current session variable and active throttle setting
        $Script:ConfigLowUtilCheckInterval = $LowUtilCheckInterval

        if ($Script:RMMThrottle) {

            $Script:RMMThrottle.LowUtilCheckInterval = $LowUtilCheckInterval

        }
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
