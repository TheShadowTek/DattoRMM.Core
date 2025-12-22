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

    [string] GetSummary() {

        $EmailStatus = if ($this.SendsEmails) { 'Emails' } else { 'NoEmails' }
        $TicketStatus = if ($this.CreatesTicket) { 'Ticket' } else { 'NoTicket' }

        return "$EmailStatus, $TicketStatus"

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

    [string] GetSummary() {

        $Device = if ($this.DeviceName) { $this.DeviceName } else { 'Unknown' }
        $Site = if ($this.SiteName) { $this.SiteName } else { 'Unknown' }

        return "$Device @ $Site"

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

    [string] GetSummary() {

        $Type = if ($this.ActionType) { $this.ActionType } else { 'Unknown' }
        $Desc = if ($this.Description) { $this.Description } else { '' }

        return "${Type}: ${Desc}"

    }
}

class DRMMAlertContext : DRMMObject {

    [string]$Class

    DRMMAlertContext() : base() {

    }

    [string] GetSummary() {

        return $this.Class

    }

    static [object] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $ClassValue = [DRMMObject]::GetValue($Response, '@class')

        if ($null -eq $ClassValue) {

            # Return generic context if no @class
            return [DRMMAlertContextGeneric]::FromAPIMethod($Response)

        }

        # Map @class values to specific context classes
        $Result = switch -Regex ($ClassValue) {

            '^online_offline_status_ctx$' { [DRMMAlertOnlineOfflineStatusContext]::FromAPIMethod($Response) }
            '^ransomware_ctx$' { [DRMMAlertRansomWareContext]::FromAPIMethod($Response) }
            '^eventlog_ctx$' { [DRMMAlertEventLogContext]::FromAPIMethod($Response) }
            '^comp_script_ctx' { [DRMMAlertScriptContext]::FromAPIMethod($Response) }
            '^antivirus_ctx$' { [DRMMAlertAntivirusContext]::FromAPIMethod($Response) }
            '^backup_management_ctx$' { [DRMMAlertBackupManagementContext]::FromAPIMethod($Response) }
            '^custom_snmp_ctx$' { [DRMMAlertCustomSNMPContext]::FromAPIMethod($Response) }
            '^disk_health_ctx$' { [DRMMAlertDiskHealthContext]::FromAPIMethod($Response) }
            '^disk_usage_ctx$' { [DRMMAlertDiskUsageContext]::FromAPIMethod($Response) }
            '^endpoint_security_threat_ctx$' { [DRMMAlertEndpointSecurityThreatContext]::FromAPIMethod($Response) }
            '^endpoint_security_windows_defender_ctx$' { [DRMMAlertEndpointSecurityWindowsDefenderContext]::FromAPIMethod($Response) }
            '^fan_ctx$' { [DRMMAlertFanContext]::FromAPIMethod($Response) }
            '^filesystem_ctx$' { [DRMMAlertFileSystemContext]::FromAPIMethod($Response) }
            '^network_monitor_ctx$' { [DRMMAlertNetworkMonitorContext]::FromAPIMethod($Response) }
            '^patch_ctx$' { [DRMMAlertPatchContext]::FromAPIMethod($Response) }
            '^ping_ctx$' { [DRMMAlertPingContext]::FromAPIMethod($Response) }
            '^printer_ctx$' { [DRMMAlertPrinterContext]::FromAPIMethod($Response) }
            '^psu_ctx$' { [DRMMAlertPsuContext]::FromAPIMethod($Response) }
            '^resource_usage_ctx$' { [DRMMAlertResourceUsageContext]::FromAPIMethod($Response) }
            '^snmp_probe_ctx$' { [DRMMAlertSNMPProbeContext]::FromAPIMethod($Response) }
            '^seccenter_ctx$' { [DRMMAlertSecCenterContext]::FromAPIMethod($Response) }
            '^security_management_ctx$' { [DRMMAlertSecurityManagementContext]::FromAPIMethod($Response) }
            '^status_ctx$' { [DRMMAlertStatusContext]::FromAPIMethod($Response) }
            '^temperature_ctx$' { [DRMMAlertTemperatureContext]::FromAPIMethod($Response) }
            '^windows_performance_ctx$' { [DRMMAlertWindowsPerformanceContext]::FromAPIMethod($Response) }
            '^wmi_ctx$' { [DRMMAlertWmiContext]::FromAPIMethod($Response) }
            default { [DRMMAlertContextGeneric]::FromAPIMethod($Response) }

        }

        return $Result

    }
}

class DRMMAlertContextGeneric : DRMMAlertContext {

    [hashtable]$Properties

    DRMMAlertContextGeneric() : base() {

    }

