<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Loads built-in and user-defined export transforms into module state.
.DESCRIPTION
    Reads the built-in ExportTransforms.psd1 from Private/Data and optionally merges
    user-defined transforms from $HOME/.DattoRMM.Core/ExportTransforms.psd1.

    User transforms are additive. A user entry with the same class and transform name
    as a built-in entry will override the built-in version.

    The merged result is stored in $Script:ExportTransforms for use by Export-RMMObjectCsv.
#>
function Initialize-ExportTransforms {
    [CmdletBinding()]
    param ()

    # Load built-in transforms
    $BuiltInPath = Join-Path $PSScriptRoot '..\Data\ExportTransforms.psd1'

    if (Test-Path $BuiltInPath) {

        $Script:ExportTransforms = Import-PowerShellDataFile -Path $BuiltInPath
        Write-Debug "Loaded built-in export transforms from $BuiltInPath"

    } else {

        $Script:ExportTransforms = @{}
        Write-Warning "Built-in export transforms file not found at $BuiltInPath"

    }

    # Load user-defined transforms from profile directory
    $UserPath = Join-Path (Join-Path $HOME '.DattoRMM.Core') 'ExportTransforms.psd1'

    if (Test-Path $UserPath) {

        try {

            $UserTransforms = Import-PowerShellDataFile -Path $UserPath
            Write-Verbose "Loading user export transforms from $UserPath"

            foreach ($TypeName in $UserTransforms.Keys) {

                if (-not $Script:ExportTransforms.ContainsKey($TypeName)) {

                    $Script:ExportTransforms[$TypeName] = @{}

                }

                foreach ($TransformName in $UserTransforms[$TypeName].Keys) {

                    $Script:ExportTransforms[$TypeName][$TransformName] = $UserTransforms[$TypeName][$TransformName]
                    Write-Debug "User transform loaded: $TypeName/$TransformName"

                }
            }

        } catch {

            Write-Warning "Failed to load user export transforms from $UserPath`: $($_.Exception.Message)"

        }
    }
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAP7Hd7AYhzRHjl
# EnWxDw4T9N+pyh8UjoishdY12qEGiKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIAgSXqbmHk7zx3PrLugKQsYLZZq
# GZ/q1SJ4CYfnlvoPMA0GCSqGSIb3DQEBAQUABIIBAGmTpooGF9M6e/N1DjaWkp/z
# BDabLfvUPgLrLj/n9DFPMAex5H8d8jeBgwOjfWgT7g0LHr+ivwunG9/cZSXoltUS
# AQ7OW8TyZhk961DkO4Wz2acGUCOtvUy/coDO+ZLUJhDlZeckHu92GmvR+cD5+G3V
# M57uXpxBfMvEyNYFjh3uVvk2wociUOf2sb8bAtKJgrUhAfSRAWjuC5jRpgSjYlQv
# bMqToOTXJGR4d4JZflWdAVoPp38vqjsBWSnGc2boqtTPAslgWCC4/u8U6gBywQx0
# 0WV4JRe/6YlcAvvy6XjMfHChP7UCsmEn9cLiof2bU3+LGNWpSuEYxJKxjwH35hI=
# SIG # End signature block
