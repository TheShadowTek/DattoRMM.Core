<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Handles API request throttling based on current utilization to avoid hitting rate limits.
.DESCRIPTION
    This function checks the current API request rate and applies delays or pauses as necessary to prevent hitting the
    API rate limits. It uses the Get-RMMRequestRate function to retrieve the current request count and rate limit, and
    calculate the utilization. If utilization exceeds the defined thresholds, it will either delay requests or pause
    them entirely until utilization drops to a safe level.
#>
function Invoke-APIThrottle {
    [CmdletBinding()]
    param ()

    # Throttle review
    if ($Script:RMMThrottle.CheckCount -ge $Script:RMMThrottle.CheckInterval) {

        $Script:RMMThrottle.CheckCount = 1
        Write-Debug "Updating request rate status from Datto RMM API."
        Update-Throttle

    } else {

        $script:RMMThrottle.CheckCount++

    }

    # Apply throttling if required
    if ($Script:RMMThrottle.Throttle) {

        while ($Script:RMMThrottle.Pause) {

            Write-Warning "High API Utilisation detected ($([math]::Round($Script:RMMThrottle.Utilisation * 100, 2))%). Pausing requests to avoid throttling."
            Start-Sleep -Seconds 60
            Update-Throttle
            
        }

        if ($Script:RMMThrottle.DelayMS -gt 0) {

            Write-Debug "Delaying next request by $($Script:RMMThrottle.DelayMS) ms to avoid throttling."
            Start-Sleep -Milliseconds $Script:RMMThrottle.DelayMS

        }
    }
}