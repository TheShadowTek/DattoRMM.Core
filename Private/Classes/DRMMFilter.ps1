<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '.\DRMMObject.psm1'
# using module '.\DRMMAlert.ps1'   # For PSScriptAnalyzer only
# using module '.\DRMMDevice.ps1'   # For PSScriptAnalyzer only

class DRMMFilter : DRMMObject {

    [long]$Id
    [long]$FilterId
    [string]$Name
    [string]$Description
    [string]$Type
    [string]$Scope
    [Nullable[guid]]$SiteUid
    [Nullable[datetime]]$DateCreate
    [Nullable[datetime]]$LastUpdated

    DRMMFilter() : base() {

    }

    static [DRMMFilter] FromAPIMethod([pscustomobject]$Response, [string]$Scope, [Nullable[guid]]$SiteUid) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Filter = [DRMMFilter]::new()
        $Filter.Id = $Response.id
        $Filter.FilterId = $Response.id
        $Filter.Name = $Response.name
        $Filter.Description = $Response.description
        $Filter.Type = $Response.type
        $Filter.Scope = $Scope
        $Filter.SiteUid = $SiteUid

        $CreateDate = [DRMMObject]::ParseApiDate($Response.dateCreate)
        $Filter.DateCreate = $CreateDate.DateTime

        $UpdatedDate = [DRMMObject]::ParseApiDate($Response.lastUpdated)
        $Filter.LastUpdated = $UpdatedDate.DateTime

        return $Filter

    }

    [bool] IsGlobal() { return ($this.Scope -eq 'Global') }
    [bool] IsSite()   { return ($this.Scope -eq 'Site') }
    [bool] IsDefault() { return ($this.Type -eq 'rmm_default') }
    [bool] IsCustom()  { return ($this.Type -eq 'custom') }

    [string] GetSummary() {

        $ScopeValue = if ($this.Scope) { $this.Scope } else { 'Global' }
        $TypeValue = if ($this.Type) { " ($($this.Type))" } else { '' }

        return "$($this.Name) [$ScopeValue]$TypeValue"

    }

    # API Methods
    [DRMMDevice[]] GetDevices() {

        $result = if ($this.SiteUid) {

            Get-RMMDevice -SiteUid $this.SiteUid -FilterId $this.FilterId

        } else {

            Get-RMMDevice -FilterId $this.FilterId

        }

        if ($null -eq $result) {

            return @()

        }

        return $result

    }

    [int] GetDeviceCount() {

        $devices = $this.GetDevices()

        return $devices.Count

    }

    [DRMMAlert[]] GetAlerts() {

        if (-not (Get-Command -Name Get-RMMAlert -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        $devices = $this.GetDevices()
        $allAlerts = @()

        foreach ($device in $devices) {

            $alerts = Get-RMMAlert -DeviceUid $device.Uid -Status 'All'

            if ($alerts) {

                $allAlerts += $alerts

            }
        }

        return $allAlerts

    }

    [DRMMAlert[]] GetAlerts([string]$Status) {

        if (-not (Get-Command -Name Get-RMMAlert -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        $devices = $this.GetDevices()
        $allAlerts = @()

        foreach ($device in $devices) {

            $alerts = Get-RMMAlert -DeviceUid $device.Uid -Status $Status

            if ($alerts) {

                $allAlerts += $alerts

            }
        }

        return $allAlerts

    }
}


