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

    $IsRead = ($Script:LegacyThrottleMode -or $Method -eq 'Get')
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

    # Drift guard: when no delays are active and utilisation is below threshold, drift is
    # rolling-window oscillation (API window phase vs local window phase desynchronising
    # naturally), not a concurrent-session signal. Suppress compression so single-session
    # calibration intervals stay stable rather than collapsing to CalibrationMinSeconds.
    if ($CurrentDelayMS -eq 0 -and $EffectiveUtil -lt $Script:RMMThrottle.ThrottleUtilisationThreshold) {

        $DriftFactor = 1.0

    } else {

        $DriftFactor = 1 / (1 + $DriftRatio * $Script:RMMThrottle.DriftScalingFactor)

    }

    # Delay-pacing floor: when delays are active, scale calibration interval so that
    # enough requests pass between calibrations to avoid wasting API calls on
    # calibration overhead during well-paced operation.
    # DelayMS 800 × 10 = 8s floor → ~10 requests between calibrations.
    # DelayMS 0 × 10 = 0 → no effect, confidence/drift formula governs.
    $DelayPacingFloorSeconds = ($CurrentDelayMS / 1000) * 10

    # Stability-adaptive base: when a session has been stable (no drift, no delays, below
    # threshold) for CalibrationStabilityThreshold consecutive calibrations, the effective
    # base is allowed to double per threshold block, capped at CalibrationMaxSeconds.
    # This reduces calibration API call overhead in long-running stable single-session
    # extracts without sacrificing responsiveness — any instability signal resets the count
    # immediately and the interval returns to CalibrationBaseSeconds on the next calibration.
    $StableCount = if ($IsRead) {$Script:RMMThrottle.ReadStableCalibrationCount} else {$Script:RMMThrottle.WriteStableCalibrationCount}
    $StabilityDoublings = [math]::Floor($StableCount / [math]::Max($Script:RMMThrottle.CalibrationStabilityThreshold, 1))
    $ExtendedBaseSeconds = [math]::Min(
        $Script:RMMThrottle.CalibrationMaxSeconds,
        $Script:RMMThrottle.CalibrationBaseSeconds * [math]::Pow(2, $StabilityDoublings)
    )

    # Stability-adaptive base: when a session has been stable (no drift, no delays, below
    # threshold) for CalibrationStabilityThreshold consecutive calibrations, the effective
    # base is allowed to double per threshold block, capped at CalibrationMaxSeconds.
    # This reduces calibration API call overhead in long-running stable single-session
    # extracts without sacrificing responsiveness — any instability signal resets the count
    # immediately and the interval returns to CalibrationBaseSeconds on the next calibration.
    $StableCount = if ($IsRead) {$Script:RMMThrottle.ReadStableCalibrationCount} else {$Script:RMMThrottle.WriteStableCalibrationCount}
    $StabilityDoublings = [math]::Floor($StableCount / [math]::Max($Script:RMMThrottle.CalibrationStabilityThreshold, 1))
    $ExtendedBaseSeconds = [math]::Min(
        $Script:RMMThrottle.CalibrationMaxSeconds,
        $Script:RMMThrottle.CalibrationBaseSeconds * [math]::Pow(2, $StabilityDoublings)
    )

    # Effective interval: highest of three floors:
    #   1. CalibrationMinSeconds: absolute floor to prevent API spam
    #   2. ExtendedBase × Confidence × DriftFactor: dynamic formula using stability-adaptive base
    #   3. DelayPacingFloor: delay-correlated floor when throttling is active
    # Low confidence OR high drift → short interval → frequent calibration
    # High confidence AND low drift AND stable → extended base → minimal API overhead
    # High delay → long interval → let paced requests breathe between calibrations
    $EffectiveInterval = [math]::Max(
        $Script:RMMThrottle.CalibrationMinSeconds,
        [math]::Max(
            $ExtendedBaseSeconds * $ConfidenceFactor * $DriftFactor,
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

        # Stability count: increment if this calibration was clean (no drift, no delays, below
        # threshold); reset to 0 on any instability so the extended interval snaps back to base.
        $CalibrationWasStable = (
            $DriftGap -lt $Script:RMMThrottle.DriftThresholdPercent -and
            $CurrentDelayMS -eq 0 -and
            $EffectiveUtil -lt $Script:RMMThrottle.ThrottleUtilisationThreshold
        )

        if ($IsRead) {

            $Script:RMMThrottle.ReadStableCalibrationCount = if ($CalibrationWasStable) {$Script:RMMThrottle.ReadStableCalibrationCount + 1} else {0}

        } else {

            $Script:RMMThrottle.WriteStableCalibrationCount = if ($CalibrationWasStable) {$Script:RMMThrottle.WriteStableCalibrationCount + 1} else {0}

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
        # Seed MaxDelay with the calibration-determined floor and hold it flat until next
        # calibration. This prevents undercharging when local sample counts are low and
        # other concurrent sessions are consuming shared quota.
        $MaxDelay = $Script:RMMThrottle.ReadDelayMS

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
        # Seed MaxDelay with the calibration-determined floor and hold it flat until next calibration.
        $MaxDelay = $Script:RMMThrottle.WriteDelayMS

        # Global write bucket
        if ($Script:RMMThrottle.WriteLimit -gt 0) {

            $WriteUtil = $Script:RMMThrottle.WriteLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.WriteLimit, 1)

            if ($WriteUtil -ge $PauseThreshold) {

                $ShouldPause = $true
                $PauseBucketLabel = 'Write'
                $PauseBucketUtil = $WriteUtil

            } elseif ($WriteUtil -ge $Script:RMMThrottle.ThrottleUtilisationThreshold) {

                $Delay = $WriteUtil * $Script:RMMThrottle.DelayMultiplier
                $MaxDelay = [math]::Max($MaxDelay, $Delay)

            }
        }

        # Per-operation write bucket (if operation is tracked)
        # Delay is scaled by the ratio of account write limit to operation limit so that
        # low-limit operations (e.g. 100) get proportionally larger delays than high-limit
        # ones (e.g. 600). This prevents small-bucket operations from racing toward pause
        # because each request consumes a much larger fraction of a small bucket.
        # The ratio is derived from live API-reported limits, so it self-tunes if Datto
        # adjusts operation limits in future.
        if ($OperationName -and $Script:RMMThrottle.OperationBuckets.ContainsKey($OperationName)) {

            $OpBucket   = $Script:RMMThrottle.OperationBuckets[$OperationName]
            $ApiOpUtil  = if ($OpBucket.ContainsKey('ApiUtilisation')) { $OpBucket.ApiUtilisation } else { 0.0 }
            $OpUtil     = [math]::Max($ApiOpUtil, $OpBucket.LocalTimestamps.Count / [math]::Max($OpBucket.Limit, 1))
            $LimitRatio = [math]::Max(1.0, $Script:RMMThrottle.WriteLimit / [math]::Max($OpBucket.Limit, 1))

            if ($OpUtil -ge $PauseThreshold) {

                $ShouldPause = $true

                if ($OpUtil -gt $PauseBucketUtil) {

                    $PauseBucketLabel = $OperationName
                    $PauseBucketUtil = $OpUtil

                }

            } elseif ($OpUtil -ge $Script:RMMThrottle.ThrottleUtilisationThreshold) {

                $Delay = $OpUtil * $Script:RMMThrottle.DelayMultiplier * $LimitRatio
                $MaxDelay = [math]::Max($MaxDelay, $Delay)

            }

        } elseif ($OperationName) {

            # Unknown write operation — apply conservative safety delay
            $SafetyDelay = $Script:RMMThrottle.UnknownOperationSafetyFactor * $Script:RMMThrottle.DelayMultiplier

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

            Write-Debug "Throttle[$TrackLabel]: Pause triggered by '$PauseBucketLabel' at $([math]::Round($PauseBucketUtil * 100, 2))% (threshold $([math]::Round($PauseThreshold * 100, 2))%). Sleeping 30s."
            Start-Sleep -Seconds 30
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

                    $OpBucket  = $Script:RMMThrottle.OperationBuckets[$OperationName]
                    $ApiOpUtil = if ($OpBucket.ContainsKey('ApiUtilisation')) { $OpBucket.ApiUtilisation } else { 0.0 }
                    $OpUtil    = [math]::Max($ApiOpUtil, $OpBucket.LocalTimestamps.Count / [math]::Max($OpBucket.Limit, 1))

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
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDh7gPHT08ylGEn
# POUi74kOs1RUGnim6E63gJp+11ASlKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDd4tEx3JdIFDGclzWcXL1L7KLZo
# YPFS2pXRockuuAEMMA0GCSqGSIb3DQEBAQUABIIBAALrm4i8/+hoKKBpkXm2ckgV
# vOkc7YaJQofc7lbSRFBFl4P4hm2ClapQlBNn9gLkOCaFgYJwVgr6sHIEK/VQb8BL
# ZHKOyZ6mV1qGybBtBrPYANiSxVhsa4XU0coypHzdf3X7eZxQtT8iTsovrJ3BLU4h
# dDOcdZqtW5i+XTuqi4vA44ukUS9zte6YaKIcwTwqRzHWx5R1rLw5jp4Fm6o0o9zv
# 1mPVTrSSPqUCr/jI9JFwVelyktjJF2hmlnVivDs0Uoj/w4mWvsJRhrTg4yvIhoUI
# 8EyRxbquH2a5a/KbInW7W6VZgHcdJWvCaOdUuQjGuDpNYsUwhI86Rr06JAfhRMQ=
# SIG # End signature block
