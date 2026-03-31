<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Pre-request throttle gate with independent read/write calibration and time-based pacing.
.DESCRIPTION
    Evaluates the appropriate bucket(s) based on HTTP method before each API request. Read
    (GET) requests are evaluated against the read bucket only. Write (PUT/POST/DELETE) requests
    are evaluated against the global write bucket and per-operation write buckets only. Reads
    and writes are independent quotas and never cross-evaluate.

    Each track maintains its own calibration state (confidence, drift, interval, samples).
    When either track triggers calibration, Update-Throttle is called once and both tracks
    receive fresh data from the API. The highest pressure across all applicable buckets for
    the current request type determines the actual delay applied.

    Calibration frequency per track is governed by three floors (highest wins):
      1. CalibrationMinSeconds — absolute floor to prevent API spam.
      2. Base × Confidence × DriftFactor — dynamic formula based on sample count and drift.
      3. Delay-pacing floor — current delay × 10, ensuring enough paced requests pass
         between calibrations to avoid wasting overhead when throttling is already active.
#>
function Invoke-ApiThrottle {
    [CmdletBinding()]
    param (

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = 'Get',

        [string]
        $OperationName
    )

    $IsRead = ($Method -eq 'Get')
    $Now = [datetime]::UtcNow
    $WindowStart = $Now.AddSeconds(-$Script:RMMThrottle.WindowSizeSeconds)

    # --- Prune expired timestamps from all local buckets ---
    Invoke-ThrottleBucketPrune -WindowStart $WindowStart

    # --- Select the active track's state for calibration ---
    if ($IsRead) {

        $LocalSampleCount = $Script:RMMThrottle.ReadLocalTimestamps.Count
        $LocalUtil = $LocalSampleCount / [math]::Max($Script:RMMThrottle.ReadLimit, 1)
        $EffectiveUtil = [math]::Max($Script:RMMThrottle.ReadUtilisation, $LocalUtil)
        $StoredUtil = $Script:RMMThrottle.ReadUtilisation
        $CurrentDelayMS = $Script:RMMThrottle.ReadDelayMS
        $LastCalibrationUtc = $Script:RMMThrottle.ReadLastCalibrationUtc
        $SamplesAtLastCalibration = $Script:RMMThrottle.ReadSamplesAtLastCalibration
        $TrackLabel = 'Read'

    } else {

        $LocalSampleCount = $Script:RMMThrottle.WriteLocalTimestamps.Count
        $LocalUtil = $LocalSampleCount / [math]::Max($Script:RMMThrottle.WriteLimit, 1)
        $EffectiveUtil = [math]::Max($Script:RMMThrottle.WriteUtilisation, $LocalUtil)
        $StoredUtil = $Script:RMMThrottle.WriteUtilisation
        $CurrentDelayMS = $Script:RMMThrottle.WriteDelayMS
        $LastCalibrationUtc = $Script:RMMThrottle.WriteLastCalibrationUtc
        $SamplesAtLastCalibration = $Script:RMMThrottle.WriteSamplesAtLastCalibration
        $TrackLabel = 'Write'

    }

    # --- Time-based calibration with confidence-weighted dynamic interval ---

    # Drift detection: gap between API-reported and local-tracked utilisation
    # Any measurable gap indicates concurrent sessions or external API consumers
    $DriftGap = [math]::Abs($StoredUtil - $LocalUtil)

    # Confidence factor: how much we trust local tracking based on sample count
    # Few samples (early window) → low confidence → short interval → frequent calibration
    # Many samples (full window) → high confidence → full base interval → trust local
    $ConfidenceFactor = [math]::Min(1.0, $LocalSampleCount / [math]::Max($Script:RMMThrottle.CalibrationConfidenceCount, 1))

    # Drift factor: collapses interval as drift exceeds sensitivity threshold
    # DriftRatio: how far over the threshold (0 = no drift, 1 = at threshold, 5 = 5x threshold)
    # DriftFactor: 1.0 = no drift, 0.33 = at threshold, ~0 = extreme drift
    if ($DriftGap -gt 0 -and $Script:RMMThrottle.DriftThresholdPercent -gt 0) {

        $DriftRatio = $DriftGap / $Script:RMMThrottle.DriftThresholdPercent

    } else {

        $DriftRatio = 0

    }

    $DriftFactor = 1 / (1 + $DriftRatio * $Script:RMMThrottle.DriftScalingFactor)

    # Delay-pacing floor: when delays are active, scale calibration interval so that
    # enough requests pass between calibrations to avoid wasting API calls on
    # calibration overhead during well-paced operation.
    # DelayMS 800 × 10 = 8s floor → ~10 requests between calibrations.
    # DelayMS 0 × 10 = 0 → no effect, confidence/drift formula governs.
    $DelayPacingFloorSeconds = ($CurrentDelayMS / 1000) * 10

    # Effective interval: highest of three floors:
    #   1. CalibrationMinSeconds: absolute floor to prevent API spam
    #   2. Base × Confidence × DriftFactor: dynamic formula
    #   3. DelayPacingFloor: delay-correlated floor when throttling is active
    # Low confidence OR high drift → short interval → frequent calibration
    # High confidence AND low drift → full base → minimal API overhead
    # High delay → long interval → let paced requests breathe between calibrations
    $EffectiveInterval = [math]::Max(
        $Script:RMMThrottle.CalibrationMinSeconds,
        [math]::Max(
            $Script:RMMThrottle.CalibrationBaseSeconds * $ConfidenceFactor * $DriftFactor,
            $DelayPacingFloorSeconds
        )
    )

    $ElapsedSeconds = ($Now - $LastCalibrationUtc).TotalSeconds

    # Request-count gate: caps how many requests can pass between calibrations.
    # Three tiers based on the session's current phase:
    #   1. Building confidence (< 100%): tight gate — detect concurrent sessions early
    #   2. Full confidence, below threshold: moderate gate — no delays to limit frequency
    #   3. Full confidence, at/above threshold: disabled — delays naturally pace requests
    $Threshold = [math]::Max($Script:RMMThrottle.ThrottleUtilisationThreshold, 0.01)
    $RequestsSinceCalibration = $LocalSampleCount - $SamplesAtLastCalibration

    if ($ConfidenceFactor -lt 1.0) {

        $RequestGateLimit = [math]::Max(10, [math]::Ceiling($Script:RMMThrottle.CalibrationConfidenceCount * 0.2))

    } elseif ($EffectiveUtil -lt $Threshold) {

        $RequestGateLimit = [math]::Max(10, [math]::Ceiling($Script:RMMThrottle.CalibrationConfidenceCount * 0.4))

    } else {

        $RequestGateLimit = 0

    }

    $RequestGateTriggered = $RequestGateLimit -gt 0 -and $RequestsSinceCalibration -ge $RequestGateLimit

    if ($ElapsedSeconds -ge $EffectiveInterval -or $RequestGateTriggered) {

        if ($DriftGap -ge $Script:RMMThrottle.DriftThresholdPercent) {

            Write-Debug "Throttle[$TrackLabel]: Drift $([math]::Round($DriftGap * 100, 1))% (Stored: $([math]::Round($StoredUtil * 100, 1))% vs Local: $([math]::Round($LocalUtil * 100, 1))%) — interval $([math]::Round($EffectiveInterval, 2))s."

        }

        $CalibrationTrigger = if ($RequestGateTriggered -and $ElapsedSeconds -lt $EffectiveInterval) {'request-gate'} else {'interval'}
        Write-Debug "Throttle[$TrackLabel]: Calibrating ($CalibrationTrigger, $([math]::Round($ElapsedSeconds, 1))s since last, interval $([math]::Round($EffectiveInterval, 2))s, confidence $([math]::Round($ConfidenceFactor * 100, 0))%, samples $LocalSampleCount, +$RequestsSinceCalibration since last)."
        Update-Throttle

        # Refresh effective utilisation after calibration
        if ($IsRead) {

            $LocalUtil = $Script:RMMThrottle.ReadLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.ReadLimit, 1)
            $EffectiveUtil = [math]::Max($Script:RMMThrottle.ReadUtilisation, $LocalUtil)

        } else {

            $LocalUtil = $Script:RMMThrottle.WriteLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.WriteLimit, 1)
            $EffectiveUtil = [math]::Max($Script:RMMThrottle.WriteUtilisation, $LocalUtil)

        }
    }

    # --- Calculate max delay across all applicable buckets for this request type ---
    # Evaluate every bucket relevant to the request's HTTP method and determine:
    #   1. MaxDelay — highest computed delay across all applicable buckets
    #   2. ShouldPause — whether any bucket exceeds the pause threshold
    # For writes, the highest utilisation across global write AND per-operation
    # buckets governs both delay and pause decisions.
    $MaxDelay = 0
    $ShouldPause = $false
    $PauseBucketLabel = ''
    $PauseBucketUtil = 0
    $PauseThreshold = $Script:RMMThrottle.AccountCutOffRatio - $Script:RMMThrottle.ThrottleCutOffOverhead

    if ($IsRead) {

        # Read requests: evaluate read bucket only
        # Seed MaxDelay with the last calibration-determined value as a floor.
        # This carries the API-reported picture forward between calibrations,
        # preventing sessions with low local sample counts from being undercharged
        # when other concurrent sessions are consuming shared quota.
        if ($Script:RMMThrottle.ReadDelayMS -gt 0) {

            $MaxDelay = $Script:RMMThrottle.ReadDelayMS

        }

        if ($EffectiveUtil -ge $PauseThreshold) {

            $ShouldPause = $true
            $PauseBucketLabel = 'Read'
            $PauseBucketUtil = $EffectiveUtil

        } elseif ($EffectiveUtil -ge $Script:RMMThrottle.ThrottleUtilisationThreshold) {

            $Delay = $EffectiveUtil * $Script:RMMThrottle.DelayMultiplier
            $MaxDelay = [math]::Max($MaxDelay, $Delay)

        }

    } else {

        # Write requests: evaluate global write bucket + per-operation bucket
        # Seed MaxDelay from calibration-determined write delay floor
        if ($Script:RMMThrottle.WriteDelayMS -gt 0) {

            $MaxDelay = $Script:RMMThrottle.WriteDelayMS

        }

        # Global write bucket
        if ($Script:RMMThrottle.WriteLimit -gt 0) {

            $WriteUtil = $Script:RMMThrottle.WriteLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.WriteLimit, 1)

            if ($WriteUtil -ge $PauseThreshold) {

                $ShouldPause = $true
                $PauseBucketLabel = 'Write'
                $PauseBucketUtil = $WriteUtil

            } elseif ($WriteUtil -ge $Script:RMMThrottle.ThrottleUtilisationThreshold) {

                $Delay = $WriteUtil * $Script:RMMThrottle.WriteDelayMultiplier
                $MaxDelay = [math]::Max($MaxDelay, $Delay)

            }
        }

        # Per-operation write bucket (if operation is tracked)
        if ($OperationName -and $Script:RMMThrottle.OperationBuckets.ContainsKey($OperationName)) {

            $OpBucket = $Script:RMMThrottle.OperationBuckets[$OperationName]
            $OpUtil = $OpBucket.LocalTimestamps.Count / [math]::Max($OpBucket.Limit, 1)

            if ($OpUtil -ge $PauseThreshold) {

                $ShouldPause = $true

                if ($OpUtil -gt $PauseBucketUtil) {

                    $PauseBucketLabel = $OperationName
                    $PauseBucketUtil = $OpUtil

                }

            } elseif ($OpUtil -ge $Script:RMMThrottle.ThrottleUtilisationThreshold) {

                $Delay = $OpUtil * $Script:RMMThrottle.WriteDelayMultiplier
                $MaxDelay = [math]::Max($MaxDelay, $Delay)

            }

        } elseif ($OperationName) {

            # Unknown write operation — apply conservative safety delay
            $SafetyDelay = $Script:RMMThrottle.UnknownOperationSafetyFactor * $Script:RMMThrottle.WriteDelayMultiplier

            if ($SafetyDelay -gt 0) {

                $MaxDelay = [math]::Max($MaxDelay, $SafetyDelay)
                Write-Debug "Throttle: Unknown write operation '$OperationName' — safety delay $([math]::Round($SafetyDelay, 0))ms."

            }
        }
    }

    # --- Apply throttling ---
    # Write-Warning is wrapped in a local $WarningPreference override to prevent callers
    # that set -WarningAction Stop (e.g. New-RMMVariable) from converting the throttle
    # pause warning into a terminating error. The pause warning is an operational signal
    # that must always complete — it precedes a mandatory Start-Sleep.
    if ($ShouldPause) {

        while ($ShouldPause) {

            $SavedWarningPreference = $WarningPreference
            $WarningPreference = 'Continue'
            Write-Warning "High API utilisation detected ($PauseBucketLabel $([math]::Round($PauseBucketUtil * 100, 2))%). Pausing requests to avoid rate limiting."
            $WarningPreference = $SavedWarningPreference

            Write-Debug "Throttle[$TrackLabel]: Pause triggered by '$PauseBucketLabel' at $([math]::Round($PauseBucketUtil * 100, 2))% (threshold $([math]::Round($PauseThreshold * 100, 2))%). Sleeping 60s."
            Start-Sleep -Seconds 60
            Write-Debug "Throttle[$TrackLabel]: Pause sleep completed. Re-evaluating all applicable buckets."
            Update-Throttle

            # Re-evaluate ALL applicable buckets after calibration — pause continues
            # until the highest utilisation across every relevant bucket drops below threshold
            $ShouldPause = $false
            $PauseBucketUtil = 0
            $PauseBucketLabel = ''

            if ($IsRead) {

                $LocalUtil = $Script:RMMThrottle.ReadLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.ReadLimit, 1)
                $EffectiveUtil = [math]::Max($Script:RMMThrottle.ReadUtilisation, $LocalUtil)

                if ($EffectiveUtil -ge $PauseThreshold) {

                    $ShouldPause = $true
                    $PauseBucketLabel = 'Read'
                    $PauseBucketUtil = $EffectiveUtil

                }

            } else {

                # Global write bucket
                $LocalUtil = $Script:RMMThrottle.WriteLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.WriteLimit, 1)
                $WriteUtil = [math]::Max($Script:RMMThrottle.WriteUtilisation, $LocalUtil)

                if ($WriteUtil -ge $PauseThreshold) {

                    $ShouldPause = $true
                    $PauseBucketLabel = 'Write'
                    $PauseBucketUtil = $WriteUtil

                }

                # Per-operation write bucket
                if ($OperationName -and $Script:RMMThrottle.OperationBuckets.ContainsKey($OperationName)) {

                    $OpBucket = $Script:RMMThrottle.OperationBuckets[$OperationName]
                    $OpUtil = $OpBucket.LocalTimestamps.Count / [math]::Max($OpBucket.Limit, 1)

                    if ($OpUtil -ge $PauseThreshold) {

                        $ShouldPause = $true

                        if ($OpUtil -gt $PauseBucketUtil) {

                            $PauseBucketLabel = $OperationName
                            $PauseBucketUtil = $OpUtil

                        }
                    }
                }
            }

            Write-Debug "Throttle[$TrackLabel]: Pause re-evaluation — highest bucket: '$PauseBucketLabel' at $([math]::Round($PauseBucketUtil * 100, 2))%. Continue pause: $ShouldPause"

        }
    }

    if ($MaxDelay -gt 0) {

        Write-Debug "Throttle[$TrackLabel]: Delaying next request by $([math]::Round($MaxDelay, 0))ms (highest bucket pressure)."
        Start-Sleep -Milliseconds ([int]$MaxDelay)

    }
}
# SIG # Begin signature block
# MIIcXwYJKoZIhvcNAQcCoIIcUDCCHEwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDFwwSZSUtxrYE3
# LE5m4LOEvozQqaKkcEI3rdXyVl1iT6CCFogwggNKMIICMqADAgECAhB464iXHfI6
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
# CQQxIgQgTTRI+Cj4SFOGFhzAfkT8YWWHGoleMSBqNsJyEqfC3sAwDQYJKoZIhvcN
# AQEBBQAEggEAiVKXoYWHOyv4MZCR55umNgfrRpf8hoVsg8SGUeFjwVjcRhReeeTG
# LaOzrM2WyEYK4LcE9ZlWwTVgbzBlq5RN4NRQUvKRmkaccUBogQHypSd4II9jNOFV
# VmoKpdwm8slEXckhCbegXxRkgOqaQNONYQfglObKd6R3NEtufMoK0hZFrXah13Fv
# QfU3D4/6VcLP43XWyHeXgvjU55BQgXBf+TSFW2lzQ27vPtEvwANYz8yG/0b2aUPR
# c95ljvWBYJ2BKXQyUnwa9gKXjCvJ6G2gFxMXYx7CGmQcRwFTB5E+mf8AbucMa1fU
# h9ul3pHG+jfaliGYWkIxQRfZfooYa70ym6GCAyYwggMiBgkqhkiG9w0BCQYxggMT
# MIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5j
# LjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNB
# NDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUD
# BAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0yNjAzMzEwMDMwMjZaMC8GCSqGSIb3DQEJBDEiBCDBAZZu1a8YjvwnGlrW51gF
# Np9/hADr9Dfj88kW6dtr+zANBgkqhkiG9w0BAQEFAASCAgAjzY/U266N4dt1tR9o
# phTp4xC0TLpMyEs3zWnfuSBWf9Lq8lokQA2IqfzFyqXYU9c3bDud2AX2Xlct1dDZ
# Ccx8sZKfR+SQ1wxGHCjycTKQW/agtCjeF8ICMdi6d/h6MLFH17Io0RV7o1Lebcgv
# xEQX21PiKvC60vMefTs0sEzT6aIAw+Ra5wf2xcxa+O9aBndeUHbroM+eiDEXYhRw
# z3wR4NttNQIH2pYoJZ07FCfW2duXwTgRrgrDrFuBrslkVF74h9alVnuf7w9T9IIs
# MD6bzWnXmvmarC4fLMuLtEbgoXbKl9ZuhtctOM5R/yc4m2w2LyGJMJGGdBWZ9IqX
# O6JHNruP1neZ95dUelw2RHVPWcvz7bMLipPY6kc7j9cpApFkw3uHkvY/M3OLYT/n
# swd9bKSEbKYOqa54jWI/EAhxzjDuWr0xl+QaUbcmweMdnXXh3k038VQiuOt6MJox
# fSybF7iljRoQKyQu18LOphFQ9CCJHKH1LNIFNafsXhCM/c5mtVyaAjGAohEmlpqd
# 6/slMwoCEePCXvpQ11bC1NIlaRlIDfe6fjMGAy/bWv7Ce9ZXlhgk0dKLStXOYAry
# efcmdm5RESJH5NSYgLkt4M36buWlSdv1prPSin78ZfJdyQJHzGftnCY281/v/5lj
# AVXoBUVOVAQHdSFhzXtNn5lsew==
# SIG # End signature block
