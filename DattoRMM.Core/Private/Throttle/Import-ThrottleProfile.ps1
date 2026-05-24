<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Loads throttle profile settings from a configuration hashtable into the session throttle state.
.DESCRIPTION
    Applies throttle profile settings from a saved or custom configuration to the session's
    $Script:RMMThrottle state. For standard profiles (Cautious, Medium, Aggressive), all profile
    properties are loaded from the ThrottleProfileDefaults data file. For Custom profiles,
    DefaultProfile values are loaded first, then any custom overrides from the configuration are
    applied on top.

    This function is called during module initialisation when loading saved configuration, and
    encapsulates all throttle profile loading logic to keep the main psm1 clean.
#>
function Import-ThrottleProfile {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true
        )]
        [hashtable]
        $Config
    )

    if ($Config.ThrottleProfile -ne 'Custom') {

        # Standard profile — apply all profile defaults
        $ProfileName = $Config.ThrottleProfile

        if ($ProfileName -notin @('Cautious', 'Medium', 'Aggressive')) {

            Write-Warning "Invalid ThrottleProfile '$ProfileName' — defaulting to 'DefaultProfile'."
            $ProfileName = 'DefaultProfile'

        }

        $Script:RMMThrottle.Profile = $ProfileName
        $Script:ConfigThrottleProfile = $ProfileName
        $ProfileDefaults = $Script:ThrottleProfileDefaults[$ProfileName]

        foreach ($Key in $ProfileDefaults.Keys) {

            $Script:RMMThrottle[$Key] = $ProfileDefaults[$Key]

        }

        Write-Verbose "ThrottleProfile: $ProfileName"

    } else {

        # Custom profile — load DefaultProfile as base, then overlay custom values
        Write-Warning "Loading custom throttle configuration from $($Script:ConfigPath) — session behaviour may be unpredictable..."
        $Script:RMMThrottle.Profile = 'Custom'
        $Script:ConfigThrottleProfile = 'Custom'
        $DefaultProfile = $Script:ThrottleProfileDefaults['DefaultProfile']

        foreach ($Key in $DefaultProfile.Keys) {

            $Script:RMMThrottle[$Key] = $DefaultProfile[$Key]

        }

        # Override with any custom values present in configuration.
        # Keys are derived from DefaultProfile to stay in sync with ThrottleProfiles.psd1.
        foreach ($Key in $Script:ThrottleProfileDefaults['DefaultProfile'].Keys) {

            if ($Config.ContainsKey($Key)) {

                $Script:RMMThrottle[$Key] = $Config[$Key]
                Write-Warning "`tCUSTOM $($Key): $($Config[$Key])"

            }
        }
    }
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA78GWuvWRAVuou
# daHjc2tPrc3e4porx7OBNgYAiSXD36CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEximjm3r0r0g5RJFaa+uMXsHscp
# tF2XVtnlNXA5iBTEMA0GCSqGSIb3DQEBAQUABIIBAEOdk2M7rGavdBdJlC0WVemg
# NXHMzOSNVxQErOXrpZ1CI1HldcWa6pS/vc1j8tMgfj+B891SXiH5yrQrloB8av0n
# iIM5b+0W3+Q4tkEdsoFgd/Z6rzR5JUM8GyxyNpq/67blWJWbrxH0IT0qh+nZecWW
# iLnkVQYEqGty8VB8ZCZyT4Q9yBcGKH6YbLzs1er0UOwtd/K49Ncp6QKt3D60VL0Q
# WF5tYsG5JfdgfwOw5rzqpXjNyo1cz1ElSsFKSqyCoWJx7ZWdU/8VsF8Y3h2jQr7w
# e7fGByntUPH5jtQ1yekmX7qV2wf1WahNk3pt19HdY3bdHeFbHc5y6eRK5dDspRk=
# SIG # End signature block
