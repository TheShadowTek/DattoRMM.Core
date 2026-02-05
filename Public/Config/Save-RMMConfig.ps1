
<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Save-RMMConfig {
    <#
    .SYNOPSIS
        Saves the current in-memory DattoRMM.Core configuration to disk.

    .DESCRIPTION
        Save-RMMConfig writes the current session's configuration (platform, page size, throttle profile, token expiry, etc.) to the persistent configuration file at $HOME/.DattoRMM.Core/config.json.

        For removing the config file and resetting to defaults, use Reset-RMMConfig.

    .EXAMPLE
        Save-RMMConfig

        Saves the current session's configuration to the config file.

    .INPUTS
        None. You cannot pipe objects to Save-RMMConfig.

    .OUTPUTS
        None. Writes to the config file.

    .NOTES
        Configuration is stored at: $HOME/.DattoRMM.Core/config.json
        Use Reset-RMMConfig to delete the config file and reset persistent settings.
        Current session values are not changed by Reset-RMMConfig.

    .LINK
        Set-RMMConfig
        Reset-RMMConfig
        Get-RMMConfig
        about_DattoRMM.CoreThrottling
    #>

    [CmdletBinding()]
    param()

    # Save current session config to file

    if ($null -eq $Script:RMMAuth) {

        throw "No active session. Please connect using Connect-DattoRMM before saving configuration."

    }

    $Config = @{
        'Platform' = $Script:SessionPlatform.ToString()
        'PageSize' = $Script:PageSize
        'ThrottleProfile' = $Script:RMMThrottle.Profile
        'TokenExpireHours' = $Script:TokenExpireHours
        'APIMaxRetries' = $Script:APIMethodRetry.MaxRetries
        'APIRetryIntervalSeconds' = $Script:APIMethodRetry.RetryIntervalSeconds
        'APITimeoutSeconds' = $Script:APIMethodRetry.TimeoutSeconds
    }

    $Success = Write-ConfigFile -Config $Config

    if ($Success) {

        Write-Host "Configuration saved successfully." -ForegroundColor Green

    } else {

        throw "Failed to save configuration."

    }
}

