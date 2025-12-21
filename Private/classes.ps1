# enum types
enum RMMSiteExtendedProperty {
    Settings
    Variables
    Filters
}

enum RMMScope {
    Global
    Site
}

enum RMMPlatform {
    Pinotage
    Concord
    Vidal
    Merlot
    Zinfandel
    Syrah
}

# classes

class DRMMObject {

    DRMMObject() {}

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

class DRMMStatus : DRMMObject {

    [string]$Version
    [string]$Status
    [Nullable[datetime]]$Started

    DRMMStatus() : base() {

    }

    static [DRMMStatus] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) { return $null }

        $Result = [DRMMStatus]::new()
        $Result.Version = [DRMMObject]::GetValue($Response, 'version')
        $Result.Status = [DRMMObject]::GetValue($Response, 'status')
        
        $StartedValue = [DRMMObject]::GetValue($Response, 'started')

        if ($null -ne $StartedValue) {
            
            try {

                $Result.Started = [datetime]::Parse($StartedValue)

            } catch {

                $Result.Started = $null

            }
        }

        return $Result

    }
}

class DRMMDevicesStatus : DRMMObject {

    [long]$NumberOfDevices
    [long]$NumberOfOnlineDevices
    [long]$NumberOfOfflineDevices

    DRMMDevicesStatus() : base() {

    }

    static [DRMMDevicesStatus] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) { return $null }

            $DevicesStatus = [DRMMDevicesStatus]::new()
            $DevicesStatus.NumberOfDevices = $Response.numberOfDevices
            $DevicesStatus.NumberOfOnlineDevices = $Response.numberOfOnlineDevices
            $DevicesStatus.NumberOfOfflineDevices = $Response.numberOfOfflineDevices

            return $DevicesStatus

    }

    [string] GetSummary() {

        return "Devices: $($this.NumberOfDevices), Online: $($this.NumberOfOnlineDevices), Offline: $($this.NumberOfOfflineDevices)"

    }
}

class DRMMSiteSettings : DRMMObject {

    [DRMMGeneralSettings]$GeneralSettings
    [DRMMProxySettings]$ProxySettings  # Reuse existing class
    [DRMMMailRecipient[]]$MailRecipients
    [guid]$SiteUid

    DRMMSiteSettings() : base() {

    }

    static [DRMMSiteSettings] FromAPIMethod([pscustomobject]$Response, $SiteUid) {

        if ($null -eq $Response) {return $null}

        $Settings = [DRMMSiteSettings]::new()

        if ($Response.generalSettings) {

            $Settings.GeneralSettings = [DRMMGeneralSettings]::FromAPIMethod($Response.generalSettings)

        } else {

            $Settings.GeneralSettings = $null

        }

        if ($Response.proxySettings) {

            $Settings.ProxySettings = [DRMMProxySettings]::FromAPIMethod($Response.proxySettings)
            
        } else {

            $Settings.ProxySettings = $null

        }

        $Settings.MailRecipients = $Response.mailRecipients | ForEach-Object {[DRMMMailRecipient]::FromAPIMethod($_)}
        $Settings.SiteUid = $SiteUid
        
        return $Settings
    }

    [string] GetSummary() {

        $GeneralInfo = if ($this.GeneralSettings) { "OnDemand: $($this.GeneralSettings.OnDemand)" } else { "OnDemand: -" }
        $ProxyInfo = if ($this.ProxySettings) { " | Proxy: $($this.ProxySettings.GetSummary())" } else { " | Proxy: -" }
        $MailCount = if ($this.MailRecipients) { " | Mail Recipients: $($this.MailRecipients.Count)" } else { " | Mail Recipients: 0" }

        return "$GeneralInfo$ProxyInfo$MailCount"

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

    static [DRMMProxySettings] FromAPIMethod([pscustomobject]$Response) {

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

    [string] GetSummary() {

        $ProxyInfo = if ($this.Host) {"$($this.Type)://$($this.Host)$(if ($this.Port) {":$($this.Port)"})"} else {$null}
        return $ProxyInfo

    }
}

class DRMMGeneralSettings : DRMMObject {

    [string]$Name
    [string]$Uid
    [string]$Description
    [bool]$OnDemand

    DRMMGeneralSettings() : base() {}

    static [DRMMGeneralSettings] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {return $null}

        $Settings = [DRMMGeneralSettings]::new()
        $Settings.Name = $Response.name
        $Settings.Uid = $Response.uid
        $Settings.Description = $Response.description
        $Settings.OnDemand = $Response.onDemand

        return $Settings

    }

    [string] GetSummary() {

        return "OnDemand: $($this.OnDemand)"

    }
}

class DRMMMailRecipient : DRMMObject {

