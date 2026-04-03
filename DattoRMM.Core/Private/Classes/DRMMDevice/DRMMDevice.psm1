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
        The GetUdfAsJson method takes a UDF number (1-30) as input and retrieves the corresponding UDF value from the device. If the UDF value is not empty, it attempts to parse it as JSON and returns the resulting object. If the UDF number is out of range or if parsing fails, appropriate exceptions are thrown.
    .OUTPUTS
        A JSON object containing the value of the specified UDF.
    #>
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

    <#
    .SYNOPSIS
        Retrieves the value of a specified User-Defined Field (UDF) as a CSV object with custom headers.
    .DESCRIPTION
        The GetUdfAsCsv method takes a UDF number (1-30) and an array of header names as input. It retrieves the corresponding UDF value from the device, which is expected to be in CSV format. The method then parses the CSV data using the provided headers and returns it as an array of PSCustomObject.
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
        The GetUdfAsCsv method takes a UDF number (1-30), a delimiter, and an array of header names as input. It retrieves the corresponding UDF value from the device, which is expected to be in CSV format. The method then parses the CSV data using the provided delimiter and headers, returning it as an array of PSCustomObject.
    #>
    [pscustomobject] GetUdfAsCsv([int]$UdfNumber, [string]$Delimiter, [string[]]$Headers) {

        if ($UdfNumber -lt 1 -or $UdfNumber -gt 30) {

            throw "UDF number must be between 1 and 30"

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
        The SetUDF method takes a hashtable of UDF field names and values, and updates the corresponding UDFs for the device using the Set-RMMDeviceUDF cmdlet. The -Force parameter is used to bypass confirmation prompts.
    .OUTPUTS
        This method does not return a value. It performs an action to set the specified UDFs for the device.
    #>
    [DRMMDevice] SetUDF([hashtable]$UDFFields) {

        return Set-RMMDeviceUDF -DeviceUid $this.Uid @UDFFields -Force

    }

    <#
    .SYNOPSIS
        Clears the value of a specified User-Defined Field (UDF) for the device.
    .DESCRIPTION
        The ClearUDF method takes a UDF number (1-30) as input and clears the corresponding UDF value for the device by setting it to an empty string using the Set-RMMDeviceUDF cmdlet. The -Force parameter is used to bypass confirmation prompts.
    .OUTPUTS
        This method does not return a value. It performs an action to clear the specified UDF.
    #>
    [DRMMDevice] ClearUDF([int]$UdfNumber) {

        if ($UdfNumber -lt 1 -or $UdfNumber -gt 30) {

            throw "UDF number must be between 1 and 30"

        }

        $udfParam = @{"UDF$UdfNumber" = ''}

        return Set-RMMDeviceUDF -DeviceUid $this.Uid @udfParam -Force

    }

    <#
    .SYNOPSIS
        Clears the values of all User-Defined Fields (UDFs) for the device.
    .DESCRIPTION
        The ClearUDFs method clears the values of all UDFs (1-30) for the device by setting them to empty strings using the Set-RMMDeviceUDF cmdlet. The -Force parameter is used to bypass confirmation prompts.
    .OUTPUTS
        This method does not return a value. It performs an action to clear all UDFs.
    #>
    [DRMMDevice] ClearUDFs() {

        $udfParams = @{}

        for ($i = 1; $i -le 30; $i++) {

            $udfParams["UDF$i"] = ''

        }

        return Set-RMMDeviceUDF -DeviceUid $this.Uid @udfParams -Force

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
    The DRMMDeviceUdfs class models the user-defined fields (UDFs) for a device in the DRMM platform. It includes properties for Udf1 through Udf30, which can store custom data defined by the user. The class provides a constructor and a static method to create an instance from API response data, populating the UDF properties based on the response.
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

    DRMMDeviceUdfs() : base() {

    }

    static [DRMMDeviceUdfs] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $UdfEntries = [DRMMDeviceUdfs]::new()

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