    static [DRMMAlertContextGeneric] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextGeneric]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        
        # Store all properties except @class
        $Context.Properties = @{}
        foreach ($Property in $Response.PSObject.Properties) {

            if ($Property.Name -ne '@class') {

                $Context.Properties[$Property.Name] = $Property.Value

            }
        }

        return $Context

    }
}

class DRMMAlertOnlineOfflineStatusContext : DRMMAlertContext {

    [string]$Status

    DRMMAlertOnlineOfflineStatusContext() : base() {

    }

    static [DRMMAlertOnlineOfflineStatusContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertOnlineOfflineStatusContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Status = [DRMMObject]::GetValue($Response, 'status')

        return $Context

    }
}

class DRMMAlertRansomWareContext : DRMMAlertContext {

    [int]$State
    [int]$ConfidenceFactor
    [string[]]$AffectedDirectories
    [string[]]$WatchPaths
    [string]$Rwextension
    [Nullable[datetime]]$MetaAlertTime
    [Nullable[datetime]]$AlertTime

    DRMMAlertRansomWareContext() : base() {

    }

    static [DRMMAlertRansomWareContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertRansomWareContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.State = [DRMMObject]::GetValue($Response, 'state')
        $Context.ConfidenceFactor = [DRMMObject]::GetValue($Response, 'confidenceFactor')
        $Context.AffectedDirectories = [DRMMObject]::GetValue($Response, 'affectedDirectories')
        $Context.WatchPaths = [DRMMObject]::GetValue($Response, 'watchPaths')
        $Context.Rwextension = [DRMMObject]::GetValue($Response, 'rwextension')
        $Context.MetaAlertTime = ([DRMMObject]::ParseApiDate([DRMMObject]::GetValue($Response, 'metaAlertTime'))).DateTime
        $Context.AlertTime = ([DRMMObject]::ParseApiDate([DRMMObject]::GetValue($Response, 'alertTime'))).DateTime

        return $Context

    }
}

class DRMMAlertEventLogContext : DRMMAlertContext {

    [string]$LogName
    [string]$Code
    [string]$Type
    [string]$Source
    [string]$Description
    [int]$TriggerCount
    [Nullable[datetime]]$LastTriggered
    [bool]$CausedSuspension

    DRMMAlertEventLogContext() : base() {

    }

    static [DRMMAlertEventLogContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertEventLogContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.LogName = [DRMMObject]::GetValue($Response, 'logName')
        $Context.Code = [DRMMObject]::GetValue($Response, 'code')
        $Context.Type = [DRMMObject]::GetValue($Response, 'type')
        $Context.Source = [DRMMObject]::GetValue($Response, 'source')
        $Context.Description = [DRMMObject]::GetValue($Response, 'description')
        $Context.TriggerCount = [DRMMObject]::GetValue($Response, 'triggerCount')
        $Context.LastTriggered = ([DRMMObject]::ParseApiDate([DRMMObject]::GetValue($Response, 'lastTriggered'))).DateTime
        $Context.CausedSuspension = [DRMMObject]::GetValue($Response, 'causedSuspension')

        return $Context

    }
}

class DRMMAlertScriptContext : DRMMAlertContext {

    [hashtable]$Samples

    DRMMAlertScriptContext() : base() {

    }

    static [DRMMAlertScriptContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertScriptContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        
        $SamplesData = [DRMMObject]::GetValue($Response, 'samples')
        if ($null -ne $SamplesData) {

            $Context.Samples = @{}
            foreach ($Property in $SamplesData.PSObject.Properties) {

                $Context.Samples[$Property.Name] = $Property.Value

            }
        }

        return $Context

    }
}

class DRMMAlertAntivirusContext : DRMMAlertContext {

    [string]$Status
    [string]$ProductName

    DRMMAlertAntivirusContext() : base() {

    }

    static [DRMMAlertAntivirusContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertAntivirusContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Status = [DRMMObject]::GetValue($Response, 'status')
        $Context.ProductName = [DRMMObject]::GetValue($Response, 'productName')

        return $Context

    }
}

class DRMMAlertBackupManagementContext : DRMMAlertContext {

    [string]$ErrorMessage
    [int]$Timeout

    DRMMAlertBackupManagementContext() : base() {

    }

    static [DRMMAlertBackupManagementContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertBackupManagementContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.ErrorMessage = [DRMMObject]::GetValue($Response, 'errorMessage')
        $Context.Timeout = [DRMMObject]::GetValue($Response, 'timeout')

        return $Context

    }
}

class DRMMAlertCustomSNMPContext : DRMMAlertContext {

    [string]$DisplayName
    [string]$CurrentValue
    [string]$MonitorInstance

    DRMMAlertCustomSNMPContext() : base() {

    }

    static [DRMMAlertCustomSNMPContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertCustomSNMPContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.DisplayName = [DRMMObject]::GetValue($Response, 'displayName')
        $Context.CurrentValue = [DRMMObject]::GetValue($Response, 'currentValue')
        $Context.MonitorInstance = [DRMMObject]::GetValue($Response, 'monitorInstance')

        return $Context

    }
}

class DRMMAlertDiskHealthContext : DRMMAlertContext {

    [string]$Reason
    [string]$Type

    DRMMAlertDiskHealthContext() : base() {

    }

    static [DRMMAlertDiskHealthContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertDiskHealthContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Reason = [DRMMObject]::GetValue($Response, 'reason')
        $Context.Type = [DRMMObject]::GetValue($Response, 'type')

        return $Context

    }
}

class DRMMAlertDiskUsageContext : DRMMAlertContext {

    [string]$DiskName
    [float]$TotalVolume
    [float]$FreeSpace
    [string]$UnitOfMeasure
    [string]$DiskNameDesignation

    DRMMAlertDiskUsageContext() : base() {

    }

    static [DRMMAlertDiskUsageContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertDiskUsageContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.DiskName = [DRMMObject]::GetValue($Response, 'diskName')
        $Context.TotalVolume = [DRMMObject]::GetValue($Response, 'totalVolume')
        $Context.FreeSpace = [DRMMObject]::GetValue($Response, 'freeSpace')
        $Context.UnitOfMeasure = [DRMMObject]::GetValue($Response, 'unitOfMeasure')
        $Context.DiskNameDesignation = [DRMMObject]::GetValue($Response, 'diskNameDesignation')

        return $Context

    }
}

class DRMMAlertEndpointSecurityThreatContext : DRMMAlertContext {

    [string]$EsAlertId
    [string]$Description

    DRMMAlertEndpointSecurityThreatContext() : base() {

    }

    static [DRMMAlertEndpointSecurityThreatContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertEndpointSecurityThreatContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.EsAlertId = [DRMMObject]::GetValue($Response, 'esAlertId')
        $Context.Description = [DRMMObject]::GetValue($Response, 'description')

        return $Context

    }
}

class DRMMAlertEndpointSecurityWindowsDefenderContext : DRMMAlertContext {

    [string]$EsAlertId
    [string]$Description

    DRMMAlertEndpointSecurityWindowsDefenderContext() : base() {

    }

    static [DRMMAlertEndpointSecurityWindowsDefenderContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertEndpointSecurityWindowsDefenderContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.EsAlertId = [DRMMObject]::GetValue($Response, 'esAlertId')
        $Context.Description = [DRMMObject]::GetValue($Response, 'description')

        return $Context

    }
}

class DRMMAlertFanContext : DRMMAlertContext {

    [string]$Reason
    [string]$Type

    DRMMAlertFanContext() : base() {

    }

    static [DRMMAlertFanContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertFanContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Reason = [DRMMObject]::GetValue($Response, 'reason')
        $Context.Type = [DRMMObject]::GetValue($Response, 'type')

        return $Context

    }
}

class DRMMAlertFileSystemContext : DRMMAlertContext {

    [float]$Sample
    [float]$Threshold
    [string]$Path
    [string]$ObjectType
    [string]$Condition

    DRMMAlertFileSystemContext() : base() {

    }

    static [DRMMAlertFileSystemContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertFileSystemContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Sample = [DRMMObject]::GetValue($Response, 'sample')
        $Context.Threshold = [DRMMObject]::GetValue($Response, 'threshold')
        $Context.Path = [DRMMObject]::GetValue($Response, 'path')
        $Context.ObjectType = [DRMMObject]::GetValue($Response, 'objectType')
        $Context.Condition = [DRMMObject]::GetValue($Response, 'condition')

        return $Context

    }
}

class DRMMAlertNetworkMonitorContext : DRMMAlertContext {

    [string]$Description

    DRMMAlertNetworkMonitorContext() : base() {

    }

    static [DRMMAlertNetworkMonitorContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertNetworkMonitorContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Description = [DRMMObject]::GetValue($Response, 'description')

        return $Context

    }
}

class DRMMAlertPatchContext : DRMMAlertContext {

    [string]$PatchUid
    [string]$PolicyUid
    [string]$Result
    [string]$Info

    DRMMAlertPatchContext() : base() {

    }

    static [DRMMAlertPatchContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertPatchContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.PatchUid = [DRMMObject]::GetValue($Response, 'patchUid')
        $Context.PolicyUid = [DRMMObject]::GetValue($Response, 'policyUid')
        $Context.Result = [DRMMObject]::GetValue($Response, 'result')
        $Context.Info = [DRMMObject]::GetValue($Response, 'info')

        return $Context

    }
}

