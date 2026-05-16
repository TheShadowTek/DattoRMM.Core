<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '..\DRMMObject\DRMMObject.psm1'
<#
.SYNOPSIS
    Represents the status of the DRMM system, including properties such as version, status, and start time.
.DESCRIPTION
    The DRMMStatus class models the status of the DRMM system, encapsulating properties such as Version, Status, and Started. The class provides a constructor and a static method to create an instance from API response data. The FromAPIMethod static method takes a response object, extracts the relevant information, and populates the properties of the DRMMStatus instance accordingly. The class serves as a representation of the current status of the DRMM system, allowing for easy access to version information, overall status, and the time when the system started.
#>
class DRMMStatus : DRMMObject {

    # The version of the Datto RMM platform.
    [string]$Version
    # The current operational status of the Datto RMM platform.
    [string]$Status
    # The UTC date and time when the Datto RMM service was started.
    [Nullable[datetime]]$Started

    DRMMStatus() : base() {

    }

    static [DRMMStatus] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Result = [DRMMStatus]::new()
        $Result.Version = $Response.version
        $Result.Status = $Response.status
        
        $Result.Started = [DRMMObject]::ParseApiDateTime($Response.started)

        return $Result

    }
}
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCpnW2zSsxfUhts
# Lc9aJ/TUjMqsdVEigJQjTHiJrcklRKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICmw4cR5c0hWfqgpXT01zrD+aLDO
# XRq3f7vIZWBzYtJKMA0GCSqGSIb3DQEBAQUABIIBACUlbybQOlrIxz74tvMM3ipE
# oOhHIJ4RiLC6WP83iMKjBJVjIyuNgr5zCwrbfJzF0EmU7Vkwh10JBYRxFl59+jrA
# ZJj6sLmtNcur+eR4m8RTSaw7ACOnJAOY5bzzptY4QYtXKG/kzolLpBBATnwuVqb+
# lYdl3BJqksbPEZrDjOJXaw//V9u3W2sPUjBKI9ouioT3jinRI9mqqHNdo8m1llB+
# etjdLqLvm7UEuAlZWqulVR2qW501sUI2MUueyBchXZWAmD9ffFlVobbjnneKZgLy
# dFqj/TzuhRxgR3q5ruqQas8WTTZL/uF+2DTDgQaMAzCg21jvj29Q0fVqCti52+M=
# SIG # End signature block
