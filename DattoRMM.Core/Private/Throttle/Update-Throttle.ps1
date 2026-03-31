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

            $OpName = $_.Name

            if ($Script:RMMThrottle.OperationBuckets.ContainsKey($OpName)) {

                # Update limit in case it changed dynamically
                $Script:RMMThrottle.OperationBuckets[$OpName].Limit = $_.Value.limit

            } else {

                # New operation appeared — add bucket
                $Script:RMMThrottle.OperationBuckets[$OpName] = @{
                    Limit           = $_.Value.limit
                    LocalTimestamps = [System.Collections.Generic.List[datetime]]::new()
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

        $Script:RMMThrottle.WriteDelayMS = $Script:RMMThrottle.WriteUtilisation * $Script:RMMThrottle.WriteDelayMultiplier

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
# MIIcXwYJKoZIhvcNAQcCoIIcUDCCHEwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAMgPDQWwNv2skg
# nxTq4f3fJstyZNtieAn6l6AlMNuSIaCCFogwggNKMIICMqADAgECAhB464iXHfI6
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
# XpF9pOzFLMUwggWNMIIEdaADAgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3
# DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAX
# BgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3Vy
# ZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBH
# NDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIw
# aTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLK
# EdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4Tm
# dDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembu
# d8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnD
# eMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1
# XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVld
# QnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTS
# YW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSm
# M9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzT
# QRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6Kx
# fgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/
# MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv
# 9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBr
# MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUH
# MAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYG
# BFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72a
# rKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFID
# yE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/o
# Wajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv
# 76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30
# fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQwgga0MIIE
# nKADAgECAhANx6xXBf8hmS5AQyIMOkmGMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNV
# BAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdp
# Y2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0y
# NTA1MDcwMDAwMDBaFw0zODAxMTQyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYD
# VQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBH
# NCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEwggIiMA0GCSqG
# SIb3DQEBAQUAA4ICDwAwggIKAoICAQC0eDHTCphBcr48RsAcrHXbo0ZodLRRF51N
# rY0NlLWZloMsVO1DahGPNRcybEKq+RuwOnPhof6pvF4uGjwjqNjfEvUi6wuim5ba
# p+0lgloM2zX4kftn5B1IpYzTqpyFQ/4Bt0mAxAHeHYNnQxqXmRinvuNgxVBdJkf7
# 7S2uPoCj7GH8BLuxBG5AvftBdsOECS1UkxBvMgEdgkFiDNYiOTx4OtiFcMSkqTtF
# 2hfQz3zQSku2Ws3IfDReb6e3mmdglTcaarps0wjUjsZvkgFkriK9tUKJm/s80Fio
# cSk1VYLZlDwFt+cVFBURJg6zMUjZa/zbCclF83bRVFLeGkuAhHiGPMvSGmhgaTzV
# yhYn4p0+8y9oHRaQT/aofEnS5xLrfxnGpTXiUOeSLsJygoLPp66bkDX1ZlAeSpQl
# 92QOMeRxykvq6gbylsXQskBBBnGy3tW/AMOMCZIVNSaz7BX8VtYGqLt9MmeOreGP
# RdtBx3yGOP+rx3rKWDEJlIqLXvJWnY0v5ydPpOjL6s36czwzsucuoKs7Yk/ehb//
# Wx+5kMqIMRvUBDx6z1ev+7psNOdgJMoiwOrUG2ZdSoQbU2rMkpLiQ6bGRinZbI4O
# Lu9BMIFm1UUl9VnePs6BaaeEWvjJSjNm2qA+sdFUeEY0qVjPKOWug/G6X5uAiynM
# 7Bu2ayBjUwIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4E
# FgQU729TSunkBnx6yuKQVvYv1Ensy04wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5n
# P+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcG
# CCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQu
# Y29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGln
# aUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNV
# HSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIB
# ABfO+xaAHP4HPRF2cTC9vgvItTSmf83Qh8WIGjB/T8ObXAZz8OjuhUxjaaFdleMM
# 0lBryPTQM2qEJPe36zwbSI/mS83afsl3YTj+IQhQE7jU/kXjjytJgnn0hvrV6hqW
# Gd3rLAUt6vJy9lMDPjTLxLgXf9r5nWMQwr8Myb9rEVKChHyfpzee5kH0F8HABBgr
# 0UdqirZ7bowe9Vj2AIMD8liyrukZ2iA/wdG2th9y1IsA0QF8dTXqvcnTmpfeQh35
# k5zOCPmSNq1UH410ANVko43+Cdmu4y81hjajV/gxdEkMx1NKU4uHQcKfZxAvBAKq
# MVuqte69M9J6A47OvgRaPs+2ykgcGV00TYr2Lr3ty9qIijanrUR3anzEwlvzZiiy
# fTPjLbnFRsjsYg39OlV8cipDoq7+qNNjqFzeGxcytL5TTLL4ZaoBdqbhOhZ3ZRDU
# phPvSRmMThi0vw9vODRzW6AxnJll38F0cuJG7uEBYTptMSbhdhGQDpOXgpIUsWTj
# d6xpR6oaQf/DJbg3s6KCLPAlZ66RzIg9sC+NJpud/v4+7RWsWCiKi9EOLLHfMR2Z
# yJ/+xhCx9yHbxtl5TPau1j/1MIDpMPx0LckTetiSuEtQvLsNz3Qbp7wGWqbIiOWC
# nb5WqxL3/BAPvIXKUjPSxyZsq8WhbaM2tszWkPZPubdcMIIG7TCCBNWgAwIBAgIQ
# CoDvGEuN8QWC0cR2p5V0aDANBgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0
# ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMB4XDTI1
# MDYwNDAwMDAwMFoXDTM2MDkwMzIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNV
# BAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBTSEEyNTYgUlNB
# NDA5NiBUaW1lc3RhbXAgUmVzcG9uZGVyIDIwMjUgMTCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBANBGrC0Sxp7Q6q5gVrMrV7pvUf+GcAoB38o3zBlCMGMy
# qJnfFNZx+wvA69HFTBdwbHwBSOeLpvPnZ8ZN+vo8dE2/pPvOx/Vj8TchTySA2R4Q
# KpVD7dvNZh6wW2R6kSu9RJt/4QhguSssp3qome7MrxVyfQO9sMx6ZAWjFDYOzDi8
# SOhPUWlLnh00Cll8pjrUcCV3K3E0zz09ldQ//nBZZREr4h/GI6Dxb2UoyrN0ijtU
# DVHRXdmncOOMA3CoB/iUSROUINDT98oksouTMYFOnHoRh6+86Ltc5zjPKHW5KqCv
# pSduSwhwUmotuQhcg9tw2YD3w6ySSSu+3qU8DD+nigNJFmt6LAHvH3KSuNLoZLc1
# Hf2JNMVL4Q1OpbybpMe46YceNA0LfNsnqcnpJeItK/DhKbPxTTuGoX7wJNdoRORV
# bPR1VVnDuSeHVZlc4seAO+6d2sC26/PQPdP51ho1zBp+xUIZkpSFA8vWdoUoHLWn
# qWU3dCCyFG1roSrgHjSHlq8xymLnjCbSLZ49kPmk8iyyizNDIXj//cOgrY7rlRyT
# laCCfw7aSUROwnu7zER6EaJ+AliL7ojTdS5PWPsWeupWs7NpChUk555K096V1hE0
# yZIXe+giAwW00aHzrDchIc2bQhpp0IoKRR7YufAkprxMiXAJQ1XCmnCfgPf8+3mn
# AgMBAAGjggGVMIIBkTAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBTkO/zyMe39/dfz
# kXFjGVBDz2GM6DAfBgNVHSMEGDAWgBTvb1NK6eQGfHrK4pBW9i/USezLTjAOBgNV
# HQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwgZUGCCsGAQUFBwEB
# BIGIMIGFMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXQYI
# KwYBBQUHMAKGUWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRy
# dXN0ZWRHNFRpbWVTdGFtcGluZ1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNydDBfBgNV
# HR8EWDBWMFSgUqBQhk5odHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRU
# cnVzdGVkRzRUaW1lU3RhbXBpbmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcmwwIAYD
# VR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4IC
# AQBlKq3xHCcEua5gQezRCESeY0ByIfjk9iJP2zWLpQq1b4URGnwWBdEZD9gBq9fN
# aNmFj6Eh8/YmRDfxT7C0k8FUFqNh+tshgb4O6Lgjg8K8elC4+oWCqnU/ML9lFfim
# 8/9yJmZSe2F8AQ/UdKFOtj7YMTmqPO9mzskgiC3QYIUP2S3HQvHG1FDu+WUqW4da
# IqToXFE/JQ/EABgfZXLWU0ziTN6R3ygQBHMUBaB5bdrPbF6MRYs03h4obEMnxYOX
# 8VBRKe1uNnzQVTeLni2nHkX/QqvXnNb+YkDFkxUGtMTaiLR9wjxUxu2hECZpqyU1
# d0IbX6Wq8/gVutDojBIFeRlqAcuEVT0cKsb+zJNEsuEB7O7/cuvTQasnM9AWcIQf
# VjnzrvwiCZ85EE8LUkqRhoS3Y50OHgaY7T/lwd6UArb+BOVAkg2oOvol/DJgddJ3
# 5XTxfUlQ+8Hggt8l2Yv7roancJIFcbojBcxlRcGG0LIhp6GvReQGgMgYxQbV1S3C
# rWqZzBt1R9xJgKf47CdxVRd/ndUlQ05oxYy2zRWVFjF7mcr4C34Mj3ocCVccAvlK
# V9jEnstrniLvUxxVZE/rptb7IRE2lskKPIJgbaP5t2nGj/ULLi49xTcBZU8atufk
# +EMF/cWuiC7POGT75qaL6vdCvHlshtjdNXOCIUjsarfNZzGCBS0wggUpAgEBMFEw
# PTEWMBQGA1UECgwNUm9iZXJ0IEZhZGRlczEjMCEGA1UEAwwaRGF0dG9STU0uQ29y
# ZSBDb2RlIFNpZ25pbmcCEHjriJcd8jqCSwSQMNPKs2wwDQYJYIZIAWUDBAIBBQCg
# gYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0B
# CQQxIgQgpzgmTONSvymVafQPkpDCWAH/CVbLG67EGRPCQVRyc38wDQYJKoZIhvcN
# AQEBBQAEggEAmjZR8ZbAK27690yq4GISKWeT2Cptm+4FQ2TdHbvSP2Ov4TY/Cj4O
# hy8y05w7gIAwHC+JY+B0JyppUKwzvbwsYPx+g/PgBWjYspPVUm7qSuMXkuykL3L6
# 64lrOAAw372fz98d8bBXzsxCV625UyZ8jtAYPhAMJC/o+ksK7IDKNKty9rxPVmZo
# Uqmxs8lZgvkKZULy7p2NjM0T9gskTCRr+O5p07WY3SpWP1W6mPO74ITQkKTBxGPf
# e0kX08ArUU5HXv/XcI0KJ/Fdy00wwiTwki0qzCj2rgIMd1gElfv8kDih5CT8puxu
# 9KoM34mHEyJq/+22TC+FQ4BpIsRPrUSuIqGCAyYwggMiBgkqhkiG9w0BCQYxggMT
# MIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5j
# LjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNB
# NDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUD
# BAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0yNjAzMzEwMDMwMjdaMC8GCSqGSIb3DQEJBDEiBCCCX7j0NVrPK3KtpeVPqhgq
# FGkXQXt6GIyR/khdLG2m8jANBgkqhkiG9w0BAQEFAASCAgAtXYJdVK+wCNptvYTa
# HgNZRb2pnpPL4ehyEQTsEDVQqxQ8O2GA6jG8aNHtYIFD0M8Uqm2B2bmBZRKmV4oC
# hTf5OCB9L5WTy0GI0T65m7jAXwsV4MR4dciG9uwxCbcleVhKolRGZcl9n3HIGnWQ
# 5z7OubwIzlovp6LDpmtjhEPXwtoeC6gYxXFTLqcN5soNA1AqPTe+HtaGPR8dprQS
# 6BJHBUC3nPgTCVwk9/Vy08LdSjNNoCz/Cpp51Yz93I7ZkvoHGHvXcnnKzXVwgw14
# Qksi/X6I1XR+ynyriPpVDGdKn26NiLH+0bRBQKnfT9QOOcAYsE5J7uElD9mJgFeE
# txeODqcTwmziQPsf8KX7RO++9A0h1/z9ss11Pdx6YfXLWcNicavanyVKMiZsbfWs
# I5JzUGXdKsiAgN0f9RUUc0ZjZWqTtnu6ScnwkZaMBoOsALyV6TA3N9O1h7Q3nzZD
# Jo1YNRgdOrbNJgN4lwEXzpRnSpLdSHzlM3uuANBce2W860gczbrFKqM77VA80/m/
# Y4hsFZikq/CbnAiXJAkr5MhS0fiSn0o+bNdxU7+bnEXulsGZ36xlU6csMPD2in9O
# 1WsGkHYi/H6PYzrZLluWYVAThbm5pelO/RQmMQb0V59y9j7wZesA0uzyH4Kl+f/I
# URuV29BekT0pG61qBVF5qFegsA==
# SIG # End signature block
