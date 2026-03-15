<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Removes expired timestamps from all local sliding-window throttle buckets.
.DESCRIPTION
    Prunes timestamps older than the rolling window start from the global account bucket,
    global write bucket, and all per-operation write buckets. Called before each throttle
    evaluation to ensure local counters reflect only the current window.
#>
function Invoke-ThrottleBucketPrune {
    [CmdletBinding()]
    param (

        [Parameter(
            Mandatory = $true
        )]
        [datetime]
        $WindowStart
    )

    # Prune global account timestamps
    while ($Script:RMMThrottle.AccountLocalTimestamps.Count -gt 0 -and $Script:RMMThrottle.AccountLocalTimestamps[0] -lt $WindowStart) {

        $Script:RMMThrottle.AccountLocalTimestamps.RemoveAt(0)

    }

    # Prune global write timestamps
    while ($Script:RMMThrottle.WriteLocalTimestamps.Count -gt 0 -and $Script:RMMThrottle.WriteLocalTimestamps[0] -lt $WindowStart) {

        $Script:RMMThrottle.WriteLocalTimestamps.RemoveAt(0)

    }

    # Prune per-operation write buckets
    foreach ($OpName in @($Script:RMMThrottle.OperationBuckets.Keys)) {

        $Bucket = $Script:RMMThrottle.OperationBuckets[$OpName]

        while ($Bucket.LocalTimestamps.Count -gt 0 -and $Bucket.LocalTimestamps[0] -lt $WindowStart) {

            $Bucket.LocalTimestamps.RemoveAt(0)

        }
    }
}
