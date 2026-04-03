<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '..\DRMMAlert\DRMMAlert.psm1'
using module '..\DRMMDevice\DRMMDevice.psm1'
using module '..\DRMMFilter\DRMMFilter.psm1'
using module '..\DRMMObject\DRMMObject.psm1'
using module '..\DRMMVariable\DRMMVariable.psm1'
<#
.SYNOPSIS
    Represents a site in the DRMM system, including its properties, settings, and associated devices and variables.
.DESCRIPTION
    The DRMMSite class models a site within the DRMM platform, encapsulating properties such as Id, Uid, AccountUid, Name, Description, Notes, OnDemand status, SplashtopAutoInstall setting, ProxySettings, DevicesStatus, SiteSettings, Variables, Filters, AutotaskCompanyName, AutotaskCompanyId, and PortalUrl. It provides a constructor and a static method to create an instance from API response data. The class also includes methods to generate a summary string of the site's information, update site properties, retrieve associated alerts and devices, and open the site's portal URL in a web browser.
#>
class DRMMSite : DRMMObject {

    # The unique identifier of the site.
    [long]$Id
    # The unique identifier (UID) of the site.
    [guid]$Uid
    # The unique identifier (UID) of the account associated with the site.
    [string]$AccountUid
    # The name of the site.
    [string]$Name
    # The description of the site.
    [string]$Description
    # Additional notes about the site.
    [string]$Notes
    # Indicates whether the site is on-demand.
    [bool]$OnDemand
    # Indicates whether Splashtop auto-install is enabled for the site.
    [bool]$SplashtopAutoInstall
    # The proxy settings for the site.
    [DRMMSiteProxySettings]$ProxySettings
    # The status of the devices associated with the site.
    [DRMMDevicesStatus]$DevicesStatus
    # The settings for the site.
    [DRMMSiteSettings]$SiteSettings
    # The variables associated with the site.
    [DRMMVariable[]]$Variables
    # The filters associated with the site.
    [DRMMFilter[]]$Filters
    # The name of the Autotask company associated with the site.
    [string]$AutotaskCompanyName
    # The identifier of the Autotask company associated with the site.
    [string]$AutotaskCompanyId
    # The URL of the site portal.
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

    <#
    .SYNOPSIS
        Generates a summary string for the site, including its name, unique identifier, and device count.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the site's name, unique identifier (UID), and the count of devices associated with the site. If the device count information is not available, it defaults to '0'.
    .OUTPUTS
        A summary string that includes the name, unique identifier, and device count for the site.
    #>
    [string] GetSummary() {

        $DeviceCount = if ($this.DevicesStatus -and $null -ne $this.DevicesStatus.NumberOfDevices) {"$($this.DevicesStatus.NumberOfDevices)"} else {'0'}

        return "$($this.Name) ($($this.Uid)) - Devices: $DeviceCount"

    }

    <#
    .SYNOPSIS
        Updates the properties of the site based on the provided hashtable of property names and values.
    .DESCRIPTION
        The Set method takes a hashtable of property names and values, constructs a parameter set for the Set-RMMSite cmdlet, and updates the site's properties accordingly. The -Force parameter is included to bypass confirmation prompts during the update process. The method returns the updated site object after the changes have been applied.
    .OUTPUTS
        This method does not return a value. It performs an action to update the properties of the site based on the provided hashtable of property names and values.
    #>
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

    <#
    .SYNOPSIS
        Retrieves alerts associated with the site, optionally filtered by status.
    .DESCRIPTION
        The GetAlerts method fetches alerts for the site using the Get-RMMAlert cmdlet. If no status is specified, it retrieves all alerts. If a status is provided, it filters alerts based on the given status. The method returns an array of DRMMAlert objects or an empty array if no alerts are found.
    .OUTPUTS
        A collection of alerts associated with the site, optionally filtered by the specified status.
    #>
    [DRMMAlert[]] GetAlerts() {

        $Result = Get-RMMAlert -SiteUid $this.Uid -Status 'All'

        if ($null -eq $Result) {

            return @()

        }

        return $Result

    }

