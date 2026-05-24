<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Removes expired timestamps from all local sliding-window throttle buckets.
.DESCRIPTION
    Prunes timestamps older than the rolling window start from the read bucket,
    write bucket, and all per-operation write buckets. Called before each throttle
    evaluation to ensure local counters reflect only the current window.
#>
function Invoke-ThrottleBucketPrune {
    [CmdletBinding()]
    param (

        [Parameter(
            Mandatory = $true
        )]
        [datetime]
        $WindowStart
    )

    # Prune read timestamps
    while ($Script:RMMThrottle.ReadLocalTimestamps.Count -gt 0 -and $Script:RMMThrottle.ReadLocalTimestamps[0] -lt $WindowStart) {

        $Script:RMMThrottle.ReadLocalTimestamps.RemoveAt(0)

    }

    # Prune global write timestamps
    while ($Script:RMMThrottle.WriteLocalTimestamps.Count -gt 0 -and $Script:RMMThrottle.WriteLocalTimestamps[0] -lt $WindowStart) {

        $Script:RMMThrottle.WriteLocalTimestamps.RemoveAt(0)

    }

    # Prune per-operation write buckets
    foreach ($OpName in @($Script:RMMThrottle.OperationBuckets.Keys)) {

        $Bucket = $Script:RMMThrottle.OperationBuckets[$OpName]

        while ($Bucket.LocalTimestamps.Count -gt 0 -and $Bucket.LocalTimestamps[0] -lt $WindowStart) {

            $Bucket.LocalTimestamps.RemoveAt(0)

        }
    }
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBHefBKi3YbXjmV
# 2lnUau4eiPjiUEvBUDy7N2rUw+5mP6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJJx+VNY/6zAWe2llb8PGCha9dWR
# 8beAk8CVHyT8DRS6MA0GCSqGSIb3DQEBAQUABIIBACDYbM4QYxy+w9HAUWhoYxPV
# fpmPnvcbvKwv6kLB2+uUGItbOPFhPMEeW/MhGODWNosw6OX31jTNQtwSm5x9M3V5
# ZU1AXQxIzhfGMxom2pINUNcXDn+L7KwJE1UIhFzHwuJXGL8/FnipGl5/Ss2YsA8Z
# 5p6QcEPGGUpZEyc7qUki2uac2XbslYmTaFNHWJOGH4o3gFFGTRGHFTKqOapA0Y6g
# ufjUfYPNhe5byRFmeDil7Nk9xpAvPf/01J/4Pzt/grmvj0O0KLnJYJUa1Z4gEzDQ
# Cer7jYalW27/8UmJhMnLS/bljCToQkdkGQLWY6Sw0zWtXvsQjAK3rya2rqMPPX4=
# SIG # End signature block
