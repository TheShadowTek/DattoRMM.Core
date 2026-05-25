<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Discovers API rate limits and initialises multi-bucket throttle state.
.DESCRIPTION
    Calls GET /v2/system/request_rate to discover the account's rate limits and populates
    the session throttle state with discovered values. This includes the read limit, write
    limit, and per-operation write buckets (dynamically built from the API response).

    The Datto RMM API tracks reads and writes as independent quotas:
    - accountCount / accountRateLimit   → read (GET) operations only
    - accountWriteCount / accountWriteRateLimit → write (PUT/POST/DELETE) operations only

    Falls back to safe defaults (600/min per bucket, empty operation buckets) if the
    rate-status call fails, logging a warning. Profile settings are not modified — only
    discovered limits and tracking state are initialised.

    Called once by Connect-DattoRMM immediately after successful authentication.
#>
function Initialize-ThrottleState {
    [CmdletBinding()]
    param ()

    try {

        Write-Debug "Throttle: Discovering API rate limits from Datto RMM."
        $RateInfo = Get-RMMRequestRate

        # Read bucket (GET requests)
        $Script:RMMThrottle.ReadLimit = $RateInfo.accountRateLimit
        $Script:RMMThrottle.AccountCutOffRatio = $RateInfo.accountCutOffRatio
        $Script:RMMThrottle.WindowSizeSeconds = $RateInfo.slidingTimeWindowSizeSeconds

        # Write bucket (PUT/POST/DELETE requests)
        $Script:RMMThrottle.WriteLimit = $RateInfo.accountWriteRateLimit

        # Per-operation write buckets — dynamically built from API response
        $Script:RMMThrottle.OperationBuckets = @{}

        if ($null -ne $RateInfo.operationWriteStatus) {

            $RateInfo.operationWriteStatus.PSObject.Properties | ForEach-Object {

                $Script:RMMThrottle.OperationBuckets[$_.Name] = @{
                    Limit = $_.Value.limit
                    LocalTimestamps = [System.Collections.Generic.List[datetime]]::new()
                }
            }
        }

        # Seed local tracking state from current API counters so local utilisation is aligned on connect
        $Script:RMMThrottle.ReadLocalTimestamps = [System.Collections.Generic.List[datetime]]::new()
        $Script:RMMThrottle.WriteLocalTimestamps = [System.Collections.Generic.List[datetime]]::new()

        $Now = [datetime]::UtcNow
        $WindowStart = $Now.AddSeconds(-$Script:RMMThrottle.WindowSizeSeconds)

        $ReadSeedCount = [math]::Max(0, [int]$RateInfo.accountCount)
        $WriteSeedCount = [math]::Max(0, [int]$RateInfo.accountWriteCount)
        $ReadSeedStep = [timespan]::FromSeconds($Script:RMMThrottle.WindowSizeSeconds / [math]::Max($ReadSeedCount, 1))
        $WriteSeedStep = [timespan]::FromSeconds($Script:RMMThrottle.WindowSizeSeconds / [math]::Max($WriteSeedCount, 1))

        for ($i = 0; $i -lt $ReadSeedCount; $i++) {

            $Script:RMMThrottle.ReadLocalTimestamps.Add($WindowStart.AddTicks($ReadSeedStep.Ticks * $i))

        }

        for ($i = 0; $i -lt $WriteSeedCount; $i++) {

            $Script:RMMThrottle.WriteLocalTimestamps.Add($WindowStart.AddTicks($WriteSeedStep.Ticks * $i))

        }

        # Seed per-operation buckets from current API counters when available
        if ($null -ne $RateInfo.operationWriteStatus) {

            $RateInfo.operationWriteStatus.PSObject.Properties | ForEach-Object {

                $OpName = $_.Name
                $OpCount = [math]::Max(0, [int]$_.Value.count)

                if ($Script:RMMThrottle.OperationBuckets.ContainsKey($OpName)) {

                    $OpSeedStep = [timespan]::FromSeconds($Script:RMMThrottle.WindowSizeSeconds / [math]::Max($OpCount, 1))

                    for ($i = 0; $i -lt $OpCount; $i++) {

                        $Script:RMMThrottle.OperationBuckets[$OpName].LocalTimestamps.Add($WindowStart.AddTicks($OpSeedStep.Ticks * $i))

                    }

                    # Seed API-reported utilisation so the per-op floor is available before the first Update-Throttle fires
                    $Script:RMMThrottle.OperationBuckets[$OpName].ApiUtilisation = $OpCount / [math]::Max([int]$_.Value.limit, 1)

                }
            }
        }

        Write-Debug "Throttle: Seeded local window from API baseline — Read=$ReadSeedCount, Write=$WriteSeedCount"

        $Now = [datetime]::UtcNow
        $Script:RMMThrottle.ReadLastCalibrationUtc = $Now
        $Script:RMMThrottle.WriteLastCalibrationUtc = $Now
        $Script:RMMThrottle.ReadSamplesAtLastCalibration = $Script:RMMThrottle.ReadLocalTimestamps.Count
        $Script:RMMThrottle.WriteSamplesAtLastCalibration = $Script:RMMThrottle.WriteLocalTimestamps.Count
        $Script:RMMThrottle.ReadUtilisation = $Script:RMMThrottle.ReadLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.ReadLimit, 1)
        $Script:RMMThrottle.WriteUtilisation = $Script:RMMThrottle.WriteLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.WriteLimit, 1)
        $Script:RMMThrottle.ReadDelayMS = 0
        $Script:RMMThrottle.WriteDelayMS = 0
        $Script:RMMThrottle.Pause = $false
        $Script:RMMThrottle.Throttle = $false

        Write-Verbose "Rate limits discovered: Read=$($Script:RMMThrottle.ReadLimit)/min, Write=$($Script:RMMThrottle.WriteLimit)/min, Operations=$($Script:RMMThrottle.OperationBuckets.Count) buckets."

    } catch {

        Write-Warning "Failed to discover API rate limits: $($_.Exception.Message). Using safe defaults (600/min per bucket)."

        $Script:RMMThrottle.ReadLimit = 600
        $Script:RMMThrottle.AccountCutOffRatio = 0.9
        $Script:RMMThrottle.WindowSizeSeconds = 60
        $Script:RMMThrottle.WriteLimit = 600
        $Script:RMMThrottle.OperationBuckets = @{}

        # Reset local tracking even on failure
        $Script:RMMThrottle.ReadLocalTimestamps = [System.Collections.Generic.List[datetime]]::new()
        $Script:RMMThrottle.WriteLocalTimestamps = [System.Collections.Generic.List[datetime]]::new()

        $Now = [datetime]::UtcNow
        $Script:RMMThrottle.ReadLastCalibrationUtc = $Now
        $Script:RMMThrottle.WriteLastCalibrationUtc = $Now
        $Script:RMMThrottle.ReadSamplesAtLastCalibration = 0
        $Script:RMMThrottle.WriteSamplesAtLastCalibration = 0

    }
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBQmFKOd4TIT1Xt
# S07RgyzrHoksdrVdvrBmcXemFllt4qCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOm0oeNX1Uy6nGGKqzlC1SX4bUIP
# L49kuaNPPtK6wBKcMA0GCSqGSIb3DQEBAQUABIIBADr1TMpAKcZF8P5LigwNHg+a
# IF6fWPR+LZZv34EhSNR8GATx4KuNWJiQFFCE7YR40jzeF3NeCD8pAqjLJ2WuqsGF
# /g8J5OwqbYjIkYiu5yrBkwr1XS2wjdtTlxR/vUwKX0VI5RjVur+NyFhLRNGo0a/9
# SK7VdWYKePLXx21wZ0eOV87B+RCTCpukSMHLYjODX0vQ4FxxTVOCut8+X/66sF+k
# qkr42FtrNseYPrUuvkOWE41AMKGTKYLcZXgkTOFig1FXzTkE291Vrng5aaGWkRYa
# JfqO97maM2koGtV51I2iTyvhLkU+Gf7L2Iwx6e2ZEjt02esfRYptsHpnf2OSLEw=
# SIG # End signature block