    <#
    .SYNOPSIS
        Retrieves alerts associated with the site, optionally filtered by status.
    .DESCRIPTION
        The GetAlerts method fetches alerts for the site using the Get-RMMAlert cmdlet. If no status is specified, it retrieves all alerts. If a status is provided, it filters alerts based on the given status. The method returns an array of DRMMAlert objects or an empty array if no alerts are found.
    #>
    [DRMMAlert[]] GetAlerts([string]$Status) {

        $Result = Get-RMMAlert -SiteUid $this.Uid -Status $Status

        if ($null -eq $Result) {

            return @()

        }

        return $Result

    }

    <#
    .SYNOPSIS
        Opens the portal URL associated with the site in the default web browser.
    .DESCRIPTION
        The OpenPortal method checks if the PortalUrl property is set for the site. If it is available, it launches the URL in the default web browser using the Start-Process cmdlet. If the PortalUrl is not set, it issues a warning indicating that the portal URL is not available for the site.
    .OUTPUTS
        This method does not return a value. It performs an action to open the portal URL in the default web browser.
    #>
    [void] OpenPortal() {

        if ($this.PortalUrl) {

            Start-Process $this.PortalUrl

        } else {

            Write-Warning "Portal URL is not available for site $($this.Name)"

        }
    }

    <#
    .SYNOPSIS
        Retrieves devices associated with the site, optionally filtered by a specific filter ID.
    .DESCRIPTION
        The GetDevices method fetches devices for the site using the Get-RMMDevice cmdlet.
    .OUTPUTS
        A collection of devices associated with the site, optionally filtered by the specified filter ID.
    #>
    [DRMMDevice[]] GetDevices() {

        $Result = Get-RMMDevice -SiteUid $this.Uid

        if ($null -eq $Result) {

            return @()

        }

        return $Result

    }

    <#
    .SYNOPSIS
        Retrieves devices associated with the site, optionally filtered by a specific filter ID.
    .DESCRIPTION
        The GetDevices method fetches devices for the site using the Get-RMMDevice cmdlet. Retrieves devices that match the specified filter criteria. The method returns an array of DRMMDevice objects or an empty array if no devices are found.
    #>
    [DRMMDevice[]] GetDevices([long]$FilterId) {

        $Result = Get-RMMDevice -SiteUid $this.Uid -FilterId $FilterId

        if ($null -eq $Result) {

            return @()

        }

        return $Result

    }

    <#
    .SYNOPSIS
        Retrieves the count of devices associated with the site.
    .DESCRIPTION
        The GetDeviceCount method returns the number of devices associated with the site. It checks the DevicesStatus property and returns the NumberOfDevices if available; otherwise, it returns 0.
    .OUTPUTS
        The count of devices associated with the site.
    #>
    [int] GetDeviceCount() {

        if ($this.DevicesStatus -and $null -ne $this.DevicesStatus.NumberOfDevices) {

            return $this.DevicesStatus.NumberOfDevices

        }

        return 0

    }

    <#
    .SYNOPSIS
        Retrieves variables associated with the site.
    .DESCRIPTION
        The GetVariables method fetches variables for the site using the Get-RMMVariable cmdlet. The method returns an array of DRMMVariable objects or an empty array if no variables are found.
    .OUTPUTS
        A collection of variables associated with the site.
    #>
    [DRMMVariable[]] GetVariables() {

        $Result = Get-RMMVariable -SiteUid $this.Uid

        if ($null -eq $Result) {

            return @()

        }

        return $Result

    }

    <#
    .SYNOPSIS
        Retrieves a specific variable associated with the site by name.
    .DESCRIPTION
        The GetVariable method takes a variable name as input and fetches the corresponding variable for the site using the Get-RMMVariable cmdlet. If the variable is found, it returns a DRMMVariable object; otherwise, it returns null.
    .OUTPUTS
        The variable associated with the site that matches the specified name, or null if no matching variable is found.
    #>
    [DRMMVariable] GetVariable([string]$Name) {

        $Result = Get-RMMVariable -SiteUid $this.Uid -Name $Name

        if ($null -eq $Result) {

            return $null

        }

        return $Result

    }

