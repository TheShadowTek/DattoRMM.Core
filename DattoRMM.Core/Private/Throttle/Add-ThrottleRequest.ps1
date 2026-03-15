<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Records a completed API request in the local sliding-window throttle counters.
.DESCRIPTION
    Routes the timestamp into the correct bucket based on HTTP method. Read (GET) requests
    are recorded in the read bucket only. Write (PUT/POST/DELETE) requests are recorded in
    the global write bucket and the per-operation write bucket (if the operation is tracked).
    Reads and writes are independent quotas — a read never touches the write bucket and a
    write never touches the read bucket. This function is called after each API response to
    maintain accurate local utilisation estimates between calibration cycles.
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

    if ($Method -eq 'Get') {

        # Record in read bucket
        $Script:RMMThrottle.ReadLocalTimestamps.Add($Now)

        # Update local read utilisation estimate
        $Script:RMMThrottle.ReadUtilisation = $Script:RMMThrottle.ReadLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.ReadLimit, 1)

    } else {

        # Record in global write bucket
        $Script:RMMThrottle.WriteLocalTimestamps.Add($Now)

        # Update local write utilisation estimate
        $Script:RMMThrottle.WriteUtilisation = $Script:RMMThrottle.WriteLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.WriteLimit, 1)

        # Per-operation write bucket
        if ($OperationName -and $Script:RMMThrottle.OperationBuckets.ContainsKey($OperationName)) {

            $Script:RMMThrottle.OperationBuckets[$OperationName].LocalTimestamps.Add($Now)

        }
    }
}
