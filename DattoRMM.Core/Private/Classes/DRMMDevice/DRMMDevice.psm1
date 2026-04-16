<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '..\DRMMAlert\DRMMAlert.psm1'
using module '..\DRMMDeviceAudit\DRMMDeviceAudit.psm1'
using module '..\DRMMJob\DRMMJob.psm1'
using module '..\DRMMNetworkInterface\DRMMNetworkInterface.psm1'
using module '..\DRMMObject\DRMMObject.psm1'
<#
.SYNOPSIS
    Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device.
.DESCRIPTION
    The DRMMDevice class models a device within the DRMM platform, providing properties that describe the device's attributes and state, as well as methods to retrieve related information such as alerts and to perform actions like opening the device portal.
#>
class DRMMDevice : DRMMObject {

    # The unique identifier of the device.
    [long]$Id
    # The unique identifier (UID) of the device.
    [guid]$Uid
    # The unique identifier of the site to which the device belongs.
    [long]$SiteId
    # The unique identifier (UID) of the site to which the device belongs.
    [guid]$SiteUid
    # The name of the site to which the device belongs.
    [string]$SiteName
    # The type of the device.
    [DRMMDeviceType]$DeviceType
    # The hostname of the device.
    [string]$Hostname
    # The internal IP address of the device.
    [string]$IntIpAddress
    # The operating system running on the device.
    [string]$OperatingSystem
    # The user who last logged into the device.
    [string]$LastLoggedInUser
    # The domain to which the device belongs.
    [string]$Domain
    # The version of the CAG agent installed on the device.
    [string]$CagVersion
    # The display version of the device.
    [string]$DisplayVersion
    # The external IP address of the device.
    [string]$ExtIpAddress
    # The device's description.
    [string]$Description
    # Indicates whether the device is running a 64-bit operating system.
    [bool]$A64Bit
    # Indicates whether the device requires a reboot.
    [bool]$RebootRequired
    # Indicates whether the device is currently online.
    [bool]$Online
    # Indicates whether the device is currently suspended in the DRMM system.
    [bool]$Suspended
    # Indicates whether the device has been marked as deleted.
    [bool]$Deleted
    # The last time the device was seen online.
    [Nullable[datetime]]$LastSeen
    # The date and time when the device was last rebooted.
    [Nullable[datetime]]$LastReboot
    # The date when the device was last audited.
    [Nullable[datetime]]$LastAuditDate
    # The date when the device was created in the DRMM system.
    [Nullable[datetime]]$CreationDate
    # User-defined fields associated with the device.
    [DRMMDeviceUdfs]$Udfs
    # Indicates whether SNMP is enabled on the device.
    [bool]$SnmpEnabled
    # The class of the device, which may indicate its role or type within the organization.
    [string]$DeviceClass
    # The URL to access the device's portal in the DRMM system.
    [string]$PortalUrl
    # The date when the device's warranty expires.
    [string]$WarrantyDate
    # Information about the device's antivirus software.
    [DRMMDeviceAntivirusInfo]$Antivirus
    # Information about the device's patch management status.
    [DRMMDevicePatchManagement]$PatchManagement
    # Information about the device's software status.
    [string]$SoftwareStatus
    # The URL for web remote access to the device.
    [string]$WebRemoteUrl
    # Information about the device's network probe status.
    [bool]$NetworkProbe
    # Indicates whether the device was onboarded via network monitoring.
    [bool]$OnboardedViaNetworkMonitor
    # Indicates whether the last logged in user information is revealed for the device.
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
        $Device.Udfs = [DRMMDeviceUdfs]::FromAPIMethod($Response.udf)
        $Device.Antivirus = [DRMMDeviceAntivirusInfo]::FromAPIMethod($Response.antivirus)
        $Device.PatchManagement = [DRMMDevicePatchManagement]::FromAPIMethod($Response.patchManagement)
        $Device.LastSeen = ([DRMMObject]::ParseApiDate($Response.lastSeen)).DateTime
        $Device.LastReboot = ([DRMMObject]::ParseApiDate($Response.lastReboot)).DateTime
        $Device.LastAuditDate = ([DRMMObject]::ParseApiDate($Response.lastAuditDate)).DateTime
        $Device.CreationDate = ([DRMMObject]::ParseApiDate($Response.creationDate)).DateTime

