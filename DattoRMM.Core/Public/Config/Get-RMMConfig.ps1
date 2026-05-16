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
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Config/Get-RMMConfig.md

    .LINK
        Set-RMMConfig

    .LINK
        Save-RMMConfig

    .LINK
        Remove-RMMConfig

    .LINK
        about_DattoRMM.CoreConfiguration
    #>

    [CmdletBinding()]
    param()

    # Output only the current session configuration values
    $ConfigInfo = [PSCustomObject]@{
        ConfiguredPlatform = $Script:ConfigPlatform
        ConfiguredPageSize = $Script:ConfigPageSize
        ConfiguredThrottleProfile = $Script:ConfigThrottleProfile
        ConfiguredTokenExpireHours = $Script:ConfigTokenExpireHours
        ConfiguredApiMaxRetries = $Script:ConfigApiMaxRetries
        ConfiguredApiRetryIntervalSeconds = $Script:ConfigApiRetryIntervalSeconds
        ConfiguredApiTimeoutSeconds = $Script:ConfigApiTimeoutSeconds
        ConfiguredTokenRefreshBufferMinutes = $Script:ConfigTokenRefreshBufferMinutes
        SessionPlatform = $Script:SessionPlatform
        SessionPageSize = $Script:SessionPageSize
        SessionThrottleProfile = $Script:RMMThrottle.Profile
        SessionTokenExpireHours = $Script:TokenExpireHours
        SessionApiMaxRetries = $Script:ApiMethodRetry.MaxRetries
        SessionApiRetryIntervalSeconds = $Script:ApiMethodRetry.RetryIntervalSeconds
        SessionApiTimeoutSeconds = $Script:ApiMethodRetry.TimeoutSeconds
        SessionTokenRefreshBufferMinutes = $Script:TokenRefreshBufferMinutes
    }

    return $ConfigInfo
    
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA13qVOtDtKvZoe
# xJ31f00ncaD2pWJ3L1WZF0rLaDDuI6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIC8L0jRoY8T3Ke1/mmsk0FJ/oh6a
# Z7NPc8mln+avkTTrMA0GCSqGSIb3DQEBAQUABIIBAB/uQY6HMWrqK+QZSZPgPusA
# 5HSVKYvVKZNED+bRvdFoeW0WTRejZ+yrH++7qabpBMdQtA1CvLs+AM2Oqd4Amr8p
# MKS236v6PjmHHoVpI3BZf4nROkcMm8jw5tF4yJH1Tq61zc8Aw8wfxd7pP27sVNHP
# OY+60hpeeLhtFjjdBSfm8wAB81OxcR3+4WCcnMIm7yYR1ga6b6s5OYH6UntyFJvb
# 4zDWCneBphtQYFukJYRmkku1O15OQuBCGviBP2aDT8rsymzq6Hob7tThiHaB5z/B
# UwSBsXddZ6Um0OzDPcNyCyV+aW664OezEC7q/1/iwUMLl1tJRM65FgxiA/4/Dzg=
# SIG # End signature block
