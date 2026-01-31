<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '.\DRMMObject.psm1'
using module '.\DRMMVariable.psm1'
using module '.\DRMMFilter.psm1'
using module '.\DRMMAlert.psm1'
using module '.\DRMMDevice.psm1'

class DRMMSite : DRMMObject {

    [long]$Id
    [string]$Uid
    [string]$AccountUid
    [string]$Name
    [string]$Description
    [string]$Notes
    [bool]$OnDemand
    [bool]$SplashtopAutoInstall
    [DRMMSiteProxySettings]$ProxySettings
    [DRMMDevicesStatus]$DevicesStatus
    [DRMMSiteSettings]$SiteSettings
    [DRMMVariable[]]$Variables
    [DRMMFilter[]]$Filters
    [string]$AutotaskCompanyName
    [string]$AutotaskCompanyId
    [string]$PortalUrl

    DRMMSite() : base() {

    }

    static [DRMMSite] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

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

            $Site.ProxySettings = [DRMMSiteProxySettings]::FromAPIMethod($ProxySettingsResponse)

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

    [DRMMSite] Set([hashtable]$Properties) {

        $params = @{
            Site = $this
            Force = $true
        }

        foreach ($key in $Properties.Keys) {

            $params[$key] = $Properties[$key]

        }

        return Set-RMMSite @params

    }

    [DRMMAlert[]] GetAlerts() {

        $Result = Get-RMMAlert -SiteUid $this.Uid -Status 'All'

        if ($null -eq $Result) {

            return @()

        }

        return $Result

    }

    [DRMMAlert[]] GetAlerts([string]$Status) {

        $Result = Get-RMMAlert -SiteUid $this.Uid -Status $Status

        if ($null -eq $Result) {

            return @()

        }

        return $Result

    }

    [void] OpenPortal() {

        if ($this.PortalUrl) {

            Start-Process $this.PortalUrl

        } else {

            Write-Warning "Portal URL is not available for site $($this.Name)"

        }
    }

    # Device Management Methods
    [DRMMDevice[]] GetDevices() {

        $Result = Get-RMMDevice -SiteUid $this.Uid

        if ($null -eq $Result) {

            return @()

        }

        return $Result

    }

    [DRMMDevice[]] GetDevices([long]$FilterId) {

        $Result = Get-RMMDevice -SiteUid $this.Uid -FilterId $FilterId

        if ($null -eq $Result) {

            return @()

        }

        return $Result

    }

    [int] GetDeviceCount() {

        if ($this.DevicesStatus -and $null -ne $this.DevicesStatus.NumberOfDevices) {

            return $this.DevicesStatus.NumberOfDevices

        }

        return 0

    }

    # Variable Management Methods
    [DRMMVariable[]] GetVariables() {

        $Result = Get-RMMVariable -SiteUid $this.Uid

        if ($null -eq $Result) {

            return @()

        }

        return $Result

    }

    [DRMMVariable] GetVariable([string]$Name) {

        $Result = Get-RMMVariable -SiteUid $this.Uid -Name $Name

        if ($null -eq $Result) {

            return $null

        }

        return $Result

    }

    [DRMMVariable] NewVariable([string]$Name, [string]$Value) {

        return New-RMMVariable -SiteUid $this.Uid -Name $Name -Value $Value -Force

    }

    [DRMMVariable] NewVariable([string]$Name, [string]$Value, [bool]$Masked) {

        return New-RMMVariable -SiteUid $this.Uid -Name $Name -Value $Value -Masked:$Masked -Force

    }

    # Filter Management Methods
    [DRMMFilter[]] GetFilters() {

        $Result = Get-RMMFilter -SiteUid $this.Uid

        if ($null -eq $Result) {

            return @()

        }

        return $Result

    }

    [DRMMFilter] GetFilter([string]$Name) {

        $Result = Get-RMMFilter -SiteUid $this.Uid -Name $Name

        if ($null -eq $Result) {

            return $null

        }

        return $Result

    }

    [DRMMSiteSettings] GetSettings() {

        return Get-RMMSiteSettings -SiteUid $this.Uid

    }

    [DRMMSiteSettings] SetProxy([string]$ProxyHost, [int]$Port, [string]$Type) {

        return Set-RMMSiteProxy -SiteUid $this.Uid -Host $ProxyHost -Port $Port -Type $Type -Force

    }

    [DRMMSiteSettings] SetProxy([string]$ProxyHost, [int]$Port, [string]$Type, [string]$Username, [SecureString]$Password) {

        return Set-RMMSiteProxy -SiteUid $this.Uid -Host $ProxyHost -Port $Port -Type $Type -Username $Username -Password $Password -Force

    }

    [DRMMSiteSettings] RemoveProxy() {

        return Remove-RMMSiteProxy -SiteUid $this.Uid -Force

    }
}

class DRMMSiteGeneralSettings : DRMMObject {

    [string]$Name
    [string]$Uid
    [string]$Description
    [bool]$OnDemand

    DRMMSiteGeneralSettings() : base() {}

    static [DRMMSiteGeneralSettings] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Settings = [DRMMSiteGeneralSettings]::new()
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

class DRMMSiteMailRecipient : DRMMObject {

    [string]$Name
    [string]$Email
    [string]$Type

    DRMMSiteMailRecipient() : base() {}

    static [DRMMSiteMailRecipient] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Recipient = [DRMMSiteMailRecipient]::new()
        $Recipient.Name = $Response.name
        $Recipient.Email = $Response.email
        $Recipient.Type = $Response.type

        return $Recipient

    }
}

class DRMMSiteProxySettings : DRMMObject {

    [string]$Host
    [string]$Username
    [securestring]$Password
    [int]$Port
    [string]$Type

    DRMMSiteProxySettings() : base() {

    }

    static [DRMMSiteProxySettings] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

            $ProxySettings = [DRMMSiteProxySettings]::new()
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

class DRMMSiteSettings : DRMMObject {

    [DRMMSiteGeneralSettings]$GeneralSettings
    [DRMMSiteProxySettings]$ProxySettings  # Reuse existing class
    [DRMMSiteMailRecipient[]]$MailRecipients
    [guid]$SiteUid

    DRMMSiteSettings() : base() {

    }

    static [DRMMSiteSettings] FromAPIMethod([pscustomobject]$Response, $SiteUid) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Settings = [DRMMSiteSettings]::new()

        if ($Response.generalSettings) {

            $Settings.GeneralSettings = [DRMMSiteGeneralSettings]::FromAPIMethod($Response.generalSettings)

        } else {

            $Settings.GeneralSettings = $null

        }

        if ($Response.proxySettings) {

            $Settings.ProxySettings = [DRMMSiteProxySettings]::FromAPIMethod($Response.proxySettings)
            
        } else {

            $Settings.ProxySettings = $null

        }

        $Settings.MailRecipients = $Response.mailRecipients | ForEach-Object {[DRMMSiteMailRecipient]::FromAPIMethod($_)}
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

class DRMMDevicesStatus : DRMMObject {

    [long]$NumberOfDevices
    [long]$NumberOfOnlineDevices
    [long]$NumberOfOfflineDevices

    DRMMDevicesStatus() : base() {

    }

    static [DRMMDevicesStatus] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

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