class DRMMAlertPingContext : DRMMAlertContext {

    [string]$InstanceName
    [int]$RoundtripTime
    [string[]]$Reasons

    DRMMAlertPingContext() : base() {

    }

    static [DRMMAlertPingContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertPingContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.InstanceName = [DRMMObject]::GetValue($Response, 'instanceName')
        $Context.RoundtripTime = [DRMMObject]::GetValue($Response, 'roundtripTime')
        $Context.Reasons = [DRMMObject]::GetValue($Response, 'reasons')

        return $Context

    }
}

class DRMMAlertPrinterContext : DRMMAlertContext {

    [string]$IpAddress
    [string]$MacAddress
    [int]$MarkerSupplyIndex
    [int]$CurrentLevel

    DRMMAlertPrinterContext() : base() {

    }

    static [DRMMAlertPrinterContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertPrinterContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.IpAddress = [DRMMObject]::GetValue($Response, 'ipAddress')
        $Context.MacAddress = [DRMMObject]::GetValue($Response, 'macAddress')
        $Context.MarkerSupplyIndex = [DRMMObject]::GetValue($Response, 'markerSupplyIndex')
        $Context.CurrentLevel = [DRMMObject]::GetValue($Response, 'currentLevel')

        return $Context

    }
}

class DRMMAlertPsuContext : DRMMAlertContext {

    [string]$Reason
    [string]$Type

    DRMMAlertPsuContext() : base() {

    }

    static [DRMMAlertPsuContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertPsuContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Reason = [DRMMObject]::GetValue($Response, 'reason')
        $Context.Type = [DRMMObject]::GetValue($Response, 'type')

        return $Context

    }
}

class DRMMAlertResourceUsageContext : DRMMAlertContext {

    [string]$ProcessName
    [float]$Sample
    [string]$Type

    DRMMAlertResourceUsageContext() : base() {

    }

    static [DRMMAlertResourceUsageContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertResourceUsageContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.ProcessName = [DRMMObject]::GetValue($Response, 'processName')
        $Context.Sample = [DRMMObject]::GetValue($Response, 'sample')
        $Context.Type = [DRMMObject]::GetValue($Response, 'type')

        return $Context

    }
}

class DRMMAlertSNMPProbeContext : DRMMAlertContext {

    [string]$IpAddress
    [string]$Oid
    [string]$RuleName
    [string]$ResponseValue
    [string]$DeviceName
    [string]$MonitorName

    DRMMAlertSNMPProbeContext() : base() {

    }

    static [DRMMAlertSNMPProbeContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertSNMPProbeContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.IpAddress = [DRMMObject]::GetValue($Response, 'ipAddress')
        $Context.OID = [DRMMObject]::GetValue($Response, 'OID')
        $Context.RuleName = [DRMMObject]::GetValue($Response, 'ruleName')
        $Context.ResponseValue = [DRMMObject]::GetValue($Response, 'responseValue')
        $Context.DeviceName = [DRMMObject]::GetValue($Response, 'deviceName')
        $Context.MonitorName = [DRMMObject]::GetValue($Response, 'monitorName')
        $Context.Oid = [DRMMObject]::GetValue($Response, 'oid')

        return $Context

    }
}

class DRMMAlertSecCenterContext : DRMMAlertContext {

    [string]$ProductName
    [string]$AlertType

    DRMMAlertSecCenterContext() : base() {

    }

    static [DRMMAlertSecCenterContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertSecCenterContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.ProductName = [DRMMObject]::GetValue($Response, 'productName')
        $Context.AlertType = [DRMMObject]::GetValue($Response, 'alertType')

        return $Context

    }
}

class DRMMAlertSecurityManagementContext : DRMMAlertContext {

    [int]$Status
    [string]$ProductName
    [int]$InfoTime
    [string]$VirusName
    [string[]]$InfectedFiles
    [int]$ProductNotUpdatedForDays
    [int]$SystemRemainsInfectedForHours
    [int]$ExpiryLicenseForDays

    DRMMAlertSecurityManagementContext() : base() {

    }

    static [DRMMAlertSecurityManagementContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertSecurityManagementContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Status = [DRMMObject]::GetValue($Response, 'status')
        $Context.ProductName = [DRMMObject]::GetValue($Response, 'productName')
        $Context.InfoTime = [DRMMObject]::GetValue($Response, 'infoTime')
        $Context.VirusName = [DRMMObject]::GetValue($Response, 'virusName')
        $Context.InfectedFiles = [DRMMObject]::GetValue($Response, 'infectedFiles')
        $Context.ProductNotUpdatedForDays = [DRMMObject]::GetValue($Response, 'productNotUpdatedForDays')
        $Context.SystemRemainsInfectedForHours = [DRMMObject]::GetValue($Response, 'systemRemainsInfectedForHours')
        $Context.ExpiryLicenseForDays = [DRMMObject]::GetValue($Response, 'expiryLicenseForDays')

        return $Context

    }
}

