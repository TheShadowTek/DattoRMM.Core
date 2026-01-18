<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMConfig {
    <#
    .SYNOPSIS
        Retrieves the current DattoRMM.Core module configuration.

    .DESCRIPTION
        The Get-RMMConfig function displays the current configuration settings for the DattoRMM.Core module,
        including both values loaded from the configuration file and their current in-memory values.
        
        This helps verify what defaults are configured and active in the current session.

    .EXAMPLE
        Get-RMMConfig

        Displays all current configuration settings.

    .EXAMPLE
        $Config = Get-RMMConfig
        $Config.DefaultPlatform

        Retrieves the configuration and accesses a specific property.

    .INPUTS
        None. You cannot pipe objects to Get-RMMConfig.

    .OUTPUTS
        PSCustomObject. Returns an object with configuration properties and their values.

    .NOTES
        Configuration is stored at: $HOME/.DattoRMM.Core/config.json
        
        The output shows:
        - Configured values from the config file
        - Current session values (may differ if changed via Set-RMMConfig during session)
        - Default fallback values when no configuration exists

    .LINK
        Set-RMMConfig
        Reset-RMMConfig
        Set-RMMPageSize
        Get-RMMPageSize
    #>

    [CmdletBinding()]
    param()

    # Read config file
    $FileConfig = Read-ConfigFile

    # Build output object with both file and session values
    $ConfigInfo = [PSCustomObject]@{
        DefaultPlatform = [PSCustomObject]@{
            Configured = if ($FileConfig.DefaultPlatform) { $FileConfig.DefaultPlatform } else { $null }
            CurrentSession = if ($Script:ConfigDefaultPlatform) { $Script:ConfigDefaultPlatform.ToString() } else { $null }
            Fallback = 'Pinotage'
        }
        DefaultPageSize = [PSCustomObject]@{
            Configured = if ($FileConfig.DefaultPageSize) { $FileConfig.DefaultPageSize } else { $null }
            CurrentSession = $Script:ConfigDefaultPageSize
            Fallback = 'Account Maximum'
        }
        LowUtilCheckInterval = [PSCustomObject]@{
            Configured = if ($FileConfig.LowUtilCheckInterval) { $FileConfig.LowUtilCheckInterval } else { $null }
            CurrentSession = $Script:ConfigLowUtilCheckInterval
            Fallback = 50
        }
        TokenExpireHours = [PSCustomObject]@{
            Configured = if ($FileConfig.TokenExpireHours) { $FileConfig.TokenExpireHours } else { $null }
            CurrentSession = $Script:TokenExpireHours
            Fallback = 100
        }
        ConfigFilePath = Get-ConfigFilePath
        ConfigFileExists = Test-Path (Get-ConfigFilePath)
    }

    return $ConfigInfo
    
}