    <#
    .SYNOPSIS
        Creates a new variable associated with the site.
    .DESCRIPTION
        The NewVariable method creates a new variable for the site using the New-RMMVariable cmdlet. It takes the variable name and value as parameters and returns a DRMMVariable object representing the newly created variable.
    .OUTPUTS
        The newly created variable associated with the site.
    #>
    [DRMMVariable] NewVariable([string]$Name, [string]$Value) {

        return New-RMMVariable -SiteUid $this.Uid -Name $Name -Value $Value -Force

    }

    <#
    .SYNOPSIS
        Creates a new variable associated with the site, with an option to mask the value.
    .DESCRIPTION
        The NewVariable method creates a new variable for the site using the New-RMMVariable cmdlet. It takes the variable name, value, and a boolean parameter to indicate whether the value should be masked (secret). The method returns a DRMMVariable object representing the newly created variable.
    #>
    [DRMMVariable] NewVariable([string]$Name, [string]$Value, [bool]$Masked) {

        return New-RMMVariable -SiteUid $this.Uid -Name $Name -Value $Value -Masked:$Masked -Force

    }

    <#
    .SYNOPSIS
        Retrieves filters associated with the site.
    .DESCRIPTION
        The GetFilters method fetches filters for the site using the Get-RMMFilter cmdlet. The method returns an array of DRMMFilter objects or an empty array if no filters are found.
    .OUTPUTS
        A collection of filters associated with the site.
    #>
    [DRMMFilter[]] GetFilters() {

        $Result = Get-RMMFilter -Site $this

        if ($null -eq $Result) {

            return @()

        }

        return $Result

    }

    <#
    .SYNOPSIS
        Retrieves a specific filter associated with the site by name.
    .DESCRIPTION
        The GetFilter method takes a filter name as input and fetches the corresponding filter for the site using the Get-RMMFilter cmdlet. If the filter is found, it returns a DRMMFilter object; otherwise, it returns null.
    .OUTPUTS
        The filter associated with the site that matches the specified name, or null if no matching filter is found.
    #>
    [DRMMFilter] GetFilter([string]$Name) {

        $Result = Get-RMMFilter -Site $this -Name $Name

        if ($null -eq $Result) {

            return $null

        }

        return $Result

    }

    <#
    .SYNOPSIS
        Retrieves the site settings for the site.
    .DESCRIPTION
        The GetSettings method fetches the site settings for the site using the Get-RMMSiteSettings cmdlet. The method returns a DRMMSiteSettings object representing the site's settings.
    .OUTPUTS
        The site settings associated with the site.
    #>
    [DRMMSiteSettings] GetSettings() {

        return Get-RMMSiteSettings -SiteUid $this.Uid

    }

    <#
    .SYNOPSIS
        Sets the proxy settings for the site.
    .DESCRIPTION
        The SetProxy method configures the proxy settings for the site using the Set-RMMSiteProxy cmdlet. It takes the proxy host, port, and type as parameters and returns a DRMMSiteSettings object representing the updated site settings.
    .OUTPUTS
        This method does not return a value. It performs an action to set the proxy settings for the site, including authentication credentials.
    #>
    [DRMMSiteSettings] SetProxy([string]$ProxyHost, [int]$Port, [string]$Type) {

        return Set-RMMSiteProxy -SiteUid $this.Uid -Host $ProxyHost -Port $Port -Type $Type -Force

    }