        return $Device

    }

    <#
    .SYNOPSIS
        Retrieves the alerts associated with the device, filtered by status.
    .DESCRIPTION
        The GetAlerts method returns an array of DRMMAlert objects representing the alerts associated with the device. By default, it retrieves only open alerts.
    .OUTPUTS
        An array of alerts associated with the device that match the specified status.
    #>
    [DRMMAlert[]] GetAlerts() {

        return Get-RMMAlert -DeviceUid $this.Uid -Status 'Open'

    }

    <#
    .SYNOPSIS
        Retrieves the alerts associated with the device, filtered by a specified status.
    .DESCRIPTION
        The GetAlerts method returns an array of DRMMAlert objects representing the alerts associated with the device, filtered by the specified status (e.g., 'Open', 'Resolved', 'All').
    #>
    [DRMMAlert[]] GetAlerts([string]$Status) {

        return Get-RMMAlert -DeviceUid $this.Uid -Status $Status

    }

    <#
    .SYNOPSIS
        Opens the device's portal URL in the default web browser.
    .DESCRIPTION
        The OpenPortal method launches the portal URL associated with the device using the default web browser. If the portal URL is not available, a warning is displayed.
    .OUTPUTS
        This method does not return a value. It performs an action to open the portal URL in the default web browser.
    #>
    [void] OpenPortal() {

        if ($this.PortalUrl) {

            Start-Process $this.PortalUrl

        } else {

            Write-Warning "Portal URL is not available for device $($this.Hostname)"

        }
    }

    <#
    .SYNOPSIS
        Opens the device's web remote URL in the default web browser.
    .DESCRIPTION
        The OpenWebRemote method launches the web remote URL associated with the device using the default web browser. If the web remote URL is not available, a warning is displayed.
    .OUTPUTS
        This method does not return a value. It performs an action to open the web remote URL in the default web browser.
    #>
    [void] OpenWebRemote() {

        if ($this.WebRemoteUrl) {

            Start-Process $this.WebRemoteUrl

        } else {

            Write-Warning "Web Remote URL is not available for device $($this.Hostname)"

        }
    }

    <#
    .SYNOPSIS
        Retrieves the value of a specified User-Defined Field (UDF) as a JSON object.
    .DESCRIPTION
        The GetUdfAsJson method takes a UDF number (1-300) as input and retrieves the corresponding UDF value from the device. If the UDF value is not empty, it attempts to parse it as JSON and returns the resulting object. If the UDF number is out of range or if parsing fails, appropriate exceptions are thrown.
    .OUTPUTS
        A JSON object containing the value of the specified UDF.
    #>
    [object] GetUdfAsJson([int]$UdfNumber) {

        if ($UdfNumber -lt 1 -or $UdfNumber -gt [DRMMDeviceUdfs]::MaxUdfCount) {

            throw "UDF number must be between 1 and $([DRMMDeviceUdfs]::MaxUdfCount)"

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

    <#
    .SYNOPSIS
        Retrieves the value of a specified User-Defined Field (UDF) as a CSV object with custom headers.
    .DESCRIPTION
        The GetUdfAsCsv method takes a UDF number (1-300) and an array of header names as input. It retrieves the corresponding UDF value from the device, which is expected to be in CSV format. The method then parses the CSV data using the provided headers and returns it as an array of PSCustomObject.
    .OUTPUTS
        A CSV object containing the value of the specified UDF, formatted with the provided delimiter and headers.
    #>
    [pscustomobject] GetUdfAsCsv([int]$UdfNumber, [string[]]$Headers) {

        # Default delimiter: comma
        return $this.GetUdfAsCsv($UdfNumber, ',', $Headers)

    }

    <#
    .SYNOPSIS
        Retrieves the value of a specified User-Defined Field (UDF) as a CSV object with a custom delimiter and headers.
    .DESCRIPTION
        The GetUdfAsCsv method takes a UDF number (1-300), a delimiter, and an array of header names as input. It retrieves the corresponding UDF value from the device, which is expected to be in CSV format. The method then parses the CSV data using the provided delimiter and headers, returning it as an array of PSCustomObject.
    #>
    [pscustomobject] GetUdfAsCsv([int]$UdfNumber, [string]$Delimiter, [string[]]$Headers) {

        if ($UdfNumber -lt 1 -or $UdfNumber -gt [DRMMDeviceUdfs]::MaxUdfCount) {

            throw "UDF number must be between 1 and $([DRMMDeviceUdfs]::MaxUdfCount)"

        }

        if ([string]::IsNullOrEmpty($Delimiter)) {

            throw "Delimiter cannot be null or empty"

        }

        if ($null -eq $Headers -or $Headers.Count -eq 0) {

            throw "Headers must contain at least one column name"

        }

        $UdfPropName = "Udf$UdfNumber"
        $UdfValue = $this.Udfs.$UdfPropName

        if ([string]::IsNullOrWhiteSpace($UdfValue)) {
            
            return $null

        }

        try {

            # Parse single row of delimited data with custom headers
            $CsvText = $UdfValue
            return (ConvertFrom-Csv -InputObject $CsvText -Delimiter $Delimiter -Header $Headers)

        } catch {

            Write-Error "Failed to parse UDF $UdfNumber as delimited data: $_"
            return $null

        }

    }

    <#
    .SYNOPSIS
        Generates a summary string for the device, including its hostname and device type.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the device's hostname and its device type category. If the device type information is not available, it defaults to 'Unknown'.
    .OUTPUTS
        A summary string for the device, including its hostname and device type.
    #>
    [string] GetSummary() {

        $DeviceTypeStr = if ($this.DeviceType) { "$($this.DeviceType.Category)" } else { 'Unknown' }
        return "$($this.Hostname)|$DeviceTypeStr"

    }

    <#
    .SYNOPSIS
        Resolves all open alerts associated with the device.
    .DESCRIPTION
        The ResolveAllAlerts method retrieves all open alerts for the device and resolves each one by calling the Resolve-RMMAlert cmdlet with the alert's unique identifier and the -Force parameter to bypass confirmation prompts.
    .OUTPUTS
        This method does not return a value. It performs an action to resolve all open alerts associated with the device.
    #>
    [void] ResolveAllAlerts() {

        $Alerts = $this.GetAlerts('Open')

        foreach ($Alert in $Alerts) {

            Resolve-RMMAlert -AlertUid $Alert.Uid -Force

        }
    }

    # Data Retrieval Methods
    <#
    .SYNOPSIS
        Gets the most recent audit information for this device.
    .DESCRIPTION
        This method retrieves the latest audit data for the device, which may include system information, hardware details, and other relevant data collected during the last audit process.
    .OUTPUTS
        The most recent audit information for this device.
    #>
    [DRMMDeviceAudit] GetAudit() {

        return Get-RMMDeviceAudit -DeviceUid $this.Uid

    }

    <#
    .SYNOPSIS
        Gets the software information for this device.
    .DESCRIPTION
        This method retrieves the software data for the device, which may include installed applications and versions.
    .OUTPUTS
        The software information for this device.
    #>
    [DRMMDeviceAuditSoftware[]] GetSoftware() {

        return Get-RMMDeviceSoftware -DeviceUid $this.Uid

    }

    <#
    .SYNOPSIS
        Sets the value of one or more User-Defined Fields (UDFs) for the device.
    .DESCRIPTION
        The SetUdf method takes a hashtable of UDF field names and values, and updates the corresponding UDFs for the device using the Set-RMMDeviceUdf cmdlet. The -Force parameter is used to bypass confirmation prompts.
    .OUTPUTS
        This method does not return a value. It performs an action to set the specified UDFs for the device.
    #>
    [DRMMDevice] SetUdf([hashtable]$UdfFields) {

        return Set-RMMDeviceUdf -DeviceUid $this.Uid -UDFFields $UdfFields -Force

    }

    <#
    .SYNOPSIS
        Clears the value of a specified User-Defined Field (UDF) for the device.
    .DESCRIPTION
        The ClearUdf method takes a UDF number (1-300) as input and clears the corresponding UDF value for the device by setting it to an empty string using the Set-RMMDeviceUdf cmdlet. The -Force parameter is used to bypass confirmation prompts.
    .OUTPUTS
        This method does not return a value. It performs an action to clear the specified UDF.
    #>
    [DRMMDevice] ClearUdf([int]$UdfNumber) {

        if ($UdfNumber -lt 1 -or $UdfNumber -gt [DRMMDeviceUdfs]::MaxUdfCount) {

            throw "UDF number must be between 1 and $([DRMMDeviceUdfs]::MaxUdfCount)"

        }

        return Set-RMMDeviceUdf -DeviceUid $this.Uid -UdfNumber $UdfNumber -UdfValue '' -Force

    }

    <#
    .SYNOPSIS
        Clears the values of all User-Defined Fields (UDFs) for the device.
    .DESCRIPTION
        The ClearUdfs method clears the values of all UDFs (1-300) for the device by setting them to empty strings using the Set-RMMDeviceUdf cmdlet. The -Force parameter is used to bypass confirmation prompts.
    .OUTPUTS
        This method does not return a value. It performs an action to clear all UDFs.
    #>
    [DRMMDevice] ClearUdfs() {

        $UdfFields = @{}

        for ($i = 1; $i -le [DRMMDeviceUdfs]::MaxUdfCount; $i++) {

            $UdfFields["udf$i"] = ''

        }

        return Set-RMMDeviceUdf -DeviceUid $this.Uid -UDFFields $UdfFields -Force

    }

    <#
    .SYNOPSIS
        Sets the warranty date for the device.
    .DESCRIPTION
        The SetWarranty method takes a datetime value representing the warranty expiration date and updates the device's warranty information using the Set-RMMDeviceWarranty cmdlet. The -Force parameter is used to bypass confirmation prompts.
    .OUTPUTS
        This method does not return a value. It performs an action to set the warranty date for the device.
    #>
    [DRMMDevice] SetWarranty([datetime]$WarrantyDate) {

        return Set-RMMDeviceWarranty -DeviceUid $this.Uid -WarrantyDate $WarrantyDate -Force

    }


    <#
    .SYNOPSIS
        Runs a quick job on the device for a specified job component and variables.
    .DESCRIPTION
        The RunQuickJob method takes a component unique identifier and a hashtable of variables, and initiates a quick job on the device using the New-RMMQuickJob cmdlet. The -Force parameter is used to bypass confirmation prompts.
    .OUTPUTS
        A DRMMJob object representing the job that was run on the device.
    #>
    [DRMMJob] RunQuickJob([guid]$ComponentUid, [hashtable]$Variables) {

        return New-RMMQuickJob -DeviceUid $this.Uid -ComponentUid $ComponentUid -Variables $Variables -Force

    }

    <#
    .SYNOPSIS
        Moves the device to a different site within the DRMM system.
    .DESCRIPTION
        The Move method takes a target site unique identifier as input and moves the device to the specified
    .OUTPUTS
        This method does not return a value. It performs an action to move the device to the specified site.
    #>
    [DRMMDevice] Move([guid]$TargetSiteUid) {

        return Move-RMMDevice -DeviceUid $this.Uid -TargetSiteUid $TargetSiteUid -Force

    }
}

<#
.SYNOPSIS
    Represents antivirus information for a device in the DRMM system, including the antivirus product name and its status.
.DESCRIPTION
    The DRMMDeviceAntivirusInfo class models the antivirus information associated with a device in the DRMM platform. It includes properties such as AntivirusProduct and AntivirusStatus, which provide details about the antivirus software installed on the device and its current status. The class also includes methods to determine if the antivirus is running and up to date, as well as a method to generate a summary string of the antivirus information.
#>
class DRMMDeviceAntivirusInfo : DRMMObject {

    # The name of the antivirus product installed on the device.
    [string]$AntivirusProduct
    # The current status of the antivirus product on the device.
    [string]$AntivirusStatus

    DRMMDeviceAntivirusInfo() : base() {

    }

    static [DRMMDeviceAntivirusInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $AntivirusInfo = [DRMMDeviceAntivirusInfo]::new()
        $AntivirusInfo.AntivirusProduct = $Response.antivirusProduct
        $AntivirusInfo.AntivirusStatus = $Response.antivirusStatus

        return $AntivirusInfo

    }

    <#
    .SYNOPSIS
        Determines if the antivirus is currently running on the device.
    .DESCRIPTION
        The IsRunning method checks the AntivirusStatus property to determine if the antivirus is currently running on the device. It returns true if the status indicates that the antivirus is running, and false otherwise.
    .OUTPUTS
        A boolean value indicating whether the antivirus is currently running on the device.
    #>
    [bool] IsRunning() {

        return ($this.AntivirusStatus -match '^Running')

    }

    <#
    .SYNOPSIS
        Determines if the antivirus is running and up to date on the device.
    .DESCRIPTION
        The IsUpToDate method checks the AntivirusStatus property to determine if the antivirus is both running and up to date on the device. It returns true if the status indicates that the antivirus is running and up to date, and false otherwise.
    .OUTPUTS
        A boolean value indicating whether the antivirus is running and up to date on the device.
    #>
    [bool] IsUpToDate() {

        return ($this.AntivirusStatus -eq 'RunningAndUpToDate')

    }

    <#
    .SYNOPSIS
        Generates a summary string of the antivirus product and its status.
    .DESCRIPTION
        The GetSummary method returns a string that combines the AntivirusProduct and AntivirusStatus properties, providing a concise summary of the antivirus information for the device.
    .OUTPUTS
        A summary string of the antivirus product and its status.
    #>
    [string] GetSummary() {

        return "$($this.AntivirusProduct) - $($this.AntivirusStatus)"

    }
}

<#
.SYNOPSIS
    Represents a network interface associated with a device in the DRMM system.
.DESCRIPTION
    The DRMMDeviceNetworkInterface class models the network interface information for a device in the DRMM platform. It includes properties such as Id, Uid, SiteId, SiteUid, SiteName, DeviceType, Hostname, IntIpAddress, ExtIpAddress, and an array of network interfaces (Nics). The class provides a constructor and a static method to create an instance from API response data.
#>
class DRMMDeviceNetworkInterface : DRMMObject {

    # The unique identifier of the network interface.
    [long]$Id
    # The unique identifier (UID) of the network interface.
    [guid]$Uid
    # The unique identifier of the site to which the network interface belongs.
    [long]$SiteId
    # The unique identifier (UID) of the site to which the network interface belongs.
    [guid]$SiteUid
    # The name of the site to which the network interface belongs.
    [string]$SiteName
    # The type of the network device.
    [DRMMDeviceType]$DeviceType
    # The hostname associated with the network interface.
    [string]$Hostname
    # The internal IP address of the network interface.
    [string]$IntIpAddress
    # The external IP address of the network interface.
    [string]$ExtIpAddress
    # The network interface cards associated with the device.
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

<##
.SYNOPSIS
    Represents a device type in the DRMM system.
.DESCRIPTION
    The DRMMDeviceType class models the type information for a device in the DRMM platform. It includes properties such as Category and Type. The class provides a constructor and a static method to create an instance from API response data.
#>
class DRMMDeviceType : DRMMObject {

    # The category of the device type.
    [string]$Category
    # The specific type of the device.
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

<#
.SYNOPSIS
    Represents user-defined fields (UDFs) associated with a device in the DRMM system.
.DESCRIPTION
    The DRMMDeviceUdfs class models the user-defined fields (UDFs) for a device in the DRMM platform. It includes properties for Udf1 through Udf300, which can store custom data defined by the user. The class provides a static MaxUdfCount constant defining the upper bound, a constructor, and a static method to create an instance from API response data, populating the UDF properties based on the response.
#>
class DRMMDeviceUdfs : DRMMObject {

    # The value of user-defined field 1 for the device.
    [string]$Udf1
    # The value of user-defined field 2 for the device.
    [string]$Udf2
    # The value of user-defined field 3 for the device.
    [string]$Udf3
    # The value of user-defined field 4 for the device.
    [string]$Udf4
    # The value of user-defined field 5 for the device.
    [string]$Udf5
    # The value of user-defined field 6 for the device.
    [string]$Udf6
    # The value of user-defined field 7 for the device.
    [string]$Udf7
    # The value of user-defined field 8 for the device.
    [string]$Udf8
    # The value of user-defined field 9 for the device.
    [string]$Udf9
    # The value of user-defined field 10 for the device.
    [string]$Udf10
    # The value of user-defined field 11 for the device.
    [string]$Udf11
    # The value of user-defined field 12 for the device.
    [string]$Udf12
    # The value of user-defined field 13 for the device.
    [string]$Udf13
    # The value of user-defined field 14 for the device.
    [string]$Udf14
    # The value of user-defined field 15 for the device.
    [string]$Udf15
    # The value of user-defined field 16 for the device.
    [string]$Udf16
    # The value of user-defined field 17 for the device.
    [string]$Udf17
    # The value of user-defined field 18 for the device.
    [string]$Udf18
    # The value of user-defined field 19 for the device.
    [string]$Udf19
    # The value of user-defined field 20 for the device.
    [string]$Udf20
    # The value of user-defined field 21 for the device.
    [string]$Udf21
    # The value of user-defined field 22 for the device.
    [string]$Udf22
    # The value of user-defined field 23 for the device.
    [string]$Udf23
    # The value of user-defined field 24 for the device.
    [string]$Udf24
    # The value of user-defined field 25 for the device.
    [string]$Udf25
    # The value of user-defined field 26 for the device.
    [string]$Udf26
    # The value of user-defined field 27 for the device.
    [string]$Udf27
    # The value of user-defined field 28 for the device.
    [string]$Udf28
    # The value of user-defined field 29 for the device.
    [string]$Udf29
    # The value of user-defined field 30 for the device.
    [string]$Udf30
    # The value of user-defined field 31 for the device.
    [string]$Udf31
    # The value of user-defined field 32 for the device.
    [string]$Udf32
    # The value of user-defined field 33 for the device.
    [string]$Udf33
    # The value of user-defined field 34 for the device.
    [string]$Udf34
    # The value of user-defined field 35 for the device.
    [string]$Udf35
    # The value of user-defined field 36 for the device.
    [string]$Udf36
    # The value of user-defined field 37 for the device.
    [string]$Udf37
    # The value of user-defined field 38 for the device.
    [string]$Udf38
    # The value of user-defined field 39 for the device.
    [string]$Udf39
    # The value of user-defined field 40 for the device.
    [string]$Udf40
    # The value of user-defined field 41 for the device.
    [string]$Udf41
    # The value of user-defined field 42 for the device.
    [string]$Udf42
    # The value of user-defined field 43 for the device.
    [string]$Udf43
    # The value of user-defined field 44 for the device.
    [string]$Udf44
    # The value of user-defined field 45 for the device.
    [string]$Udf45
    # The value of user-defined field 46 for the device.
    [string]$Udf46
    # The value of user-defined field 47 for the device.
    [string]$Udf47
    # The value of user-defined field 48 for the device.
    [string]$Udf48
    # The value of user-defined field 49 for the device.
    [string]$Udf49
    # The value of user-defined field 50 for the device.
    [string]$Udf50
    # The value of user-defined field 51 for the device.
    [string]$Udf51
    # The value of user-defined field 52 for the device.
    [string]$Udf52
    # The value of user-defined field 53 for the device.
    [string]$Udf53
    # The value of user-defined field 54 for the device.
    [string]$Udf54
    # The value of user-defined field 55 for the device.
    [string]$Udf55
    # The value of user-defined field 56 for the device.
    [string]$Udf56
    # The value of user-defined field 57 for the device.
    [string]$Udf57
    # The value of user-defined field 58 for the device.
    [string]$Udf58
    # The value of user-defined field 59 for the device.
    [string]$Udf59
    # The value of user-defined field 60 for the device.
    [string]$Udf60
    # The value of user-defined field 61 for the device.
    [string]$Udf61
    # The value of user-defined field 62 for the device.
    [string]$Udf62
    # The value of user-defined field 63 for the device.
    [string]$Udf63
    # The value of user-defined field 64 for the device.
    [string]$Udf64
    # The value of user-defined field 65 for the device.
    [string]$Udf65
    # The value of user-defined field 66 for the device.
    [string]$Udf66
    # The value of user-defined field 67 for the device.
    [string]$Udf67
    # The value of user-defined field 68 for the device.
    [string]$Udf68
    # The value of user-defined field 69 for the device.
    [string]$Udf69
    # The value of user-defined field 70 for the device.
    [string]$Udf70
    # The value of user-defined field 71 for the device.
    [string]$Udf71
    # The value of user-defined field 72 for the device.
    [string]$Udf72
    # The value of user-defined field 73 for the device.
    [string]$Udf73
    # The value of user-defined field 74 for the device.
    [string]$Udf74
    # The value of user-defined field 75 for the device.
    [string]$Udf75
    # The value of user-defined field 76 for the device.
    [string]$Udf76
    # The value of user-defined field 77 for the device.
    [string]$Udf77
    # The value of user-defined field 78 for the device.
    [string]$Udf78
    # The value of user-defined field 79 for the device.
    [string]$Udf79
    # The value of user-defined field 80 for the device.
    [string]$Udf80
    # The value of user-defined field 81 for the device.
    [string]$Udf81
    # The value of user-defined field 82 for the device.
    [string]$Udf82
    # The value of user-defined field 83 for the device.
    [string]$Udf83
    # The value of user-defined field 84 for the device.
    [string]$Udf84
    # The value of user-defined field 85 for the device.
    [string]$Udf85
    # The value of user-defined field 86 for the device.
    [string]$Udf86
    # The value of user-defined field 87 for the device.
    [string]$Udf87
    # The value of user-defined field 88 for the device.
    [string]$Udf88
    # The value of user-defined field 89 for the device.
    [string]$Udf89
    # The value of user-defined field 90 for the device.
    [string]$Udf90
    # The value of user-defined field 91 for the device.
    [string]$Udf91
    # The value of user-defined field 92 for the device.
    [string]$Udf92
    # The value of user-defined field 93 for the device.
    [string]$Udf93
    # The value of user-defined field 94 for the device.
    [string]$Udf94
    # The value of user-defined field 95 for the device.
    [string]$Udf95
    # The value of user-defined field 96 for the device.
    [string]$Udf96
    # The value of user-defined field 97 for the device.
    [string]$Udf97
    # The value of user-defined field 98 for the device.
    [string]$Udf98
    # The value of user-defined field 99 for the device.
    [string]$Udf99
    # The value of user-defined field 100 for the device.
    [string]$Udf100
    # The value of user-defined field 101 for the device.
    [string]$Udf101
    # The value of user-defined field 102 for the device.
    [string]$Udf102
    # The value of user-defined field 103 for the device.
    [string]$Udf103
    # The value of user-defined field 104 for the device.
    [string]$Udf104
    # The value of user-defined field 105 for the device.
    [string]$Udf105
    # The value of user-defined field 106 for the device.
    [string]$Udf106
    # The value of user-defined field 107 for the device.
    [string]$Udf107
    # The value of user-defined field 108 for the device.
    [string]$Udf108
    # The value of user-defined field 109 for the device.
    [string]$Udf109
    # The value of user-defined field 110 for the device.
    [string]$Udf110
    # The value of user-defined field 111 for the device.
    [string]$Udf111
    # The value of user-defined field 112 for the device.
    [string]$Udf112
    # The value of user-defined field 113 for the device.
    [string]$Udf113
    # The value of user-defined field 114 for the device.
    [string]$Udf114
    # The value of user-defined field 115 for the device.
    [string]$Udf115
    # The value of user-defined field 116 for the device.
    [string]$Udf116
    # The value of user-defined field 117 for the device.
    [string]$Udf117
    # The value of user-defined field 118 for the device.
    [string]$Udf118
    # The value of user-defined field 119 for the device.
    [string]$Udf119
    # The value of user-defined field 120 for the device.
    [string]$Udf120
    # The value of user-defined field 121 for the device.
    [string]$Udf121
    # The value of user-defined field 122 for the device.
    [string]$Udf122
    # The value of user-defined field 123 for the device.
    [string]$Udf123
    # The value of user-defined field 124 for the device.
    [string]$Udf124
    # The value of user-defined field 125 for the device.
    [string]$Udf125
    # The value of user-defined field 126 for the device.
    [string]$Udf126
    # The value of user-defined field 127 for the device.
    [string]$Udf127
    # The value of user-defined field 128 for the device.
    [string]$Udf128
    # The value of user-defined field 129 for the device.
    [string]$Udf129
    # The value of user-defined field 130 for the device.
    [string]$Udf130
    # The value of user-defined field 131 for the device.
    [string]$Udf131
    # The value of user-defined field 132 for the device.
    [string]$Udf132
    # The value of user-defined field 133 for the device.
    [string]$Udf133
    # The value of user-defined field 134 for the device.
    [string]$Udf134
    # The value of user-defined field 135 for the device.
    [string]$Udf135
    # The value of user-defined field 136 for the device.
    [string]$Udf136
    # The value of user-defined field 137 for the device.
    [string]$Udf137
    # The value of user-defined field 138 for the device.
    [string]$Udf138
    # The value of user-defined field 139 for the device.
    [string]$Udf139
    # The value of user-defined field 140 for the device.
    [string]$Udf140
    # The value of user-defined field 141 for the device.
    [string]$Udf141
    # The value of user-defined field 142 for the device.
    [string]$Udf142
    # The value of user-defined field 143 for the device.
    [string]$Udf143
    # The value of user-defined field 144 for the device.
    [string]$Udf144
    # The value of user-defined field 145 for the device.
    [string]$Udf145
    # The value of user-defined field 146 for the device.
    [string]$Udf146
    # The value of user-defined field 147 for the device.
    [string]$Udf147
    # The value of user-defined field 148 for the device.
    [string]$Udf148
    # The value of user-defined field 149 for the device.
    [string]$Udf149
    # The value of user-defined field 150 for the device.
    [string]$Udf150
    # The value of user-defined field 151 for the device.
    [string]$Udf151
    # The value of user-defined field 152 for the device.
    [string]$Udf152
    # The value of user-defined field 153 for the device.
    [string]$Udf153
    # The value of user-defined field 154 for the device.
    [string]$Udf154
    # The value of user-defined field 155 for the device.
    [string]$Udf155
    # The value of user-defined field 156 for the device.
    [string]$Udf156
    # The value of user-defined field 157 for the device.
    [string]$Udf157
    # The value of user-defined field 158 for the device.
    [string]$Udf158
    # The value of user-defined field 159 for the device.
    [string]$Udf159
    # The value of user-defined field 160 for the device.
    [string]$Udf160
    # The value of user-defined field 161 for the device.
    [string]$Udf161
    # The value of user-defined field 162 for the device.
    [string]$Udf162
    # The value of user-defined field 163 for the device.
    [string]$Udf163
    # The value of user-defined field 164 for the device.
    [string]$Udf164
    # The value of user-defined field 165 for the device.
    [string]$Udf165
    # The value of user-defined field 166 for the device.
    [string]$Udf166
    # The value of user-defined field 167 for the device.
    [string]$Udf167
    # The value of user-defined field 168 for the device.
    [string]$Udf168
    # The value of user-defined field 169 for the device.
    [string]$Udf169
    # The value of user-defined field 170 for the device.
    [string]$Udf170
    # The value of user-defined field 171 for the device.
    [string]$Udf171
    # The value of user-defined field 172 for the device.
    [string]$Udf172
    # The value of user-defined field 173 for the device.
    [string]$Udf173
    # The value of user-defined field 174 for the device.
    [string]$Udf174
    # The value of user-defined field 175 for the device.
    [string]$Udf175
    # The value of user-defined field 176 for the device.
    [string]$Udf176
    # The value of user-defined field 177 for the device.
    [string]$Udf177
    # The value of user-defined field 178 for the device.
    [string]$Udf178
    # The value of user-defined field 179 for the device.
    [string]$Udf179
    # The value of user-defined field 180 for the device.
    [string]$Udf180
    # The value of user-defined field 181 for the device.
    [string]$Udf181
    # The value of user-defined field 182 for the device.
    [string]$Udf182
    # The value of user-defined field 183 for the device.
    [string]$Udf183
    # The value of user-defined field 184 for the device.
    [string]$Udf184
    # The value of user-defined field 185 for the device.
    [string]$Udf185
    # The value of user-defined field 186 for the device.
    [string]$Udf186
    # The value of user-defined field 187 for the device.
    [string]$Udf187
    # The value of user-defined field 188 for the device.
    [string]$Udf188
    # The value of user-defined field 189 for the device.
    [string]$Udf189
    # The value of user-defined field 190 for the device.
    [string]$Udf190
    # The value of user-defined field 191 for the device.
    [string]$Udf191
    # The value of user-defined field 192 for the device.
    [string]$Udf192
    # The value of user-defined field 193 for the device.
    [string]$Udf193
    # The value of user-defined field 194 for the device.
    [string]$Udf194
    # The value of user-defined field 195 for the device.
    [string]$Udf195
    # The value of user-defined field 196 for the device.
    [string]$Udf196
    # The value of user-defined field 197 for the device.
    [string]$Udf197
    # The value of user-defined field 198 for the device.
    [string]$Udf198
    # The value of user-defined field 199 for the device.
    [string]$Udf199
    # The value of user-defined field 200 for the device.
    [string]$Udf200
    # The value of user-defined field 201 for the device.
    [string]$Udf201
    # The value of user-defined field 202 for the device.
    [string]$Udf202
    # The value of user-defined field 203 for the device.
    [string]$Udf203
    # The value of user-defined field 204 for the device.
    [string]$Udf204
    # The value of user-defined field 205 for the device.
    [string]$Udf205
    # The value of user-defined field 206 for the device.
    [string]$Udf206
    # The value of user-defined field 207 for the device.
    [string]$Udf207
    # The value of user-defined field 208 for the device.
    [string]$Udf208
    # The value of user-defined field 209 for the device.
    [string]$Udf209
    # The value of user-defined field 210 for the device.
    [string]$Udf210
    # The value of user-defined field 211 for the device.
    [string]$Udf211
    # The value of user-defined field 212 for the device.
    [string]$Udf212
    # The value of user-defined field 213 for the device.
    [string]$Udf213
    # The value of user-defined field 214 for the device.
    [string]$Udf214
    # The value of user-defined field 215 for the device.
    [string]$Udf215
    # The value of user-defined field 216 for the device.
    [string]$Udf216
    # The value of user-defined field 217 for the device.
    [string]$Udf217
    # The value of user-defined field 218 for the device.
    [string]$Udf218
    # The value of user-defined field 219 for the device.
    [string]$Udf219
    # The value of user-defined field 220 for the device.
    [string]$Udf220
    # The value of user-defined field 221 for the device.
    [string]$Udf221
    # The value of user-defined field 222 for the device.
    [string]$Udf222
    # The value of user-defined field 223 for the device.
    [string]$Udf223
    # The value of user-defined field 224 for the device.
    [string]$Udf224
    # The value of user-defined field 225 for the device.
    [string]$Udf225
    # The value of user-defined field 226 for the device.
    [string]$Udf226
    # The value of user-defined field 227 for the device.
    [string]$Udf227
    # The value of user-defined field 228 for the device.
    [string]$Udf228
    # The value of user-defined field 229 for the device.
    [string]$Udf229
    # The value of user-defined field 230 for the device.
    [string]$Udf230
    # The value of user-defined field 231 for the device.
    [string]$Udf231
    # The value of user-defined field 232 for the device.
    [string]$Udf232
    # The value of user-defined field 233 for the device.
    [string]$Udf233
    # The value of user-defined field 234 for the device.
    [string]$Udf234
    # The value of user-defined field 235 for the device.
    [string]$Udf235
    # The value of user-defined field 236 for the device.
    [string]$Udf236
    # The value of user-defined field 237 for the device.
    [string]$Udf237
    # The value of user-defined field 238 for the device.
    [string]$Udf238
    # The value of user-defined field 239 for the device.
    [string]$Udf239
    # The value of user-defined field 240 for the device.
    [string]$Udf240
    # The value of user-defined field 241 for the device.
    [string]$Udf241
    # The value of user-defined field 242 for the device.
    [string]$Udf242
    # The value of user-defined field 243 for the device.
    [string]$Udf243
    # The value of user-defined field 244 for the device.
    [string]$Udf244
    # The value of user-defined field 245 for the device.
    [string]$Udf245
    # The value of user-defined field 246 for the device.
    [string]$Udf246
    # The value of user-defined field 247 for the device.
    [string]$Udf247
    # The value of user-defined field 248 for the device.
    [string]$Udf248
    # The value of user-defined field 249 for the device.
    [string]$Udf249
    # The value of user-defined field 250 for the device.
    [string]$Udf250
    # The value of user-defined field 251 for the device.
    [string]$Udf251
    # The value of user-defined field 252 for the device.
    [string]$Udf252
    # The value of user-defined field 253 for the device.
    [string]$Udf253
    # The value of user-defined field 254 for the device.
    [string]$Udf254
    # The value of user-defined field 255 for the device.
    [string]$Udf255
    # The value of user-defined field 256 for the device.
    [string]$Udf256
    # The value of user-defined field 257 for the device.
    [string]$Udf257
    # The value of user-defined field 258 for the device.
    [string]$Udf258
    # The value of user-defined field 259 for the device.
    [string]$Udf259
    # The value of user-defined field 260 for the device.
    [string]$Udf260
    # The value of user-defined field 261 for the device.
    [string]$Udf261
    # The value of user-defined field 262 for the device.
    [string]$Udf262
    # The value of user-defined field 263 for the device.
    [string]$Udf263
    # The value of user-defined field 264 for the device.
    [string]$Udf264
    # The value of user-defined field 265 for the device.
    [string]$Udf265
    # The value of user-defined field 266 for the device.
    [string]$Udf266
    # The value of user-defined field 267 for the device.
    [string]$Udf267
    # The value of user-defined field 268 for the device.
    [string]$Udf268
    # The value of user-defined field 269 for the device.
    [string]$Udf269
    # The value of user-defined field 270 for the device.
    [string]$Udf270
    # The value of user-defined field 271 for the device.
    [string]$Udf271
    # The value of user-defined field 272 for the device.
    [string]$Udf272
    # The value of user-defined field 273 for the device.
    [string]$Udf273
    # The value of user-defined field 274 for the device.
    [string]$Udf274
    # The value of user-defined field 275 for the device.
    [string]$Udf275
    # The value of user-defined field 276 for the device.
    [string]$Udf276
    # The value of user-defined field 277 for the device.
    [string]$Udf277
    # The value of user-defined field 278 for the device.
    [string]$Udf278
    # The value of user-defined field 279 for the device.
    [string]$Udf279
    # The value of user-defined field 280 for the device.
    [string]$Udf280
    # The value of user-defined field 281 for the device.
    [string]$Udf281
    # The value of user-defined field 282 for the device.
    [string]$Udf282
    # The value of user-defined field 283 for the device.
    [string]$Udf283
    # The value of user-defined field 284 for the device.
    [string]$Udf284
    # The value of user-defined field 285 for the device.
    [string]$Udf285
    # The value of user-defined field 286 for the device.
    [string]$Udf286
    # The value of user-defined field 287 for the device.
    [string]$Udf287
    # The value of user-defined field 288 for the device.
    [string]$Udf288
    # The value of user-defined field 289 for the device.
    [string]$Udf289
    # The value of user-defined field 290 for the device.
    [string]$Udf290
    # The value of user-defined field 291 for the device.
    [string]$Udf291
    # The value of user-defined field 292 for the device.
    [string]$Udf292
    # The value of user-defined field 293 for the device.
    [string]$Udf293
    # The value of user-defined field 294 for the device.
    [string]$Udf294
    # The value of user-defined field 295 for the device.
    [string]$Udf295
    # The value of user-defined field 296 for the device.
    [string]$Udf296
    # The value of user-defined field 297 for the device.
    [string]$Udf297
    # The value of user-defined field 298 for the device.
    [string]$Udf298
    # The value of user-defined field 299 for the device.
    [string]$Udf299
    # The value of user-defined field 300 for the device.
    [string]$Udf300

    # Maximum number of UDFs supported by the Datto RMM API.
    static [int]$MaxUdfCount = 300

    DRMMDeviceUdfs() : base() {

    }

    static [DRMMDeviceUdfs] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $UdfEntries = [DRMMDeviceUdfs]::new()

        for ($i = 1; $i -le [DRMMDeviceUdfs]::MaxUdfCount; $i++) {

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

<#
.SYNOPSIS
    Represents patch management information for a device in the DRMM system.
.DESCRIPTION
    The DRMMDevicePatchManagement class models the patch management status for a device in the DRMM platform. It includes properties such as PatchStatus, PatchesApprovedPending, PatchesNotApproved, and PatchesInstalled, which provide insights into the device's patch management state. The class provides a constructor and a static method to create an instance from API response data.
#>
class DRMMDevicePatchManagement : DRMMObject {

    # The current status of patch management on the device.
    [string]$PatchStatus
    # The number of patches that are approved but pending installation.
    [Nullable[long]]$PatchesApprovedPending
    # The number of patches that are not approved for installation.
    [Nullable[long]]$PatchesNotApproved
    # The number of patches that have been installed on the device.
    [Nullable[long]]$PatchesInstalled

    DRMMDevicePatchManagement() : base() {

    }

    static [DRMMDevicePatchManagement] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $PatchMgmt = [DRMMDevicePatchManagement]::new()
        $PatchMgmt.PatchStatus = $Response.patchStatus
        $PatchMgmt.PatchesApprovedPending = $Response.patchesApprovedPending
        $PatchMgmt.PatchesNotApproved = $Response.patchesNotApproved
        $PatchMgmt.PatchesInstalled = $Response.patchesInstalled

        return $PatchMgmt

    }
}
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDaRcdRGaZel0Nu
# c4SzCNBRtfYIY37jOr1QzcLG2W6R4qCCA04wggNKMIICMqADAgECAhB464iXHfI6
# gksEkDDTyrNsMA0GCSqGSIb3DQEBCwUAMD0xFjAUBgNVBAoMDVJvYmVydCBGYWRk
# ZXMxIzAhBgNVBAMMGkRhdHRvUk1NLkNvcmUgQ29kZSBTaWduaW5nMB4XDTI2MDMz
# MTAwMTMzMFoXDTI4MDMzMTAwMjMzMFowPTEWMBQGA1UECgwNUm9iZXJ0IEZhZGRl
# czEjMCEGA1UEAwwaRGF0dG9STU0uQ29yZSBDb2RlIFNpZ25pbmcwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQChn1EpMYQgl1RgWzQj2+wp2mvdfb3UsaBS
# nxEVGoQ0gj96tJ2MHAF7zsITdUjwaflKS1vE6wAlOg5EI1V79tJCMxzM0bFpOdR1
# L5F2HE/ovIAKNkHxFUF5qWU8vVeAsOViFQ4yhHpzLen0WLF6vhmc9eH23dLQy5fy
# tELZQEc2WbQFa4HMAitP/P9kHAu6CUx5s4woLIOyyR06jkr3l9vk0sxcbCxx7+dF
# RrsSLyPYPH+bUAB8+a0hs+6qCeteBuUfLvGzpMhpzKAsY82WZ3Rd9X38i32dYj+y
# dYx+nx+UEMDLjDJrZgnVa8as4RojqVLcEns5yb/XTjLxDc58VatdAgMBAAGjRjBE
# MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU
# H+B0vf97dYXqdUX1YMcWhFsY6fcwDQYJKoZIhvcNAQELBQADggEBAJmD4EEGNmcD
# 1JtFoRGxuLJaTHxDwBsjqcRQRE1VPZNGaiwIm8oSQdHVjQg0oIyK7SEb02cs6n6Y
# NZbwf7B7WZJ4aKYbcoLug1k1x9SoqwBmfElECeJTKXf6dkRRNmrAodpGCixR4wMH
# KXqwqP5F+5j7bdnQPiIVXuMesxc4tktz362ysph1bqKjDQSCBpwi0glEIH7bv5Ms
# Ey9Gl3fe+vYC5W06d2LYVebEfm9+7766hsOgpdDVgdtnN+e6uwIJjG/6PTG6TMDP
# y+pr5K6LyUVYJYcWWUTZRBqqwBHiLGekPbxrjEVfxUY32Pq4QfLzUH5hhUCAk4HN
# XpF9pOzFLMUxggIDMIIB/wIBATBRMD0xFjAUBgNVBAoMDVJvYmVydCBGYWRkZXMx
# IzAhBgNVBAMMGkRhdHRvUk1NLkNvcmUgQ29kZSBTaWduaW5nAhB464iXHfI6gksE
# kDDTyrNsMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKEC
# gAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwG
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINqk634L+fIY7utGlBzQXmFjOS54
# MMCo8kxZ0N8jWzMuMA0GCSqGSIb3DQEBAQUABIIBAACuvufeV5/d1FgDFJvnLmUM
# 0AsjxUO/dMTbbNqRIPmkYE6WNT7JjRqQuejRqyExu1dJnJT4WeUPyvUXS8dYHcBT
# sY5O7dsFTsPn0/20M9xGCw2MUY3cQe3bfmGrRRikRLlGp8a8bOEPgxLx+KmxmFP+
# qe2S0DNbyzbnGPSAQLCEkyNDILrGJFCFzgZoBQ6KpDZQYkiQ4ReW2jXg5najOxqS
# KKIRFSEoW1Y0rPiC0DSDTBzABPuV6jRWp2t+fT+rceYRj+AGdxSHkGfMTd7l9XQ6
# 8VGKUYdGpwIlpcHCA9CWm5CVJQWigZktydye3gmHTiqliuYSZNt3uMvo7OGJnzc=
# SIG # End signature block