class DRMMAlertStatusContext : DRMMAlertContext {

    [string]$ProcessName
    [string]$Status

    DRMMAlertStatusContext() : base() {

    }

    static [DRMMAlertStatusContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertStatusContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.ProcessName = [DRMMObject]::GetValue($Response, 'processName')
        $Context.Status = [DRMMObject]::GetValue($Response, 'status')

        return $Context

    }
}

class DRMMAlertTemperatureContext : DRMMAlertContext {

    [float]$Degree
    [string]$Type

    DRMMAlertTemperatureContext() : base() {

    }

    static [DRMMAlertTemperatureContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertTemperatureContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Degree = [DRMMObject]::GetValue($Response, 'degree')
        $Context.Type = [DRMMObject]::GetValue($Response, 'type')

        return $Context

    }
}

class DRMMAlertWindowsPerformanceContext : DRMMAlertContext {

    [float]$Value

    DRMMAlertWindowsPerformanceContext() : base() {

    }

    static [DRMMAlertWindowsPerformanceContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertWindowsPerformanceContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Value = [DRMMObject]::GetValue($Response, 'value')

        return $Context

    }
}

class DRMMAlertWmiContext : DRMMAlertContext {

    [string]$Value

    DRMMAlertWmiContext() : base() {

    }

    static [DRMMAlertWmiContext] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertWmiContext]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Value = [DRMMObject]::GetValue($Response, 'value')

        return $Context

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
        $NetMapping.PortalUrl = $Response.portalUrl
        
        if ($Response.dattoNetworkingNetworkIds) {

            $NetMapping.DatatoNetworkingNetworkIds = $Response.dattoNetworkingNetworkIds

        }

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
class DRMMJobComponentVariable : DRMMObject {

    [string]$Name
    [string]$Value

    DRMMJobComponentVariable() : base() {

    }

    static [DRMMJobComponentVariable] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Variable = [DRMMJobComponentVariable]::new()
        $Variable.Name = [DRMMObject]::GetValue($Response, 'name')
        $Variable.Value = [DRMMObject]::GetValue($Response, 'value')

        return $Variable

    }
}

class DRMMJobComponent : DRMMObject {

    [guid]$Uid
    [string]$Name
    [DRMMJobComponentVariable[]]$Variables

    DRMMJobComponent() : base() {

    }

    static [DRMMJobComponent] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Component = [DRMMJobComponent]::new()
        $Component.Uid = [DRMMObject]::GetValue($Response, 'uid')
        $Component.Name = [DRMMObject]::GetValue($Response, 'name')
        
        if ($Response.variables) {

            $Component.Variables = $Response.variables | ForEach-Object {

                [DRMMJobComponentVariable]::FromAPIMethod($_)

            }
        }

        return $Component

    }
}

class DRMMJobComponentResult : DRMMObject {

    [guid]$ComponentUid
    [string]$ComponentName
    [string]$ComponentStatus
    [int]$NumberOfWarnings
    [bool]$HasStdOut
    [bool]$HasStdErr

    DRMMJobComponentResult() : base() {

    }

    static [DRMMJobComponentResult] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Result = [DRMMJobComponentResult]::new()
        $Result.ComponentUid = [DRMMObject]::GetValue($Response, 'componentUid')
        $Result.ComponentName = [DRMMObject]::GetValue($Response, 'componentName')
        $Result.ComponentStatus = [DRMMObject]::GetValue($Response, 'componentStatus')
        $Result.NumberOfWarnings = [DRMMObject]::GetValue($Response, 'numberOfWarnings')
        $Result.HasStdOut = [DRMMObject]::GetValue($Response, 'hasStdOut')
        $Result.HasStdErr = [DRMMObject]::GetValue($Response, 'hasStdErr')

        return $Result

    }
}

class DRMMJobResults : DRMMObject {

    [guid]$JobUid
    [guid]$DeviceUid
    [Nullable[datetime]]$RanOn
    [string]$JobDeploymentStatus
    [DRMMJobComponentResult[]]$ComponentResults

    DRMMJobResults() : base() {

    }

    static [DRMMJobResults] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Results = [DRMMJobResults]::new()
        $Results.JobUid = [DRMMObject]::GetValue($Response, 'jobUid')
        $Results.DeviceUid = [DRMMObject]::GetValue($Response, 'deviceUid')
        $Results.JobDeploymentStatus = [DRMMObject]::GetValue($Response, 'jobDeploymentStatus')

