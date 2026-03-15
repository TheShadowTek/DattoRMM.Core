<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Records a completed API request in the local sliding-window throttle counters.
.DESCRIPTION
    Updates the global account bucket timestamp list for every request. For write operations,
    also updates the global write bucket and the per-operation write bucket (if the operation
    is tracked). This function is called after each successful API response to maintain accurate
    local utilisation estimates between calibration cycles.
#>
function Add-ThrottleRequest {
    [CmdletBinding()]
    param (

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = 'Get',

        [string]
        $OperationName
    )

    $Now = [datetime]::UtcNow

    # Always record in global account bucket
    $Script:RMMThrottle.AccountLocalTimestamps.Add($Now)

    # Update local account utilisation estimate
    $Script:RMMThrottle.AccountUtilisation = $Script:RMMThrottle.AccountLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.AccountLimit, 1)

    # Record in write buckets if this is a write operation
    if ($Method -ne 'Get') {

        $Script:RMMThrottle.WriteLocalTimestamps.Add($Now)

        # Per-operation write bucket
        if ($OperationName -and $Script:RMMThrottle.OperationBuckets.ContainsKey($OperationName)) {

            $Script:RMMThrottle.OperationBuckets[$OperationName].LocalTimestamps.Add($Now)

        }
    }
}
