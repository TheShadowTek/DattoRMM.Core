<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '.\DRMMObject.psm1'
using module '.\DRMMAlert.psm1'
using module '.\DRMMDevice.psm1'

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

    [bool] IsGlobal() {
        
        return ($this.Scope -eq 'Global')
    
    }

    [bool] IsSite() {
        
        return ($this.Scope -eq 'Site')
    
    }

    [bool] IsDefault() {
        
        return ($this.Type -eq 'rmm_default')
    
    }

    [bool] IsCustom() {
        
        return ($this.Type -eq 'custom')
    
    }


    [string] GetSummary() {

        if ($this.Scope) {

            $ScopeValue = $this.Scope

        } else {

            $ScopeValue = 'Global'

        }

        if ($this.Type) {

            $TypeValue = $this.Type

        } else {

            $TypeValue = '-'

        }

        return "$($this.Name) [$ScopeValue]$TypeValue"

    }

    # API Methods
    [DRMMDevice[]] GetDevices() {

        if ($this.IsSite()) {

            return Get-RMMDevice -SiteUid $this.SiteUid -FilterId $this.FilterId

        } else {

            return Get-RMMDevice -FilterId $this.FilterId

        }
    }

    [int] GetDeviceCount() {

        return $this.GetDevices().Count

    }

    [DRMMAlert[]] GetAlerts() {

        $Devices = $this.GetDevices()
        $AllAlerts = @()

        foreach ($Device in $Devices) {

            $Alerts = Get-RMMAlert -DeviceUid $Device.Uid -Status 'Open'

            if ($Alerts) {

                $AllAlerts += $Alerts
            }
        }

        return $AllAlerts

    }

    [DRMMAlert[]] GetAlerts([string]$Status) {

        $Devices = $this.GetDevices()
        $AllAlerts = @()

        foreach ($Device in $Devices) {

            $Alerts = Get-RMMAlert -DeviceUid $Device.Uid -Status $Status

            if ($Alerts) {

                $AllAlerts += $Alerts

            }
        }

        return $AllAlerts

    }
}


