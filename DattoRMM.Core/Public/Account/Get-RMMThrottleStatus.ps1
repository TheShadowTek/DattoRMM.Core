<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMThrottleStatus {
    <#
    .SYNOPSIS
        Retrieves a detailed snapshot of the current API rate limits, counts, and local throttle state.

    .DESCRIPTION
        The Get-RMMThrottleStatus function provides a combined view of the Datto RMM API rate-status
        endpoint data and the local sliding-window throttle model. It calls the rate-status API to
        fetch fresh account and write counts, limits, and per-operation bucket status, then merges
        this with the local throttle tracking state (timestamps, utilisation, flags, thresholds).

        The returned DRMMThrottleStatus object includes:
        - Active throttle profile and configured thresholds
        - Global account and write utilisation (both API-reported and locally tracked)
        - Throttle and pause flags reflecting the current state before drift adjustment
        - Current computed delay in milliseconds
        - Calibration metadata (last calibration time, sample count)
        - A Buckets collection of DRMMThrottleBucket objects covering the account bucket,
          write bucket, and all per-operation write buckets (both mapped and unidentified)

        Each bucket reports its Type (Account, Write, or Operation), Name, Limit, ApiCount,
        LocalCount, and computed Utilisation ratio.

        This function is designed for monitoring, diagnostics, and sample capture during long-running
        load tests. It does not modify any throttle state. For the raw API response without local
        enrichment, use Get-RMMRequestRate instead.

    .EXAMPLE
        Get-RMMThrottleStatus

        Retrieves the current combined throttle status snapshot.

    .EXAMPLE
        $Status = Get-RMMThrottleStatus
        PS > $Status.GetSummary()

        Retrieves throttle status and displays a summary of utilisation, flags, and delay.

    .EXAMPLE
        Get-RMMThrottleStatus | Select-Object -ExpandProperty Buckets | Format-Table

        Retrieves throttle status and displays all rate-limit buckets in a table.

    .EXAMPLE
        (Get-RMMThrottleStatus).Buckets | Where-Object Type -eq 'Operation' | Sort-Object Utilisation -Descending

        Retrieves and filters only per-operation buckets, sorted by utilisation.

    .EXAMPLE
        $Status = Get-RMMThrottleStatus
        PS > $Status.Buckets | Where-Object {$_.Utilisation -gt 0}

        Shows only buckets with active utilisation for quick load test monitoring.

    .INPUTS
        None. You cannot pipe objects to Get-RMMThrottleStatus.

    .OUTPUTS
        DRMMThrottleStatus. Returns a throttle status object with the following properties:
        - Profile (string): Active throttle profile name
        - AccountUid (string): Account unique identifier from the API
        - WindowSizeSeconds (int): Rolling window size in seconds
        - AccountUtilisation (double): Global account utilisation ratio (higher of API or local)
        - WriteUtilisation (double): Global write utilisation ratio (higher of API or local)
        - AccountCutOffRatio (double): API-reported account cut-off ratio
        - ThrottleUtilisationThreshold (double): Configured threshold at which throttling activates
        - PauseThreshold (double): Computed threshold at which hard pause activates
        - Throttle (bool): Whether soft throttling is currently active
        - Pause (bool): Whether hard pause is currently active
        - DelayMs (double): Current computed delay in milliseconds
        - DelayMultiplier (double): Configured global delay multiplier
        - WriteDelayMultiplier (double): Configured write delay multiplier
        - LastCalibrationUtc (datetime): UTC time of the last calibration
        - SamplesAtLastCalibration (int): Local account samples at last calibration
        - Buckets (DRMMThrottleBucket[]): Collection of all tracked rate-limit buckets

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        This function calls the rate-status API endpoint to fetch fresh data, which itself
        counts as an API request against the account rate limit.

        The throttle state reported is a pre-drift-adjustment snapshot. The actual throttle
        engine may adjust utilisation values during calibration cycles.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMThrottleStatus.md

    .LINK
        Get-RMMRequestRate

    .LINK
        Connect-DattoRMM

    .LINK
        about_DattoRMM.CoreThrottling

    .LINK
        about_DRMMThrottleStatus
    #>

    [CmdletBinding()]
    param ()

    process {

        # Fetch fresh rate-status from the API
        $RateInfo = Invoke-ApiMethod -Path 'system/request_rate' -Method GET

        Write-Debug "ThrottleStatus: API returned Account=$($RateInfo.accountCount)/$($RateInfo.accountRateLimit), Write=$($RateInfo.accountWriteCount)/$($RateInfo.accountWriteRateLimit)"

        # --- Build the result object ---
        $Result = [DRMMThrottleStatus]::new()
        $Result.Profile = $Script:RMMThrottle.Profile
        $Result.AccountUid = $RateInfo.accountUid
        $Result.WindowSizeSeconds = $RateInfo.slidingTimeWindowSizeSeconds
        $Result.AccountCutOffRatio = $RateInfo.accountCutOffRatio
        $Result.ThrottleUtilisationThreshold = $Script:RMMThrottle.ThrottleUtilisationThreshold
        $Result.PauseThreshold = $RateInfo.accountCutOffRatio - $Script:RMMThrottle.ThrottleCutOffOverhead
        $Result.DelayMultiplier = $Script:RMMThrottle.DelayMultiplier
        $Result.WriteDelayMultiplier = $Script:RMMThrottle.WriteDelayMultiplier
        $Result.LastCalibrationUtc = $Script:RMMThrottle.LastCalibrationUtc
        $Result.SamplesAtLastCalibration = $Script:RMMThrottle.SamplesAtLastCalibration

        # --- Compute utilisation from both sources (same logic as Update-Throttle, pre-drift) ---
        $ApiAccountUtil = $RateInfo.accountCount / [math]::Max($RateInfo.accountRateLimit, 1)
        $LocalAccountUtil = $Script:RMMThrottle.AccountLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.AccountLimit, 1)
        $Result.AccountUtilisation = [math]::Max($ApiAccountUtil, $LocalAccountUtil)

        $ApiWriteUtil = 0.0
        $LocalWriteUtil = 0.0

        if ($RateInfo.accountWriteRateLimit -gt 0) {

            $ApiWriteUtil = $RateInfo.accountWriteCount / [math]::Max($RateInfo.accountWriteRateLimit, 1)
            $LocalWriteUtil = $Script:RMMThrottle.WriteLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.WriteLimit, 1)

        }

        $Result.WriteUtilisation = [math]::Max($ApiWriteUtil, $LocalWriteUtil)

        # --- Compute flags and delay (mirrors Update-Throttle logic, pre-adjustment) ---
        $Result.Throttle = ($Result.AccountUtilisation -ge $Script:RMMThrottle.ThrottleUtilisationThreshold)
        $Result.Pause = ($Result.AccountUtilisation -ge $Result.PauseThreshold)

        if ($Result.Throttle) {

            $Result.DelayMs = $Result.AccountUtilisation * $Script:RMMThrottle.DelayMultiplier

        } else {

            $Result.DelayMs = 0

        }

        # --- Build bucket collection ---
        $BucketList = [System.Collections.Generic.List[DRMMThrottleBucket]]::new()

        # Account bucket
        $AccountBucket = [DRMMThrottleBucket]::new()
        $AccountBucket.Type = 'Account'
        $AccountBucket.Name = 'Account'
        $AccountBucket.Limit = $RateInfo.accountRateLimit
        $AccountBucket.ApiCount = $RateInfo.accountCount
        $AccountBucket.LocalCount = $Script:RMMThrottle.AccountLocalTimestamps.Count
        $AccountBucket.Utilisation = $Result.AccountUtilisation
        $BucketList.Add($AccountBucket)

        # Write bucket
        $WriteBucket = [DRMMThrottleBucket]::new()
        $WriteBucket.Type = 'Write'
        $WriteBucket.Name = 'Write'
        $WriteBucket.Limit = $RateInfo.accountWriteRateLimit
        $WriteBucket.ApiCount = $RateInfo.accountWriteCount
        $WriteBucket.LocalCount = $Script:RMMThrottle.WriteLocalTimestamps.Count
        $WriteBucket.Utilisation = $Result.WriteUtilisation
        $BucketList.Add($WriteBucket)

        # Per-operation write buckets from API response
        if ($null -ne $RateInfo.operationWriteStatus) {

            $RateInfo.operationWriteStatus.PSObject.Properties | ForEach-Object {

                $OpName = $_.Name
                $OpBucket = [DRMMThrottleBucket]::new()
                $OpBucket.Type = 'Operation'
                $OpBucket.Name = $OpName
                $OpBucket.Limit = $_.Value.limit
                $OpBucket.ApiCount = $_.Value.count

                # Merge local tracking if bucket exists locally
                if ($Script:RMMThrottle.OperationBuckets.ContainsKey($OpName)) {

                    $OpBucket.LocalCount = $Script:RMMThrottle.OperationBuckets[$OpName].LocalTimestamps.Count

                } else {

                    $OpBucket.LocalCount = 0

                }

                # Utilisation is higher of API or local
                $ApiOpUtil = $OpBucket.ApiCount / [math]::Max($OpBucket.Limit, 1)
                $LocalOpUtil = $OpBucket.LocalCount / [math]::Max($OpBucket.Limit, 1)
                $OpBucket.Utilisation = [math]::Max($ApiOpUtil, $LocalOpUtil)

                $BucketList.Add($OpBucket)

            }
        }

        # Include any locally tracked operation buckets not present in the API response
        if ($Script:RMMThrottle.OperationBuckets -and $Script:RMMThrottle.OperationBuckets.Count -gt 0) {

            $ApiOpNames = @()

            if ($null -ne $RateInfo.operationWriteStatus) {

                $ApiOpNames = @($RateInfo.operationWriteStatus.PSObject.Properties.Name)

            }

            $Script:RMMThrottle.OperationBuckets.GetEnumerator() | ForEach-Object {

                if ($_.Key -notin $ApiOpNames) {

                    $UnmappedBucket = [DRMMThrottleBucket]::new()
                    $UnmappedBucket.Type = 'Operation'
                    $UnmappedBucket.Name = $_.Key
                    $UnmappedBucket.Limit = $_.Value.Limit
                    $UnmappedBucket.ApiCount = 0
                    $UnmappedBucket.LocalCount = $_.Value.LocalTimestamps.Count
                    $UnmappedBucket.Utilisation = $UnmappedBucket.LocalCount / [math]::Max($UnmappedBucket.Limit, 1)

                    $BucketList.Add($UnmappedBucket)

                }
            }
        }

        $Result.Buckets = $BucketList.ToArray()

        Write-Debug "ThrottleStatus: Built $($Result.Buckets.Count) buckets — Account=$([math]::Round($Result.AccountUtilisation * 100, 2))%, Write=$([math]::Round($Result.WriteUtilisation * 100, 2))%, Throttle=$($Result.Throttle), Pause=$($Result.Pause)"

        $Result

    }
}