    <#
    .SYNOPSIS
        Sets the proxy settings for the site, including authentication credentials.
    .DESCRIPTION
        The SetProxy method configures the proxy settings for the site using the Set-RMMSiteProxy cmdlet. It takes the proxy host, port, type, username, and password as parameters and returns a DRMMSiteSettings object representing the updated site settings with proxy authentication.
    #>
    [DRMMSiteSettings] SetProxy([string]$ProxyHost, [int]$Port, [string]$Type, [string]$Username, [SecureString]$Password) {

        return Set-RMMSiteProxy -SiteUid $this.Uid -Host $ProxyHost -Port $Port -Type $Type -Username $Username -Password $Password -Force

    }

    <#
    .SYNOPSIS
        Removes the proxy settings for the site.
    .DESCRIPTION
        The RemoveProxy method deletes the proxy settings for the site using the Remove-RMMSiteProxy cmdlet. It returns a DRMMSiteSettings object representing the updated site settings with the proxy configuration removed.
    .OUTPUTS
        This method does not return a value. It performs an action to remove the proxy settings for the site.
    #>
    [DRMMSiteSettings] RemoveProxy() {

        return Remove-RMMSiteProxy -SiteUid $this.Uid -Force

    }
}

<#
.SYNOPSIS
    Represents the general settings for a site in the DRMM system, including properties such as name, unique identifier, description, and on-demand status.
.DESCRIPTION
    The DRMMSiteGeneralSettings class models the general settings for a site within the DRMM platform. It includes properties such as Name, Uid, Description, and OnDemand status. The class provides a constructor and a static method to create an instance from API response data. Additionally, it includes a method to generate a summary string of the general settings information.
#>
class DRMMSiteGeneralSettings : DRMMObject {

    # The name of the site's general settings.
    [string]$Name
    # The unique identifier (UID) of the site's general settings.
    [string]$Uid
    # The description of the site's general settings.
    [string]$Description
    # Indicates whether the site is on-demand.
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

    <#
    .SYNOPSIS
        Generates a summary string for the general settings, including the on-demand status.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the general settings of the site, specifically indicating whether the site is configured for on-demand access. The summary includes the OnDemand property value.
    .OUTPUTS
        A summary string that includes the on-demand status of the site's general settings.
    #>
    [string] GetSummary() {

        return "OnDemand: $($this.OnDemand)"

    }
}

<#
.SYNOPSIS
    Represents a mail recipient for site notifications in the DRMM system, including properties such as name, email, and type.
.DESCRIPTION
    The DRMMSiteMailRecipient class models a mail recipient for site notifications within the DRMM platform. It includes properties such as Name, Email, and Type. The class provides a constructor and a static method to create an instance from API response data. Additionally, it includes a method to generate a summary string of the mail recipient's information.
#>
class DRMMSiteMailRecipient : DRMMObject {

    # The name of the mail recipient.
    [string]$Name
    # The email address of the mail recipient.
    [string]$Email
    # The type of the mail recipient (e.g., "To", "Cc", "Bcc").
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

<#
.SYNOPSIS
    Represents a deleted site in the DRMM system, with properties similar to DRMMSite but with a string type for Uid to handle invalid GUIDs.
.DESCRIPTION
    The DRMMDeletedDevicesSite class models a deleted site within the DRMM platform. It includes properties similar to the DRMMSite class, but the Uid property is defined as a string to accommodate cases where the GUID may be invalid or not properly formatted. The class provides a constructor and a static method to create an instance from API response data, allowing for the handling of deleted site information without strict GUID validation.
#>
class DRMMDeletedDevicesSite : DRMMSite {
    
    # Shadow the base Uid property with string type to handle invalid GUIDs
    # Shadow the base Uid property with string type to handle invalid GUIDs
    [string]$Uid
    
    DRMMDeletedDevicesSite() : base() {
    }
    
