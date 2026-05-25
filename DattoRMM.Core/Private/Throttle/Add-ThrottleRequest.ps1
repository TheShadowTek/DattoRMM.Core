<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Records a completed API request in the local sliding-window throttle counters.
.DESCRIPTION
    Routes the timestamp into the correct bucket based on HTTP method. Read (GET) requests
    are recorded in the read bucket only. Write (PUT/POST/DELETE) requests are recorded in
    the global write bucket and the per-operation write bucket (if the operation is tracked).
    Reads and writes are independent quotas — a read never touches the write bucket and a
    write never touches the read bucket. This function is called after each API response to
    record the timestamp only. Local utilisation ratios are derived from these timestamps at
    evaluation time. API-calibrated utilisation fields are owned exclusively by Update-Throttle.
#>
function Add-ThrottleRequest {
    [CmdletBinding()]
    param (

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = 'Get',

        [string]
        $OperationName
    )

    $Now = [datetime]::UtcNow

    if ($Script:LegacyThrottleMode -or $Method -eq 'Get') {

        # Record in read bucket
        $Script:RMMThrottle.ReadLocalTimestamps.Add($Now)

    } else {

        # Record in global write bucket
        $Script:RMMThrottle.WriteLocalTimestamps.Add($Now)

        # Per-operation write bucket
        if ($OperationName -and $Script:RMMThrottle.OperationBuckets.ContainsKey($OperationName)) {

            $Script:RMMThrottle.OperationBuckets[$OperationName].LocalTimestamps.Add($Now)

        }
    }
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDuwPLnOZ0RG11+
# uO0coMZ3ChK33hfuDQZhQoZwoPDpxqCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAUSe/ELLzzGu+hsIZwefocnAjkW
# 6aRBh6T6pSWmjCW3MA0GCSqGSIb3DQEBAQUABIIBAGfao8yzPALPVfRIlm7DfO6v
# pTQphWHHl7Gy4XNxnwUroz5IN8SGgZw8T8nLn99RmVeuaAoifvFmoCD9tqBbXJfu
# hdh3SzvjJw+naFUhTRUPJ76lkkZ0rP9E/FOsPe5pZ0E/rLRJVzZu26yJsBN59gFU
# VAnpv8facRCXnBY7KZ0ntvO5H7s7cQR1bULVUqlqonww6rgCuUucZS0ssFH7cx3h
# kNVisn0jOrBDyAk5kWlHl4JnFd2FWxMyV3Xl27Bw6ob56QKsKUjGALvD+umQLBhW
# EECGT1fxmg5G3mlYmbMCNUeSF2cLNaPtb2oBrUn1mQdwh9Jv+9nCBGV1tFTgiPY=
# SIG # End signature block