    [string]$Name
    [string]$Email
    [string]$Type

    DRMMMailRecipient() : base() {}

    static [DRMMMailRecipient] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {return $null}

        $Recipient = [DRMMMailRecipient]::new()
        $Recipient.Name = $Response.name
        $Recipient.Email = $Response.email
        $Recipient.Type = $Response.type

        return $Recipient

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
    [DRMMVariable[]]$Variables
    [object]$Filters  # Placeholder for filters data
    [string]$AutotaskCompanyName
    [string]$AutotaskCompanyId
    [string]$PortalUrl

    DRMMSite() : base() {

    }

    static [DRMMSite] FromAPIMethod([pscustomobject]$Response) {

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

        $ProxySettingsResponse = $Response.proxySettings

        if ($ProxySettingsResponse) {

            $Site.ProxySettings = [DRMMProxySettings]::FromAPIMethod($ProxySettingsResponse)

        }

        $DevicesStatusResponse = $Response.devicesStatus

        if ($DevicesStatusResponse) {

            $Site.DevicesStatus = [DRMMDevicesStatus]::FromAPIMethod($DevicesStatusResponse)

        }

        $SiteSettingsResponse = $Response.siteSettings

        if ($SiteSettingsResponse) {

            $Site.SiteSettings = [DRMMSiteSettings]::FromAPIMethod($SiteSettingsResponse)

        }

        return $Site

    }

    [string] GetSummary() {

        $DeviceCount = if ($this.DevicesStatus -and $null -ne $this.DevicesStatus.NumberOfDevices) {"$($this.DevicesStatus.NumberOfDevices)"} else {'0'}

        return "$($this.Name) ($($this.Uid)) - Devices: $DeviceCount"

    }

