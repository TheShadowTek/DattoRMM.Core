<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Discovers API rate limits and initialises multi-bucket throttle state.
.DESCRIPTION
    Calls GET /v2/system/request_rate to discover the account's rate limits and populates
    the session throttle state with discovered values. This includes the global account limit,
    global write limit, and per-operation write buckets (dynamically built from the API response).

    Falls back to safe defaults (600/min global, empty operation buckets) if the rate-status
    call fails, logging a warning. Profile settings are not modified — only discovered limits
    and tracking state are initialised.

    Called once by Connect-DattoRMM immediately after successful authentication.
#>
function Initialize-ThrottleState {
    [CmdletBinding()]
    param ()

    try {

        Write-Debug "Throttle: Discovering API rate limits from Datto RMM."
        $RateInfo = Get-RMMRequestRate

        # Global account bucket
        $Script:RMMThrottle.AccountLimit = $RateInfo.accountRateLimit
        $Script:RMMThrottle.AccountCutOffRatio = $RateInfo.accountCutOffRatio
        $Script:RMMThrottle.WindowSizeSeconds = $RateInfo.slidingTimeWindowSizeSeconds

        # Global write bucket
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
        $Script:RMMThrottle.AccountLocalTimestamps = [System.Collections.Generic.List[datetime]]::new()
        $Script:RMMThrottle.WriteLocalTimestamps = [System.Collections.Generic.List[datetime]]::new()

        $Now = [datetime]::UtcNow
        $WindowStart = $Now.AddSeconds(-$Script:RMMThrottle.WindowSizeSeconds)

        $AccountSeedCount = [math]::Max(0, [int]$RateInfo.accountCount)
        $WriteSeedCount = [math]::Max(0, [int]$RateInfo.accountWriteCount)
        $AccountSeedStep = [timespan]::FromSeconds($Script:RMMThrottle.WindowSizeSeconds / [math]::Max($AccountSeedCount, 1))
        $WriteSeedStep = [timespan]::FromSeconds($Script:RMMThrottle.WindowSizeSeconds / [math]::Max($WriteSeedCount, 1))

        for ($i = 0; $i -lt $AccountSeedCount; $i++) {

            $Script:RMMThrottle.AccountLocalTimestamps.Add($WindowStart.AddTicks($AccountSeedStep.Ticks * $i))

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
                }
            }
        }

        Write-Debug "Throttle: Seeded local window from API baseline — Account=$AccountSeedCount, Write=$WriteSeedCount"

        $Script:RMMThrottle.LastCalibrationUtc = [datetime]::UtcNow
        $Script:RMMThrottle.SamplesAtLastCalibration = $Script:RMMThrottle.AccountLocalTimestamps.Count
        $Script:RMMThrottle.AccountUtilisation = $Script:RMMThrottle.AccountLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.AccountLimit, 1)
        $Script:RMMThrottle.WriteUtilisation = $Script:RMMThrottle.WriteLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.WriteLimit, 1)
        $Script:RMMThrottle.DelayMS = 0
        $Script:RMMThrottle.Pause = $false
        $Script:RMMThrottle.Throttle = $false

        Write-Verbose "Rate limits discovered: Account=$($Script:RMMThrottle.AccountLimit)/min, Write=$($Script:RMMThrottle.WriteLimit)/min, Operations=$($Script:RMMThrottle.OperationBuckets.Count) buckets."

    } catch {

        Write-Warning "Failed to discover API rate limits: $($_.Exception.Message). Using safe defaults (600/min global)."

        $Script:RMMThrottle.AccountLimit = 600
        $Script:RMMThrottle.AccountCutOffRatio = 0.9
        $Script:RMMThrottle.WindowSizeSeconds = 60
        $Script:RMMThrottle.WriteLimit = 600
        $Script:RMMThrottle.OperationBuckets = @{}

        # Reset local tracking even on failure
        $Script:RMMThrottle.AccountLocalTimestamps = [System.Collections.Generic.List[datetime]]::new()
        $Script:RMMThrottle.WriteLocalTimestamps = [System.Collections.Generic.List[datetime]]::new()
        $Script:RMMThrottle.LastCalibrationUtc = [datetime]::UtcNow
        $Script:RMMThrottle.SamplesAtLastCalibration = 0

    }
}
