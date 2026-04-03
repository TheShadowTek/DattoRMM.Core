
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
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Config/Save-RMMConfig.md

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
        'ApiMaxRetries' = $Script:ApiMethodRetry.MaxRetries
        'ApiRetryIntervalSeconds' = $Script:ApiMethodRetry.RetryIntervalSeconds
        'ApiTimeoutSeconds' = $Script:ApiMethodRetry.TimeoutSeconds
    }

    $Success = Write-ConfigFile -Config $Config

    if ($Success) {

        # Sync Config* tracking variables to reflect what is now persisted
        $Script:ConfigPlatform = $Script:SessionPlatform
        $Script:ConfigPageSize = $Script:PageSize
        $Script:ConfigThrottleProfile = $Script:RMMThrottle.Profile
        $Script:ConfigTokenExpireHours = $Script:TokenExpireHours
        $Script:ConfigApiMaxRetries = $Script:ApiMethodRetry.MaxRetries
        $Script:ConfigApiRetryIntervalSeconds = $Script:ApiMethodRetry.RetryIntervalSeconds
        $Script:ConfigApiTimeoutSeconds = $Script:ApiMethodRetry.TimeoutSeconds

        Write-Host "Configuration saved successfully." -ForegroundColor Green

    } else {

        throw "Failed to save configuration."

    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA4NCBEvDl6L43S
# THpc88xBjCNuidTV7H5+bxLx1PSqJqCCA04wggNKMIICMqADAgECAhB464iXHfI6
# gksEkDDTyrNsMA0GCSqGSIb3DQEBCwUAMD0xFjAUBgNVBAoMDVJvYmVydCBGYWRk
# ZXMxIzAhBgNVBAMMGkRhdHRvUk1NLkNvcmUgQ29kZSBTaWduaW5nMB4XDTI2MDMz
# MTAwMTMzMFoXDTI4MDMzMTAwMjMzMFowPTEWMBQGA1UECgwNUm9iZXJ0IEZhZGRl
# czEjMCEGA1UEAwwaRGF0dG9STU0uQ29yZSBDb2RlIFNpZ25pbmcwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQChn1EpMYQgl1RgWzQj2+wp2mvdfb3UsaBS
# nxEVGoQ0gj96tJ2MHAF7zsITdUjwaflKS1vE6wAlOg5EI1V79tJCMxzM0bFpOdR1
# L5F2HE/ovIAKNkHxFUF5qWU8vVeAsOViFQ4yhHpzLen0WLF6vhmc9eH23dLQy5fy
# tELZQEc2WbQFa4HMAitP/P9kHAu6CUx5s4woLIOyyR06jkr3l9vk0sxcbCxx7+dF
# RrsSLyPYPH+bUAB8+a0hs+6qCeteBuUfLvGzpMhpzKAsY82WZ3Rd9X38i32dYj+y
# dYx+nx+UEMDLjDJrZgnVa8as4RojqVLcEns5yb/XTjLxDc58VatdAgMBAAGjRjBE
# MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU
# H+B0vf97dYXqdUX1YMcWhFsY6fcwDQYJKoZIhvcNAQELBQADggEBAJmD4EEGNmcD
# 1JtFoRGxuLJaTHxDwBsjqcRQRE1VPZNGaiwIm8oSQdHVjQg0oIyK7SEb02cs6n6Y
# NZbwf7B7WZJ4aKYbcoLug1k1x9SoqwBmfElECeJTKXf6dkRRNmrAodpGCixR4wMH
# KXqwqP5F+5j7bdnQPiIVXuMesxc4tktz362ysph1bqKjDQSCBpwi0glEIH7bv5Ms
# Ey9Gl3fe+vYC5W06d2LYVebEfm9+7766hsOgpdDVgdtnN+e6uwIJjG/6PTG6TMDP
# y+pr5K6LyUVYJYcWWUTZRBqqwBHiLGekPbxrjEVfxUY32Pq4QfLzUH5hhUCAk4HN
# XpF9pOzFLMUxggIDMIIB/wIBATBRMD0xFjAUBgNVBAoMDVJvYmVydCBGYWRkZXMx
# IzAhBgNVBAMMGkRhdHRvUk1NLkNvcmUgQ29kZSBTaWduaW5nAhB464iXHfI6gksE
# kDDTyrNsMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKEC
# gAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwG
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDR7uZsGHVxm2sqKpj4GFRssLu2k
# Vv3sbT2ubPOz92FOMA0GCSqGSIb3DQEBAQUABIIBABHDP+8FBqA5GNZjRfNxz6jo
# kGux1a3zCMUu72WlU1QZf1dp+DF/EQ1njNNhJcqSokngYen24UPvJ7utoOM9V1ax
# Q87U73sIJL/FH3rrDDdqeYpadFHRGtzb8pdbgDT9qt3SBqqhirSBT/yIauSdLirf
# AowD61hsrahMWrobRtdw3MuT9KmmIHRhIr+WOdzJJZjpmrGfusVzbqekIASA38bd
# c9rNLM0HPKd3K26HATLV5QK4UPMzSczY6P/pZkgnp16Caep64j7PjQBF+LjWDIm4
# ke4WOR0CnAU54/WruZthOSm57nSxaJEatZYhWgtgFpleKUHjgt2Ckeq3RaPmOxg=
# SIG # End signature block
