<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '..\DRMMObject\DRMMObject.psm1'
<#
.SYNOPSIS
    Represents the status of the DRMM system, including properties such as version, status, and start time.
.DESCRIPTION
    The DRMMStatus class models the status of the DRMM system, encapsulating properties such as Version, Status, and Started. The class provides a constructor and a static method to create an instance from API response data. The FromAPIMethod static method takes a response object, extracts the relevant information, and populates the properties of the DRMMStatus instance accordingly. The class serves as a representation of the current status of the DRMM system, allowing for easy access to version information, overall status, and the time when the system started.
#>
class DRMMStatus : DRMMObject {

    # The version information.
    [string]$Version
    # The current status.
    [string]$Status
    # The start time of the status.
    [Nullable[datetime]]$Started

    DRMMStatus() : base() {

    }

    static [DRMMStatus] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Result = [DRMMStatus]::new()
        $Result.Version = $Response.version
        $Result.Status = $Response.status
        
        $Result.Started = ([DRMMObject]::ParseApiDate($Response.started)).DateTime

        return $Result

    }
}