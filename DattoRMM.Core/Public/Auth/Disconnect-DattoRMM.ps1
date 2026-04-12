<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Disconnect-DattoRMM {
    <#
    .SYNOPSIS
        Disconnects from the Datto RMM API and clears authentication information.

    .DESCRIPTION
        The Disconnect-DattoRMM function clears the stored authentication token and credentials from the module's script scope, effectively ending the current API session.

        This function should be called when you are finished working with the Datto RMM API to ensure credentials are removed from memory.

    .EXAMPLE
        Disconnect-DattoRMM

        Disconnects from the Datto RMM API and clears stored authentication.

    .EXAMPLE
        Connect-DattoRMM -Key "your-api-key" -Secret $Secret
        PS > Get-RMMDevice
        PS > Disconnect-DattoRMM

        Connects to the API, performs operations, then disconnects and clears credentials.

    .INPUTS
        None. You cannot pipe objects to Disconnect-DattoRMM.

    .OUTPUTS
        None. This function does not generate output but clears authentication information from module scope.

    .NOTES
        After disconnecting, you will need to run Connect-DattoRMM again to re-authenticate
        before making additional API calls.

        The module also automatically clears authentication information when the module is removed
        from the session.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Disconnect-DattoRMM.md

    .LINK
        Connect-DattoRMM
    #>

    $Script:RMMAuth = $null
    $Script:MaxPageSize = $null
    $Script:APIUrl = $null
    $Script:API = $null
    $Script:PageSize = $null
    $Script:LegacyThrottleMode = $false

    Write-Verbose "Disconnected from Datto RMM API."

}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCoA8eHSL1zUScD
# EwPoO8cYhCOlfyooULi+9ln5Hlc7ZKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILEgkaDMHtUcA8w3O0b3vtHlIxJt
# wHaDvjWKV9OJMpAKMA0GCSqGSIb3DQEBAQUABIIBADFn4Pre0+Ss+j//pEwJCSQc
# mbdGPsQ9nmNV5sDYZPw4R0pvMe5YtoqRvE6YYwQleOjOfeI7c/9mzpto6oviVCcD
# Z7Ddg+8inTXXiNLb6gNDwOKe5hcaJr2uW82EQ1nDof2wbVaUd20+NGooj1ii6RAT
# Hdrh+OcQ8WTa9hw2HXESYT/xaL0Dg6spCWI2KBppCitsxMipRaVZbNGVjifX+2Yl
# LArgterQWlhiZRfG1jokeaofkls9KXIqOkI3EhXt0sx4e942WxNqAvJyqu/bzohb
# prFyXpAgrgD3ZyKoUzdDmSz26JZpEFsAFEoSsUrItrUdHxz0syep3XVk8WkEAsY=
# SIG # End signature block