    [DRMMSite] Update([pscustomobject]$UpdatePayload) {

        if (-not (Get-Command -Name Invoke-APIMethod -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        $Path = "site/$($this.Uid)"
        Write-Debug "Updating site $($this.Name) ($($this.Uid)) in Datto RMM: $Path"
        $ResponseObject = $null #Invoke-APIMethod -Method 'POST' -Path $Path -Body $UpdatePayload

        if ($null -eq $ResponseObject) {

            return $null

        }

        return [DRMMSite]::FromAPIMethod($ResponseObject)

    }

    [void] Delete() {

        if (-not (Get-Command -Name Invoke-APIMethod -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        $Path = "site/$($this.Uid)"
        Write-Debug "Deleting site $($this.Name) ($($this.Uid)) from Datto RMM: $Path"
        #Invoke-APIMethod -Method 'DELETE' -Path $Path | Out-Null

    }

    [DRMMAlert[]] GetAlerts() {

        if (-not (Get-Command -Name Get-RMMAlert -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Get-RMMAlert -SiteUid $this.Uid -Status 'All'

    }

    [DRMMAlert[]] GetAlerts([string]$Status) {

        if (-not (Get-Command -Name Get-RMMAlert -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Get-RMMAlert -SiteUid $this.Uid -Status $Status

    }

    [void] OpenPortal() {

        if ($this.PortalUrl) {

            Start-Process $this.PortalUrl

        } else {

            Write-Warning "Portal URL is not available for site $($this.Name)"

        }

    }
}

class DRMMVariable : DRMMObject {

    [long]$Id
    [string]$Name
    [object]$Value
    [string]$Scope
    [Nullable[guid]]$SiteUid
    [bool]$IsSecret

    DRMMVariable() : base() {

    }

    static [DRMMVariable] FromAPIMethod([pscustomobject]$Response, [string]$Scope, [Nullable[guid]]$SiteUid) {

        if ($null -eq $Response) { return $null }

        $Variable = [DRMMVariable]::new()
        $Variable.Id = $Response.id
        $Variable.Name = $Response.name
        $Variable.Value = $Response.value
        $Variable.IsSecret = $Response.masked
        $Variable.Scope = $Scope
        $Variable.SiteUid = $SiteUid

        return $Variable

    }

    [bool] IsGlobal() { return ($this.Scope -eq 'Global') }
    [bool] IsSite()   { return ($this.Scope -eq 'Site') }

    [string] GetSummary() {

        # API already returns masked values for secret variables
        $ScopeValue = if ($this.Scope) { $this.Scope } else { 'Global' }

        return "$($this.Name) [$ScopeValue] = $($this.Value)"

    }
}

class DRMMFilter : DRMMObject {

    [long]$Id
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

        if ($null -eq $Response) { return $null }

        $Filter = [DRMMFilter]::new()
        $Filter.Id = $Response.id
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
}

class DRMMAlertMonitorInfo : DRMMObject {

    [bool]$SendsEmails
    [bool]$CreatesTicket

    DRMMAlertMonitorInfo() : base() {

    }

    static [DRMMAlertMonitorInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $MonitorInfo = [DRMMAlertMonitorInfo]::new()
        $MonitorInfo.SendsEmails = $Response.sendsEmails
        $MonitorInfo.CreatesTicket = $Response.createsTicket

        return $MonitorInfo

    }
}

class DRMMAlertSourceInfo : DRMMObject {

    [string]$DeviceUid
    [string]$DeviceName
    [string]$SiteUid
    [string]$SiteName

    DRMMAlertSourceInfo() : base() {

    }

    static [DRMMAlertSourceInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $SourceInfo = [DRMMAlertSourceInfo]::new()
        $SourceInfo.DeviceUid = $Response.deviceUid
        $SourceInfo.DeviceName = $Response.deviceName
        $SourceInfo.SiteUid = $Response.siteUid
        $SourceInfo.SiteName = $Response.siteName

        return $SourceInfo

    }
}

class DRMMResponseAction : DRMMObject {

    [Nullable[datetime]]$ActionTime
    [string]$ActionType
    [string]$Description
    [string]$ActionReference
    [string]$ActionReferenceInt

    DRMMResponseAction() : base() {

    }

    static [DRMMResponseAction] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $ResponseAction = [DRMMResponseAction]::new()

        $ActionDate = [DRMMObject]::ParseApiDate($Response.actionTime)
        $ResponseAction.ActionTime = $ActionDate.DateTime

        $ResponseAction.ActionType = $Response.actionType

        $ResponseAction.Description = $Response.description

        $ResponseAction.ActionReference = $Response.actionReference

        $ResponseAction.ActionReferenceInt = $Response.actionReferenceInt

        return $ResponseAction

    }
}

class DRMMAlertContext : DRMMObject {

    [string]$Class
    [hashtable]$Properties

    DRMMAlertContext() : base() {

    }

    static [DRMMAlertContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContext]::new()
        $Context.Class = $Response.'@class'
        
        # Store all properties except @class
        $Context.Properties = @{}
        foreach ($Property in $Response.PSObject.Properties) {

            if ($Property.Name -ne '@class') {

                $Context.Properties[$Property.Name] = $Property.Value

            }

        }

        return $Context

    }

    [string] GetContextType() {
        
        if ($this.Class) {

            return $this.Class -replace 'Context$', ''

        }

        return 'Unknown'

    }
}

class DRMMAlert : DRMMObject {

    [guid]$AlertUid
    [string]$Priority
    [string]$Diagnostics
    [bool]$Resolved
    [string]$ResolvedBy
    [Nullable[datetime]]$ResolvedOn
    [bool]$Muted
    [string]$TicketNumber
    [Nullable[datetime]]$Timestamp
    [DRMMAlertMonitorInfo]$AlertMonitorInfo
    [DRMMAlertContext]$AlertContext
    [DRMMAlertSourceInfo]$AlertSourceInfo
    [DRMMResponseAction[]]$ResponseActions
    [Nullable[int]]$AutoresolveMins
    [string]$Scope
    [Nullable[guid]]$SiteUid

    DRMMAlert() : base() {

    }

    static [DRMMAlert] FromAPIMethod([pscustomobject]$Response, [string]$Scope, [Nullable[guid]]$SiteUid) {

        if ($null -eq $Response) {

            return $null

        }

        $Alert = [DRMMAlert]::new()
        $Alert.AlertUid = $Response.alertUid
        $Alert.Priority = $Response.priority
        $Alert.Diagnostics = $Response.diagnostics
        $Alert.Resolved = $Response.resolved
        $Alert.ResolvedBy = $Response.resolvedBy
        $Alert.Muted = $Response.muted
        $Alert.TicketNumber = $Response.ticketNumber
        $Alert.AutoresolveMins = $Response.autoresolveMins
        $Alert.Scope = $Scope
        $Alert.SiteUid = $SiteUid

        $Alert.AlertMonitorInfo = [DRMMAlertMonitorInfo]::FromAPIMethod($Response.alertMonitorInfo)
        $Alert.AlertContext = [DRMMAlertContext]::FromAPIMethod($Response.alertContext)
        $Alert.AlertSourceInfo = [DRMMAlertSourceInfo]::FromAPIMethod($Response.alertSourceInfo)

        if ($null -ne $Response.responseActions) {

            $Alert.ResponseActions = $Response.responseActions | ForEach-Object {

                [DRMMResponseAction]::FromAPIMethod($_)
                
            }

        }

        #$ResolvedDate = [DRMMObject]::ParseApiDate($Response.resolvedOn)
        #$Alert.ResolvedOn = $ResolvedDate.DateTime
        $Alert.ResolvedOn = $Response.resolvedOn
        #$TimestampDate = [DRMMObject]::ParseApiDate($Response.timestamp)
        #$Alert.Timestamp = $TimestampDate.DateTime
        $Alert.Timestamp = $Response.timestamp

        return $Alert

    }

    [bool] IsGlobal() { return ($this.Scope -eq 'Global') }
    [bool] IsSite()   { return ($this.Scope -eq 'Site') }
    [bool] IsOpen()   { return (-not $this.Resolved) }
    [bool] IsCritical() { return ($this.Priority -eq 'Critical') }
    [bool] IsHigh()   { return ($this.Priority -eq 'High') }

    [string] GetSummary() {

        $StatusValue = if ($this.Resolved) { 'Resolved' } else { 'Open' }
        $MutedValue = if ($this.Muted) { ' (Muted)' } else { '' }
        $DeviceName = if ($this.AlertSourceInfo.DeviceName) { $this.AlertSourceInfo.DeviceName } else { 'Unknown' }

        return "[$StatusValue$MutedValue] $($this.Priority) - $DeviceName"

    }
}

class DRMMUdfs : DRMMObject {

    [string]$Udf1
    [string]$Udf2
    [string]$Udf3
    [string]$Udf4
    [string]$Udf5
    [string]$Udf6
    [string]$Udf7
    [string]$Udf8
    [string]$Udf9
    [string]$Udf10
    [string]$Udf11
    [string]$Udf12
    [string]$Udf13
    [string]$Udf14
    [string]$Udf15
    [string]$Udf16
    [string]$Udf17
    [string]$Udf18
    [string]$Udf19
    [string]$Udf20
    [string]$Udf21
    [string]$Udf22
    [string]$Udf23
    [string]$Udf24
    [string]$Udf25
    [string]$Udf26
    [string]$Udf27
    [string]$Udf28
    [string]$Udf29
    [string]$Udf30

    DRMMUdfs() : base() {

    }

    static [DRMMUdfs] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $UdfEntries = [DRMMUdfs]::new()

        for ($i = 1; $i -le 30; $i++) {

            $PropName = "udf$i"
            $UdfPropName = "Udf$i"

            if ($Response.PSObject.Properties.Name -contains $PropName) {

                $Value = $Response.$PropName

                if ($null -ne $Value -and $Value -ne '') {

                    $UdfEntries.$UdfPropName = $Value

                }

            }

        }

        return $UdfEntries

    }
}

class DRMMDeviceType : DRMMObject {

    [string]$Category
    [string]$Type

    DRMMDeviceType() : base() {

    }

    static [DRMMDeviceType] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $DeviceType = [DRMMDeviceType]::new()
        $DeviceType.Category = $Response.category
        $DeviceType.Type = $Response.type

        return $DeviceType

    }
}

class DRMMNetworkInterface : DRMMObject {

    [string]$Instance
    [string]$Ipv4
    [string]$Ipv6
    [string]$MacAddress
    [string]$Type

    DRMMNetworkInterface() : base() {

    }

    static [DRMMNetworkInterface] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Nic = [DRMMNetworkInterface]::new()
        $Nic.Instance = $Response.instance
        $Nic.Ipv4 = $Response.ipv4
        $Nic.Ipv6 = $Response.ipv6
        $Nic.MacAddress = $Response.macAddress
        $Nic.Type = $Response.type

        return $Nic

    }
}

class DRMMDeviceNetworkInterface : DRMMObject {

    [long]$Id
    [guid]$Uid
    [long]$SiteId
    [guid]$SiteUid
    [string]$SiteName
    [DRMMDeviceType]$DeviceType
    [string]$Hostname
    [string]$IntIpAddress
    [string]$ExtIpAddress
    [DRMMNetworkInterface[]]$Nics

    DRMMDeviceNetworkInterface() : base() {

        $this.Nics = @()

    }

    static [DRMMDeviceNetworkInterface] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Device = [DRMMDeviceNetworkInterface]::new()
        $Device.Id = $Response.id
        $Device.Uid = $Response.uid
        $Device.SiteId = $Response.siteId
        $Device.SiteUid = $Response.siteUid
        $Device.SiteName = $Response.siteName
        $Device.DeviceType = [DRMMDeviceType]::FromAPIMethod($Response.deviceType)
        $Device.Hostname = $Response.hostname
        $Device.IntIpAddress = $Response.intIpAddress
        $Device.ExtIpAddress = $Response.extIpAddress

        if ($Response.nics) {

            $Device.Nics = $Response.nics | ForEach-Object {

                [DRMMNetworkInterface]::FromAPIMethod($_)

            }

        }

        return $Device

    }
}

class DRMMAntivirusInfo : DRMMObject {

    [string]$AntivirusProduct
    [string]$AntivirusStatus

    DRMMAntivirusInfo() : base() {

    }

    static [DRMMAntivirusInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $AntivirusInfo = [DRMMAntivirusInfo]::new()
        $AntivirusInfo.AntivirusProduct = $Response.antivirusProduct
        $AntivirusInfo.AntivirusStatus = $Response.antivirusStatus

        return $AntivirusInfo

    }

    [bool] IsRunning() {

        return ($this.AntivirusStatus -match '^Running')

    }

    [bool] IsUpToDate() {

        return ($this.AntivirusStatus -eq 'RunningAndUpToDate')

    }

    [string] GetSummary() {

        return "$($this.AntivirusProduct) - $($this.AntivirusStatus)"

    }
}

class DRMMUser : DRMMObject {

    [string]$FirstName
    [string]$LastName
    [string]$Username
    [string]$Email
    [string]$Telephone
    [string]$Status
    [Nullable[datetime]]$Created
    [Nullable[datetime]]$LastAccess
    [bool]$Disabled

    DRMMUser() : base() {

    }

    static [DRMMUser] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $User = [DRMMUser]::new()
        $User.FirstName = $Response.firstName
        $User.LastName = $Response.lastName
        $User.Username = $Response.username
        $User.Email = $Response.email
        $User.Telephone = $Response.telephone
        $User.Status = $Response.status
        $User.Disabled = $Response.disabled

        $User.Created = ([DRMMObject]::ParseApiDate($Response.created)).DateTime
        $User.LastAccess = ([DRMMObject]::ParseApiDate($Response.lastAccess)).DateTime

        return $User

    }

    [string] GetFullName() {

        return "$($this.FirstName) $($this.LastName)".Trim()

    }

    [string] GetSummary() {

        $FullName = $this.GetFullName()
        $StatusText = if ($this.Disabled) { " (Disabled)" } else { "" }

        return "$FullName ($($this.Username))$StatusText"

    }
}

class DRMMPatchManagement : DRMMObject {