    static [DRMMDeletedDevicesSite] FromAPIMethod([pscustomobject]$Response) {
        
        if ($null -eq $Response) {
            return $null
        }
        
        $Site = [DRMMDeletedDevicesSite]::new()
        
        $Site.Id = $Response.id
        $Site.Uid = $Response.uid  # String assignment, no GUID validation
        $Site.AccountUid = $Response.accountUid
        $Site.Name = $Response.name
        $Site.Description = $Response.description
        $Site.Notes = $Response.notes
        $Site.OnDemand = $Response.onDemand
        $Site.SplashtopAutoInstall = $Response.splashtopAutoInstall
        $Site.AutotaskCompanyName = $Response.autotaskCompanyName
        $Site.AutotaskCompanyId = $Response.autotaskCompanyId
        $Site.PortalUrl = $Response.portalUrl
        
        if ($Response.proxySettings) {
            $Site.ProxySettings = [DRMMSiteProxySettings]::FromAPIMethod($Response.proxySettings)
        }
        
        if ($Response.devicesStatus) {
            $Site.DevicesStatus = [DRMMDevicesStatus]::FromAPIMethod($Response.devicesStatus)
        }
        
        return $Site
    }
}

<#
.SYNOPSIS
    Represents the proxy settings for a site in the DRMM system, including properties such as host, port, type, and authentication credentials.
.DESCRIPTION
    The DRMMSiteProxySettings class models the proxy settings for a site within the DRMM platform. It includes properties such as Host, Port, Type, Username, and Password. The class provides a constructor and a static method to create an instance from API response data. Additionally, it includes a method to generate a summary string of the proxy settings information. The class handles the conversion of password data from the API response, ensuring that it is stored as a secure string when appropriate.
#>
class DRMMSiteProxySettings : DRMMObject {

    # The host address of the proxy server.
    [string]$Host
    # The username for the proxy server.
    [string]$Username
    # The password for the proxy server.
    [securestring]$Password
    # The port number of the proxy server.
    [int]$Port
    # The type of the proxy server (e.g., HTTP, SOCKS).
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

    <#
    .SYNOPSIS
        Generates a summary string for the proxy settings, including the type, host, and port information.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the proxy settings for the site. It includes the proxy type, host, and port information if available. If the host is not set, it returns null to indicate that proxy settings are not configured.
    .OUTPUTS
        A summary string that includes the type, host, and port information of the site's proxy settings.
    #>
    [string] GetSummary() {

        $ProxyInfo = if ($this.Host) {"$($this.Type)://$($this.Host)$(if ($this.Port) {":$($this.Port)"})"} else {$null}
        return $ProxyInfo

    }
}

<#
.SYNOPSIS
    Represents the overall settings for a site in the DRMM system, including general settings, proxy settings, mail recipients, and site UID.
.DESCRIPTION
    The DRMMSiteSettings class models the overall settings for a site within the DRMM platform. It includes properties such as GeneralSettings, ProxySettings, MailRecipients, and SiteUid. The class provides a constructor and a static method to create an instance from API response data. Additionally, it includes a method to generate a summary string of the site's settings information, combining details from the general settings, proxy settings, and mail recipients. The class serves as a comprehensive representation of the site's configuration, allowing for easy access and management of various settings related to the site.
#>
class DRMMSiteSettings : DRMMObject {

    # The general settings of the site.
    [DRMMSiteGeneralSettings]$GeneralSettings
    # The proxy settings for the site.
    [DRMMSiteProxySettings]$ProxySettings  # Reuse existing class
    # Reuse existing class
    [DRMMSiteMailRecipient[]]$MailRecipients
    # Reuse existing class
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

