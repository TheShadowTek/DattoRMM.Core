<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Calibrates local throttle state against actual API-reported utilisation.
.DESCRIPTION
    Calls the rate-status endpoint and adjusts the local sliding-window model. If the API
    reports higher utilisation than local tracking (indicating concurrent sessions or external
    API consumers), the local model adopts the higher value. Also refreshes per-operation
    bucket limits in case they have been adjusted by Datto.
#>
function Update-Throttle {
    [CmdletBinding()]
    param ()

    $Now = [datetime]::UtcNow
    $WindowStart = $Now.AddSeconds(-$Script:RMMThrottle.WindowSizeSeconds)

    $PrePruneAccountCount = $Script:RMMThrottle.AccountLocalTimestamps.Count
    $PrePruneWriteCount = $Script:RMMThrottle.WriteLocalTimestamps.Count

    # Ensure local counters are always aligned to the active rolling window before calibration
    Invoke-ThrottleBucketPrune -WindowStart $WindowStart

    $PostPruneAccountCount = $Script:RMMThrottle.AccountLocalTimestamps.Count
    $PostPruneWriteCount = $Script:RMMThrottle.WriteLocalTimestamps.Count

    Write-Debug "Throttle: Local prune window $($Script:RMMThrottle.WindowSizeSeconds)s | Account $PrePruneAccountCount->$PostPruneAccountCount | Write $PrePruneWriteCount->$PostPruneWriteCount"

    try {

        $RateInfo = Get-RMMRequestRate

    } catch {

        Write-Debug "Throttle: Calibration failed — $($_.Exception.Message). Retaining local state."
        return

    }

    $PauseThreshold = $RateInfo.accountCutOffRatio - $Script:RMMThrottle.ThrottleCutOffOverhead

    # --- Global account calibration ---
    $ApiAccountUtil = $RateInfo.accountCount / [math]::Max($RateInfo.accountRateLimit, 1)
    $LocalAccountUtil = $Script:RMMThrottle.AccountLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.AccountLimit, 1)

    # Use the higher of API-reported or local-tracked utilisation
    # This handles concurrent sessions consuming the shared quota
    $Script:RMMThrottle.AccountUtilisation = [math]::Max($ApiAccountUtil, $LocalAccountUtil)

    # --- Global write calibration ---
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
    $Script:RMMThrottle.Throttle = ($Script:RMMThrottle.AccountUtilisation -ge $Script:RMMThrottle.ThrottleUtilisationThreshold)
    $Script:RMMThrottle.Pause = ($Script:RMMThrottle.AccountUtilisation -ge $PauseThreshold)

    if ($Script:RMMThrottle.Throttle) {

        $Script:RMMThrottle.DelayMS = $Script:RMMThrottle.AccountUtilisation * $Script:RMMThrottle.DelayMultiplier

    } else {

        $Script:RMMThrottle.DelayMS = 0

    }

    $Script:RMMThrottle.LastCalibrationUtc = [datetime]::UtcNow
    $Script:RMMThrottle.SamplesAtLastCalibration = $Script:RMMThrottle.AccountLocalTimestamps.Count

    Write-Debug @"
Throttle Calibration:
`tAccount Utilisation: $([math]::Round($Script:RMMThrottle.AccountUtilisation * 100, 2))% (API: $([math]::Round($ApiAccountUtil * 100, 2))%, Local: $([math]::Round($LocalAccountUtil * 100, 2))%)
`tWrite Utilisation: $([math]::Round($Script:RMMThrottle.WriteUtilisation * 100, 2))%
`tLocal Counts: Account=$PostPruneAccountCount, Write=$PostPruneWriteCount
`tAPI Counts: Account=$($RateInfo.accountCount), Write=$($RateInfo.accountWriteCount)
`tAccount Limit: $($Script:RMMThrottle.AccountLimit) | Write Limit: $($Script:RMMThrottle.WriteLimit)
`tOperation Buckets: $($Script:RMMThrottle.OperationBuckets.Count)
`tPause Threshold: $([math]::Round($PauseThreshold * 100, 2))%
`tThrottle: $($Script:RMMThrottle.Throttle) | Pause: $($Script:RMMThrottle.Pause)
`tDelay MS: $([math]::Round($Script:RMMThrottle.DelayMS, 2))
"@

}