    [string]$PatchStatus
    [Nullable[long]]$PatchesApprovedPending
    [Nullable[long]]$PatchesNotApproved
    [Nullable[long]]$PatchesInstalled

    DRMMPatchManagement() : base() {

    }

    static [DRMMPatchManagement] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $PatchMgmt = [DRMMPatchManagement]::new()
        $PatchMgmt.PatchStatus = $Response.patchStatus
        $PatchMgmt.PatchesApprovedPending = $Response.patchesApprovedPending
        $PatchMgmt.PatchesNotApproved = $Response.patchesNotApproved
        $PatchMgmt.PatchesInstalled = $Response.patchesInstalled

        return $PatchMgmt

    }
}

class DRMMDevice : DRMMObject {

    [long]$Id
    [guid]$Uid
    [long]$SiteId
    [guid]$SiteUid
    [string]$SiteName
    [DRMMDeviceType]$DeviceType
    [string]$Hostname
    [string]$IntIpAddress
    [string]$OperatingSystem
    [string]$LastLoggedInUser
    [string]$Domain
    [string]$CagVersion
    [string]$DisplayVersion
    [string]$ExtIpAddress
    [string]$Description
    [bool]$A64Bit
    [bool]$RebootRequired
    [bool]$Online
    [bool]$Suspended
    [bool]$Deleted
    [Nullable[datetime]]$LastSeen
    [Nullable[datetime]]$LastReboot
    [Nullable[datetime]]$LastAuditDate
    [Nullable[datetime]]$CreationDate
    [DRMMUdfs]$Udfs
    [bool]$SnmpEnabled
    [string]$DeviceClass
    [string]$PortalUrl
    [string]$WarrantyDate
    [DRMMAntivirusInfo]$Antivirus
    [DRMMPatchManagement]$PatchManagement
    [string]$SoftwareStatus
    [string]$WebRemoteUrl
    [bool]$NetworkProbe
    [bool]$OnboardedViaNetworkMonitor
    [bool]$RevealLastLoggedInUser

