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
