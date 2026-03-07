<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Pre-request throttle gate with multi-bucket awareness and time-based calibration.
.DESCRIPTION
    Evaluates global account, global write, and per-operation write buckets to determine
    the appropriate delay before an API request. Uses local sliding-window tracking as the
    primary control mechanism, with periodic time-based calibration against the live API
    to detect concurrent usage. The highest pressure across all applicable buckets determines
    the actual delay applied.
#>
function Invoke-APIThrottle {
    [CmdletBinding()]
    param (

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = 'Get',

        [string]
        $OperationName
    )

    $Now = [datetime]::UtcNow
    $WindowStart = $Now.AddSeconds(-$Script:RMMThrottle.WindowSizeSeconds)

    # --- Prune expired timestamps from all local buckets ---
    Invoke-ThrottleBucketPrune -WindowStart $WindowStart

    # --- Time-based calibration with confidence-weighted dynamic interval ---
    $LocalSampleCount = $Script:RMMThrottle.AccountLocalTimestamps.Count
    $LocalAccountUtil = $LocalSampleCount / [math]::Max($Script:RMMThrottle.AccountLimit, 1)
    $EffectiveAccountUtil = [math]::Max($Script:RMMThrottle.AccountUtilisation, $LocalAccountUtil)

    # Drift detection: gap between API-reported and local-tracked utilisation
    # Any measurable gap indicates concurrent sessions or external API consumers
    $DriftGap = [math]::Abs($Script:RMMThrottle.AccountUtilisation - $LocalAccountUtil)

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

    # Effective interval: Base × Confidence × DriftFactor, clamped to floor
    # Low confidence OR high drift → short interval → frequent calibration
    # High confidence AND low drift → full base → minimal API overhead
    $EffectiveInterval = [math]::Max(
        $Script:RMMThrottle.CalibrationMinSeconds,
        $Script:RMMThrottle.CalibrationBaseSeconds * $ConfidenceFactor * $DriftFactor
    )

    $ElapsedSeconds = ($Now - $Script:RMMThrottle.LastCalibrationUtc).TotalSeconds

    # Request-count gate: caps how many requests can pass between calibrations.
    # Three tiers based on the session's current phase:
    #   1. Building confidence (< 100%): tight gate — detect concurrent sessions early
    #   2. Full confidence, below threshold: moderate gate — no delays to limit frequency
    #   3. Full confidence, at/above threshold: disabled — delays naturally pace requests
    $Threshold = [math]::Max($Script:RMMThrottle.ThrottleUtilisationThreshold, 0.01)
    $RequestsSinceCalibration = $LocalSampleCount - $Script:RMMThrottle.SamplesAtLastCalibration

    if ($ConfidenceFactor -lt 1.0) {

        $RequestGateLimit = [math]::Max(10, [math]::Ceiling($Script:RMMThrottle.CalibrationConfidenceCount * 0.2))

    } elseif ($EffectiveAccountUtil -lt $Threshold) {

        $RequestGateLimit = [math]::Max(10, [math]::Ceiling($Script:RMMThrottle.CalibrationConfidenceCount * 0.4))

    } else {

        $RequestGateLimit = 0

    }

    $RequestGateTriggered = $RequestGateLimit -gt 0 -and $RequestsSinceCalibration -ge $RequestGateLimit

    if ($ElapsedSeconds -ge $EffectiveInterval -or $RequestGateTriggered) {

        if ($DriftGap -ge $Script:RMMThrottle.DriftThresholdPercent) {

            Write-Debug "Throttle: Drift $([math]::Round($DriftGap * 100, 1))% (API: $([math]::Round($Script:RMMThrottle.AccountUtilisation * 100, 1))% vs Local: $([math]::Round($LocalAccountUtil * 100, 1))%) — interval $([math]::Round($EffectiveInterval, 2))s."

        }

        $CalibrationTrigger = if ($RequestGateTriggered -and $ElapsedSeconds -lt $EffectiveInterval) {'request-gate'} else {'interval'}
        Write-Debug "Throttle: Calibrating ($CalibrationTrigger, $([math]::Round($ElapsedSeconds, 1))s since last, interval $([math]::Round($EffectiveInterval, 2))s, confidence $([math]::Round($ConfidenceFactor * 100, 0))%, samples $LocalSampleCount, +$RequestsSinceCalibration since last)."
        Update-Throttle

        # Refresh effective utilisation after calibration
        $LocalAccountUtil = $Script:RMMThrottle.AccountLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.AccountLimit, 1)
        $EffectiveAccountUtil = [math]::Max($Script:RMMThrottle.AccountUtilisation, $LocalAccountUtil)

    }

    # --- Calculate max delay across all relevant buckets ---
    $MaxDelay = 0
    $ShouldPause = $false
    $PauseThreshold = $Script:RMMThrottle.AccountCutOffRatio - $Script:RMMThrottle.ThrottleCutOffOverhead

    # 1. Global account bucket (all requests)
    # Seed MaxDelay with the last calibration-determined value as a floor.
    # This carries the API-reported global picture forward between calibrations,
    # preventing sessions with low local sample counts from being undercharged
    # when other concurrent sessions are consuming shared quota.
    if ($Script:RMMThrottle.DelayMS -gt 0) {

        $MaxDelay = $Script:RMMThrottle.DelayMS

    }

    if ($EffectiveAccountUtil -ge $PauseThreshold) {

        $ShouldPause = $true

    } elseif ($EffectiveAccountUtil -ge $Script:RMMThrottle.ThrottleUtilisationThreshold) {

        $Delay = $EffectiveAccountUtil * $Script:RMMThrottle.DelayMultiplier
        $MaxDelay = [math]::Max($MaxDelay, $Delay)

    }

    # 2. Global write bucket (write methods only)
    if ($Method -ne 'Get' -and $Script:RMMThrottle.WriteLimit -gt 0) {

        $WriteUtil = $Script:RMMThrottle.WriteLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.WriteLimit, 1)

        if ($WriteUtil -ge $PauseThreshold) {

            $ShouldPause = $true

        } elseif ($WriteUtil -ge $Script:RMMThrottle.ThrottleUtilisationThreshold) {

            $Delay = $WriteUtil * $Script:RMMThrottle.WriteDelayMultiplier
            $MaxDelay = [math]::Max($MaxDelay, $Delay)

        }
    }

    # 3. Per-operation write bucket (if operation is tracked)
    if ($OperationName -and $Script:RMMThrottle.OperationBuckets.ContainsKey($OperationName)) {

        $OpBucket = $Script:RMMThrottle.OperationBuckets[$OperationName]
        $OpUtil = $OpBucket.LocalTimestamps.Count / [math]::Max($OpBucket.Limit, 1)

        if ($OpUtil -ge $PauseThreshold) {

            $ShouldPause = $true

        } elseif ($OpUtil -ge $Script:RMMThrottle.ThrottleUtilisationThreshold) {

            $Delay = $OpUtil * $Script:RMMThrottle.WriteDelayMultiplier
            $MaxDelay = [math]::Max($MaxDelay, $Delay)

        }

    } elseif ($OperationName -and $Method -ne 'Get') {

        # Unknown write operation — apply conservative safety delay
        $SafetyDelay = $Script:RMMThrottle.UnknownOperationSafetyFactor * $Script:RMMThrottle.WriteDelayMultiplier

        if ($SafetyDelay -gt 0) {

            $MaxDelay = [math]::Max($MaxDelay, $SafetyDelay)
            Write-Debug "Throttle: Unknown write operation '$OperationName' — safety delay $([math]::Round($SafetyDelay, 0))ms."

        }
    }

    # --- Apply throttling ---
    if ($ShouldPause) {

        while ($ShouldPause) {

            Write-Warning "High API utilisation detected ($([math]::Round($EffectiveAccountUtil * 100, 2))%). Pausing requests to avoid rate limiting."
            Start-Sleep -Seconds 60
            Update-Throttle

            # Re-evaluate after calibration
            $LocalAccountUtil = $Script:RMMThrottle.AccountLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.AccountLimit, 1)
            $EffectiveAccountUtil = [math]::Max($Script:RMMThrottle.AccountUtilisation, $LocalAccountUtil)
            $ShouldPause = $EffectiveAccountUtil -ge $PauseThreshold

        }
    }

    if ($MaxDelay -gt 0) {

        Write-Debug "Throttle: Delaying next request by $([math]::Round($MaxDelay, 0))ms (highest bucket pressure)."
        Start-Sleep -Milliseconds ([int]$MaxDelay)

    }
}