        $RanOnValue = [DRMMObject]::GetValue($Response, 'ranOn')
        if ($null -ne $RanOnValue) {

            try {

                $Results.RanOn = [datetime]::Parse($RanOnValue)

            } catch {

                $Results.RanOn = $null

            }
        }

        if ($Response.componentResults) {

            $Results.ComponentResults = $Response.componentResults | ForEach-Object {

                [DRMMJobComponentResult]::FromAPIMethod($_)

            }

        }

        return $Results

    }
}

class DRMMJobStdData : DRMMObject {

    [guid]$ComponentUid
    [string]$ComponentName
    [string]$StdData

    DRMMJobStdData() : base() {

    }

    static [DRMMJobStdData] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Result = [DRMMJobStdData]::new()
        $Result.ComponentUid = [DRMMObject]::GetValue($Response, 'componentUid')
        $Result.ComponentName = [DRMMObject]::GetValue($Response, 'componentName')
        $Result.StdData = [DRMMObject]::GetValue($Response, 'stdData')

        return $Result

    }
}

class DRMMJob : DRMMObject {

    [long]$Id
    [guid]$Uid
    [string]$Name
    [Nullable[datetime]]$DateCreated
    [string]$Status

    DRMMJob() : base() {

    }

    static [DRMMJob] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Job = [DRMMJob]::new()
        $Job.Id = [DRMMObject]::GetValue($Response, 'id')
        $Job.Uid = [DRMMObject]::GetValue($Response, 'uid')
        $Job.Name = [DRMMObject]::GetValue($Response, 'name')
        $Job.Status = [DRMMObject]::GetValue($Response, 'status')

        $DateCreatedValue = [DRMMObject]::GetValue($Response, 'dateCreated')

        if ($null -ne $DateCreatedValue) {

            try {

                $Job.DateCreated = [datetime]::Parse($DateCreatedValue)

            } catch {

                $Job.DateCreated = $null

            }
        }

        return $Job

    }
}

class DRMMSoftware : DRMMObject {

    [string]$Name
    [string]$Version

    DRMMSoftware() : base() {

    }

    static [DRMMSoftware] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Software = [DRMMSoftware]::new()
        $Software.Name = [DRMMObject]::GetValue($Response, 'name')
        $Software.Version = [DRMMObject]::GetValue($Response, 'version')

        return $Software

    }
}

class DRMMSystemInfo : DRMMObject {

    [string]$Manufacturer
    [string]$Model
    [long]$TotalPhysicalMemory
    [string]$Username
    [string]$DotNetVersion
    [int]$TotalCpuCores

    DRMMSystemInfo() : base() {

    }

    static [DRMMSystemInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $SystemInfo = [DRMMSystemInfo]::new()
        $SystemInfo.Manufacturer = [DRMMObject]::GetValue($Response, 'manufacturer')
        $SystemInfo.Model = [DRMMObject]::GetValue($Response, 'model')
        $SystemInfo.TotalPhysicalMemory = [DRMMObject]::GetValue($Response, 'totalPhysicalMemory')
        $SystemInfo.Username = [DRMMObject]::GetValue($Response, 'username')
        $SystemInfo.DotNetVersion = [DRMMObject]::GetValue($Response, 'dotNetVersion')
        $SystemInfo.TotalCpuCores = [DRMMObject]::GetValue($Response, 'totalCpuCores')

        return $SystemInfo

    }
}

class DRMMBios : DRMMObject {

    [string]$Manufacturer
    [string]$Name
    [string]$SerialNumber
    [string]$SmbiosBiosVersion

    DRMMBios() : base() {

    }

    static [DRMMBios] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Bios = [DRMMBios]::new()
        $Bios.Manufacturer = [DRMMObject]::GetValue($Response, 'manufacturer')
        $Bios.Name = [DRMMObject]::GetValue($Response, 'name')
        $Bios.SerialNumber = [DRMMObject]::GetValue($Response, 'serialNumber')
        $Bios.SmbiosBiosVersion = [DRMMObject]::GetValue($Response, 'smbiosBiosVersion')

        return $Bios

    }
}

class DRMMBaseBoard : DRMMObject {

    [string]$Manufacturer
    [string]$Product
    [string]$SerialNumber

    DRMMBaseBoard() : base() {

    }

    static [DRMMBaseBoard] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $BaseBoard = [DRMMBaseBoard]::new()
        $BaseBoard.Manufacturer = [DRMMObject]::GetValue($Response, 'manufacturer')
        $BaseBoard.Product = [DRMMObject]::GetValue($Response, 'product')
        $BaseBoard.SerialNumber = [DRMMObject]::GetValue($Response, 'serialNumber')

        return $BaseBoard

    }
}