    DRMMDevice() : base() {

        $this.RevealLastLoggedInUser = $false

    }

    static [DRMMDevice] FromAPIMethod([pscustomobject]$Response) {

        return [DRMMDevice]::FromAPIMethod($Response, $false)

    }

    static [DRMMDevice] FromAPIMethod([pscustomobject]$Response, [bool]$RevealLastLoggedInUser) {

        if ($null -eq $Response) {

            return $null

        }

        $Device = [DRMMDevice]::new()
        $Device.Id = $Response.id
        $Device.Uid = $Response.uid
        $Device.SiteId = $Response.siteId
        $Device.SiteUid = $Response.siteUid
        $Device.SiteName = $Response.siteName
        $Device.Hostname = $Response.hostname
        $Device.IntIpAddress = $Response.intIpAddress
        $Device.OperatingSystem = $Response.operatingSystem
        $Device.RevealLastLoggedInUser = $RevealLastLoggedInUser

        if ($RevealLastLoggedInUser) {

            $Device.LastLoggedInUser = $Response.lastLoggedInUser

        } else {

            $Device.LastLoggedInUser = [DRMMObject]::MaskString([string]$Response.lastLoggedInUser, 2, '*')

        }

        $Device.Domain = $Response.domain
        $Device.CagVersion = $Response.cagVersion
        $Device.DisplayVersion = $Response.displayVersion
        $Device.ExtIpAddress = $Response.extIpAddress
        $Device.Description = $Response.description
        $Device.A64Bit = $Response.a64Bit
        $Device.RebootRequired = $Response.rebootRequired
        $Device.Online = $Response.online
        $Device.Suspended = $Response.suspended
        $Device.Deleted = $Response.deleted
        $Device.SnmpEnabled = $Response.snmpEnabled
        $Device.DeviceClass = $Response.deviceClass
        $Device.PortalUrl = $Response.portalUrl
        $Device.WarrantyDate = $Response.warrantyDate
        $Device.SoftwareStatus = $Response.softwareStatus
        $Device.WebRemoteUrl = $Response.webRemoteUrl
        $Device.NetworkProbe = $Response.networkProbe
        $Device.OnboardedViaNetworkMonitor = $Response.onboardedViaNetworkMonitor

        $Device.DeviceType = [DRMMDeviceType]::FromAPIMethod($Response.deviceType)
        $Device.Udfs = [DRMMUdfs]::FromAPIMethod($Response.udf)
        $Device.Antivirus = [DRMMAntivirusInfo]::FromAPIMethod($Response.antivirus)
        $Device.PatchManagement = [DRMMPatchManagement]::FromAPIMethod($Response.patchManagement)

        $Device.LastSeen = ([DRMMObject]::ParseApiDate($Response.lastSeen)).DateTime
        $Device.LastReboot = ([DRMMObject]::ParseApiDate($Response.lastReboot)).DateTime
        $Device.LastAuditDate = ([DRMMObject]::ParseApiDate($Response.lastAuditDate)).DateTime
        $Device.CreationDate = ([DRMMObject]::ParseApiDate($Response.creationDate)).DateTime

        return $Device

    }

