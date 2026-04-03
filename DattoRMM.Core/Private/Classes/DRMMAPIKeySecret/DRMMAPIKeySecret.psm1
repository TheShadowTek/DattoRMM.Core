<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '..\DRMMObject\DRMMObject.psm1'
<#
.SYNOPSIS
    Represents API key and secret information for authenticating with the DRMM API.
.DESCRIPTION
    The DRMMAPIKeySecret class encapsulates the API key, API secret, and associated username for a DRMM account. It provides a static method to create an instance of the class from a typical API response object that contains these credentials. The API secret is stored as a secure string to enhance security when handling sensitive information.
.LINK
    Reset-RMMApiKeys
#>
class DRMMAPIKeySecret : DRMMObject {

    # API authentication key.
    [string]$ApiKey
    # API authentication secret.
    [securestring]$ApiSecret
    # Username associated with the API key and secret.
    [string]$Username

    DRMMAPIKeySecret() : base() {

    }

    static [DRMMAPIKeySecret] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $KeySecret = [DRMMAPIKeySecret]::new()
        $KeySecret.ApiKey = $Response.apiAccessKey
        $KeySecret.ApiSecret = ConvertTo-SecureString -String $Response.apiSecretKey -AsPlainText -Force
        $Response.apiSecretKey = $null # Clear plain text secret from memory
        $KeySecret.Username = $Response.userName

        return $KeySecret

    }

}
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBIXQtReN9ZR/9A
# HIc62KXgr1x7gJFMNu+9rmL98K5lJKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIdLF3nP8tjm306HQdTQKUgDd4i4
# GENECTNMIPrsjO15MA0GCSqGSIb3DQEBAQUABIIBAJaLopzbxI0J4E3Ub0XfBK8q
# 8aWliaC5Lp/lqIGBexCuRbHMmbIaaK9UEcd+fcBVSS0mrMoTc2A6WRF+JOpAroU5
# s89q4hbZfUV2FJ97NzHmNX2tgESCxHoYebf4pmeCQ27wecoN91xh+90/0Kgt07lk
# uNs6KkXLzaeKj8ldPBe7zVJRHbO3+xO9VfxYLEFE1VXSJR88GShX2HUmNTyECxEn
# ie9t60F2MVmOVH2wPTcyZlTgWsMQU+aOKocsyjJpahyE1m117rgn/0Ddeyk1GDbA
# 2UFGLdDjYpDokMKYG6RO/I0pXRXs5VRmEJRvKaDPDTZTz+H6tTZdq9CF0PSfmvs=
# SIG # End signature block