class DRMMDisplay : DRMMObject {

    [string]$Instance
    [int]$ScreenHeight
    [int]$ScreenWidth

    DRMMDisplay() : base() {

    }

    static [DRMMDisplay] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Display = [DRMMDisplay]::new()
        $Display.Instance = [DRMMObject]::GetValue($Response, 'instance')
        $Display.ScreenHeight = [DRMMObject]::GetValue($Response, 'screenHeight')
        $Display.ScreenWidth = [DRMMObject]::GetValue($Response, 'screenWidth')

        return $Display

    }
}

class DRMMLogicalDisk : DRMMObject {

    [string]$Description
    [string]$DiskIdentifier
    [long]$Freespace
    [long]$Size

    DRMMLogicalDisk() : base() {

    }

    static [DRMMLogicalDisk] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Disk = [DRMMLogicalDisk]::new()
        $Disk.Description = [DRMMObject]::GetValue($Response, 'description')
        $Disk.DiskIdentifier = [DRMMObject]::GetValue($Response, 'diskIdentifier')
        $Disk.Freespace = [DRMMObject]::GetValue($Response, 'freespace')
        $Disk.Size = [DRMMObject]::GetValue($Response, 'size')

        return $Disk

    }
}

class DRMMMobileInfo : DRMMObject {

    [string]$Iccid
    [string]$Imei
    [string]$Number
    [string]$Operator

    DRMMMobileInfo() : base() {

    }

    static [DRMMMobileInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Mobile = [DRMMMobileInfo]::new()
        $Mobile.Iccid = [DRMMObject]::GetValue($Response, 'iccid')
        $Mobile.Imei = [DRMMObject]::GetValue($Response, 'imei')
        $Mobile.Number = [DRMMObject]::GetValue($Response, 'number')
        $Mobile.Operator = [DRMMObject]::GetValue($Response, 'operator')

        return $Mobile

    }
}

class DRMMProcessor : DRMMObject {

    [string]$Name

    DRMMProcessor() : base() {

    }

    static [DRMMProcessor] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Processor = [DRMMProcessor]::new()
        $Processor.Name = [DRMMObject]::GetValue($Response, 'name')

        return $Processor

    }
}

class DRMMVideoBoard : DRMMObject {

    [string]$DisplayAdapter

    DRMMVideoBoard() : base() {

    }

    static [DRMMVideoBoard] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $VideoBoard = [DRMMVideoBoard]::new()
        $VideoBoard.DisplayAdapter = [DRMMObject]::GetValue($Response, 'displayAdapter')

        return $VideoBoard

    }
}

class DRMMAttachedDevice : DRMMObject {

    [string]$Description
    [string]$Instance

    DRMMAttachedDevice() : base() {

    }

    static [DRMMAttachedDevice] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Device = [DRMMAttachedDevice]::new()
        $Device.Description = [DRMMObject]::GetValue($Response, 'description')
        $Device.Instance = [DRMMObject]::GetValue($Response, 'instance')

        return $Device

    }
}

class DRMMSnmpInfo : DRMMObject {

    [string]$Contact
    [string]$Description
    [string]$Location
    [string]$Name

    DRMMSnmpInfo() : base() {

    }

    static [DRMMSnmpInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Snmp = [DRMMSnmpInfo]::new()
        $Snmp.Contact = [DRMMObject]::GetValue($Response, 'contact')
        $Snmp.Description = [DRMMObject]::GetValue($Response, 'description')
        $Snmp.Location = [DRMMObject]::GetValue($Response, 'location')
        $Snmp.Name = [DRMMObject]::GetValue($Response, 'name')

        return $Snmp

    }
}

class DRMMPhysicalMemory : DRMMObject {

    [string]$BankLabel
    [long]$Capacity
    [string]$Manufacturer
    [string]$PartNumber
    [string]$SerialNumber
    [int]$Speed

    DRMMPhysicalMemory() : base() {

    }

    static [DRMMPhysicalMemory] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Memory = [DRMMPhysicalMemory]::new()
        $Memory.BankLabel = [DRMMObject]::GetValue($Response, 'bankLabel')
        $Memory.Capacity = [DRMMObject]::GetValue($Response, 'capacity')
        $Memory.Manufacturer = [DRMMObject]::GetValue($Response, 'manufacturer')
        $Memory.PartNumber = [DRMMObject]::GetValue($Response, 'partNumber')
        $Memory.SerialNumber = [DRMMObject]::GetValue($Response, 'serialNumber')
        $Memory.Speed = [DRMMObject]::GetValue($Response, 'speed')

        return $Memory

    }
}

class DRMMDeviceAudit : DRMMObject {

