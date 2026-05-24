<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Loads user-supplied Format.ps1xml and Types.ps1xml files from the module profile folder.
.DESCRIPTION
    Scans $HOME/.DattoRMM.Core/ for files matching the naming conventions:

        DattoRMM.Core.<name>.Format.ps1xml
        DattoRMM.Core.<name>.Types.ps1xml

    Matching files are loaded using Update-FormatData and Update-TypeData with -PrependPath,
    allowing user definitions to take precedence over module-shipped defaults.

    Files are loaded in alphabetical order by filename, giving the user a deterministic
    load sequence through naming (e.g., 10-Base before 20-Custom).

    No error is raised if the profile folder does not exist or contains no matching files.
    A malformed file generates a warning and processing continues with remaining files.
#>
function Initialize-UserExtensions {
    [CmdletBinding()]
    param ()

    $ProfileFolder = Join-Path $HOME '.DattoRMM.Core'

    if (-not (Test-Path $ProfileFolder)) {

        Write-Debug "Profile folder not found — no user extensions to load."
        return

    }

    # Load Format extensions
    $FormatFiles = Get-ChildItem -Path $ProfileFolder -Filter 'DattoRMM.Core.*.Format.ps1xml' -ErrorAction SilentlyContinue | Sort-Object Name

    foreach ($File in $FormatFiles) {

        try {

            Update-FormatData -PrependPath $File.FullName
            Write-Verbose "Loaded user format extension: $($File.Name)"

        } catch {

            Write-Warning "Failed to load user format extension '$($File.Name)': $($_.Exception.Message)"

        }
    }

    # Load Types extensions
    $TypeFiles = Get-ChildItem -Path $ProfileFolder -Filter 'DattoRMM.Core.*.Types.ps1xml' -ErrorAction SilentlyContinue |
        Sort-Object Name

    foreach ($File in $TypeFiles) {

        try {

            Update-TypeData -PrependPath $File.FullName
            Write-Verbose "Loaded user type extension: $($File.Name)"

        } catch {

            Write-Warning "Failed to load user type extension '$($File.Name)': $($_.Exception.Message)"

        }
    }
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDKdKmKEungtiSk
# PZq/1mt82NW8NgSExi50DyDlhNp/hKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICJ4C9cjZP17kGS0hxMcezB3SxxX
# 3KbVa/n1KyD8wUUDMA0GCSqGSIb3DQEBAQUABIIBAGsgYeK8TjqI0Uu36hJeQqDO
# pAhzaY6oAzRNLj9qDG8wQ/MV8Nm1oRI/tkG2J00WvPaJ9KC8jOgQ+SAJWfyMdVCF
# E2qiVzLfInKzKLhN7Am9wr9+piRBUmLLGVDc+ICW/JLE8HP24+Tz7lDsTN3U7iKX
# ytbFiRBAXFkYOt0FmQDbx2vHiy42NzOdP/XxekG+TY2uXZ63Mee0TVhoOuPXbVOq
# jQ0cDVFyOS7qNFmBY2ecOccK9XtGLTfxM48lXepd1bhZTbJiDCj45YvW1Fs9W1Tz
# ZwdhwCyL8Miw8gPTmzg4KVEcEVWWnLBIsML5CxgsyRaGWXsiEB05eEBE2bY6sc4=
# SIG # End signature block
