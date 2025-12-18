class DRMMObject {

    [string]$ApiBaseUrl
    [string]$AccountUid

    DRMMObject([string]$ApiBaseUrl = $null, [string]$AccountUid = $null) {

        $this.ApiBaseUrl = $ApiBaseUrl
        $this.AccountUid = $AccountUid

    }

    static [object] GetValue([pscustomobject]$InputObject, [string]$Key) {

        if ($null -eq $InputObject) {

            return $null

        }

        if ($InputObject.PSObject.Properties.Name -contains $Key) {

            return $InputObject.$Key

        }

        return $null

    }

    static [bool] ValidateShape([pscustomobject]$Sample, [string[]]$RequiredProperties) {

        if ($null -eq $Sample -or $null -eq $RequiredProperties) {

            return $false

        }

        $Names = $Sample.PSObject.Properties.Name
        foreach ($Prop in $RequiredProperties) {

            if (-not ($Names -contains $Prop)) {

                return $false

            }

        }

        return $true

    }

    static [datetime] ConvertEpochToDateTime([long]$Epoch) {

        if ($null -eq $Epoch) {

            return $null

        }

        if ($Epoch -gt 9999999999) {

            return [DateTimeOffset]::FromUnixTimeMilliseconds($Epoch).UtcDateTime

        }

        return [DateTimeOffset]::FromUnixTimeSeconds($Epoch).UtcDateTime

    }

    static [hashtable] ParseApiDate([object]$Value) {

        if ($null -eq $Value) {

            return @{ DateTime = $null; Epoch = $null; Raw = $null }

        }

        if ($Value -is [int] -or $Value -is [long] -or ($Value -is [string] -and $Value -match '^\d+$')) {

            $Num = [long]$Value

            if ($Num -gt 9999999999) {

                $Dto = [DateTimeOffset]::FromUnixTimeMilliseconds($Num)
                $EpochSeconds = [long]$Dto.ToUnixTimeSeconds()

            } else {

                $Dto = [DateTimeOffset]::FromUnixTimeSeconds($Num)
                $EpochSeconds = $Num

            }

            return @{ DateTime = $Dto.UtcDateTime; Epoch = $EpochSeconds; Raw = $Value }

        }

        try {

            $Dto = [DateTimeOffset]::Parse([string]$Value)
            $EpochSeconds = [long]$Dto.ToUnixTimeSeconds()
            return @{ DateTime = $Dto.UtcDateTime; Epoch = $EpochSeconds; Raw = $Value }

        } catch {

            return @{ DateTime = $null; Epoch = $null; Raw = $Value }

        }

    }

    static [string] MaskString([string]$Value, [int]$VisibleChars = 1, [string]$MaskChar = '*') {

        if ($null -eq $Value -or $Value -eq '') {

            return ($MaskChar * 3)

        }

        $StringValue = [string]$Value
        if ($VisibleChars -le 0) {

            return ($MaskChar * $StringValue.Length)

        }

        if ($StringValue.Length -le $VisibleChars) {

            return ($MaskChar * $StringValue.Length)

        }

        $Visible = $StringValue.Substring(0, [math]::Min($VisibleChars, $StringValue.Length))
        $MaskedCount = $StringValue.Length - $Visible.Length
        return ($Visible + ($MaskChar * $MaskedCount))

    }

    static [string] GetMissingHelperErrorMessage() {

        return "Required internal API helper is not available. Ensure the module is loaded and try again."

    }

    static [void] ThrowMissingHelperError() {

        throw [DRMMObject]::GetMissingHelperErrorMessage()

    }

}

class DRMMProxySettings : DRMMObject {

    [string]$Host
    [string]$Username
    [securestring]$Password
    [int]$Port
    [string]$Type

    DRMMProxySettings() : base() {

    }