    [guid]$DeviceUid
    [string]$PortalUrl
    [string]$WebRemoteUrl
    [DRMMSystemInfo]$SystemInfo
    [DRMMNetworkInterface[]]$Nics
    [DRMMBios]$Bios
    [DRMMBaseBoard]$BaseBoard
    [DRMMDisplay[]]$Displays
    [DRMMLogicalDisk[]]$LogicalDisks
    [DRMMMobileInfo[]]$MobileInfo
    [DRMMProcessor[]]$Processors
    [DRMMVideoBoard[]]$VideoBoards
    [DRMMAttachedDevice[]]$AttachedDevices
    [DRMMSnmpInfo]$SnmpInfo
    [DRMMPhysicalMemory[]]$PhysicalMemory
    [DRMMSoftware[]]$Software

    DRMMDeviceAudit() : base() {

    }

    static [DRMMDeviceAudit] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Audit = [DRMMDeviceAudit]::new()
        $Audit.PortalUrl = [DRMMObject]::GetValue($Response, 'portalUrl')
        $Audit.WebRemoteUrl = [DRMMObject]::GetValue($Response, 'webRemoteUrl')
        
        # System info
        $SystemInfoData = [DRMMObject]::GetValue($Response, 'systemInfo')
        if ($null -ne $SystemInfoData) {

            $Audit.SystemInfo = [DRMMSystemInfo]::FromAPIMethod($SystemInfoData)

        }

        # BIOS
        $BiosData = [DRMMObject]::GetValue($Response, 'bios')
        if ($null -ne $BiosData) {

            $Audit.Bios = [DRMMBios]::FromAPIMethod($BiosData)

        }

        # Base board
        $BaseBoardData = [DRMMObject]::GetValue($Response, 'baseBoard')
        if ($null -ne $BaseBoardData) {

            $Audit.BaseBoard = [DRMMBaseBoard]::FromAPIMethod($BaseBoardData)

        }

        # SNMP info
        $SnmpData = [DRMMObject]::GetValue($Response, 'snmpInfo')
        if ($null -ne $SnmpData) {

            $Audit.SnmpInfo = [DRMMSnmpInfo]::FromAPIMethod($SnmpData)

        }

        # Network interfaces
        $NicsData = [DRMMObject]::GetValue($Response, 'nics')
        if ($null -ne $NicsData -and $NicsData.Count -gt 0) {

            $Audit.Nics = @($NicsData | ForEach-Object { [DRMMNetworkInterface]::FromAPIMethod($_) })

        }

        # Displays
        $DisplaysData = [DRMMObject]::GetValue($Response, 'displays')
        if ($null -ne $DisplaysData -and $DisplaysData.Count -gt 0) {

            $Audit.Displays = @($DisplaysData | ForEach-Object { [DRMMDisplay]::FromAPIMethod($_) })

        }

        # Logical disks
        $DisksData = [DRMMObject]::GetValue($Response, 'logicalDisks')
        if ($null -ne $DisksData -and $DisksData.Count -gt 0) {

            $Audit.LogicalDisks = @($DisksData | ForEach-Object { [DRMMLogicalDisk]::FromAPIMethod($_) })

        }

        # Mobile info
        $MobileData = [DRMMObject]::GetValue($Response, 'mobileInfo')
        if ($null -ne $MobileData -and $MobileData.Count -gt 0) {

            $Audit.MobileInfo = @($MobileData | ForEach-Object { [DRMMMobileInfo]::FromAPIMethod($_) })

        }

        # Processors
        $ProcessorsData = [DRMMObject]::GetValue($Response, 'processors')
        if ($null -ne $ProcessorsData -and $ProcessorsData.Count -gt 0) {

            $Audit.Processors = @($ProcessorsData | ForEach-Object { [DRMMProcessor]::FromAPIMethod($_) })

        }

        # Video boards
        $VideoData = [DRMMObject]::GetValue($Response, 'videoBoards')
        if ($null -ne $VideoData -and $VideoData.Count -gt 0) {

            $Audit.VideoBoards = @($VideoData | ForEach-Object { [DRMMVideoBoard]::FromAPIMethod($_) })

        }

        # Attached devices
        $AttachedData = [DRMMObject]::GetValue($Response, 'attachedDevices')
        if ($null -ne $AttachedData -and $AttachedData.Count -gt 0) {

            $Audit.AttachedDevices = @($AttachedData | ForEach-Object { [DRMMAttachedDevice]::FromAPIMethod($_) })

        }

        # Physical memory
        $MemoryData = [DRMMObject]::GetValue($Response, 'physicalMemory')
        if ($null -ne $MemoryData -and $MemoryData.Count -gt 0) {

            $Audit.PhysicalMemory = @($MemoryData | ForEach-Object { [DRMMPhysicalMemory]::FromAPIMethod($_) })

        }

        return $Audit

    }
}