    [DRMMAlert[]] GetAlerts() {

        if (-not (Get-Command -Name Get-RMMAlert -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Get-RMMAlert -DeviceUid $this.Uid -Status 'All'

    }

    [DRMMAlert[]] GetAlerts([string]$Status) {

        if (-not (Get-Command -Name Get-RMMAlert -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Get-RMMAlert -DeviceUid $this.Uid -Status $Status

    }

    [void] OpenPortal() {

        if ($this.PortalUrl) {

            Start-Process $this.PortalUrl

        } else {

            Write-Warning "Portal URL is not available for device $($this.Hostname)"

        }
    }

    [void] OpenWebRemote() {

        if ($this.WebRemoteUrl) {

            Start-Process $this.WebRemoteUrl

        } else {

            Write-Warning "Web Remote URL is not available for device $($this.Hostname)"

        }
    }

    [object] GetUdfAsJson([int]$UdfNumber) {

        if ($UdfNumber -lt 1 -or $UdfNumber -gt 30) {

            throw "UDF number must be between 1 and 30"

        }

        $UdfPropName = "Udf$UdfNumber"
        $UdfValue = $this.Udfs.$UdfPropName

        if ([string]::IsNullOrWhiteSpace($UdfValue)) {

            return $null

        }

        try {

            return $UdfValue | ConvertFrom-Json

        } catch {

            throw "Failed to parse UDF $UdfNumber as JSON: $_"

        }
    }

    [pscustomobject] GetUdfAsCsv([int]$UdfNumber, [string]$Delimiter, [string[]]$ColumnHeaders) {

        if ($UdfNumber -lt 1 -or $UdfNumber -gt 30) {

            throw "UDF number must be between 1 and 30"

        }

        if ([string]::IsNullOrEmpty($Delimiter)) {

            throw "Delimiter cannot be null or empty"

        }

        if ($null -eq $ColumnHeaders -or $ColumnHeaders.Count -eq 0) {

            throw "ColumnHeaders must contain at least one column name"

        }

        $UdfPropName = "Udf$UdfNumber"
        $UdfValue = $this.Udfs.$UdfPropName

        if ([string]::IsNullOrWhiteSpace($UdfValue)) {
            
            return $null

        }

        $Values = $UdfValue -split [regex]::Escape($Delimiter)
        $Result = [ordered]@{}

        for ($i = 0; $i -lt $ColumnHeaders.Count; $i++) {

            if ($i -lt $Values.Count) {

                $Value = $Values[$i]
                
                # Attempt automatic type conversion
                $TypedValue = $Value

                if (-not [string]::IsNullOrWhiteSpace($Value)) {

                    # Try converting to number
                    if ($Value -match '^\-?\d+$') {

                        try {

                            $TypedValue = [int]$Value

                        } catch {

                            # If too large for int, use long
                            $TypedValue = [long]$Value

                        }

                    } elseif ($Value -match '^\-?\d+\.\d+$') {

                        $TypedValue = [double]$Value

                    } elseif ($Value -eq 'true' -or $Value -eq 'false') {

                        $TypedValue = [bool]::Parse($Value)

                    }
                }

                $Result[$ColumnHeaders[$i]] = $TypedValue

            } else {

                $Result[$ColumnHeaders[$i]] = $null

            }
        }

        return [pscustomobject]$Result

    }

    [string] GetSummary() {

        $DeviceTypeStr = if ($this.DeviceType) { "$($this.DeviceType.Category)" } else { 'Unknown' }
        return "$($this.Hostname)|$DeviceTypeStr"

    }
}

class DRMMComponentVariable : DRMMObject {

    [string]$Name
    [string]$DefaultValue
    [string]$Type
    [bool]$Direction
    [string]$Description
    [int]$Index

    DRMMComponentVariable() : base() {

    }

    static [DRMMComponentVariable] FromAPIMethod([pscustomobject]$Response) {

        $Variable = [DRMMComponentVariable]::new()

        $Variable.Name = [DRMMObject]::GetValue($Response, 'name')
        $Variable.DefaultValue = [DRMMObject]::GetValue($Response, 'defaultVal')
        $Variable.Type = [DRMMObject]::GetValue($Response, 'type')
        $Variable.Direction = [DRMMObject]::GetValue($Response, 'direction')
        $Variable.Description = [DRMMObject]::GetValue($Response, 'description')
        $Variable.Index = [DRMMObject]::GetValue($Response, 'variablesIdx')

        return $Variable

    }

    [string] GetSummary() {

        $DirectionText = if ($this.Direction) { 'Input' } else { 'Output' }
        return "[$DirectionText] $($this.Name) ($($this.Type))"

    }
}

class DRMMComponent : DRMMObject {

    [int]$Id
    [string]$Uid
    [string]$Name
    [string]$Description
    [string]$CategoryCode
    [bool]$CredentialsRequired
    [DRMMComponentVariable[]]$Variables

    DRMMComponent() : base() {

    }

    static [DRMMComponent] FromAPIMethod([pscustomobject]$Response) {

        $Component = [DRMMComponent]::new()

        $Component.Id = [DRMMObject]::GetValue($Response, 'id')
        $Component.Uid = [DRMMObject]::GetValue($Response, 'uid')
        $Component.Name = [DRMMObject]::GetValue($Response, 'name')
        $Component.Description = [DRMMObject]::GetValue($Response, 'description')
        $Component.CategoryCode = [DRMMObject]::GetValue($Response, 'categoryCode')
        $Component.CredentialsRequired = [DRMMObject]::GetValue($Response, 'credentialsRequired')

        # Parse variables array
        $Component.Variables = @()
        $VariablesArray = [DRMMObject]::GetValue($Response, 'variables')
        if ($null -ne $VariablesArray -and $VariablesArray.Count -gt 0) {

            foreach ($VarItem in $VariablesArray) {

                $Component.Variables += [DRMMComponentVariable]::FromAPIMethod($VarItem)

            }
        }

        return $Component

    }

    [DRMMComponentVariable] GetVariable([string]$Name) {

        return $this.Variables | Where-Object {$_.Name -eq $Name} | Select-Object -First 1

    }

    [DRMMComponentVariable[]] GetInputVariables() {

        return $this.Variables | Where-Object {$_.Direction -eq $true}

    }

    [DRMMComponentVariable[]] GetOutputVariables() {

        return $this.Variables | Where-Object {$_.Direction -eq $false}

    }

    [string] GetSummary() {

        $VarCount = if ($this.Variables) {$this.Variables.Count} else {0}
        $CredText = if ($this.CredentialsRequired) {' [Credentials Required]'} else {''}
        return "$($this.Name)$CredText - $VarCount variable(s) - $($this.CategoryCode)"

    }
}

class DRMMAccountDescriptor : DRMMObject {

    [string]$BillingEmail
    [int]$DeviceLimit
    [string]$TimeZone

    DRMMAccountDescriptor() : base() {

    }

    static [DRMMAccountDescriptor] FromAPIMethod([pscustomobject]$Response) {

        $Descriptor = [DRMMAccountDescriptor]::new()

        $Descriptor.BillingEmail = [DRMMObject]::GetValue($Response, 'bilingEmail')
        $Descriptor.DeviceLimit = [DRMMObject]::GetValue($Response, 'deviceLimit')
        $Descriptor.TimeZone = [DRMMObject]::GetValue($Response, 'timeZone')

        return $Descriptor

    }
}

class DRMMAccountDevicesStatus : DRMMObject {

    [int]$NumberOfDevices
    [int]$NumberOfOnlineDevices
    [int]$NumberOfOfflineDevices
    [int]$NumberOfOnDemandDevices
    [int]$NumberOfManagedDevices

    DRMMAccountDevicesStatus() : base() {

    }

    static [DRMMAccountDevicesStatus] FromAPIMethod([pscustomobject]$Response) {

        $Status = [DRMMAccountDevicesStatus]::new()

        $Status.NumberOfDevices = [DRMMObject]::GetValue($Response, 'numberOfDevices')
        $Status.NumberOfOnlineDevices = [DRMMObject]::GetValue($Response, 'numberOfOnlineDevices')
        $Status.NumberOfOfflineDevices = [DRMMObject]::GetValue($Response, 'numberOfOfflineDevices')
        $Status.NumberOfOnDemandDevices = [DRMMObject]::GetValue($Response, 'numberOfOnDemandDevices')
        $Status.NumberOfManagedDevices = [DRMMObject]::GetValue($Response, 'numberOfManagedDevices')

        return $Status

    }

    [double] GetOnlinePercentage() {

        if ($this.NumberOfDevices -eq 0) {
            return 0
        }
        return [Math]::Round(($this.NumberOfOnlineDevices / $this.NumberOfDevices) * 100, 2)

    }

    [string] GetSummary() {

        return "$($this.NumberOfOnlineDevices)/$($this.NumberOfDevices) online ($($this.GetOnlinePercentage())%)"

    }
}

class DRMMAccount : DRMMObject {

    [int]$Id
    [string]$Uid
    [string]$Name
    [string]$Currency
    [DRMMAccountDescriptor]$Descriptor
    [DRMMAccountDevicesStatus]$DevicesStatus

    DRMMAccount() : base() {

    }

    static [DRMMAccount] FromAPIMethod([pscustomobject]$Response) {

        $Account = [DRMMAccount]::new()

        $Account.Id = [DRMMObject]::GetValue($Response, 'id')
        $Account.Uid = [DRMMObject]::GetValue($Response, 'uid')
        $Account.Name = [DRMMObject]::GetValue($Response, 'name')
        $Account.Currency = [DRMMObject]::GetValue($Response, 'currency')

        # Parse descriptor
        $DescriptorData = [DRMMObject]::GetValue($Response, 'descriptor')
        if ($null -ne $DescriptorData) {
            $Account.Descriptor = [DRMMAccountDescriptor]::FromAPIMethod($DescriptorData)
        }

        # Parse devices status
        $DevicesStatusData = [DRMMObject]::GetValue($Response, 'devicesStatus')
        if ($null -ne $DevicesStatusData) {
            $Account.DevicesStatus = [DRMMAccountDevicesStatus]::FromAPIMethod($DevicesStatusData)
        }

        return $Account

    }

    [string] GetSummary() {

        $DeviceInfo = if ($this.DevicesStatus) { $this.DevicesStatus.GetSummary() } else { 'No device status' }
        return "$($this.Name) - $DeviceInfo"

    }
}

class DRMMNetMapping : DRMMObject {

    [long]$Id
    [guid]$Uid
    [string]$AccountUid
    [string]$Name
    [string]$Description
    [long[]]$DatatoNetworkingNetworkIds
    [string]$PortalUrl

    DRMMNetMapping() : base() {

        $this.DatatoNetworkingNetworkIds = @()

    }

    static [DRMMNetMapping] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $NetMapping = [DRMMNetMapping]::new()
        $NetMapping.Id = $Response.id
        $NetMapping.Uid = $Response.uid
        $NetMapping.AccountUid = $Response.accountUid
        $NetMapping.Name = $Response.name
        $NetMapping.Description = $Response.description
        
        if ($Response.dattoNetworkingNetworkIds) {

            $NetMapping.DatatoNetworkingNetworkIds = $Response.dattoNetworkingNetworkIds

        }

        $NetMapping.PortalUrl = $Response.portalUrl

        return $NetMapping

    }

    [void] OpenPortal() {

        if ($this.PortalUrl) {

            Start-Process $this.PortalUrl

        } else {

            Write-Warning "Portal URL is not available for site $($this.Name)"

        }
    }
}
