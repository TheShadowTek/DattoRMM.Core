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