    static [DRMMProxySettings] FromApi([pscustomobject]$Response) {

        if ($null -eq $Response) { return $null }

        $ProxySettings = [DRMMProxySettings]::new()
        $ProxySettings.Host = $Response.host
        $ProxySettings.Username = $Response.username
        $RawPassword = $Response.password

        if ($RawPassword -is [securestring]) {

            $ProxySettings.Password = $RawPassword

        } elseif ($RawPassword -is [string] -and $RawPassword.Length -gt 0) {

            $ProxySettings.Password = ConvertTo-SecureString -String $RawPassword -AsPlainText -Force

        } else {

            $ProxySettings.Password = $null

        }

        $ProxySettings.Port = $Response.port
        $ProxySettings.Type = $Response.type

        return $ProxySettings

    }

}

class DRMMDevicesStatus : DRMMObject {

    [long]$NumberOfDevices
    [long]$NumberOfOnlineDevices
    [long]$NumberOfOfflineDevices

    DRMMDevicesStatus() : base() {

    }

    static [DRMMDevicesStatus] FromApi([pscustomobject]$Response) {

        if ($null -eq $Response) { return $null }

        $DevicesStatus = [DRMMDevicesStatus]::new()
        $DevicesStatus.NumberOfDevices = $Response.numberOfDevices
        $DevicesStatus.NumberOfOnlineDevices = $Response.numberOfOnlineDevices
        $DevicesStatus.NumberOfOfflineDevices = $Response.numberOfOfflineDevices

        return $DevicesStatus

    }

}

class DRMMSiteSettings : DRMMObject {

    [bool]$AutoPatch
    [string]$Timezone
    [string]$MaintenanceWindow
    [bool]$EnableAlerts

    DRMMSiteSettings() : base() {

    }

    static [DRMMSiteSettings] FromApi([pscustomobject]$Response) {

        if ($null -eq $Response) { return $null }

        $Settings = [DRMMSiteSettings]::new()
        $Settings.AutoPatch = $Response.autoPatch
        $Settings.Timezone = $Response.timezone
        $Settings.MaintenanceWindow = $Response.maintenanceWindow
        $Settings.EnableAlerts = $Response.enableAlerts

        return $Settings

    }

}

class DRMMSite : DRMMObject {

    [long]$Id
    [string]$Uid
    [string]$AccountUid
    [string]$Name
    [string]$Description
    [string]$Notes
    [bool]$OnDemand
    [bool]$SplashtopAutoInstall
    [DRMMProxySettings]$ProxySettings
    [DRMMDevicesStatus]$DevicesStatus
    [DRMMSiteSettings]$SiteSettings
    [string]$AutotaskCompanyName
    [string]$AutotaskCompanyId
    [string]$PortalUrl
    [datetime]$CreatedAt
    [long]$CreatedAtEpoch
    [datetime]$UpdatedAt
    [long]$UpdatedAtEpoch

    DRMMSite() : base() {

    }

    static [DRMMSite] FromApi([pscustomobject]$Response) {

        if ($null -eq $Response) { return $null }

        $Site = [DRMMSite]::new()
        $Site.Id = $Response.id
        $Site.Uid = $Response.uid
        $Site.AccountUid = $Response.accountUid
        $Site.Name = $Response.name
        $Site.Description = $Response.description
        $Site.Notes = $Response.notes
        $Site.OnDemand = $Response.onDemand
        $Site.SplashtopAutoInstall = $Response.splashtopAutoInstall
        $Site.AutotaskCompanyName = $Response.autotaskCompanyName
        $Site.AutotaskCompanyId = $Response.autotaskCompanyId
        $Site.PortalUrl = $Response.portalUrl
        $CreatedEpoch = $Response.createdAt

        if ($null -ne $CreatedEpoch) {

            $Site.CreatedAtEpoch = [long]$CreatedEpoch
            $Site.CreatedAt = [DRMMObject]::ConvertEpochToDateTime($Site.CreatedAtEpoch)

        }

        $UpdatedEpoch = $Response.updatedAt

        if ($null -ne $UpdatedEpoch) {

            $Site.UpdatedAtEpoch = [long]$UpdatedEpoch
            $Site.UpdatedAt = [DRMMObject]::ConvertEpochToDateTime($Site.UpdatedAtEpoch)

        }

        $ProxySettingsResponse = $Response.proxySettings

        if ($ProxySettingsResponse) {

            $Site.ProxySettings = [DRMMProxySettings]::FromApi($ProxySettingsResponse)

        }

        $DevicesStatusResponse = $Response.devicesStatus

        if ($DevicesStatusResponse) {

            $Site.DevicesStatus = [DRMMDevicesStatus]::FromApi($DevicesStatusResponse)

        }

        $SiteSettingsResponse = $Response.siteSettings

        if ($SiteSettingsResponse) {

            $Site.SiteSettings = [DRMMSiteSettings]::FromApi($SiteSettingsResponse)

        }

        return $Site

    }

