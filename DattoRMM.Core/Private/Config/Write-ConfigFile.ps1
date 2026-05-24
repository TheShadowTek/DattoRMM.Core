<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Write-ConfigFile {
    <#
    .SYNOPSIS
        Writes the DattoRMM.Core configuration file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Config
    )

    try {

        $ConfigDir = Split-Path -Path $Script:ConfigPath -Parent

        # Create directory if it doesn't exist
        if (-not (Test-Path $ConfigDir)) {

            New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null
            Write-Verbose "Created configuration directory: $ConfigDir"

        }

        # Convert to JSON and write
        $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $Script:ConfigPath -Force -ErrorAction Stop
        Write-Verbose "Configuration saved to: $Script:ConfigPath"

        return $true

    } catch {

        Write-Warning "Failed to write configuration file: $_"
        return $false
        
    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDVjrN1vyyY/66q
# xOw/rN6TYOXKc/j4oUrsC9d4rrwkRaCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIem6oKz6MBw5/7ZOlO1VO5WwbZS
# krJXkPo/oawklcrKMA0GCSqGSIb3DQEBAQUABIIBAGveYmPZBND/L2wN5SpcDo9B
# ZTWngNhdsx5ejf+LQ0WY+yXBngZc0segt/9okRnh4ennouVuYau9bpn4ujiAuFzL
# dNTNcgm7GRqtZ1HuyLqueAQhBZvbD9TxrdOpIgfBqtGT9aFqGC0/tE4w4o1AqYa1
# QzcoWOkFIYYOhFdfXdyt8XtitFwlnvFPs0d7rPL+HlEi8k7lKJActZgVHSVVR9do
# GTY/vNx8XYTX49DCs9rfief/Qvx3pD8IXKZdjmqqdqsS29fwiGfi+OUk9I6WQBUE
# +INNSpzCGgZVkH/uhUrQ7NdIfTYM8oxvB+0eJhJGjZJBVoeEA0sAMTDLBub/ySg=
# SIG # End signature block