    <#
    .SYNOPSIS
        Generates a summary string for the site's settings, including on-demand status, proxy information, and mail recipient count.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the site's settings, including the on-demand status from the general settings, proxy information from the proxy settings, and the count of mail recipients. If any of these components are not available, it provides default values in the summary string to indicate their absence.
    .OUTPUTS
        A summary string that includes the on-demand status, proxy information, and mail recipient count for the site.
    #>
    [string] GetSummary() {

        $GeneralInfo = if ($this.GeneralSettings) { "OnDemand: $($this.GeneralSettings.OnDemand)" } else { "OnDemand: -" }
        $ProxyInfo = if ($this.ProxySettings) { " | Proxy: $($this.ProxySettings.GetSummary())" } else { " | Proxy: -" }
        $MailCount = if ($this.MailRecipients) { " | Mail Recipients: $($this.MailRecipients.Count)" } else { " | Mail Recipients: 0" }

        return "$GeneralInfo$ProxyInfo$MailCount"

    }    
}

<#
.SYNOPSIS
    Represents the status of devices associated with a site in the DRMM system, including counts of total devices, online devices, and offline devices.
.DESCRIPTION
    The DRMMDevicesStatus class models the status of devices for a site within the DRMM platform. It includes properties such as NumberOfDevices, NumberOfOnlineDevices, and NumberOfOfflineDevices. The class provides a constructor and a static method to create an instance from API response data. Additionally, it includes a method to generate a summary string of the device status information, providing an overview of the total number of devices and their online/offline status for the site.
#>
class DRMMDevicesStatus : DRMMObject {

    # The total number of devices.
    [long]$NumberOfDevices
    # The number of devices that are currently online.
    [long]$NumberOfOnlineDevices
    # The number of devices that are currently offline.
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

    <#
    .SYNOPSIS
        Generates a summary string for the device status, including counts of total devices, online devices, and offline devices.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the device status for the site, including the total number of devices, the number of online devices, and the number of offline devices. This summary provides a quick overview of the device status for the site, allowing for easy monitoring and assessment of the site's device health.
    .OUTPUTS
        A summary string that includes the total number of devices, the number of online devices, and the number of offline devices for the site.
    #>
    [string] GetSummary() {

        return "Devices: $($this.NumberOfDevices), Online: $($this.NumberOfOnlineDevices), Offline: $($this.NumberOfOfflineDevices)"

    }
}

<#
.SYNOPSIS
    Represents a site-scoped filter in the DRMM system, extending DRMMFilter with a Site property.
.DESCRIPTION
    The DRMMSiteFilter class extends DRMMFilter to model site-scoped filters within the DRMM platform. It adds a Site property that provides full context about the associated DRMMSite, and overrides the portal URL construction to include the site ID suffix. This subclass exists to break the circular dependency between DRMMFilter and DRMMSite while preserving the ability to navigate from a filter to its parent site via the pipeline.
#>
class DRMMSiteFilter : DRMMFilter {

    # The DRMMSite object associated with the filter. Provides full site context for site-specific filters.
    [DRMMSite]$Site

    DRMMSiteFilter() : base() {

    }

    static [DRMMSiteFilter] FromAPIMethod([pscustomobject]$Response, [DRMMSite]$Site, [string]$Platform) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Filter = [DRMMSiteFilter]::new()
        $Filter.Id = $Response.id
        $Filter.FilterId = $Response.id
        $Filter.Name = $Response.name
        $Filter.Description = $Response.description
        $Filter.Type = $Response.type
        $Filter.Scope = 'Site'
        $Filter.Site = $Site
        $Filter.SiteUid = $Site.Uid
        $Filter.PortalUrl = "https://$($Platform.ToLower()).rmm.datto.com/device-filter-results/$($Filter.Id)-$($Site.Id)"

        $CreateDate = [DRMMObject]::ParseApiDate($Response.dateCreate)
        $Filter.DateCreate = $CreateDate.DateTime

        $UpdatedDate = [DRMMObject]::ParseApiDate($Response.lastUpdated)
        $Filter.LastUpdated = $UpdatedDate.DateTime

        return $Filter

    }

    <#
    .SYNOPSIS
        Generates a summary string for the site filter, including its name, site name, and type.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the filter's name, associated site name, and type. If the Type property is not set, it defaults to '-'.
    .OUTPUTS
        A summary string that includes the filter's name, site name, and type.
    #>
    [string] GetSummary() {

        if ($this.Type) {

            $TypeValue = $this.Type

        } else {

            $TypeValue = '-'

        }

        return "$($this.Name) [Site: $($this.Site.Name)]$TypeValue"

    }
}