    [string] GetSummary() {

        $DeviceCount = if ($this.DevicesStatus -and $null -ne $this.DevicesStatus.NumberOfDevices) { $this.DevicesStatus.NumberOfDevices.ToString() } else { '0' }

        return "$($this.Name) ($($this.Uid)) - Devices: $DeviceCount"

    }

    [DRMMSite] Update([pscustomobject]$UpdatePayload) {

        if (-not (Get-Command -Name Invoke-RMMAPI -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        $Path = "/v2/site/$($this.Uid)"
        $ResponseObject = Invoke-RMMAPI -Method 'POST' -Path $Path -Body $UpdatePayload

        if ($null -eq $ResponseObject) {

            return $null

        }

        return [DRMMSite]::FromApi($ResponseObject)

    }

    [void] Delete() {

        if (-not (Get-Command -Name Invoke-RMMAPI -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        $Path = "/v2/site/$($this.Uid)"
        Invoke-RMMAPI -Method 'DELETE' -Path $Path | Out-Null

    }
}

class DRMMVariable : DRMMObject {

    [long]$Id
    [string]$Key
    [object]$Value
    [string]$Scope
    [string]$SiteUid
    [bool]$IsSecret
    [string]$Description
    [datetime]$CreatedAt
    [long]$CreatedAtEpoch
    [datetime]$UpdatedAt
    [long]$UpdatedAtEpoch

    DRMMVariable() : base() {

    }

    static [DRMMVariable] FromApi([pscustomobject]$Response) {

        if ($null -eq $Response) { return $null }

        $Variable = [DRMMVariable]::new()

        if ($Response.PSObject.Properties.Name -contains 'id')          { $Variable.Id = $Response.id }
        if ($Response.PSObject.Properties.Name -contains 'key')         { $Variable.Key = $Response.key }
        if ($Response.PSObject.Properties.Name -contains 'value')       { $Variable.Value = $Response.value }
        if ($Response.PSObject.Properties.Name -contains 'scope')       { $Variable.Scope = $Response.scope }
        if ($Response.PSObject.Properties.Name -contains 'siteUid')     { $Variable.SiteUid = $Response.siteUid }
        if ($Response.PSObject.Properties.Name -contains 'isSecret')    { $Variable.IsSecret = $Response.isSecret }
        if ($Response.PSObject.Properties.Name -contains 'description') { $Variable.Description = $Response.description }

        if ($Response.PSObject.Properties.Name -contains 'creationDate') {

            $ParseDate = [DRMMObject]::ParseApiDate($Response.creationDate)
            $Variable.CreatedAt = $ParseDate.DateTime; $Variable.CreatedAtEpoch = $ParseDate.Epoch

        }

        if ($Response.PSObject.Properties.Name -contains 'updatedDate') {

            $ParseDate = [DRMMObject]::ParseApiDate($Response.updatedDate)
            $Variable.UpdatedAt = $ParseDate.DateTime; $Variable.UpdatedAtEpoch = $ParseDate.Epoch

        }

        return $Variable

    }

    [bool] IsGlobal() { return ($this.Scope -eq 'global') }
    [bool] IsSite()   { return ($this.Scope -eq 'site') }

    [string] GetSummary([bool]$RevealValue = $false) {

        $Val = if ($this.IsSecret -and -not $RevealValue) { [DRMMObject]::MaskString([string]$this.Value) } else { $this.Value }
        $ScopeValue = if ($this.Scope) { $this.Scope } else { 'global' }

        return "$($this.Key) [$ScopeValue] = $Val"

    }

}
