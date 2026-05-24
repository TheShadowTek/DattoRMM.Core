<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Calibrates local throttle state against actual API-reported utilisation.
.DESCRIPTION
    Calls the rate-status endpoint and adjusts the local sliding-window model for both
    read and write buckets independently. If the API reports higher utilisation than local
    tracking (indicating concurrent sessions or external API consumers), the local model
    adopts the higher value. Also refreshes per-operation bucket limits in case they have
    been adjusted by Datto.

    The Datto RMM API tracks reads and writes as independent quotas:
    - accountCount / accountRateLimit   → read (GET) operations only
    - accountWriteCount / accountWriteRateLimit → write (PUT/POST/DELETE) operations only
    Read and write delays are computed independently against their respective buckets.
#>
function Update-Throttle {
    [CmdletBinding()]
    param ()

    $Now = [datetime]::UtcNow
    $WindowStart = $Now.AddSeconds(-$Script:RMMThrottle.WindowSizeSeconds)

    $PrePruneReadCount = $Script:RMMThrottle.ReadLocalTimestamps.Count
    $PrePruneWriteCount = $Script:RMMThrottle.WriteLocalTimestamps.Count

    # Ensure local counters are always aligned to the active rolling window before calibration
    Invoke-ThrottleBucketPrune -WindowStart $WindowStart

    $PostPruneReadCount = $Script:RMMThrottle.ReadLocalTimestamps.Count
    $PostPruneWriteCount = $Script:RMMThrottle.WriteLocalTimestamps.Count

    Write-Debug "Throttle: Local prune window $($Script:RMMThrottle.WindowSizeSeconds)s | Read $PrePruneReadCount->$PostPruneReadCount | Write $PrePruneWriteCount->$PostPruneWriteCount"

    try {

        $RateInfo = Get-RMMRequestRate

    } catch {

        Write-Debug "Throttle: Calibration failed — $($_.Exception.Message). Retaining local state."
        return

    }

    $PauseThreshold = $RateInfo.accountCutOffRatio - $Script:RMMThrottle.ThrottleCutOffOverhead

    # --- Read bucket calibration ---
    $ApiReadUtil = $RateInfo.accountCount / [math]::Max($RateInfo.accountRateLimit, 1)
    $LocalReadUtil = $Script:RMMThrottle.ReadLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.ReadLimit, 1)

    # Use the higher of API-reported or local-tracked utilisation
    # This handles concurrent sessions consuming the shared quota
    $Script:RMMThrottle.ReadUtilisation = [math]::Max($ApiReadUtil, $LocalReadUtil)

    # --- Write bucket calibration ---
    if ($RateInfo.accountWriteRateLimit -gt 0) {

        $ApiWriteUtil = $RateInfo.accountWriteCount / [math]::Max($RateInfo.accountWriteRateLimit, 1)
        $LocalWriteUtil = $Script:RMMThrottle.WriteLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.WriteLimit, 1)
        $Script:RMMThrottle.WriteUtilisation = [math]::Max($ApiWriteUtil, $LocalWriteUtil)

    }

    # --- Per-operation calibration: refresh limits and add any new operation buckets ---
    if ($null -ne $RateInfo.operationWriteStatus) {

        $RateInfo.operationWriteStatus.PSObject.Properties | ForEach-Object {

            $OpName    = $_.Name
            $ApiOpCount = [math]::Max(0, [int]$_.Value.count)
            $ApiOpUtil  = $ApiOpCount / [math]::Max([int]$_.Value.limit, 1)

            if ($Script:RMMThrottle.OperationBuckets.ContainsKey($OpName)) {

                # Update limit and API-reported utilisation in case either changed dynamically
                $Script:RMMThrottle.OperationBuckets[$OpName].Limit          = $_.Value.limit
                $Script:RMMThrottle.OperationBuckets[$OpName].ApiUtilisation = $ApiOpUtil

            } else {

                # New operation appeared — add bucket
                $Script:RMMThrottle.OperationBuckets[$OpName] = @{
                    Limit           = $_.Value.limit
                    LocalTimestamps = [System.Collections.Generic.List[datetime]]::new()
                    ApiUtilisation  = $ApiOpUtil
                }

            }
        }
    }

    # --- Update computed flags ---
    # Throttle/pause triggers if EITHER read OR write bucket exceeds threshold
    $ReadThrottle = ($Script:RMMThrottle.ReadUtilisation -ge $Script:RMMThrottle.ThrottleUtilisationThreshold)
    $WriteThrottle = ($Script:RMMThrottle.WriteUtilisation -ge $Script:RMMThrottle.ThrottleUtilisationThreshold)
    $Script:RMMThrottle.Throttle = ($ReadThrottle -or $WriteThrottle)

    $ReadPause = ($Script:RMMThrottle.ReadUtilisation -ge $PauseThreshold)
    $WritePause = ($Script:RMMThrottle.WriteUtilisation -ge $PauseThreshold)
    $Script:RMMThrottle.Pause = ($ReadPause -or $WritePause)

    # Compute independent delays for each track
    if ($ReadThrottle) {

        $Script:RMMThrottle.ReadDelayMS = $Script:RMMThrottle.ReadUtilisation * $Script:RMMThrottle.DelayMultiplier

    } else {

        $Script:RMMThrottle.ReadDelayMS = 0

    }

    if ($WriteThrottle) {

        $Script:RMMThrottle.WriteDelayMS = $Script:RMMThrottle.WriteUtilisation * $Script:RMMThrottle.DelayMultiplier

    } else {

        $Script:RMMThrottle.WriteDelayMS = 0

    }

    # Reset both calibration trackers — both tracks received fresh data
    $Now = [datetime]::UtcNow
    $Script:RMMThrottle.ReadLastCalibrationUtc = $Now
    $Script:RMMThrottle.WriteLastCalibrationUtc = $Now
    $Script:RMMThrottle.ReadSamplesAtLastCalibration = $Script:RMMThrottle.ReadLocalTimestamps.Count
    $Script:RMMThrottle.WriteSamplesAtLastCalibration = $Script:RMMThrottle.WriteLocalTimestamps.Count

    # Build per-operation write bucket summary lines for debug output
    $OpLines = @()
    if ($Script:RMMThrottle.OperationBuckets -and $Script:RMMThrottle.OperationBuckets.Count -gt 0) {
        $Script:RMMThrottle.OperationBuckets.GetEnumerator() | ForEach-Object {
            $OpName = $_.Key
            $Bucket = $_.Value
            $LocalCount = if ($Bucket.LocalTimestamps) { $Bucket.LocalTimestamps.Count } else { 0 }
            $Limit = if ($Bucket.Limit) { $Bucket.Limit } else { 0 }
            $UtilPct = if ($Limit -gt 0) { [math]::Round(($LocalCount / $Limit) * 100, 2) } else { 0 }
            $OpLines += ("{0}: Limit={1} Local={2} Util={3}%" -f $OpName, $Limit, $LocalCount, $UtilPct)
        }
    }

    $OpLinesText = if ($OpLines.Count -gt 0) { $OpLines -join "`n`t" } else { 'none' }

    Write-Debug @"
