<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMConfig {
    <#
    .SYNOPSIS
        Retrieves the current DattoRMM.Core module configuration.

    .DESCRIPTION
        The Get-RMMConfig function displays the current configuration settings for the DattoRMM.Core module, including both values loaded from the configuration file and their current in-memory values.
        
        This helps verify what defaults are configured and active in the current session.

    .EXAMPLE
        Get-RMMConfig

        Displays all current configuration settings.

    .EXAMPLE
        $Config = Get-RMMConfig
        $Config.SessionPageSize

        Retrieves the configuration and accesses the SessionPageSize property.

    .INPUTS
        None. You cannot pipe objects to Get-RMMConfig.

    .OUTPUTS
        PSCustomObject. Returns an object with configuration properties and their values.

    .NOTES
        Configuration is stored at: $HOME/.DattoRMM.Core/config.json
        
        The output shows:
        - Configured values from the config file
        - Current session values (may differ if changed via Save-RMMConfig during session)
        - Default fallback values when no configuration exists

    .LINK
        Save-RMMConfig
        ReSave-RMMConfig
        Set-RMMPageSize
        Get-RMMPageSize
    #>

    [CmdletBinding()]
    param()

    # Output only the current session configuration values
    $ConfigInfo = [PSCustomObject]@{
        ConfiguredPlatform = $Script:ConfigPlatform
        ConfiguredPageSize = $Script:ConfigPageSize
        ConfiguredThrottleProfile = $Script:ConfigThrottleProfile
        ConfiguredTokenExpireHours = $Script:ConfigTokenExpireHours
        SessionPlatform = $Script:SessionPlatform
        SessionPageSize = $Script:SessionPageSize
        SessionThrottleProfile = $Script:RMMThrottle.Profile
        SessionTokenExpireHours = $Script:TokenExpireHours
    }

    return $ConfigInfo
    
}