Throttle Calibration:
`tRead Utilisation: $([math]::Round($Script:RMMThrottle.ReadUtilisation * 100, 2))% (API: $([math]::Round($ApiReadUtil * 100, 2))%, Local: $([math]::Round($LocalReadUtil * 100, 2))%)
`tWrite Utilisation: $([math]::Round($Script:RMMThrottle.WriteUtilisation * 100, 2))%
`tLocal Counts: Read=$PostPruneReadCount, Write=$PostPruneWriteCount
`tAPI Counts: Read=$($RateInfo.accountCount), Write=$($RateInfo.accountWriteCount)
`tRead Limit: $($Script:RMMThrottle.ReadLimit) | Write Limit: $($Script:RMMThrottle.WriteLimit)
`tOperation Buckets: $($Script:RMMThrottle.OperationBuckets.Count)
`tOperation Stats:
`t$OpLinesText
`tPause Threshold: $([math]::Round($PauseThreshold * 100, 2))%
`tThrottle: $($Script:RMMThrottle.Throttle) | Pause: $($Script:RMMThrottle.Pause)
`tRead Delay MS: $([math]::Round($Script:RMMThrottle.ReadDelayMS, 2)) | Write Delay MS: $([math]::Round($Script:RMMThrottle.WriteDelayMS, 2))
"@

}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDIHgFpJaYwr/BC
# Shm2dK8sWthQF9+fA4Oo1f+n30oUHqCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHrdIkTHhaM4Fav9y4Dy8rrYTiyi
# 0cpWPyVHhpYH4lszMA0GCSqGSIb3DQEBAQUABIIBABbzytnYMzcCqauxzrMoS7Ef
# F/4KFfVBWX1K0CEKU3pHb6rUrsa6vCdwk44TwL0sOcipfNKEqNTUrMdc+9jArzR8
# nVyr9VxCk+85IAtBjTmou+r6pdHRO/78horSmqNFH6J7CSRwV1Uhe01DXJmhZ439
# 1DAtOaeBlprr9Kar4YN759ENAdUMYVRlPLlAGXlmTJ2n9A6dH30d3OqPl8n12Qyr
# PTcTAvRlAJKKn8ZiBSxYs+uYx4trJhhSuptns8jVZsZMQFzK0kzFtche//ifqfz/
# o8TOFcVgxngwnEb2iAW/pLD+5dugI4fhgESw5RzYPCbsSJFIwGBazF3cpUL3pGM=
# SIG # End signature block
