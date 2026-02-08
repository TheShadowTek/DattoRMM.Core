<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>

#region Enums
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

enum RMMThrottleProfile {
    Medium
    Aggressive
    Cautious
    DefaultProfile
}
#endregion Enums

#region DRMMObject - Base Class
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

        # Handle numeric epoch timestamps (int, long, double, or numeric strings)
        if ($Value -is [int] -or $Value -is [long] -or $Value -is [double] -or ($Value -is [string] -and $Value -match '^\-?\d+(\.\d+)?$')) {

            $Num = [double]$Value

            # Treat DateTime.MinValue sentinel as null (-62135596800000 ms or -62135596800 seconds)
            if ($Num -eq -62135596800000 -or $Num -eq -62135596800) {

                return @{ DateTime = $null; Epoch = $null; Raw = $Value }

            }

            if ($Num -gt 9999999999) {

                # Milliseconds
                $Dto = [DateTimeOffset]::FromUnixTimeMilliseconds([long]$Num)
                $EpochSeconds = [long]$Dto.ToUnixTimeSeconds()

            } elseif ($Num -lt -9999999999) {

                # Negative milliseconds
                $Dto = [DateTimeOffset]::FromUnixTimeMilliseconds([long]$Num)
                $EpochSeconds = [long]$Dto.ToUnixTimeSeconds()

            } else {

                # Seconds (possibly with decimal milliseconds)
                $Dto = [DateTimeOffset]::FromUnixTimeSeconds($Num)
                $EpochSeconds = [long]$Num

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
}
#endregion DRMMObject - Base Class

#region DRMMAPIKeySecret class
<#
.SYNOPSIS
    Represents API key and secret information for authenticating with the DRMM API.
.DESCRIPTION
    The DRMMAPIKeySecret class encapsulates the API key, API secret, and associated username for a DRMM account. It provides a static method to create an instance of the class from a typical API response object that contains these credentials. The API secret is stored as a secure string to enhance security when handling sensitive information.
#>
class DRMMAPIKeySecret : DRMMObject {

    [string]$ApiKey
    [securestring]$ApiSecret
    [string]$Username

    DRMMAPIKeySecret() : base() {

    }

    static [DRMMAPIKeySecret] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $KeySecret = [DRMMAPIKeySecret]::new()
        $KeySecret.ApiKey = $Response.apiAccessKey
        $KeySecret.ApiSecret = ConvertTo-SecureString -String $Response.apiSecretKey -AsPlainText -Force
        $Response.apiSecretKey = $null # Clear plain text secret from memory
        $KeySecret.Username = $Response.userName

        return $KeySecret

    }

}
#endregion DRMMAPIKeySecret class

#region DRMMAccount and related classes
<#
.SYNOPSIS
    Represents an account in the DRMM system, including its properties and related information.
.DESCRIPTION
    The DRMMAccount class models an account within the DRMM platform, encapsulating properties such as the account ID, unique identifier, name, currency, and related descriptors and device status. It provides a static method to create an instance of the class from a typical API response object that contains account information. The class also includes a method to generate a summary string that combines the account name with its device status for easy display. The DRMMAccountDescriptor and DRMMAccountDevicesStatus classes represent related information about the account, such as billing details and device status, respectively.
#>
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

        $Account.Id = $Response.id
        $Account.Uid = $Response.uid
        $Account.Name = $Response.name
        $Account.Currency = $Response.currency

        # Parse descriptor
        $DescriptorData = $Response.descriptor

        if ($null -ne $DescriptorData) {

            $Account.Descriptor = [DRMMAccountDescriptor]::FromAPIMethod($DescriptorData)

        }

        # Parse devices status
        $DevicesStatusData = $Response.devicesStatus

        if ($null -ne $DevicesStatusData) {

            $Account.DevicesStatus = [DRMMAccountDevicesStatus]::FromAPIMethod($DevicesStatusData)

        }

        return $Account

    }

    <#
    .SYNOPSIS
        Generates a summary string for the account, including its name and device status.
    .DESCRIPTION
        The GetSummary method creates a concise summary of the account by combining its name with a summary of its device status. If device status information is available, it includes the number of online devices and the total number of devices. If device status information is not available, it indicates that there is no device status information. Used in TypeName properties and other display contexts to provide a quick overview of the account's status.
    #>
    [string] GetSummary() {

        $DeviceInfo = if ($this.DevicesStatus) { $this.DevicesStatus.GetSummary() } else { 'No device status' }

        return "$($this.Name) - $DeviceInfo"

    }
}

<#
.SYNOPSIS
    Represents the descriptor information for a DRMM account, including billing and timezone details.
.DESCRIPTION
    The DRMMAccountDescriptor class encapsulates details about a DRMM account's billing email, device limit, and time zone. It provides a static method to create an instance of the class from a typical API response object that contains these descriptor details. This class is used as a property within the DRMMAccount class to provide additional information about the account's configuration and limitations.
#>
class DRMMAccountDescriptor : DRMMObject {

    [string]$BillingEmail
    [int]$DeviceLimit
    [string]$TimeZone

    DRMMAccountDescriptor() : base() {

    }

    static [DRMMAccountDescriptor] FromAPIMethod([pscustomobject]$Response) {

        $Descriptor = [DRMMAccountDescriptor]::new()

        $Descriptor.BillingEmail = $Response.bilingEmail
        $Descriptor.DeviceLimit = $Response.deviceLimit
        $Descriptor.TimeZone = $Response.timeZone

        return $Descriptor

    }
}

<#
.SYNOPSIS
    Represents the device status information for a DRMM account, including counts of devices in various states.
.DESCRIPTION
    The DRMMAccountDevicesStatus class encapsulates information about the number of devices associated with a DRMM account, including the total number of devices, the number of online devices, offline devices, on-demand devices, and managed devices. It provides a static method to create an instance of the class from a typical API response object that contains these device status details. The class also includes methods to calculate the percentage of online devices and to generate a summary string that combines this information for easy display. This class is used as a property within the DRMMAccount class to provide insights into the account's device status.
#>
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

        $Status.NumberOfDevices = $Response.numberOfDevices
        $Status.NumberOfOnlineDevices = $Response.numberOfOnlineDevices
        $Status.NumberOfOfflineDevices = $Response.numberOfOfflineDevices
        $Status.NumberOfOnDemandDevices = $Response.numberOfOnDemandDevices
        $Status.NumberOfManagedDevices = $Response.numberOfManagedDevices

        return $Status

    }

    <#
    .SYNOPSIS
        Calculates the percentage of online devices for the account.
    .DESCRIPTION
        The GetOnlinePercentage method computes the percentage of devices that are currently online out of the total number of devices associated with the account. It handles cases where the total number of devices is zero to avoid division by zero errors, returning 0% in such cases. The result is rounded to two decimal places for readability. This method provides a quick metric for understanding the online status of the account's devices.
    #>
    [double] GetOnlinePercentage() {

        if ($this.NumberOfDevices -eq 0) {

            return 0

        }

        return [Math]::Round(($this.NumberOfOnlineDevices / $this.NumberOfDevices) * 100, 2)

    }

    <#
    .SYNOPSIS
        Generates a summary string for the device status, including the count of online devices and total devices.
    .DESCRIPTION
        The GetSummary method creates a concise summary of the device status for the account by combining the number of online devices with the total number of devices. It also includes the percentage of online devices in parentheses for additional context. This summary is used in the GetSummary method of the DRMMAccount class to provide a quick overview of the account's device status.
    #>
    [string] GetSummary() {

        return "$($this.NumberOfOnlineDevices)/$($this.NumberOfDevices) online ($($this.GetOnlinePercentage())%)"

    }
}
#endregion DRMMAccount and related classes

#region DRMMActivityLog and related classes
<#
.SYNOPSIS
    Represents an activity log entry in the DRMM system, including details about the activity, associated site and user information, and related context.
.DESCRIPTION
    The DRMMActivityLog class models an activity log entry within the DRMM platform, encapsulating properties such as the log ID, entity, category, action, date, site information, device ID, hostname, user information, activity details, and flags indicating the presence of standard output and error. It provides a static method to create an instance of the class from a typical API response object that contains activity log information. The class also includes a method to generate a summary string that combines key properties of the activity log for easy display. The related classes DRMMActivityLogSite and DRMMActivityLogUser represent nested information about the site and user associated with the activity log entry.
#>
class DRMMActivityLog : DRMMObject {

    [string]$Id
    [string]$Entity
    [string]$Category
    [string]$Action
    [Nullable[datetime]]$Date
    [DRMMActivityLogSite]$Site
    [Nullable[long]]$DeviceId
    [string]$Hostname
    [DRMMActivityLogUser]$User
    [PSCustomObject]$Details
    [bool]$HasStdOut
    [bool]$HasStdErr

    DRMMActivityLog() : base() {

    }

    static [DRMMActivityLog] FromAPIMethod([pscustomobject]$Response) {

        return [DRMMActivityLog]::FromAPIMethod($Response, $false)

    }

    static [DRMMActivityLog] FromAPIMethod([pscustomobject]$Response, [bool]$UseExperimentalDetailClasses) {

        if ($null -eq $Response) {

            return $null

        }

        $Log = [DRMMActivityLog]::new()
        $Log.Id = $Response.id
        $Log.Entity = $Response.entity
        $Log.Category = $Response.category
        $Log.Action = $Response.action
        $Log.DeviceId = $Response.deviceId
        $Log.Hostname = $Response.hostname
        $Log.HasStdOut = $Response.hasStdOut
        $Log.HasStdErr = $Response.hasStdErr

        # Type ActivityLogDetails by Entity_Category_Action if experimental classes enabled, otherwise use generic details class.
        $LogContext = "$($Log.Entity)_$($Log.Category)_$($Log.Action)"
        $Log.Details = [DRMMActivityLogDetails]::FromAPIMethod($Response.details, $LogContext, $UseExperimentalDetailClasses)

        # Parse the date
        $DateValue = [DRMMObject]::ParseApiDate($Response.date)
        $Log.Date = $DateValue.DateTime

        # Parse nested objects
        if ($null -ne $Response.site) {

            $Log.Site = [DRMMActivityLogSite]::FromAPIMethod($Response.site)

        }

        if ($null -ne $Response.user) {

            $Log.User = [DRMMActivityLogUser]::FromAPIMethod($Response.user)

        }

        return $Log

    }

    <#
    .SYNOPSIS
        Generates a summary string for the activity log entry, including key details about the activity.
    .DESCRIPTION
        The GetSummary method creates a concise summary of the activity log entry by combining the entity, category, action, and target information (hostname or username). It handles cases where certain properties may be null or empty, substituting "Unknown" as needed. This summary is used in TypeName properties and other display contexts to provide a quick overview of the activity log entry's key details.
    #>
    [string] GetSummary() {

        $EntityStr = if ($this.Entity) { $this.Entity } else { 'Unknown' }
        $CategoryStr = if ($this.Category) { $this.Category } else { 'Unknown' }
        $ActionStr = if ($this.Action) { $this.Action } else { 'Unknown' }
        $TargetStr = if ($this.Hostname) { $this.Hostname } elseif ($this.User) { $this.User.UserName } else { '' }

        return "[$EntityStr] ${CategoryStr}: ${ActionStr} - $TargetStr"

    }
}

<#
.SYNOPSIS
    Represents the 'Details' Property of a DRMMActivityLog entry, which can contain arbitrary key-value pairs with additional information about the activity.
.DESCRIPTION
    The 'Details' property of a DRMMActivityLog entry is designed to hold additional information about the activity in a flexible format. 

#>
class DRMMActivityLogDetails : DRMMObject {

    DRMMActivityLogDetails() : base() {

    }

    static [object] FromAPIMethod([pscustomobject]$Response, [string]$LogContext) {

        return [DRMMActivityLogDetails]::FromAPIMethod($Response, $LogContext, $false)

    }

    static [object] FromAPIMethod([pscustomobject]$Response, [string]$LogContext, [bool]$UseExperimentalDetailClasses) {

        $DetailsHashtable = $Response | ConvertFrom-Json -AsHashtable

        # If experimental detail classes are not enabled, always use generic
        if (-not $UseExperimentalDetailClasses) {

            return [DRMMActivityLogDetailsGeneric]::FromActivityLogDetail($DetailsHashtable)

        }

        # Use experimental entity/category-specific detail classes
        $Result = switch ($LogContext) {

            # DEVICE entity - job category
            'DEVICE_job_deployment' {[DRMMActivityLogDetailsDeviceJobDeployment]::FromActivityLogDetail($DetailsHashtable); break}
            'DEVICE_job_create' {[DRMMActivityLogDetailsDeviceJobCreate]::FromActivityLogDetail($DetailsHashtable); break}
            {$_ -match '^DEVICE_job_'} {[DRMMActivityLogDetailsDeviceJobGeneric]::FromActivityLogDetail($DetailsHashtable); break}
            
            # DEVICE entity - remote category
            'DEVICE_remote_chat' {[DRMMActivityLogDetailsDeviceRemoteChat]::FromActivityLogDetail($DetailsHashtable); break}
            'DEVICE_remote_jrto' {[DRMMActivityLogDetailsDeviceRemoteJrto]::FromActivityLogDetail($DetailsHashtable); break}
            {$_ -match '^DEVICE_remote_'} {[DRMMActivityLogDetailsDeviceRemoteGeneric]::FromActivityLogDetail($DetailsHashtable); break}
            
            # DEVICE entity - device category
            'DEVICE_device_move.device' {[DRMMActivityLogDetailsDeviceDeviceMoveDevice]::FromActivityLogDetail($DetailsHashtable); break}
            {$_ -match '^DEVICE_device_'} {[DRMMActivityLogDetailsDeviceDeviceGeneric]::FromActivityLogDetail($DetailsHashtable); break}
            
            # DEVICE entity - unknown category (entity-level fallback)
            {$_ -match '^DEVICE_'} {[DRMMActivityLogDetailsDeviceGeneric]::FromActivityLogDetail($DetailsHashtable); break}
            
            # USER entity - unknown category (entity-level fallback)
            {$_ -match '^USER_'} {[DRMMActivityLogDetailsUserGeneric]::FromActivityLogDetail($DetailsHashtable); break}
            
            # Unknown entity (complete fallback)
            default {[DRMMActivityLogDetailsGeneric]::FromActivityLogDetail($DetailsHashtable)}

        }
        
        return $Result

    }
}

<#
.SYNOPSIS
    Represents a generic implementation of the DRMMActivityLogDetails class, which can handle arbitrary key-value pairs from the API response.
.DESCRIPTION
    The DRMMActivityLogDetailsGeneric class is a flexible implementation of the DRMMActivityLogDetails class that can accommodate any structure of details returned by the API. It takes a PSCustomObject as input and dynamically adds its properties to the class instance. The class also includes logic to attempt parsing any properties that contain "date" in their name as date values, while retaining the original value if parsing fails. This allows it to handle a wide variety of detail structures without requiring predefined properties.
#>
class DRMMActivityLogDetailsGeneric : DRMMActivityLogDetails {


    DRMMActivityLogDetailsGeneric() : base() {

    }

    static [DRMMActivityLogDetailsGeneric] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        if ($null -eq $ActivityLogDetail) {

            return $null

        }

        $Details = [DRMMActivityLogDetailsGeneric]::new()

        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($Key -match 'date' -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $DateResult = [DRMMObject]::ParseApiDate($ActivityLogDetail[$Key])
                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $DateResult.DateTime

                } catch {

                    # If date parsing fails, add the original value
                    Write-Debug "Failed to parse date property '$Key' with value '$($ActivityLogDetail[$Key])'"
                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $ActivityLogDetail[$Key]

                }

            } else {

                $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $ActivityLogDetail[$Key]

            }
        }

        return $Details

    }
}

<#
.SYNOPSIS
    Base class for DEVICE entity activity log details, containing properties common to all DEVICE activities.
.DESCRIPTION
    The DRMMActivityLogEntityDevice class serves as a base class for all DEVICE entity activity logs, regardless of category. It encapsulates the 6 core properties that appear in all DEVICE activities: DeviceHostname, DeviceUid, Entity, EventAction, EventCategory, and Uid. Category-specific classes (job, remote, device) inherit from this class and add their category-specific properties.
#>
class DRMMActivityLogEntityDevice : DRMMActivityLogDetails {

    [string]$DeviceHostname
    [guid]$DeviceUid
    [string]$Entity
    [string]$EventAction
    [string]$EventCategory
    [guid]$Uid

    DRMMActivityLogEntityDevice() : base() {

    }

    static [void] PopulateEntityProperties([DRMMActivityLogEntityDevice]$Details, [hashtable]$ActivityLogDetail) {

        $Details.DeviceHostname = $ActivityLogDetail.'device.hostname'
        $Details.DeviceUid = $ActivityLogDetail.'device.uid'
        $Details.Entity = $ActivityLogDetail.'entity'
        $Details.EventAction = $ActivityLogDetail.'event.action'
        $Details.EventCategory = $ActivityLogDetail.'event.category'
        $Details.Uid = $ActivityLogDetail.'uid'

    }
}

<#
.SYNOPSIS
    Represents a generic DEVICE entity activity log for unknown categories, with entity-level properties and dynamic additional properties.
.DESCRIPTION
    The DRMMActivityLogDetailsDeviceGeneric class is used for DEVICE entity activity logs where the category is not yet mapped to a dedicated class (not job, remote, or device). It inherits the 6 base properties common to all DEVICE activities and dynamically adds any additional properties found in the response. This ensures type safety for known entity-level properties while maintaining flexibility for unknown categories.
#>
class DRMMActivityLogDetailsDeviceGeneric : DRMMActivityLogEntityDevice {

    DRMMActivityLogDetailsDeviceGeneric() : base() {

    }

    static [DRMMActivityLogDetailsDeviceGeneric] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        if ($null -eq $ActivityLogDetail) {

            return $null

        }

        $Details = [DRMMActivityLogDetailsDeviceGeneric]::new()

        # Populate entity-level properties
        [DRMMActivityLogEntityDevice]::PopulateEntityProperties($Details, $ActivityLogDetail)

        # Define entity property keys to exclude from dynamic properties
        $EntityPropertyKeys = @(
            'device.hostname', 'device.uid', 'entity', 'event.action', 'event.category', 'uid'
        )

        # Add any additional properties not in the entity base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($EntityPropertyKeys -contains $Key) {

                continue

            }

            if ($Key -match 'date' -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $DateResult = [DRMMObject]::ParseApiDate($ActivityLogDetail[$Key])
                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $DateResult.DateTime

                } catch {

                    # If date parsing fails, add the original value
                    Write-Debug "Failed to parse date property '$Key' with value '$($ActivityLogDetail[$Key])'"
                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $ActivityLogDetail[$Key]

                }

            } else {

                $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $ActivityLogDetail[$Key]

            }
        }

        return $Details

    }
}

<#
.SYNOPSIS
    Base class for USER entity activity log details, containing properties common to all USER activities.
.DESCRIPTION
    The DRMMActivityLogEntityUser class serves as a base class for all USER entity activity logs. As of this implementation, USER entity activities have not been observed in the wild, so this class is a placeholder for future expansion. It will likely contain properties such as UserId, UserUsername, Entity, EventAction, EventCategory, and Uid once USER activities are documented.
#>
class DRMMActivityLogEntityUser : DRMMActivityLogDetails {

    [string]$Entity
    [string]$EventAction
    [string]$EventCategory
    [guid]$Uid

    DRMMActivityLogEntityUser() : base() {

    }

    static [void] PopulateEntityProperties([DRMMActivityLogEntityUser]$Details, [hashtable]$ActivityLogDetail) {

        $Details.Entity = $ActivityLogDetail.'entity'
        $Details.EventAction = $ActivityLogDetail.'event.action'
        $Details.EventCategory = $ActivityLogDetail.'event.category'
        $Details.Uid = $ActivityLogDetail.'uid'

    }
}

<#
.SYNOPSIS
    Represents a generic USER entity activity log for unknown categories, with entity-level properties and dynamic additional properties.
.DESCRIPTION
    The DRMMActivityLogDetailsUserGeneric class is used for USER entity activity logs. As of this implementation, USER entity activities have not been observed in the wild, so this class serves as a placeholder and generic handler. It inherits base properties common to USER activities and dynamically adds any additional properties found in the response. This ensures graceful handling when USER activities are encountered.
#>
class DRMMActivityLogDetailsUserGeneric : DRMMActivityLogEntityUser {

    DRMMActivityLogDetailsUserGeneric() : base() {

    }

    static [DRMMActivityLogDetailsUserGeneric] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        if ($null -eq $ActivityLogDetail) {

            return $null

        }

        $Details = [DRMMActivityLogDetailsUserGeneric]::new()

        # Populate entity-level properties
        [DRMMActivityLogEntityUser]::PopulateEntityProperties($Details, $ActivityLogDetail)

        # Define entity property keys to exclude from dynamic properties
        $EntityPropertyKeys = @(
            'entity', 'event.action', 'event.category', 'uid'
        )

        # Add any additional properties not in the entity base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($EntityPropertyKeys -contains $Key) {

                continue

            }

            if ($Key -match 'date' -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $DateResult = [DRMMObject]::ParseApiDate($ActivityLogDetail[$Key])
                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $DateResult.DateTime

                } catch {

                    # If date parsing fails, add the original value
                    Write-Debug "Failed to parse date property '$Key' with value '$($ActivityLogDetail[$Key])'"
                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $ActivityLogDetail[$Key]

                }

            } else {

                $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $ActivityLogDetail[$Key]

            }
        }

        return $Details

    }
}

<#
.SYNOPSIS
    Base class for DEVICE job-related activity log details, containing properties common to all job actions.
.DESCRIPTION
    The DRMMActivityLogDetailsDeviceJob class serves as a base class for DEVICE entity job category activity logs. It encapsulates properties that are common across different job actions (deployment, create, etc.), including job identifiers and site information, in addition to the entity-level DEVICE properties inherited from DRMMActivityLogEntityDevice. Specific job action types inherit from this class and add their unique properties.
#>
class DRMMActivityLogDetailsDeviceJob : DRMMActivityLogEntityDevice {

    [long]$JobId
    [string]$JobName
    [string]$JobStatus
    [guid]$JobUid
    [string]$SiteName

    DRMMActivityLogDetailsDeviceJob() : base() {

    }

    static [void] PopulateCategoryProperties([DRMMActivityLogDetailsDeviceJob]$Details, [hashtable]$ActivityLogDetail) {

        # Populate entity-level properties
        [DRMMActivityLogEntityDevice]::PopulateEntityProperties($Details, $ActivityLogDetail)

        # Populate job category properties
        $Details.JobId = $ActivityLogDetail.'job.id'
        $Details.JobName = $ActivityLogDetail.'job.name'
        $Details.JobStatus = $ActivityLogDetail.'job.status'
        $Details.JobUid = $ActivityLogDetail.'job.uid'
        $Details.SiteName = $ActivityLogDetail.'site.name'

    }
}

<#
.SYNOPSIS
    Represents a generic DEVICE job activity log details for unknown job actions, with base properties and dynamic additional properties.
.DESCRIPTION
    The DRMMActivityLogDetailsDeviceJobGeneric class is used for DEVICE entity job category activity logs where the specific action is not yet mapped to a dedicated class. It inherits the 11 base properties common to all DEVICE job activities and dynamically adds any additional properties found in the response that are not part of the base class. This ensures type safety for known properties while maintaining flexibility for unknown actions.
#>
class DRMMActivityLogDetailsDeviceJobGeneric : DRMMActivityLogDetailsDeviceJob {

    DRMMActivityLogDetailsDeviceJobGeneric() : base() {

    }

    static [DRMMActivityLogDetailsDeviceJobGeneric] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        if ($null -eq $ActivityLogDetail) {

            return $null

        }

        $Details = [DRMMActivityLogDetailsDeviceJobGeneric]::new()

        # Populate base properties
        [DRMMActivityLogDetailsDeviceJob]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Define base property keys to exclude from dynamic properties
        $BasePropertyKeys = @(
            'device.hostname', 'device.uid', 'entity', 'event.action', 'event.category', 'uid',
            'job.id', 'job.name', 'job.status', 'job.uid', 'site.name'
        )

        # Add any additional properties not in the base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($BasePropertyKeys -contains $Key) {

                continue

            }

            if ($Key -match 'date' -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $DateResult = [DRMMObject]::ParseApiDate($ActivityLogDetail[$Key])
                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $DateResult.DateTime

                } catch {

                    # If date parsing fails, add the original value
                    Write-Debug "Failed to parse date property '$Key' with value '$($ActivityLogDetail[$Key])'"
                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $ActivityLogDetail[$Key]

                }

            } else {

                $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $ActivityLogDetail[$Key]

            }

        }

        return $Details

    }
}

<#
.SYNOPSIS
    Represents an activity log of entity DEVICE, category job, and action deployment, which includes specific properties related to job deployment activities.
.DESCRIPTION
    The DRMMActivityLogDetailsDeviceJobDeployment class models the details of a job deployment activity log entry. It inherits common job properties from DRMMActivityLogDetailsDeviceJob and adds deployment-specific properties such as deployment ID, scheduled job information, and notes.
#>
class DRMMActivityLogDetailsDeviceJobDeployment : DRMMActivityLogDetailsDeviceJob {

    [long]$JobDeploymentId
    [long]$JobScheduledJobId
    [guid]$JobScheduledJobUid
    [string]$Note

    DRMMActivityLogDetailsDeviceJobDeployment() : base() {

    }

    static [DRMMActivityLogDetailsDeviceJobDeployment] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsDeviceJobDeployment]::new()

        # Populate base properties
        [DRMMActivityLogDetailsDeviceJob]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Populate deployment-specific properties
        $Details.JobDeploymentId = $ActivityLogDetail.'job.deployment_id'
        $Details.JobScheduledJobId = $ActivityLogDetail.'job.scheduled_job_id'
        $Details.JobScheduledJobUid = $ActivityLogDetail.'job.scheduled_job_uid'
        $Details.Note = $ActivityLogDetail.'note'

        return $Details

    }
}

<#
.SYNOPSIS
    Represents an activity log of entity DEVICE, category job, and action create, which includes specific properties related to job creation activities.
.DESCRIPTION
    The DRMMActivityLogDetailsDeviceJobCreate class models the details of a job creation activity log entry. It inherits common job properties from DRMMActivityLogDetailsDeviceJob and adds creation-specific properties such as the job creation date and user information (email, first name, last name, username, user ID).
#>
class DRMMActivityLogDetailsDeviceJobCreate : DRMMActivityLogDetailsDeviceJob {

    [nullable[datetime]]$JobDateCreated
    [string]$UserEmail
    [string]$UserFirstName
    [long]$UserId
    [string]$UserLastName
    [string]$UserUsername

    DRMMActivityLogDetailsDeviceJobCreate() : base() {

    }

    static [DRMMActivityLogDetailsDeviceJobCreate] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsDeviceJobCreate]::new()

        # Populate base properties
        [DRMMActivityLogDetailsDeviceJob]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Populate create-specific properties
        $Details.UserEmail = $ActivityLogDetail.'user.email'
        $Details.UserFirstName = $ActivityLogDetail.'user.firstName'
        $Details.UserId = $ActivityLogDetail.'user.id'
        $Details.UserLastName = $ActivityLogDetail.'user.lastName'
        $Details.UserUsername = $ActivityLogDetail.'user.username'

        if ($null -ne $ActivityLogDetail.'job.date_created') {

            $Details.JobDateCreated = [DRMMObject]::ParseApiDate($ActivityLogDetail.'job.date_created').DateTime

        } else {

            $Details.JobDateCreated = $null

        }

        return $Details

    }
}

<#
.SYNOPSIS
    Represents a detail item within a remote session activity log, including action, detail text, and name.
.DESCRIPTION
    The DRMMActivityLogDetailsRemoteSessionDetail class models individual detail items within the remote_session.details array of a DEVICE remote activity log entry. Each detail item contains an action type, detail text, and name that describe specific events or steps within the remote session.
#>
class DRMMActivityLogDetailsRemoteSessionDetail : DRMMObject {

    [string]$Action
    [string]$Detail
    [string]$Name

    DRMMActivityLogDetailsRemoteSessionDetail() : base() {

    }

    static [DRMMActivityLogDetailsRemoteSessionDetail] FromActivityLogDetail([hashtable]$DetailItem) {

        if ($null -eq $DetailItem) {

            return $null

        }

        $SessionDetail = [DRMMActivityLogDetailsRemoteSessionDetail]::new()
        $SessionDetail.Action = $DetailItem.'action'
        $SessionDetail.Detail = $DetailItem.'detail'
        $SessionDetail.Name = $DetailItem.'name'

        return $SessionDetail

    }
}

<#
.SYNOPSIS
    Base class for DEVICE remote-related activity log details, containing properties common to all remote session actions.
.DESCRIPTION
    The DRMMActivityLogDetailsDeviceRemote class serves as a base class for DEVICE entity remote category activity logs. It encapsulates properties that are common across different remote session actions (chat, jrto, etc.), including remote session details, site information, user information, and source forwarding details, in addition to the entity-level DEVICE properties inherited from DRMMActivityLogEntityDevice. Specific remote action types inherit from this class and add their unique properties if needed.
#>
class DRMMActivityLogDetailsDeviceRemote : DRMMActivityLogEntityDevice {

    [DRMMActivityLogDetailsRemoteSessionDetail[]]$RemoteSessionDetails
    [long]$RemoteSessionId
    [nullable[datetime]]$RemoteSessionStartDate
    [string]$RemoteSessionType
    [string]$SiteName
    [string]$SourceForwardedIp
    [string]$UserEmail
    [string]$UserFirstName
    [long]$UserId
    [string]$UserLastName
    [string]$UserUsername

    DRMMActivityLogDetailsDeviceRemote() : base() {

    }

    static [void] PopulateCategoryProperties([DRMMActivityLogDetailsDeviceRemote]$Details, [hashtable]$ActivityLogDetail) {

        # Populate entity-level properties
        [DRMMActivityLogEntityDevice]::PopulateEntityProperties($Details, $ActivityLogDetail)

        # Populate remote category properties
        $Details.RemoteSessionId = $ActivityLogDetail.'remote_session.id'
        $Details.RemoteSessionType = $ActivityLogDetail.'remote_session.type'
        $Details.SiteName = $ActivityLogDetail.'site.name'
        $Details.SourceForwardedIp = $ActivityLogDetail.'source.forwarded_ip'
        $Details.UserEmail = $ActivityLogDetail.'user.email'
        $Details.UserFirstName = $ActivityLogDetail.'user.firstname'
        $Details.UserId = $ActivityLogDetail.'user.id'
        $Details.UserLastName = $ActivityLogDetail.'user.lastname'
        $Details.UserUsername = $ActivityLogDetail.'user.username'

        # Parse remote_session.start_date
        if ($null -ne $ActivityLogDetail.'remote_session.start_date') {

            $Details.RemoteSessionStartDate = [DRMMObject]::ParseApiDate($ActivityLogDetail.'remote_session.start_date').DateTime

        } else {

            $Details.RemoteSessionStartDate = $null

        }

        # Parse remote_session.details array
        if ($null -ne $ActivityLogDetail.'remote_session.details' -and $ActivityLogDetail.'remote_session.details'.Count -gt 0) {

            $Details.RemoteSessionDetails = @()
            foreach ($DetailItem in $ActivityLogDetail.'remote_session.details') {

                $Details.RemoteSessionDetails += [DRMMActivityLogDetailsRemoteSessionDetail]::FromActivityLogDetail($DetailItem)

            }

        } else {

            $Details.RemoteSessionDetails = @()

        }
    }
}

<#
.SYNOPSIS
    Represents a generic DEVICE remote activity log details for unknown remote actions, with base properties and dynamic additional properties.
.DESCRIPTION
    The DRMMActivityLogDetailsDeviceRemoteGeneric class is used for DEVICE entity remote category activity logs where the specific action is not yet mapped to a dedicated class. It inherits the 17 base properties common to all DEVICE remote activities and dynamically adds any additional properties found in the response that are not part of the base class. This ensures type safety for known properties while maintaining flexibility for unknown actions.
#>
class DRMMActivityLogDetailsDeviceRemoteGeneric : DRMMActivityLogDetailsDeviceRemote {

    DRMMActivityLogDetailsDeviceRemoteGeneric() : base() {

    }

    static [DRMMActivityLogDetailsDeviceRemoteGeneric] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        if ($null -eq $ActivityLogDetail) {

            return $null

        }

        $Details = [DRMMActivityLogDetailsDeviceRemoteGeneric]::new()

        # Populate base properties
        [DRMMActivityLogDetailsDeviceRemote]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Define base property keys to exclude from dynamic properties
        $BasePropertyKeys = @(
            'device.hostname', 'device.uid', 'entity', 'event.action', 'event.category', 'uid',
            'remote_session.id', 'remote_session.type', 'remote_session.start_date', 'remote_session.details',
            'site.name', 'source.forwarded_ip',
            'user.email', 'user.firstname', 'user.id', 'user.lastname', 'user.username'
        )

        # Add any additional properties not in the base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($BasePropertyKeys -contains $Key) {

                continue

            }

            if ($Key -match 'date' -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $DateResult = [DRMMObject]::ParseApiDate($ActivityLogDetail[$Key])
                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $DateResult.DateTime

                } catch {

                    # If date parsing fails, add the original value
                    Write-Debug "Failed to parse date property '$Key' with value '$($ActivityLogDetail[$Key])'"
                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $ActivityLogDetail[$Key]

                }

            } else {

                $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $ActivityLogDetail[$Key]

            }

        }

        return $Details

    }
}

<#
.SYNOPSIS
    Represents an activity log of entity DEVICE, category remote, and action chat, which includes specific properties related to remote chat session activities.
.DESCRIPTION
    The DRMMActivityLogDetailsDeviceRemoteChat class models the details of a remote chat session activity log entry. It inherits common remote session properties from DRMMActivityLogDetailsDeviceRemote. Currently, chat actions share all base properties with no unique properties identified, but this class allows for future expansion if chat-specific properties are discovered.
#>
class DRMMActivityLogDetailsDeviceRemoteChat : DRMMActivityLogDetailsDeviceRemote {

    DRMMActivityLogDetailsDeviceRemoteChat() : base() {

    }

    static [DRMMActivityLogDetailsDeviceRemoteChat] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsDeviceRemoteChat]::new()

        # Populate base properties
        [DRMMActivityLogDetailsDeviceRemote]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # No chat-specific properties identified yet

        return $Details

    }
}

<#
.SYNOPSIS
    Represents an activity log of entity DEVICE, category remote, and action jrto (Jump Remote Take Over), which includes specific properties related to JRTO session activities.
.DESCRIPTION
    The DRMMActivityLogDetailsDeviceRemoteJrto class models the details of a Jump Remote Take Over (jrto) activity log entry. It inherits common remote session properties from DRMMActivityLogDetailsDeviceRemote. Currently, jrto actions share all base properties with no unique properties identified, but this class allows for future expansion if jrto-specific properties are discovered.
#>
class DRMMActivityLogDetailsDeviceRemoteJrto : DRMMActivityLogDetailsDeviceRemote {

    DRMMActivityLogDetailsDeviceRemoteJrto() : base() {

    }

    static [DRMMActivityLogDetailsDeviceRemoteJrto] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsDeviceRemoteJrto]::new()

        # Populate base properties
        [DRMMActivityLogDetailsDeviceRemote]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # No jrto-specific properties identified yet

        return $Details

    }
}

<#
.SYNOPSIS
    Base class for DEVICE device-related activity log details, containing properties common to all device actions.
.DESCRIPTION
    The DRMMActivityLogDetailsDeviceDevice class serves as a base class for DEVICE entity device category activity logs. It encapsulates properties that are common across different device actions (move, etc.), including source forwarding information, in addition to the entity-level DEVICE properties inherited from DRMMActivityLogEntityDevice. Specific device action types inherit from this class and add their unique properties.
#>
class DRMMActivityLogDetailsDeviceDevice : DRMMActivityLogEntityDevice {

    [string]$SourceForwardedIp

    DRMMActivityLogDetailsDeviceDevice() : base() {

    }

    static [void] PopulateCategoryProperties([DRMMActivityLogDetailsDeviceDevice]$Details, [hashtable]$ActivityLogDetail) {

        # Populate entity-level properties
        [DRMMActivityLogEntityDevice]::PopulateEntityProperties($Details, $ActivityLogDetail)

        # Populate device category properties
        $Details.SourceForwardedIp = $ActivityLogDetail.'source.forwarded_ip'

    }
}

<#
.SYNOPSIS
    Represents a generic DEVICE device activity log details for unknown device actions, with base properties and dynamic additional properties.
.DESCRIPTION
    The DRMMActivityLogDetailsDeviceDeviceGeneric class is used for DEVICE entity device category activity logs where the specific action is not yet mapped to a dedicated class. It inherits the 7 base properties common to all DEVICE device activities and dynamically adds any additional properties found in the response that are not part of the base class. This ensures type safety for known properties while maintaining flexibility for unknown actions.
#>
class DRMMActivityLogDetailsDeviceDeviceGeneric : DRMMActivityLogDetailsDeviceDevice {

    DRMMActivityLogDetailsDeviceDeviceGeneric() : base() {

    }

    static [DRMMActivityLogDetailsDeviceDeviceGeneric] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        if ($null -eq $ActivityLogDetail) {

            return $null

        }

        $Details = [DRMMActivityLogDetailsDeviceDeviceGeneric]::new()

        # Populate base properties
        [DRMMActivityLogDetailsDeviceDevice]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Define base property keys to exclude from dynamic properties
        $BasePropertyKeys = @(
            'device.hostname', 'device.uid', 'entity', 'event.action', 'event.category', 'uid',
            'source.forwarded_ip'
        )

        # Add any additional properties not in the base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($BasePropertyKeys -contains $Key) {

                continue

            }

            if ($Key -match 'date' -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $DateResult = [DRMMObject]::ParseApiDate($ActivityLogDetail[$Key])
                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $DateResult.DateTime

                } catch {

                    # If date parsing fails, add the original value
                    Write-Debug "Failed to parse date property '$Key' with value '$($ActivityLogDetail[$Key])'"
                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $ActivityLogDetail[$Key]

                }

            } else {

                $Details | Add-Member -NotePropertyName $Key -NotePropertyValue $ActivityLogDetail[$Key]

            }
        }

        return $Details

    }
}

<#
.SYNOPSIS
    Represents an activity log of entity DEVICE, category device, and action move.device, which includes specific properties related to device site movement activities.
.DESCRIPTION
    The DRMMActivityLogDetailsDeviceDeviceMoveDevice class models the details of a device site movement activity log entry. It inherits common device properties from DRMMActivityLogDetailsDeviceDevice and adds movement-specific properties including source and destination site information (IDs, names, UIDs), site name, and user information (email, first name, last name, username, user ID) related to the device move operation.
#>
class DRMMActivityLogDetailsDeviceDeviceMoveDevice : DRMMActivityLogDetailsDeviceDevice {

    [long]$DataFromSiteId
    [string]$DataFromSiteName
    [guid]$DataFromSiteUid
    [long]$DataToSiteId
    [string]$DataToSiteName
    [guid]$DataToSiteUid
    [string]$SiteName
    [string]$UserEmail
    [string]$UserFirstName
    [long]$UserId
    [string]$UserLastName
    [string]$UserUsername

    DRMMActivityLogDetailsDeviceDeviceMoveDevice() : base() {

    }

    static [DRMMActivityLogDetailsDeviceDeviceMoveDevice] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsDeviceDeviceMoveDevice]::new()

        # Populate base properties
        [DRMMActivityLogDetailsDeviceDevice]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Populate move.device-specific properties
        $Details.DataFromSiteId = $ActivityLogDetail.'data.from_site_id'
        $Details.DataFromSiteName = $ActivityLogDetail.'data.from_site_name'
        $Details.DataFromSiteUid = $ActivityLogDetail.'data.from_site_uid'
        $Details.DataToSiteId = $ActivityLogDetail.'data.to_site_id'
        $Details.DataToSiteName = $ActivityLogDetail.'data.to_site_name'
        $Details.DataToSiteUid = $ActivityLogDetail.'data.to_site_uid'
        $Details.SiteName = $ActivityLogDetail.'site.name'
        $Details.UserEmail = $ActivityLogDetail.'user.email'
        $Details.UserFirstName = $ActivityLogDetail.'user.firstname'
        $Details.UserId = $ActivityLogDetail.'user.id'
        $Details.UserLastName = $ActivityLogDetail.'user.lastname'
        $Details.UserUsername = $ActivityLogDetail.'user.username'

        return $Details

    }
}

<#
.SYNOPSIS
    Represents site information associated with a DRMM activity log entry, including site ID and name.
.DESCRIPTION
    The DRMMActivityLogSite class models the site information related to an activity log entry in the DRMM platform. It encapsulates properties such as the site ID and name. The class provides a static method to create an instance of the class from a typical API response object that contains these site details. This class is used as a property within the DRMMActivityLog class to provide additional context about the site associated with the activity log entry.
#>
class DRMMActivityLogSite : DRMMObject {

    [long]$Id
    [string]$Name

    DRMMActivityLogSite() : base() {

    }

    static [DRMMActivityLogSite] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Site = [DRMMActivityLogSite]::new()
        $Site.Id = $Response.id
        $Site.Name = $Response.name

        return $Site

    }
}

<#
.SYNOPSIS
    Represents user information associated with a DRMM activity log entry, including user ID, username, and name details.
.DESCRIPTION
    The DRMMActivityLogUser class models the user information related to an activity log entry in the DRMM platform. It encapsulates properties such as the user ID, username, first name, and last name. The class provides a static method to create an instance of the class from a typical API response object that contains these user details. Additionally, it includes a method to generate a summary string that combines the user's first name, last name, and username for easy display in contexts where user information is relevant.
#>
class DRMMActivityLogUser : DRMMObject {

    [long]$Id
    [string]$UserName
    [string]$FirstName
    [string]$LastName

    DRMMActivityLogUser() : base() {

    }

    static [DRMMActivityLogUser] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $User = [DRMMActivityLogUser]::new()
        $User.Id = $Response.id
        $User.UserName = $Response.userName
        $User.FirstName = $Response.firstName
        $User.LastName = $Response.lastName

        return $User

    }

    <#
    .SYNOPSIS
        Generates a summary string for the user, including their first name, last name, and username.
    .DESCRIPTION
        The GetSummary method creates a concise summary of the user information by combining the first name, last name, and username. If the first name and last name are available, it formats them as "FirstName LastName (Username)". If only the username is available, it returns just the username. If neither is available, it returns a string with the user ID. This summary is used in contexts where user information is relevant, such as in activity log summaries.
    #>
    [string] GetSummary() {

        if ($this.FirstName -and $this.LastName) {

            return "$($this.FirstName) $($this.LastName) ($($this.UserName))"

        } elseif ($this.UserName) {

            return $this.UserName

        } else {

            return "User $($this.Id)"

        }
    }
}
#endregion DRMMActivityLog and related classes

#region DRMMAlert and related classes
<#
.SYNOPSIS
    Represents an alert in the DRMM system, including its properties, context, source information, and response actions.
.DESCRIPTION
    The DRMMAlert class models an alert within the DRMM platform, encapsulating properties such as the alert's unique identifier, priority, diagnostics, resolution status, ticket number, timestamp, and related information about the alert monitor, context, source, and response actions. It provides a static method to create an instance of the class from a typical API response object that contains alert information. The class also includes methods to determine if the alert is open or of certain priority levels, to resolve the alert, and to generate a summary string that combines key properties of the alert for easy display. The related classes DRMMAlertContext, DRMMAlertMonitorInfo, DRMMAlertSourceInfo, and DRMMAlertResponseAction represent nested information about the alert's context, monitoring configuration, source details, and response actions taken, respectively.
#>
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
    [DRMMAlertResponseAction[]]$ResponseActions
    [Nullable[int]]$AutoresolveMins
    [string]$PortalUrl

    DRMMAlert() : base() {

    }

    static [DRMMAlert] FromAPIMethod([pscustomobject]$Response, [string]$Platform) {

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
        $Alert.PortalUrl = "https://$($Platform.ToLower()).rmm.datto.com/alert/$($Alert.AlertUid)"

        $Alert.AlertMonitorInfo = [DRMMAlertMonitorInfo]::FromAPIMethod($Response.alertMonitorInfo)
        $Alert.AlertContext = [DRMMAlertContext]::FromAPIMethod($Response.alertContext)
        $Alert.AlertSourceInfo = [DRMMAlertSourceInfo]::FromAPIMethod($Response.alertSourceInfo)

        if ($null -ne $Response.responseActions) {

            $Alert.ResponseActions = $Response.responseActions | ForEach-Object {

                [DRMMAlertResponseAction]::FromAPIMethod($_)
                
            }
        }

        $ResolvedDate = [DRMMObject]::ParseApiDate($Response.resolvedOn)
        $Alert.ResolvedOn = $ResolvedDate.DateTime
        $TimestampDate = [DRMMObject]::ParseApiDate($Response.timestamp)
        $Alert.Timestamp = $TimestampDate.DateTime

        return $Alert

    }

    <#
    .SYNOPSIS
        Determines if the alert is currently open (not resolved).
    .DESCRIPTION
        The IsOpen method checks the Resolved property of the alert to determine if it is currently open.
    #>
    [bool] IsOpen() {return (-not $this.Resolved)}

    <#
    .SYNOPSIS
        Determines if the alert is of priority level "Critical".
    .DESCRIPTION
        The IsCritical method checks the Priority property of the alert to determine if it is classified as "Critical".
    #>
    [bool] IsCritical() {return ($this.Priority -eq 'Critical')}

    <#
    .SYNOPSIS
        Determines if the alert is of priority level "High".
    .DESCRIPTION
        The IsHigh method checks the Priority property of the alert to determine if it is classified as "High".
    #>
    [bool] IsHigh() {return ($this.Priority -eq 'High')}

    <#
    .SYNOPSIS
        Resolves the alert.
    .DESCRIPTION
        The Resolve method marks the alert as resolved by calling the Resolve-RMMAlert cmdlet with the alert's unique identifier.
    #>
    [void] Resolve() {
        
        if (-not $this.AlertUid) {

            throw "Alert does not have a valid AlertUid"
            
        }

        Resolve-RMMAlert -AlertUid $this.AlertUid

    }

    <#
    .SYNOPSIS
        Gets a summary of the alert.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the alert's status, priority, device name, monitor category, and description.
    #>
    [string] GetSummary() {

        $StatusValue = if ($this.Resolved) {'Resolved'} else {'Open'}
        $MutedValue = if ($this.Muted) {' (Muted)'} else {''}
        $DeviceName = if ($this.AlertSourceInfo.DeviceName) {$this.AlertSourceInfo.DeviceName} else {'Unknown'}
        $MonitorCategory = if ($this.AlertMonitorInfo.Category) {$this.AlertMonitorInfo.Category} else {'Unknown'}
        $MonitorDesc = if ($this.AlertMonitorInfo.Description) {$this.AlertMonitorInfo.Description} else {'No description'}

        return "[$StatusValue$MutedValue] $($this.Priority) - $DeviceName - $MonitorCategory`: $MonitorDesc"

    }

    <#
    .SYNOPSIS
        Opens the alert's portal URL in the default web browser.
    .DESCRIPTION
        The OpenPortal method launches the portal URL associated with the alert using the default web browser.
    #>
    [void] OpenPortal() {

        if ($this.PortalUrl) {
        
            Start-Process $this.PortalUrl

        } else {
        
            throw "Alert does not have a valid PortalUrl"

        }
    }
}

<#
.SYNOPSIS
    Represents the context of an alert in the DRMM system, including its class and specific details based on the type of alert.
.DESCRIPTION
    The DRMMAlertContext class models the context information associated with an alert in the DRMM platform. It includes a property for the class of the context, which indicates the type of alert context (e.g., antivirus, backup management, etc.). The class provides a static method to create an instance of the appropriate context subclass based on the '@class' property in the API response. If the '@class' property is not present or does not match known types, it defaults to creating an instance of DRMMAlertContextGeneric. Each specific context type (e.g., DRMMAlertContextAntivirus, DRMMAlertContextBackupManagement) has its own properties and parsing logic to capture relevant details for that type of alert context.
#>
class DRMMAlertContext : DRMMObject {

    [string]$Class

    DRMMAlertContext() : base() {

    }

    <#
    .SYNOPSIS
        Gets a summary of the alert context.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the alert context by including the class of the context. This provides a quick overview of the type of context associated with the alert, which can be useful for display purposes and when examining the alert's details in a list or summary view.
    #>
    [string] GetSummary() {

        return $this.Class

    }

    static [object] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $ClassValue = $Response.'@class'

        if ($null -eq $ClassValue) {

            # Return generic context if no @class
            return [DRMMAlertContextGeneric]::FromAPIMethod($Response)

        }

        # Map @class values to specific context classes
        $Result = switch -Regex ($ClassValue) {

            '^online_offline_status_ctx$' { [DRMMAlertContextOnlineOfflineStatus]::FromAPIMethod($Response) }
            '^ransomware_ctx$' { [DRMMAlertContextRansomWare]::FromAPIMethod($Response) }
            '^eventlog_ctx$' { [DRMMAlertContextEventLog]::FromAPIMethod($Response) }
            '^comp_script_ctx' { [DRMMAlertContextScript]::FromAPIMethod($Response) }
            '^antivirus_ctx$' { [DRMMAlertContextAntivirus]::FromAPIMethod($Response) }
            '^backup_management_ctx$' { [DRMMAlertContextBackupManagement]::FromAPIMethod($Response) }
            '^custom_snmp_ctx$' { [DRMMAlertContextCustomSNMP]::FromAPIMethod($Response) }
            '^disk_health_ctx$' { [DRMMAlertContextDiskHealth]::FromAPIMethod($Response) }
            '^disk_usage_ctx$' { [DRMMAlertContextDiskUsage]::FromAPIMethod($Response) }
            '^endpoint_security_threat_ctx$' { [DRMMAlertContextEndpointSecurityThreat]::FromAPIMethod($Response) }
            '^endpoint_security_windows_defender_ctx$' { [DRMMAlertContextEndpointSecurityWindowsDefender]::FromAPIMethod($Response) }
            '^fan_ctx$' { [DRMMAlertContextFan]::FromAPIMethod($Response) }
            '^filesystem_ctx$' { [DRMMAlertContextFileSystem]::FromAPIMethod($Response) }
            '^network_monitor_ctx$' { [DRMMAlertContextNetworkMonitor]::FromAPIMethod($Response) }
            '^patch_ctx$' { [DRMMAlertContextPatch]::FromAPIMethod($Response) }
            '^ping_ctx$' { [DRMMAlertContextPing]::FromAPIMethod($Response) }
            '^printer_ctx$' { [DRMMAlertContextPrinter]::FromAPIMethod($Response) }
            '^psu_ctx$' { [DRMMAlertContextPsu]::FromAPIMethod($Response) }
            '^resource_usage_ctx$' { [DRMMAlertContextResourceUsage]::FromAPIMethod($Response) }
            '^snmp_probe_ctx$' { [DRMMAlertContextSNMPProbe]::FromAPIMethod($Response) }
            '^seccenter_ctx$' { [DRMMAlertContextSecCenter]::FromAPIMethod($Response) }
            '^security_management_ctx$' { [DRMMAlertContextSecurityManagement]::FromAPIMethod($Response) }
            '^status_ctx$' { [DRMMAlertContextStatus]::FromAPIMethod($Response) }
            '^temperature_ctx$' { [DRMMAlertContextTemperature]::FromAPIMethod($Response) }
            '^windows_performance_ctx$' { [DRMMAlertContextWindowsPerformance]::FromAPIMethod($Response) }
            '^wmi_ctx$' { [DRMMAlertContextWmi]::FromAPIMethod($Response) }
            default { [DRMMAlertContextGeneric]::FromAPIMethod($Response) }

        }

        return $Result

    }
}

<#
.SYNOPSIS
    Represents a generic alert context in the DRMM system when specific context class information is not available.
.DESCRIPTION
    The DRMMAlertContextGeneric class models a generic alert context for cases where the specific context class information is not available or does not match known types. It captures the raw response data and provides a summary that includes the class if available. This allows for handling of alert contexts that may not fit into predefined categories while still retaining the original information for reference.
#>
class DRMMAlertContextAntivirus : DRMMAlertContext {

    [string]$Status
    [string]$ProductName

    DRMMAlertContextAntivirus() : base() {

    }

    static [DRMMAlertContextAntivirus] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextAntivirus]::new()
        $Context.Class = $Response.'@class'
        $Context.Status = $Response.status
        $Context.ProductName = $Response.productName

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a backup management alert in the DRMM system, including error messages and timeout information.
.DESCRIPTION
    The DRMMAlertContextBackupManagement class models the context information specific to backup management alerts in the DRMM platform. It encapsulates properties such as error messages and timeout values that are relevant to backup management scenarios.
#>
class DRMMAlertContextBackupManagement : DRMMAlertContext {

    [string]$ErrorMessage
    [int]$Timeout

    DRMMAlertContextBackupManagement() : base() {

    }

    static [DRMMAlertContextBackupManagement] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextBackupManagement]::new()
        $Context.Class = $Response.'@class'
        $Context.ErrorMessage = $Response.errorMessage
        $Context.Timeout = $Response.timeout

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a custom SNMP alert in the DRMM system, including display name, current value, and monitor instance information.
.DESCRIPTION
    The DRMMAlertContextCustomSNMP class models the context information specific to custom SNMP alerts in the DRMM platform. It encapsulates properties such as the display name of the alert, the current value that triggered the alert, and the monitor instance associated with the alert.
#>
class DRMMAlertContextCustomSNMP : DRMMAlertContext {

    [string]$DisplayName
    [string]$CurrentValue
    [string]$MonitorInstance

    DRMMAlertContextCustomSNMP() : base() {

    }

    static [DRMMAlertContextCustomSNMP] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextCustomSNMP]::new()
        $Context.Class = $Response.'@class'
        $Context.DisplayName = $Response.displayName
        $Context.CurrentValue = $Response.currentValue
        $Context.MonitorInstance = $Response.monitorInstance

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a disk health alert in the DRMM system, including the reason for the alert and the type of issue detected.
.DESCRIPTION
    The DRMMAlertContextDiskHealth class models the context information specific to disk health alerts in the DRMM platform. It encapsulates properties such as the reason for the alert and the type of disk health issue that was detected, providing insights into the underlying cause of the alert.
#>
class DRMMAlertContextDiskHealth : DRMMAlertContext {

    [string]$Reason
    [string]$Type

    DRMMAlertContextDiskHealth() : base() {

    }

    static [DRMMAlertContextDiskHealth] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextDiskHealth]::new()
        $Context.Class = $Response.'@class'
        $Context.Reason = $Response.reason
        $Context.Type = $Response.type

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a disk usage alert in the DRMM system, including details about the disk, total volume, free space, and unit of measure.
.DESCRIPTION
    The DRMMAlertContextDiskUsage class models the context information specific to disk usage alerts in the DRMM platform. It encapsulates properties such as the name of the disk, total volume, free space, unit of measure, and disk name designation. This information provides insights into the disk usage conditions that triggered the alert, allowing for better understanding and response to disk-related issues.
#>
class DRMMAlertContextDiskUsage : DRMMAlertContext {

    [string]$DiskName
    [float]$TotalVolume
    [float]$FreeSpace
    [string]$UnitOfMeasure
    [string]$DiskNameDesignation

    DRMMAlertContextDiskUsage() : base() {

    }

    static [DRMMAlertContextDiskUsage] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextDiskUsage]::new()
        $Context.Class = $Response.'@class'
        $Context.DiskName = $Response.diskName
        $Context.TotalVolume = $Response.totalVolume
        $Context.FreeSpace = $Response.freeSpace
        $Context.UnitOfMeasure = $Response.unitOfMeasure
        $Context.DiskNameDesignation = $Response.diskNameDesignation

        return $Context

    }
}

<##
.SYNOPSIS
    Represents the context of an endpoint security threat alert in the DRMM system, including alert ID and description.
.DESCRIPTION
    The DRMMAlertContextEndpointSecurityThreat class models the context information specific to endpoint security threat alerts in the DRMM platform. It encapsulates properties such as the alert ID and a description of the threat, providing detailed information about the security event that triggered the alert.
#>
class DRMMAlertContextEndpointSecurityThreat : DRMMAlertContext {

    [string]$EsAlertId
    [string]$Description

    DRMMAlertContextEndpointSecurityThreat() : base() {

    }

    static [DRMMAlertContextEndpointSecurityThreat] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextEndpointSecurityThreat]::new()
        $Context.Class = $Response.'@class'
        $Context.EsAlertId = $Response.esAlertId
        $Context.Description = $Response.description

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of an endpoint security Windows Defender alert in the DRMM system, including alert ID and description.
.DESCRIPTION
    The DRMMAlertContextEndpointSecurityWindowsDefender class models the context information specific to endpoint security Windows Defender alerts in the DRMM platform. It encapsulates properties such as the alert ID and a description of the threat, providing detailed information about the security event that triggered the alert.
#>
class DRMMAlertContextEndpointSecurityWindowsDefender : DRMMAlertContext {

    [string]$EsAlertId
    [string]$Description

    DRMMAlertContextEndpointSecurityWindowsDefender() : base() {

    }

    static [DRMMAlertContextEndpointSecurityWindowsDefender] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextEndpointSecurityWindowsDefender]::new()
        $Context.Class = $Response.'@class'
        $Context.EsAlertId = $Response.esAlertId
        $Context.Description = $Response.description

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of an event log alert in the DRMM system, including log name, code, type, source, description, trigger count, last triggered time, and suspension status.
.DESCRIPTION
    The DRMMAlertContextEventLog class models the context information specific to event log alerts in the DRMM platform. It encapsulates properties such as the log name, code, type, source, description, trigger count, last triggered time, and whether the event caused a suspension. This information provides detailed insights into the event log conditions that triggered the alert, facilitating better understanding and response to event log-related issues.
#>
class DRMMAlertContextEventLog : DRMMAlertContext {

    [string]$LogName
    [string]$Code
    [string]$Type
    [string]$Source
    [string]$Description
    [int]$TriggerCount
    [Nullable[datetime]]$LastTriggered
    [bool]$CausedSuspension

    DRMMAlertContextEventLog() : base() {

    }

    static [DRMMAlertContextEventLog] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextEventLog]::new()
        $Context.Class = $Response.'@class'
        $Context.LogName = $Response.logName
        $Context.Code = $Response.code
        $Context.Type = $Response.type
        $Context.Source = $Response.source
        $Context.Description = $Response.description
        $Context.TriggerCount = $Response.triggerCount
        $Context.LastTriggered = ([DRMMObject]::ParseApiDate($Response.lastTriggered)).DateTime
        $Context.CausedSuspension = $Response.causedSuspension

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a fan alert in the DRMM system, including reason and type.
.DESCRIPTION
    The DRMMAlertContextFan class models the context information specific to fan alerts in the DRMM platform. It encapsulates properties such as the reason for the alert and the type of fan issue, providing detailed information about the hardware event that triggered the alert.
#>
class DRMMAlertContextFan : DRMMAlertContext {

    [string]$Reason
    [string]$Type

    DRMMAlertContextFan() : base() {

    }

    static [DRMMAlertContextFan] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextFan]::new()
        $Context.Class = $Response.'@class'
        $Context.Reason = $Response.reason
        $Context.Type = $Response.type

        return $Context

    }
}


<#
.SYNOPSIS
    Represents the context of a file system alert in the DRMM system, including sample value, threshold, path, object type, and condition.
.DESCRIPTION
    The DRMMAlertContextFileSystem class models the context information specific to file system alerts in the DRMM platform. It encapsulates properties such as a sample value that triggered the alert, the threshold that was exceeded, the path of the file or directory involved, the type of object (file or directory), and the condition that caused the alert. This information provides detailed insights into the file system conditions that triggered the alert, facilitating better understanding and response to file system-related issues.
#>
class DRMMAlertContextFileSystem : DRMMAlertContext {

    [float]$Sample
    [float]$Threshold
    [string]$Path
    [string]$ObjectType
    [string]$Condition

    DRMMAlertContextFileSystem() : base() {

    }

    static [DRMMAlertContextFileSystem] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextFileSystem]::new()
        $Context.Class = $Response.'@class'
        $Context.Sample = $Response.sample
        $Context.Threshold = $Response.threshold
        $Context.Path = $Response.path
        $Context.ObjectType = $Response.objectType
        $Context.Condition = $Response.condition

        return $Context

    }
}

<#
.SYNOPSIS
    Represents a generic alert context in the DRMM system when specific context class information is not available.
.DESCRIPTION
    The DRMMAlertContextGeneric class models a generic alert context in the DRMM platform. It is used when specific context class information is not available, encapsulating a hashtable of properties that provide detailed information about the alert context. This allows for flexible handling of various alert types that do not have dedicated context classes.
#>
class DRMMAlertContextGeneric : DRMMAlertContext {

    [hashtable]$Properties

    DRMMAlertContextGeneric() : base() {

    }

    static [DRMMAlertContextGeneric] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextGeneric]::new()
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
}

<#
.SYNOPSIS
    Represents the context of a network monitor alert in the DRMM system, including a description of the alert.
.DESCRIPTION
    The DRMMAlertContextNetworkMonitor class models the context information specific to network monitor alerts in the DRMM platform. It encapsulates a description property that provides detailed information about the network event that triggered the alert.
#>
class DRMMAlertContextNetworkMonitor : DRMMAlertContext {

    [string]$Description

    DRMMAlertContextNetworkMonitor() : base() {

    }

    static [DRMMAlertContextNetworkMonitor] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextNetworkMonitor]::new()
        $Context.Class = $Response.'@class'
        $Context.Description = $Response.description

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of an online/offline status alert in the DRMM system, including the current status.
.DESCRIPTION
    The DRMMAlertContextOnlineOfflineStatus class models the context information specific to online/offline status alerts in the DRMM platform. It encapsulates a status property that indicates the current online or offline state associated with the alert.
#>
class DRMMAlertContextOnlineOfflineStatus : DRMMAlertContext {

    [string]$Status

    DRMMAlertContextOnlineOfflineStatus() : base() {

    }

    static [DRMMAlertContextOnlineOfflineStatus] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextOnlineOfflineStatus]::new()
        $Context.Class = $Response.'@class'
        $Context.Status = $Response.status

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a patch alert in the DRMM system, including patch UID, policy UID, result, and additional information.
.DESCRIPTION
    The DRMMAlertContextPatch class models the context information specific to patch alerts in the DRMM platform. It encapsulates properties such as patch UID, policy UID, result, and additional information that provide detailed context about the patch alert.
#>
class DRMMAlertContextPatch : DRMMAlertContext {

    [string]$PatchUid
    [string]$PolicyUid
    [string]$Result
    [string]$Info

    DRMMAlertContextPatch() : base() {

    }

    static [DRMMAlertContextPatch] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextPatch]::new()
        $Context.Class = $Response.'@class'
        $Context.PatchUid = $Response.patchUid
        $Context.PolicyUid = $Response.policyUid
        $Context.Result = $Response.result
        $Context.Info = $Response.info

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a ping alert in the DRMM system, including instance name, roundtrip time, and reasons for the alert.
.DESCRIPTION
    The DRMMAlertContextPing class models the context information specific to ping alerts in the DRMM platform. It encapsulates properties such as instance name, roundtrip time, and reasons that provide detailed context about the ping alert.
#>
class DRMMAlertContextPing : DRMMAlertContext {

    [string]$InstanceName
    [int]$RoundtripTime
    [string[]]$Reasons

    DRMMAlertContextPing() : base() {

    }

    static [DRMMAlertContextPing] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextPing]::new()
        $Context.Class = $Response.'@class'
        $Context.InstanceName = $Response.instanceName
        $Context.RoundtripTime = $Response.roundtripTime
        $Context.Reasons = $Response.reasons

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a printer alert in the DRMM system, including IP address, MAC address, marker supply index, and current level.
.DESCRIPTION
    The DRMMAlertContextPrinter class models the context information specific to printer alerts in the DRMM platform. It encapsulates properties such as IP address, MAC address, marker supply index, and current level that provide detailed context about the printer alert.
#>
class DRMMAlertContextPrinter : DRMMAlertContext {

    [string]$IpAddress
    [string]$MacAddress
    [int]$MarkerSupplyIndex
    [int]$CurrentLevel

    DRMMAlertContextPrinter() : base() {

    }

    static [DRMMAlertContextPrinter] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextPrinter]::new()
        $Context.Class = $Response.'@class'
        $Context.IpAddress = $Response.ipAddress
        $Context.MacAddress = $Response.macAddress
        $Context.MarkerSupplyIndex = $Response.markerSupplyIndex
        $Context.CurrentLevel = $Response.currentLevel

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a PSU (Power Supply Unit) alert in the DRMM system, including reason and type of the alert.
.DESCRIPTION
    The DRMMAlertContextPsu class models the context information specific to PSU alerts in the DRMM platform. It encapsulates properties such as reason and type that provide detailed context about the PSU alert.
#>
class DRMMAlertContextPsu : DRMMAlertContext {

    [string]$Reason
    [string]$Type

    DRMMAlertContextPsu() : base() {

    }

    static [DRMMAlertContextPsu] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextPsu]::new()
        $Context.Class = $Response.'@class'
        $Context.Reason = $Response.reason
        $Context.Type = $Response.type

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a ransomware alert in the DRMM system, including state, confidence factor, affected directories, watch paths, ransomware extension, and alert times.
.DESCRIPTION
    The DRMMAlertContextRansomWare class models the context information specific to ransomware alerts in the DRMM platform. It encapsulates properties such as state, confidence factor, affected directories, watch paths, ransomware extension, and alert times that provide detailed context about the ransomware alert.
#>
class DRMMAlertContextRansomWare : DRMMAlertContext {

    [int]$State
    [int]$ConfidenceFactor
    [string[]]$AffectedDirectories
    [string[]]$WatchPaths
    [string]$Rwextension
    [Nullable[datetime]]$MetaAlertTime
    [Nullable[datetime]]$AlertTime

    DRMMAlertContextRansomWare() : base() {

    }

    static [DRMMAlertContextRansomWare] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextRansomWare]::new()
        $Context.Class = $Response.'@class'
        $Context.State = $Response.state
        $Context.ConfidenceFactor = $Response.confidenceFactor
        $Context.AffectedDirectories = $Response.affectedDirectories
        $Context.WatchPaths = $Response.watchPaths
        $Context.Rwextension = $Response.rwextension
        $Context.MetaAlertTime = ([DRMMObject]::ParseApiDate($Response.metaAlertTime)).DateTime
        $Context.AlertTime = ([DRMMObject]::ParseApiDate($Response.alertTime)).DateTime

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a resource usage alert in the DRMM system, including process name, sample value, and type of resource.
.DESCRIPTION
    The DRMMAlertContextResourceUsage class models the context information specific to resource usage alerts in the DRMM platform. It encapsulates properties such as process name, sample value, and type that provide detailed context about the resource usage alert.
#>
class DRMMAlertContextResourceUsage : DRMMAlertContext {

    [string]$ProcessName
    [float]$Sample
    [string]$Type

    DRMMAlertContextResourceUsage() : base() {

    }

    static [DRMMAlertContextResourceUsage] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextResourceUsage]::new()
        $Context.Class = $Response.'@class'
        $Context.ProcessName = $Response.processName
        $Context.Sample = $Response.sample
        $Context.Type = $Response.type

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a script alert in the DRMM system, including a hashtable of sample values.
.DESCRIPTION
    The DRMMAlertContextScript class models the context information specific to script alerts in the DRMM platform. It encapsulates properties such as a hashtable of sample values that provide detailed context about the script alert.
#>
class DRMMAlertContextScript : DRMMAlertContext {

    [hashtable]$Samples

    DRMMAlertContextScript() : base() {

    }

    static [DRMMAlertContextScript] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextScript]::new()
        $Context.Class = $Response.'@class'
        
        $SamplesData = $Response.samples
        if ($null -ne $SamplesData) {

            $Context.Samples = @{}
            foreach ($Property in $SamplesData.PSObject.Properties) {

                $Context.Samples[$Property.Name] = $Property.Value

            }
        }

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a security center alert in the DRMM system, including product name and alert type.
.DESCRIPTION
    The DRMMAlertContextSecCenter class models the context information specific to security center alerts in the DRMM platform. It encapsulates properties such as product name and alert type that provide detailed context about the security center alert.
#>
class DRMMAlertContextSecCenter : DRMMAlertContext {

    [string]$ProductName
    [string]$AlertType

    DRMMAlertContextSecCenter() : base() {

    }

    static [DRMMAlertContextSecCenter] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextSecCenter]::new()
        $Context.Class = $Response.'@class'
        $Context.ProductName = $Response.productName
        $Context.AlertType = $Response.alertType

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a security management alert in the DRMM system, including status, product name, information time, virus name, infected files, and other related properties.
.DESCRIPTION
    The DRMMAlertContextSecurityManagement class models the context information specific to security management alerts in the DRMM platform. It encapsulates properties such as status, product name, information time, virus name, infected files, and other related properties that provide detailed context about the security management alert.
#>
class DRMMAlertContextSecurityManagement : DRMMAlertContext {

    [int]$Status
    [string]$ProductName
    [int]$InfoTime
    [string]$VirusName
    [string[]]$InfectedFiles
    [int]$ProductNotUpdatedForDays
    [int]$SystemRemainsInfectedForHours
    [int]$ExpiryLicenseForDays

    DRMMAlertContextSecurityManagement() : base() {

    }

    static [DRMMAlertContextSecurityManagement] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextSecurityManagement]::new()
        $Context.Class = $Response.'@class'
        $Context.Status = $Response.status
        $Context.ProductName = $Response.productName
        $Context.InfoTime = $Response.infoTime
        $Context.VirusName = $Response.virusName
        $Context.InfectedFiles = $Response.infectedFiles
        $Context.ProductNotUpdatedForDays = $Response.productNotUpdatedForDays
        $Context.SystemRemainsInfectedForHours = $Response.systemRemainsInfectedForHours
        $Context.ExpiryLicenseForDays = $Response.expiryLicenseForDays

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of an SNMP probe alert in the DRMM system, including IP address, OID, rule name, response value, device name, and monitor name.
.DESCRIPTION
    The DRMMAlertContextSNMPProbe class models the context information specific to SNMP probe alerts in the DRMM platform. It encapsulates properties such as IP address, OID, rule name, response value, device name, and monitor name that provide detailed context about the SNMP probe alert.
#>
class DRMMAlertContextSNMPProbe : DRMMAlertContext {

    [string]$IpAddress
    [string]$Oid
    [string]$RuleName
    [string]$ResponseValue
    [string]$DeviceName
    [string]$MonitorName

    DRMMAlertContextSNMPProbe() : base() {

    }

    static [DRMMAlertContextSNMPProbe] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextSNMPProbe]::new()
        $Context.Class = $Response.'@class'
        $Context.IpAddress = $Response.ipAddress
        $Context.OID = $Response.OID
        $Context.RuleName = $Response.ruleName
        $Context.ResponseValue = $Response.responseValue
        $Context.DeviceName = $Response.deviceName
        $Context.MonitorName = $Response.monitorName
        $Context.Oid = $Response.oid

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a status alert in the DRMM system, including process name and status information.
.DESCRIPTION
    The DRMMAlertContextStatus class models the context information specific to status alerts in the DRMM platform. It encapsulates properties such as process name and status that provide detailed context about the status alert.
#>
class DRMMAlertContextStatus : DRMMAlertContext {

    [string]$ProcessName
    [string]$Status

    DRMMAlertContextStatus() : base() {

    }

    static [DRMMAlertContextStatus] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextStatus]::new()
        $Context.Class = $Response.'@class'
        $Context.ProcessName = $Response.processName
        $Context.Status = $Response.status

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a temperature alert in the DRMM system, including degree and type of temperature issue.
.DESCRIPTION
    The DRMMAlertContextTemperature class models the context information specific to temperature alerts in the DRMM platform. It encapsulates properties such as degree and type that provide detailed context about the temperature alert.
#>
class DRMMAlertContextTemperature : DRMMAlertContext {

    [float]$Degree
    [string]$Type

    DRMMAlertContextTemperature() : base() {

    }

    static [DRMMAlertContextTemperature] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextTemperature]::new()
        $Context.Class = $Response.'@class'
        $Context.Degree = $Response.degree
        $Context.Type = $Response.type

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a Windows performance alert in the DRMM system, including a value that indicates the performance metric.
.DESCRIPTION
    The DRMMAlertContextWindowsPerformance class models the context information specific to Windows performance alerts in the DRMM platform. It encapsulates properties such as value that provide detailed context about the Windows performance alert.
#>
class DRMMAlertContextWindowsPerformance : DRMMAlertContext {

    [float]$Value

    DRMMAlertContextWindowsPerformance() : base() {

    }

    static [DRMMAlertContextWindowsPerformance] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextWindowsPerformance]::new()
        $Context.Class = $Response.'@class'
        $Context.Value = $Response.value

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of a WMI alert in the DRMM system, including a value that indicates the WMI metric or status.
.DESCRIPTION
    The DRMMAlertContextWmi class models the context information specific to WMI alerts in the DRMM platform. It encapsulates properties such as value that provide detailed context about the WMI alert.
#>
class DRMMAlertContextWmi : DRMMAlertContext {

    [string]$Value

    DRMMAlertContextWmi() : base() {

    }

    static [DRMMAlertContextWmi] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextWmi]::new()
        $Context.Class = $Response.'@class'
        $Context.Value = $Response.value

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the monitor information for an alert in the DRMM system, including whether the alert sends emails and creates tickets.
.DESCRIPTION
    The DRMMAlertMonitorInfo class models the monitor information specific to alerts in the DRMM platform. It encapsulates properties such as SendsEmails and CreatesTicket that provide detailed context about the alert's monitoring configuration.
#>
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

    <#
    .SYNOPSIS
        Generates a summary string for the alert monitor information, indicating whether it sends emails and creates tickets.
    .DESCRIPTION
        The GetSummary method of the DRMMAlertMonitorInfo class creates a concise summary string that indicates whether the alert monitor is configured to send emails and create tickets. It uses 'Emails' or 'NoEmails' to indicate the email sending status, and 'Ticket' or 'NoTicket' to indicate the ticket creation status, combining them into a single summary string.
    #>
    [string] GetSummary() {

        $EmailStatus = if ($this.SendsEmails) { 'Emails' } else { 'NoEmails' }
        $TicketStatus = if ($this.CreatesTicket) { 'Ticket' } else { 'NoTicket' }

        return "$EmailStatus, $TicketStatus"

    }
}

<#
.SYNOPSIS
    Represents the source information for an alert in the DRMM system, including device and site details.
.DESCRIPTION
    The DRMMAlertSourceInfo class models the source information specific to alerts in the DRMM platform. It encapsulates properties such as DeviceUid, DeviceName, SiteUid, and SiteName that provide detailed context about the alert's source.
#>
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

    <#
    .SYNOPSIS
        Generates a summary string for the alert source information, including device and site details.
    .DESCRIPTION
        The GetSummary method of the DRMMAlertSourceInfo class creates a concise summary string that includes the device name and site name associated with the alert source. If either the device name or site name is not available, it defaults to 'Unknown' in the summary.
    #>
    [string] GetSummary() {

        $Device = if ($this.DeviceName) { $this.DeviceName } else { 'Unknown' }
        $Site = if ($this.SiteName) { $this.SiteName } else { 'Unknown' }

        return "$Device @ $Site"

    }
}

<#
.SYNOPSIS
    Represents a response action taken for an alert in the DRMM system, including action time, type, description, and references.
.DESCRIPTION
    The DRMMAlertResponseAction class models the response actions specific to alerts in the DRMM platform. It encapsulates properties such as ActionTime, ActionType, Description, ActionReference, and ActionReferenceInt that provide detailed context about the response actions taken for an alert.
#>
class DRMMAlertResponseAction : DRMMObject {

    [Nullable[datetime]]$ActionTime
    [string]$ActionType
    [string]$Description
    [string]$ActionReference
    [string]$ActionReferenceInt

    DRMMAlertResponseAction() : base() {

    }

    static [DRMMAlertResponseAction] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $ResponseAction = [DRMMAlertResponseAction]::new()

        $ActionDate = [DRMMObject]::ParseApiDate($Response.actionTime)
        $ResponseAction.ActionTime = $ActionDate.DateTime
        $ResponseAction.ActionType = $Response.actionType
        $ResponseAction.Description = $Response.description
        $ResponseAction.ActionReference = $Response.actionReference
        $ResponseAction.ActionReferenceInt = $Response.actionReferenceInt

        return $ResponseAction

    }

    <#
    .SYNOPSIS
        Generates a summary string for the alert response action, including action type and description.
    .DESCRIPTION
        The GetSummary method of the DRMMAlertResponseAction class creates a concise summary string that includes the action type and description of the response action taken for an alert. If the action type is not available, it defaults to 'Unknown' in the summary, and if the description is not available, it defaults to an empty string.
    #>
    [string] GetSummary() {

        $Type = if ($this.ActionType) { $this.ActionType } else { 'Unknown' }
        $Desc = if ($this.Description) { $this.Description } else { '' }

        return "${Type}: ${Desc}"

    }
}
#endregion DRMMAlert and related classes

#region DRMMComponent and related classes
<#
.SYNOPSIS
    Represents a component in the DRMM system, including its properties and associated variables.
.DESCRIPTION
    The DRMMComponent class models a component within the DRMM platform, encapsulating properties such as Id, Uid, Name, Description, CategoryCode, CredentialsRequired, and an array of associated variables (DRMMComponentVariable). It provides methods to retrieve specific variables and generate summaries of the component's properties.
#>
class DRMMComponent : DRMMObject {

    [int]$Id
    [string]$Uid
    [string]$Name
    [string]$Description
    [string]$CategoryCode
    [bool]$CredentialsRequired
    [DRMMComponentVariable[]]$Variables
    [string]$PortalUrl

    DRMMComponent() : base() {

    }

    static [DRMMComponent] FromAPIMethod([pscustomobject]$Response, [string]$Platform) {

        $Component = [DRMMComponent]::new()

        $Component.Id = $Response.id
        $Component.Uid = $Response.uid
        $Component.Name = $Response.name
        $Component.Description = $Response.description
        $Component.CategoryCode = $Response.categoryCode
        $Component.CredentialsRequired = $Response.credentialsRequired
        $Component.PortalUrl = "https://$($Platform.ToLower()).rmm.datto.com/component/$($Component.Id)"

        # Parse variables array
        $Component.Variables = @()
        $VariablesArray = $Response.variables
        if ($null -ne $VariablesArray -and $VariablesArray.Count -gt 0) {

            foreach ($VarItem in $VariablesArray) {

                $Component.Variables += [DRMMComponentVariable]::FromAPIMethod($VarItem)

            }
        }

        return $Component

    }

    <#
    .SYNOPSIS
        Retrieves a specific variable from the component by name.
    .DESCRIPTION
        The GetVariable method of the DRMMComponent class allows you to retrieve a specific variable associated with the component by providing the variable's name. It searches through the component's Variables array and returns the first variable that matches the specified name. If no matching variable is found, it returns $null.
    #>
    [DRMMComponentVariable] GetVariable([string]$Name) {

        return $this.Variables | Where-Object {$_.Name -eq $Name} | Select-Object -First 1

    }

    <#
    .SYNOPSIS
        Retrieves all input variables associated with the component.
    .DESCRIPTION
        The GetInputVariables method of the DRMMComponent class returns an array of all variables that are designated as input variables (where Direction is $true) associated with the component.
    #>
    [DRMMComponentVariable[]] GetInputVariables() {

        return $this.Variables | Where-Object {$_.Direction -eq $true}

    }

    <#
    .SYNOPSIS
        Retrieves all output variables associated with the component.
    .DESCRIPTION
        The GetOutputVariables method of the DRMMComponent class returns an array of all variables that are designated as output variables (where Direction is $false) associated with the component.
    #>
    [DRMMComponentVariable[]] GetOutputVariables() {

        return $this.Variables | Where-Object {$_.Direction -eq $false}

    }

    <#
    .SYNOPSIS
        Opens the component's portal URL in the default web browser.
    .DESCRIPTION
        The OpenPortal method of the DRMMComponent class checks if the PortalUrl property is set and, if so, opens it in the default web browser using Start-Process. If the PortalUrl is not available, it writes a warning message to the console indicating that the portal URL is not available for the component's site.
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
        Generates a summary string for the component, including its name, variable count, credentials requirement, and category.
    .DESCRIPTION
        The GetSummary method returns a string summarizing key information about the component, such as its name, the number of variables it contains, whether credentials are required, and its category code.
    #>
    [string] GetSummary() {

        $ComponentName = if ($this.Name) {$this.Name} else {'Unknown Component'}
        $VarCount = if ($this.Variables) {$this.Variables.Count} else {0}
        $CredText = if ($this.CredentialsRequired) {' [Credentials Required]'} else {''}
        $Category = if ($this.CategoryCode) {" - $($this.CategoryCode)"} else {''}
        
        return "$ComponentName$CredText - $VarCount variable(s)$Category"

    }
}

<#
.SYNOPSIS
    Represents a variable associated with a DRMM component, including its name, type, direction, and other metadata.
.DESCRIPTION
    The DRMMComponentVariable class models a variable that can be used as input or output for a DRMM component. It includes properties for the variable's name, default value, type, direction (input/output), description, and index within the component's variable list. Methods allow for instantiation from API responses and for generating a summary string describing the variable.
#>
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

        $Variable.Name = $Response.name
        $Variable.DefaultValue = $Response.defaultVal
        $Variable.Type = $Response.type
        $Variable.Direction = $Response.direction
        $Variable.Description = $Response.description
        $Variable.Index = $Response.variablesIdx

        return $Variable

    }

    <#
    .SYNOPSIS
        Generates a summary string for the component variable.
    .DESCRIPTION
        The GetSummary method returns a string describing the variable, including its direction (input/output), name, and type.
    #>
    [string] GetSummary() {

        $DirectionText = if ($this.Direction) { 'Input' } else { 'Output' }
        return "[$DirectionText] $($this.Name) ($($this.Type))"

    }
}
#endregion DRMMComponent and related classes

#region DRMMNetworkInterface class
class DRMMNetworkInterface : DRMMObject {
    [string]$Instance
    [string]$Ipv4
    [string]$Ipv6
    [string]$MacAddress
    [string]$Type

    DRMMNetworkInterface() : base() {}

    static [DRMMNetworkInterface] FromAPIMethod([pscustomobject]$Response) {
        if ($null -eq $Response) { return $null }
        $Nic = [DRMMNetworkInterface]::new()
        $Nic.Instance = $Response.instance
        $Nic.Ipv4 = $Response.ipv4
        $Nic.Ipv6 = $Response.ipv6
        $Nic.MacAddress = $Response.macAddress
        $Nic.Type = $Response.type
        return $Nic
    }
}
#endregion DRMMNetworkInterface class

#region DRMMDeviceAudit and related classes
<#
.SYNOPSIS
    Represents a comprehensive audit of a device, including hardware, software, and network information.
.DESCRIPTION
    The DRMMDeviceAudit class encapsulates detailed information about a device, such as its unique identifier, portal URL, system information, network interfaces, BIOS details, baseboard information, display configurations, logical disks, mobile information, processors, video boards, attached devices, SNMP information, physical memory, and installed software. This class is typically used to represent the results of a device audit operation within the DRMM system.
#>
class DRMMDeviceAudit : DRMMObject {

    [guid]$DeviceUid
    [string]$PortalUrl
    [string]$WebRemoteUrl
    [DRMMDeviceAuditSystemInfo]$SystemInfo
    [DRMMNetworkInterface[]]$Nics
    [DRMMDeviceAuditBios]$Bios
    [DRMMDeviceAuditBaseBoard]$BaseBoard
    [DRMMDeviceAuditDisplay[]]$Displays
    [DRMMDeviceAuditLogicalDisk[]]$LogicalDisks
    [DRMMDeviceAuditMobileInfo[]]$MobileInfo
    [DRMMDeviceAuditProcessor[]]$Processors
    [DRMMDeviceAuditVideoBoard[]]$VideoBoards
    [DRMMDeviceAuditAttachedDevice[]]$AttachedDevices
    [DRMMDeviceAuditSnmpInfo]$SnmpInfo
    [DRMMDeviceAuditPhysicalMemory[]]$PhysicalMemory
    [DRMMDeviceAuditSoftware[]]$Software

    DRMMDeviceAudit() : base() {

    }

    static [DRMMDeviceAudit] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Audit = [DRMMDeviceAudit]::new()
        $Audit.PortalUrl = $Response.portalUrl
        $Audit.WebRemoteUrl = $Response.webRemoteUrl
        
        # System info
        $SystemInfoData = $Response.systemInfo
        if ($null -ne $SystemInfoData) {

            $Audit.SystemInfo = [DRMMDeviceAuditSystemInfo]::FromAPIMethod($SystemInfoData)

        }

        # BIOS
        $BiosData = $Response.bios
        if ($null -ne $BiosData) {

            $Audit.Bios = [DRMMDeviceAuditBios]::FromAPIMethod($BiosData)

        }

        # Base board
        $BaseBoardData = $Response.baseBoard
        if ($null -ne $BaseBoardData) {

            $Audit.BaseBoard = [DRMMDeviceAuditBaseBoard]::FromAPIMethod($BaseBoardData)

        }

        # SNMP info
        $SnmpData = $Response.snmpInfo
        if ($null -ne $SnmpData) {

            $Audit.SnmpInfo = [DRMMDeviceAuditSnmpInfo]::FromAPIMethod($SnmpData)

        }

        # Network interfaces
        $NicsData = $Response.nics
        if ($null -ne $NicsData -and $NicsData.Count -gt 0) {

            $Audit.Nics = @($NicsData | ForEach-Object { [DRMMNetworkInterface]::FromAPIMethod($_) })

        }

        # Displays
        $DisplaysData = $Response.displays
        if ($null -ne $DisplaysData -and $DisplaysData.Count -gt 0) {

            $Audit.Displays = @($DisplaysData | ForEach-Object { [DRMMDeviceAuditDisplay]::FromAPIMethod($_) })

        }

        # Logical disks
        $DisksData = $Response.logicalDisks
        if ($null -ne $DisksData -and $DisksData.Count -gt 0) {

            $Audit.LogicalDisks = @($DisksData | ForEach-Object { [DRMMDeviceAuditLogicalDisk]::FromAPIMethod($_) })

        }

        # Mobile info
        $MobileData = $Response.mobileInfo
        if ($null -ne $MobileData -and $MobileData.Count -gt 0) {

            $Audit.MobileInfo = @($MobileData | ForEach-Object { [DRMMDeviceAuditMobileInfo]::FromAPIMethod($_) })

        }

        # Processors
        $ProcessorsData = $Response.processors
        if ($null -ne $ProcessorsData -and $ProcessorsData.Count -gt 0) {

            $Audit.Processors = @($ProcessorsData | ForEach-Object { [DRMMDeviceAuditProcessor]::FromAPIMethod($_) })

        }

        # Video boards
        $VideoData = $Response.videoBoards
        if ($null -ne $VideoData -and $VideoData.Count -gt 0) {

            $Audit.VideoBoards = @($VideoData | ForEach-Object { [DRMMDeviceAuditVideoBoard]::FromAPIMethod($_) })

        }

        # Attached devices
        $AttachedData = $Response.attachedDevices
        if ($null -ne $AttachedData -and $AttachedData.Count -gt 0) {

            $Audit.AttachedDevices = @($AttachedData | ForEach-Object { [DRMMDeviceAuditAttachedDevice]::FromAPIMethod($_) })

        }

        # Physical memory
        $MemoryData = $Response.physicalMemory
        if ($null -ne $MemoryData -and $MemoryData.Count -gt 0) {

            $Audit.PhysicalMemory = @($MemoryData | ForEach-Object { [DRMMDeviceAuditPhysicalMemory]::FromAPIMethod($_) })

        }

        return $Audit

    }
}

<#
.SYNOPSIS
    Represents an attached device in a device audit, including its description and instance information.
.DESCRIPTION
    The DRMMDeviceAuditAttachedDevice class models the information about a device that is attached to the audited system. It includes properties such as Description and Instance, which provide details about the attached device. This class is typically used as part of the DRMMDeviceAudit to represent the various devices connected to the system being audited.
#>
class DRMMDeviceAuditAttachedDevice : DRMMObject {

    [string]$Description
    [string]$Instance

    DRMMDeviceAuditAttachedDevice() : base() {

    }

    static [DRMMDeviceAuditAttachedDevice] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Device = [DRMMDeviceAuditAttachedDevice]::new()
        $Device.Description = $Response.description
        $Device.Instance = $Response.instance

        return $Device

    }
}

<#
.SYNOPSIS
    Represents the baseboard information of a device in a device audit, including manufacturer, product, and serial number.
.DESCRIPTION
    The DRMMDeviceAuditBaseBoard class models the information about the baseboard (motherboard) of the audited system. It includes properties such as Manufacturer, Product, and SerialNumber, which provide details about the baseboard. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.
#>
class DRMMDeviceAuditBaseBoard : DRMMObject {

    [string]$Manufacturer
    [string]$Product
    [string]$SerialNumber

    DRMMDeviceAuditBaseBoard() : base() {

    }

    static [DRMMDeviceAuditBaseBoard] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $BaseBoard = [DRMMDeviceAuditBaseBoard]::new()
        $BaseBoard.Manufacturer = $Response.manufacturer
        $BaseBoard.Product = $Response.product
        $BaseBoard.SerialNumber = $Response.serialNumber

        return $BaseBoard

    }
}

<#
.SYNOPSIS
    Represents the BIOS information of a device in a device audit, including manufacturer, name, serial number, and SMBIOS BIOS version.
.DESCRIPTION
    The DRMMDeviceAuditBios class models the information about the BIOS of the audited system. It includes properties such as Manufacturer, Name, SerialNumber, and SmbiosBiosVersion, which provide details about the BIOS. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.
#>
class DRMMDeviceAuditBios : DRMMObject {

    [string]$Manufacturer
    [string]$Name
    [string]$SerialNumber
    [string]$SmbiosBiosVersion

    DRMMDeviceAuditBios() : base() {

    }

    static [DRMMDeviceAuditBios] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Bios = [DRMMDeviceAuditBios]::new()
        $Bios.Manufacturer = $Response.manufacturer
        $Bios.Name = $Response.name
        $Bios.SerialNumber = $Response.serialNumber
        $Bios.SmbiosBiosVersion = $Response.smbiosBiosVersion

        return $Bios

    }
}

<#
.SYNOPSIS
    Represents the display information of a device in a device audit, including instance, screen height, and screen width.
.DESCRIPTION
    The DRMMDeviceAuditDisplay class models the information about the display of the audited system. It includes properties such as Instance, ScreenHeight, and ScreenWidth, which provide details about the display. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.
#>
class DRMMDeviceAuditDisplay : DRMMObject {

    [string]$Instance
    [int]$ScreenHeight
    [int]$ScreenWidth

    DRMMDeviceAuditDisplay() : base() {

    }

    static [DRMMDeviceAuditDisplay] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Display = [DRMMDeviceAuditDisplay]::new()
        $Display.Instance = $Response.instance
        $Display.ScreenHeight = $Response.screenHeight
        $Display.ScreenWidth = $Response.screenWidth

        return $Display

    }
}

<#
.SYNOPSIS
    Represents the logical disk information of a device in a device audit, including description, disk identifier, free space, and size.
.DESCRIPTION
    The DRMMDeviceAuditLogicalDisk class models the information about the logical disks of the audited system. It includes properties such as Description, DiskIdentifier, Freespace, and Size, which provide details about each logical disk. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.
#>
class DRMMDeviceAuditLogicalDisk : DRMMObject {

    [string]$Description
    [string]$DiskIdentifier
    [long]$Freespace
    [long]$Size

    DRMMDeviceAuditLogicalDisk() : base() {

    }

    static [DRMMDeviceAuditLogicalDisk] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Disk = [DRMMDeviceAuditLogicalDisk]::new()
        $Disk.Description = $Response.description
        $Disk.DiskIdentifier = $Response.diskIdentifier
        $Disk.Freespace = $Response.freespace
        $Disk.Size = $Response.size

        return $Disk

    }
}

<#
.SYNOPSIS
    Represents the mobile information of a device in a device audit, including ICCID, IMEI, number, and operator.
.DESCRIPTION
    The DRMMDeviceAuditMobileInfo class models the information about the mobile connectivity of the audited system. It includes properties such as Iccid, Imei, Number, and Operator, which provide details about the mobile network information of the device. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.
#>
class DRMMDeviceAuditMobileInfo : DRMMObject {

    [string]$Iccid
    [string]$Imei
    [string]$Number
    [string]$Operator

    DRMMDeviceAuditMobileInfo() : base() {

    }

    static [DRMMDeviceAuditMobileInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Mobile = [DRMMDeviceAuditMobileInfo]::new()
        $Mobile.Iccid = $Response.iccid
        $Mobile.Imei = $Response.imei
        $Mobile.Number = $Response.number
        $Mobile.Operator = $Response.operator

        return $Mobile

    }
}

<#
.SYNOPSIS
    Represents the physical memory information of a device in a device audit, including bank label, capacity, manufacturer, part number, serial number, and speed.
.DESCRIPTION
    The DRMMDeviceAuditPhysicalMemory class models the information about the physical memory modules of the audited system. It includes properties such as BankLabel, Capacity, Manufacturer, PartNumber, SerialNumber, and Speed, which provide details about each physical memory module. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.
#>
class DRMMDeviceAuditPhysicalMemory : DRMMObject {

    [string]$BankLabel
    [long]$Capacity
    [string]$Manufacturer
    [string]$PartNumber
    [string]$SerialNumber
    [int]$Speed

    DRMMDeviceAuditPhysicalMemory() : base() {

    }

    static [DRMMDeviceAuditPhysicalMemory] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Memory = [DRMMDeviceAuditPhysicalMemory]::new()
        $Memory.BankLabel = $Response.bankLabel
        $Memory.Capacity = $Response.capacity
        $Memory.Manufacturer = $Response.manufacturer
        $Memory.PartNumber = $Response.partNumber
        $Memory.SerialNumber = $Response.serialNumber
        $Memory.Speed = $Response.speed

        return $Memory

    }
}

<#
.SYNOPSIS
    Represents the processor information of a device in a device audit, including its name.
.DESCRIPTION
    The DRMMDeviceAuditProcessor class models the information about the processor(s) of the audited system. It includes a property for the Name of the processor, which provides details about the CPU. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.
#>
class DRMMDeviceAuditProcessor : DRMMObject {

    [string]$Name

    DRMMDeviceAuditProcessor() : base() {

    }

    static [DRMMDeviceAuditProcessor] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Processor = [DRMMDeviceAuditProcessor]::new()
        $Processor.Name = $Response.name

        return $Processor

    }
}

<#
.SYNOPSIS
    Represents the SNMP information of a device in a device audit, including contact, description, location, and name.
.DESCRIPTION
    The DRMMDeviceAuditSnmpInfo class models the information about the SNMP configuration of the audited system. It includes properties such as Contact, Description, Location, and Name, which provide details about the SNMP settings of the device. This class is typically used as part of the DRMMDeviceAudit to represent the network information of the system being audited.
#>
class DRMMDeviceAuditSnmpInfo : DRMMObject {

    [string]$Contact
    [string]$Description
    [string]$Location
    [string]$Name

    DRMMDeviceAuditSnmpInfo() : base() {

    }

    static [DRMMDeviceAuditSnmpInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Snmp = [DRMMDeviceAuditSnmpInfo]::new()
        $Snmp.Contact = $Response.contact
        $Snmp.Description = $Response.description
        $Snmp.Location = $Response.location
        $Snmp.Name = $Response.name

        return $Snmp

    }
}

<#
.SYNOPSIS
    Represents the software information of a device in a device audit, including its name and version.
.DESCRIPTION
    The DRMMDeviceAuditSoftware class models the information about the software installed on the audited system. It includes properties such as Name and Version, which provide details about each software application. This class is typically used as part of the DRMMDeviceAudit to represent the software inventory of the system being audited.
#>
class DRMMDeviceAuditSoftware : DRMMObject {

    [string]$Name
    [string]$Version

    DRMMDeviceAuditSoftware() : base() {

    }

    static [DRMMDeviceAuditSoftware] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Software = [DRMMDeviceAuditSoftware]::new()
        $Software.Name = $Response.name
        $Software.Version = $Response.version

        return $Software

    }
}

<#
.SYNOPSIS
    Represents the system information of a device in a device audit, including manufacturer, model, total physical memory, username, .NET version, and total CPU cores.
.DESCRIPTION
    The DRMMDeviceAuditSystemInfo class models the information about the system of the audited device. It includes properties such as Manufacturer, Model, TotalPhysicalMemory, Username, DotNetVersion, and TotalCpuCores, which provide detailed information about the system's hardware and software environment. This class is typically used as part of the DRMMDeviceAudit to represent the overall system information of the device being audited.
#>
class DRMMDeviceAuditSystemInfo : DRMMObject {

    [string]$Manufacturer
    [string]$Model
    [long]$TotalPhysicalMemory
    [string]$Username
    [string]$DotNetVersion
    [int]$TotalCpuCores

    DRMMDeviceAuditSystemInfo() : base() {

    }

    static [DRMMDeviceAuditSystemInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $SystemInfo = [DRMMDeviceAuditSystemInfo]::new()
        $SystemInfo.Manufacturer = $Response.manufacturer
        $SystemInfo.Model = $Response.model
        $SystemInfo.TotalPhysicalMemory = $Response.totalPhysicalMemory
        $SystemInfo.Username = $Response.username
        $SystemInfo.DotNetVersion = $Response.dotNetVersion
        $SystemInfo.TotalCpuCores = $Response.totalCpuCores

        return $SystemInfo

    }
}

<#
.SYNOPSIS
    Represents the video board information of a device in a device audit, including its display adapter name.
.DESCRIPTION
    The DRMMDeviceAuditVideoBoard class models the information about the video board (graphics card) of the audited system. It includes a property for the DisplayAdapter, which provides details about the graphics hardware. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.
#>
class DRMMDeviceAuditVideoBoard : DRMMObject {

    [string]$DisplayAdapter

    DRMMDeviceAuditVideoBoard() : base() {

    }

    static [DRMMDeviceAuditVideoBoard] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $VideoBoard = [DRMMDeviceAuditVideoBoard]::new()
        $VideoBoard.DisplayAdapter = $Response.displayAdapter

        return $VideoBoard

    }
}
#endregion DRMMDeviceAudit and related classes

#region DRMMEsxiHostAudit and related classes
<#
.SYNOPSIS
    Represents the audit information of an ESXi host, including system info, guests, processors, network interfaces, physical memory, and datastores.
.DESCRIPTION
    The DRMMEsxiHostAudit class encapsulates detailed information about an ESXi host, such as its unique identifier, portal URL, system information, guest virtual machines, processors, network interfaces, physical memory modules, and datastores. This class is typically used to represent the results of an ESXi host audit operation within the DRMM system.
#>
class DRMMEsxiDatastore : DRMMObject {

    [string]$DatastoreName
    [Nullable[int]]$SubscriptionPercent
    [Nullable[long]]$FreeSpace
    [Nullable[long]]$Size
    [string]$FileSystem
    [string]$Status

    DRMMEsxiDatastore() : base() {

    }

    static [DRMMEsxiDatastore] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Datastore = [DRMMEsxiDatastore]::new()
        $Datastore.DatastoreName = $Response.datastoreName
        $Datastore.SubscriptionPercent = $Response.subscriptionPercent
        $Datastore.FreeSpace = $Response.freeSpace
        $Datastore.Size = $Response.size
        $Datastore.FileSystem = $Response.fileSystem
        $Datastore.Status = $Response.status

        return $Datastore

    }
}

<#
.SYNOPSIS
    Represents a guest virtual machine on an ESXi host, including its name, processor speed, memory size, number of snapshots, and datastores.
.DESCRIPTION
    The DRMMEsxiGuest class models the information about a guest virtual machine running on an ESXi host. It includes properties such as GuestName, ProcessorSpeedTotal, MemorySizeTotal, NumberOfSnapshots, and Datastores, which provide details about the virtual machine's configuration and resource usage. This class is typically used as part of the DRMMEsxiHostAudit to represent the virtual machines running on the ESXi host being audited.
#>
class DRMMEsxiGuest : DRMMObject {

    [string]$GuestName
    [Nullable[int]]$ProcessorSpeedTotal
    [Nullable[long]]$MemorySizeTotal
    [Nullable[int]]$NumberOfSnapshots
    [string]$Datastores

    DRMMEsxiGuest() : base() {

    }

    static [DRMMEsxiGuest] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Guest = [DRMMEsxiGuest]::new()
        $Guest.GuestName = $Response.guestName
        $Guest.ProcessorSpeedTotal = $Response.processorSpeedTotal
        $Guest.MemorySizeTotal = $Response.memorySizeTotal
        $Guest.NumberOfSnapshots = $Response.numberOfSnapshots
        $Guest.Datastores = $Response.datastores

        return $Guest

    }
}

<#
.SYNOPSIS
    Represents the audit information of an ESXi host, including system info, guests, processors, network interfaces, physical memory, and datastores.
.DESCRIPTION
    The DRMMEsxiHostAudit class encapsulates detailed information about an ESXi host, such as its unique identifier, portal URL, system information, guest virtual machines, processors, network interfaces, physical memory modules, and datastores. This class is typically used to represent the results of an ESXi host audit operation within the DRMM system.
#>
class DRMMEsxiHostAudit : DRMMObject {

    [guid]$DeviceUid
    [string]$PortalUrl
    [DRMMEsxiSystemInfo]$SystemInfo
    [DRMMEsxiGuest[]]$Guests
    [DRMMEsxiProcessor[]]$Processors
    [DRMMEsxiNic[]]$Nics
    [DRMMEsxiPhysicalMemory[]]$PhysicalMemory
    [DRMMEsxiDatastore[]]$Datastores

    DRMMEsxiHostAudit() : base() {

    }

    static [DRMMEsxiHostAudit] FromAPIMethod([pscustomobject]$Response, [guid]$DeviceUid) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Audit = [DRMMEsxiHostAudit]::new()
        $Audit.DeviceUid = $DeviceUid
        $Audit.PortalUrl = $Response.portalUrl

        # System info
        $SystemInfoData = $Response.systemInfo
        if ($null -ne $SystemInfoData) {

            $Audit.SystemInfo = [DRMMEsxiSystemInfo]::FromAPIMethod($SystemInfoData)

        }

        # Guests
        $GuestsData = $Response.guests
        if ($null -ne $GuestsData -and $GuestsData.Count -gt 0) {

            $Audit.Guests = @($GuestsData | ForEach-Object { [DRMMEsxiGuest]::FromAPIMethod($_) })

        }

        # Processors
        $ProcessorsData = $Response.processors
        if ($null -ne $ProcessorsData -and $ProcessorsData.Count -gt 0) {

            $Audit.Processors = @($ProcessorsData | ForEach-Object { [DRMMEsxiProcessor]::FromAPIMethod($_) })

        }

        # Nics
        $NicsData = $Response.nics
        if ($null -ne $NicsData -and $NicsData.Count -gt 0) {

            $Audit.Nics = @($NicsData | ForEach-Object { [DRMMEsxiNic]::FromAPIMethod($_) })

        }

        # Physical memory
        $MemoryData = $Response.physicalMemory
        if ($null -ne $MemoryData -and $MemoryData.Count -gt 0) {

            $Audit.PhysicalMemory = @($MemoryData | ForEach-Object { [DRMMEsxiPhysicalMemory]::FromAPIMethod($_) })

        }

        # Datastores
        $DatastoresData = $Response.datastores
        if ($null -ne $DatastoresData -and $DatastoresData.Count -gt 0) {

            $Audit.Datastores = @($DatastoresData | ForEach-Object { [DRMMEsxiDatastore]::FromAPIMethod($_) })

        }

        return $Audit

    }
}

<#
.SYNOPSIS
    Represents a network interface card (NIC) on an ESXi host, including its name, IP addresses, MAC address, speed, and type.
.DESCRIPTION
    The DRMMEsxiNic class models the information about a network interface card (NIC) on an ESXi host. It includes properties such as Name, Ipv4, Ipv6, MacAddress, Speed, and Type, which provide details about the NIC's configuration and capabilities. This class is typically used as part of the DRMMEsxiHostAudit to represent the network interfaces of the ESXi host being audited.
#>
class DRMMEsxiNic : DRMMObject {

    [string]$Name
    [string]$Ipv4
    [string]$Ipv6
    [string]$MacAddress
    [string]$Speed
    [string]$Type

    DRMMEsxiNic() : base() {

    }

    static [DRMMEsxiNic] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Nic = [DRMMEsxiNic]::new()
        $Nic.Name = $Response.name
        $Nic.Ipv4 = $Response.ipv4
        $Nic.Ipv6 = $Response.ipv6
        $Nic.MacAddress = $Response.macAddress
        $Nic.Speed = $Response.speed
        $Nic.Type = $Response.type

        return $Nic

    }
}

<#
.SYNOPSIS
    Represents the physical memory information of an ESXi host, including module, size, type, speed, serial number, part number, and bank.
.DESCRIPTION
    The DRMMEsxiPhysicalMemory class models the information about the physical memory modules of an ESXi host. It includes properties such as Module, Size, Type, Speed, SerialNumber, PartNumber, and Bank, which provide details about each physical memory module installed on the ESXi host. This class is typically used as part of the DRMMEsxiHostAudit to represent the memory configuration of the ESXi host being audited.
#>
class DRMMEsxiPhysicalMemory : DRMMObject {

    [string]$Module
    [Nullable[long]]$Size
    [string]$Type
    [string]$Speed
    [string]$SerialNumber
    [string]$PartNumber
    [string]$Bank

    DRMMEsxiPhysicalMemory() : base() {

    }

    static [DRMMEsxiPhysicalMemory] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Memory = [DRMMEsxiPhysicalMemory]::new()
        $Memory.Module = $Response.module
        $Memory.Size = $Response.size
        $Memory.Type = $Response.type
        $Memory.Speed = $Response.speed
        $Memory.SerialNumber = $Response.serialNumber
        $Memory.PartNumber = $Response.partNumber
        $Memory.Bank = $Response.bank

        return $Memory

    }
}

<#
.SYNOPSIS
    Represents the processor information of an ESXi host, including its frequency, name, and number of cores.
.DESCRIPTION
    The DRMMEsxiProcessor class models the information about the processor(s) of an ESXi host. It includes properties such as Frequency, Name, and NumberOfCores, which provide details about the CPU configuration of the ESXi host. This class is typically used as part of the DRMMEsxiHostAudit to represent the processor information of the ESXi host being audited.
#>
class DRMMEsxiProcessor : DRMMObject {

    [Nullable[double]]$Frequency
    [string]$Name
    [Nullable[int]]$NumberOfCores

    DRMMEsxiProcessor() : base() {

    }

    static [DRMMEsxiProcessor] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Processor = [DRMMEsxiProcessor]::new()
        $Processor.Frequency = $Response.frequency
        $Processor.Name = $Response.name
        $Processor.NumberOfCores = $Response.numberOfCores

        return $Processor

    }
}

<#
.SYNOPSIS
    Represents the system information of an ESXi host, including manufacturer, model, name, number of snapshots, and service tag.
.DESCRIPTION
    The DRMMEsxiSystemInfo class models the information about the ESXi host system. It includes properties such as Manufacturer, Model, Name, NumberOfSnapshots, and ServiceTag, which provide details about the ESXi host's hardware and configuration. This class is typically used as part of the DRMMEsxiHostAudit to represent the overall system information of the ESXi host being audited.
#>
class DRMMEsxiSystemInfo : DRMMObject {

    [string]$Manufacturer
    [string]$Model
    [string]$Name
    [Nullable[int]]$NumberOfSnapshots
    [string]$ServiceTag

    DRMMEsxiSystemInfo() : base() {

    }

    static [DRMMEsxiSystemInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $SystemInfo = [DRMMEsxiSystemInfo]::new()
        $SystemInfo.Manufacturer = $Response.manufacturer
        $SystemInfo.Model = $Response.model
        $SystemInfo.Name = $Response.name
        $SystemInfo.NumberOfSnapshots = $Response.numberOfSnapshots
        $SystemInfo.ServiceTag = $Response.serviceTag

        return $SystemInfo

    }
}
#endregion DRMMEsxiHostAudit and related classes

#region DRMMPrinterAudit and related classes
<#
.SYNOPSIS
    Represents the audit information of a printer, including SNMP info, marker supplies, printer details, system info, and network interfaces.
.DESCRIPTION
    The DRMMPrinterAudit class encapsulates detailed information about a printer, such as its unique identifier, portal URL, SNMP information, marker supplies, printer details, system information, and network interfaces. This class is typically used to represent the results of a printer audit operation within the DRMM system.
#>
class DRMMPrinter : DRMMObject {

    [Nullable[long]]$PrintedPageCount

    DRMMPrinter() : base() {

    }

    static [DRMMPrinter] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Printer = [DRMMPrinter]::new()
        $Printer.PrintedPageCount = $Response.printedPageCount

        return $Printer

    }
}

<#
.SYNOPSIS
    Represents the audit information of a printer, including SNMP info, marker supplies, printer details, system info, and network interfaces.
.DESCRIPTION
    The DRMMPrinterAudit class encapsulates detailed information about a printer, such as its unique identifier, portal URL, SNMP information, marker supplies, printer details, system information, and network interfaces. This class is typically used to represent the results of a printer audit operation within the DRMM system.
#>
class DRMMPrinterAudit : DRMMObject {

    [guid]$DeviceUid
    [string]$PortalUrl
    [DRMMPrinterSnmpInfo]$SnmpInfo
    [DRMMPrinterMarkerSupply[]]$PrinterMarkerSupplies
    [DRMMPrinter]$Printer
    [DRMMPrinterSystemInfo]$SystemInfo
    [DRMMNetworkInterface[]]$Nics

    DRMMPrinterAudit() : base() {

    }

    static [DRMMPrinterAudit] FromAPIMethod([pscustomobject]$Response, [guid]$DeviceUid) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Audit = [DRMMPrinterAudit]::new()
        $Audit.DeviceUid = $DeviceUid
        $Audit.PortalUrl = $Response.portalUrl

        # SNMP info
        $SnmpInfoData = $Response.snmpInfo
        if ($null -ne $SnmpInfoData) {

            $Audit.SnmpInfo = [DRMMPrinterSnmpInfo]::FromAPIMethod($SnmpInfoData)

        }

        # Printer marker supplies
        $SuppliesData = $Response.printerMarkerSupplies
        if ($null -ne $SuppliesData -and $SuppliesData.Count -gt 0) {

            $Audit.PrinterMarkerSupplies = @($SuppliesData | ForEach-Object { [DRMMPrinterMarkerSupply]::FromAPIMethod($_) })

        }

        # Printer
        $PrinterData = $Response.printer
        if ($null -ne $PrinterData) {

            $Audit.Printer = [DRMMPrinter]::FromAPIMethod($PrinterData)

        }

        # System info
        $SystemInfoData = $Response.systemInfo
        if ($null -ne $SystemInfoData) {

            $Audit.SystemInfo = [DRMMPrinterSystemInfo]::FromAPIMethod($SystemInfoData)

        }

        # Network interfaces
        $NicsData = $Response.nics
        if ($null -ne $NicsData -and $NicsData.Count -gt 0) {

            $Audit.Nics = @($NicsData | ForEach-Object { [DRMMNetworkInterface]::FromAPIMethod($_) })

        }

        return $Audit

    }
}

<#
.SYNOPSIS
    Represents the marker supply information of a printer, including description, maximum capacity, and supply level.
.DESCRIPTION
    The DRMMPrinterMarkerSupply class models the information about the marker supplies of a printer. It includes properties such as Description, MaxCapacity, and SuppliesLevel, which provide details about the printer's consumable supplies (e.g., ink or toner levels). This class is typically used as part of the DRMMPrinterAudit to represent the status of the printer's marker supplies.
#>
class DRMMPrinterMarkerSupply : DRMMObject {

    [string]$Description
    [string]$MaxCapacity
    [string]$SuppliesLevel

    DRMMPrinterMarkerSupply() : base() {

    }

    static [DRMMPrinterMarkerSupply] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Supply = [DRMMPrinterMarkerSupply]::new()
        $Supply.Description = $Response.description
        $Supply.MaxCapacity = $Response.maxCapacity
        $Supply.SuppliesLevel = $Response.suppliesLevel

        return $Supply

    }
}

<#
.SYNOPSIS
    Represents the SNMP information of a printer, including SNMP name, contact, description, location, uptime, NIC manufacturer, object ID, and serial number.
.DESCRIPTION
    The DRMMPrinterSnmpInfo class models the SNMP-related information of a printer. It includes properties such as SnmpName, SnmpContact, SnmpDescription, SnmpLocation, SnmpUptime, NicManufacturer, ObjectId, and SnmpSerial. This class is typically used as part of the DRMMPrinterAudit to represent the SNMP details of the printer.
#>
class DRMMPrinterSnmpInfo : DRMMObject {

    [string]$SnmpName
    [string]$SnmpContact
    [string]$SnmpDescription
    [string]$SnmpLocation
    [string]$SnmpUptime
    [string]$NicManufacturer
    [string]$ObjectId
    [string]$SnmpSerial

    DRMMPrinterSnmpInfo() : base() {

    }

    static [DRMMPrinterSnmpInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Snmp = [DRMMPrinterSnmpInfo]::new()
        $Snmp.SnmpName = $Response.snmpName
        $Snmp.SnmpContact = $Response.snmpContact
        $Snmp.SnmpDescription = $Response.snmpDescription
        $Snmp.SnmpLocation = $Response.snmpLocation
        $Snmp.SnmpUptime = $Response.snmpUptime
        $Snmp.NicManufacturer = $Response.nicManufacturer
        $Snmp.ObjectId = $Response.objectId
        $Snmp.SnmpSerial = $Response.snmpSerial

        return $Snmp

    }
}

<#
.SYNOPSIS
    Represents the system information of a printer, including manufacturer and model.
.DESCRIPTION
    The DRMMPrinterSystemInfo class models the system-related information of a printer. It includes properties such as Manufacturer and Model. This class is typically used as part of the DRMMPrinterAudit to represent the system details of the printer.
#>
class DRMMPrinterSystemInfo : DRMMObject {

    [string]$Manufacturer
    [string]$Model

    DRMMPrinterSystemInfo() : base() {

    }

    static [DRMMPrinterSystemInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $SystemInfo = [DRMMPrinterSystemInfo]::new()
        $SystemInfo.Manufacturer = $Response.manufacturer
        $SystemInfo.Model = $Response.model

        return $SystemInfo

    }
}
#endregion DRMMPrinterAudit and related classes

#region DRMMJob and related classes
<#
.SYNOPSIS
    Represents a job in the DRMM system, including its ID, unique identifier, name, creation date, and status.
.DESCRIPTION
    The DRMMJob class models a job within the DRMM platform. It includes properties such as Id, Uid, Name, DateCreated, and Status. This class provides methods to interact with job components, results, standard output, and error data. It also includes utility methods to check the job's status, calculate its age, refresh its data, and generate a summary string. The class is used to represent and manage jobs in the DRMM system.
#>
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
        $Job.Id = $Response.id
        $Job.Uid = $Response.uid
        $Job.Name = $Response.name
        $Job.Status = $Response.status

        $DateCreatedValue = $Response.dateCreated

        if ($null -ne $DateCreatedValue) {

            try {

                $Job.DateCreated = [datetime]::Parse($DateCreatedValue)

            } catch {

                $Job.DateCreated = $null

            }
        }

        return $Job

    }

    <#
    .SYNOPSIS
        Checks if the job is currently active.
    .DESCRIPTION
        The IsActive method returns a boolean value indicating whether the job's status is 'active'. This can be used to determine if the job is currently running or in progress.
    #>
    [bool] IsActive() {

        return $this.Status -eq 'active'

    }

    <#
    .SYNOPSIS
        Checks if the job is completed.
    .DESCRIPTION
        The IsCompleted method returns a boolean value indicating whether the job's status is 'completed'. This can be used to determine if the job has finished its execution.
    #>
    [bool] IsCompleted() {

        return $this.Status -eq 'completed'

    }

    <#
    .SYNOPSIS
        Calculates the age of the job based on its creation date.
    .DESCRIPTION
        The GetAge method returns a TimeSpan object representing the age of the job, calculated as the difference between the current date and the job's DateCreated property. If DateCreated is null, it returns a TimeSpan of zero.
    #>
    [timespan] GetAge() {

        if ($this.DateCreated) {

            return (Get-Date) - $this.DateCreated

        }

        return [timespan]::Zero

    }

    <#
    .SYNOPSIS
        Retrieves the components associated with the job.
    .DESCRIPTION
        The GetComponents method returns an array of DRMMJobComponent objects representing the components of the job. It uses the Get-RMMJob cmdlet with the -Components parameter to fetch this information.
    #>
    [DRMMJobComponent[]] GetComponents() {

        return (Get-RMMJob -JobUid $this.Uid -Components)

    }

    <#
    .SYNOPSIS
        Retrieves the results associated with the job for a specific device.
    .DESCRIPTION
        The GetResults method returns a DRMMJobResults object representing the results of the job for the specified device. It uses the Get-RMMJob cmdlet with the -Results parameter to fetch this information.
    #>
    [DRMMJobResults] GetResults([guid]$DeviceUid) {

        return (Get-RMMJob -JobUid $this.Uid -DeviceUid $DeviceUid -Results)

    }

    <#
    .SYNOPSIS
        Retrieves the standard output data associated with the job for a specific device.
    .DESCRIPTION
        The GetStdOut method returns an array of DRMMJobStdData objects representing the standard output data of the job for the specified device. It uses the Get-RMMJob cmdlet with the -StdOut parameter to fetch this information.
    #>
    [DRMMJobStdData[]] GetStdOut([guid]$DeviceUid) {

        return (Get-RMMJob -JobUid $this.Uid -DeviceUid $DeviceUid -StdOut)

    }

    <#
    .SYNOPSIS
        Retrieves the standard error data associated with the job for a specific device.
    .DESCRIPTION
        The GetStdErr method returns an array of DRMMJobStdData objects representing the standard error data of the job for the specified device. It uses the Get-RMMJob cmdlet with the -StdErr parameter to fetch this information.
    #>
    [DRMMJobStdData[]] GetStdErr([guid]$DeviceUid) {

        return (Get-RMMJob -JobUid $this.Uid -DeviceUid $DeviceUid -StdErr)

    }

    <#
    .SYNOPSIS
        Refreshes the job's data by fetching the latest information from the API.
    .DESCRIPTION
        The Refresh method updates the job's properties (Status, Name, DateCreated) by calling the Get-RMMJob cmdlet with the job's unique identifier. This allows the job object to reflect any changes that may have occurred since it was initially created or last refreshed.
    #>
    [void] Refresh() {

        $Updated = Get-RMMJob -JobUid $this.Uid

        if ($Updated) {

            $this.Status = $Updated.Status
            $this.Name = $Updated.Name
            $this.DateCreated = $Updated.DateCreated

        }

    }

    # Utility Methods
    <#
    .SYNOPSIS
        Generates a summary string for the job.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the job's name, status, and age. The age is calculated based on the job's creation date and is formatted to show days, hours, or minutes ago.
    #>
    [string] GetSummary() {

        $Age = ''

        if ($this.DateCreated) {

            $Span = $this.GetAge()

            if ($Span.TotalDays -ge 1) {

                $Age = " ($([int]$Span.TotalDays)d ago)"

            } elseif ($Span.TotalHours -ge 1) {

                $Age = " ($([int]$Span.TotalHours)h ago)"

            } else {

                $Age = " ($([int]$Span.TotalMinutes)m ago)"

            }

        }

        $JobName = if ($this.Name) {$this.Name} else {'Unknown Job'}

        return "$JobName - $($this.Status)$Age"

    }

    <#
    .SYNOPSIS
        Retrieves the standard output data associated with the job for a specific device.
    .DESCRIPTION
        The GetStdOutAsJson method returns an array of PSCustomObject representing the standard output data of the job for the specified device, parsed from JSON format.
    #>
    [pscustomobject[]] GetStdOutAsJson([guid]$DeviceUid) {

        $StdOutData = $this.GetStdOut($DeviceUid)

        if (-not $StdOutData -or $StdOutData.Count -eq 0) {

            return @()

        }

        # Combine all stdout lines into single string
        $JsonText = ($StdOutData | ForEach-Object {$_.StdData}) -join "`n"

        try {

            return (ConvertFrom-Json -InputObject $JsonText)

        } catch {

            Write-Error "Failed to parse stdout as JSON: $_"
            return @()

        }

    }

    <#
    .SYNOPSIS
        Retrieves the standard output data associated with the job for a specific device.
    .DESCRIPTION
        The GetStdOutAsCsv method returns an array of PSCustomObject representing the standard output data of the job for the specified device, parsed from CSV format. First row is treated as header by default.
    #>
    [pscustomobject[]] GetStdOutAsCsv([guid]$DeviceUid) {

        # Default: treat first row as header
        return $this.GetStdOutAsCsv($DeviceUid, $true, $null)

    }

    <#
    .SYNOPSIS
        Retrieves the standard output data associated with the job for a specific device.
    .DESCRIPTION
        The GetStdOutAsCsv method returns an array of PSCustomObject representing the standard output data of the job for the specified device, parsed from CSV format. It has parameters to specify whether the first row should be treated as a header.
    #>

    [pscustomobject[]] GetStdOutAsCsv([guid]$DeviceUid, [bool]$FirstRowAsHeader) {

        return $this.GetStdOutAsCsv($DeviceUid, $FirstRowAsHeader, $null)

    }

    <#
    .SYNOPSIS
        Retrieves the standard output data associated with the job for a specific device.
    .DESCRIPTION
        The GetStdOutAsCsv method returns an array of PSCustomObject representing the standard output data of the job for the specified device, parsed from CSV format. It has parameters to specify whether the first row should be treated as a header and to provide custom headers if needed.
    #>
    [pscustomobject[]] GetStdOutAsCsv([guid]$DeviceUid, [bool]$FirstRowAsHeader, [string[]]$Headers) {

        $StdOutData = $this.GetStdOut($DeviceUid)

        if (-not $StdOutData -or $StdOutData.Count -eq 0) {

            return @()

        }

        # Combine all stdout lines into single string
        $CsvText = ($StdOutData | ForEach-Object {$_.StdData}) -join "`n"

        try {

            if ($Headers -and $Headers.Count -gt 0) {

                # Custom headers provided
                if ($FirstRowAsHeader) {

                    # Original CSV has headers, skip that first line before parsing
                    $CsvText = ($CsvText -split "`n" | Select-Object -Skip 1) -join "`n"

                }

                # Parse with custom headers (all remaining rows are data)
                return (ConvertFrom-Csv -InputObject $CsvText -Header $Headers)

            } elseif ($FirstRowAsHeader) {

                # Standard CSV with header row
                return (ConvertFrom-Csv -InputObject $CsvText)

            } else {

                # FirstRowAsHeader = false but no custom headers provided
                throw "When FirstRowAsHeader is false, you must provide custom headers via the Headers parameter"

            }

        } catch {

            Write-Error "Failed to parse stdout as CSV: $_"
            return @()

        }

    }
}

<#
.SYNOPSIS
    Represents a component of a DRMM job, including its unique identifier, name, and associated variables.
.DESCRIPTION
    The DRMMJobComponent class models a component within a DRMM job. It includes properties such as Uid, Name, and Variables, which provide details about the component's identity and configuration. The class also includes a static method to create an instance of DRMMJobComponent from API response data.
#>
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
        $Component.Uid = $Response.uid
        $Component.Name = $Response.name
        
        if ($Response.variables) {

            $Component.Variables = $Response.variables | ForEach-Object {

                [DRMMJobComponentVariable]::FromAPIMethod($_)

            }
        }

        return $Component

    }
}

<#
.SYNOPSIS
    Represents the result of a DRMM job component, including its unique identifier, name, status, number of warnings, and whether it has standard output or error data.
.DESCRIPTION
    The DRMMJobComponentResult class models the result of a component within a DRMM job. It includes properties such as ComponentUid, ComponentName, ComponentStatus, NumberOfWarnings, HasStdOut, and HasStdErr, which provide details about the outcome of the component's execution. The class also includes a static method to create an instance of DRMMJobComponentResult from API response data.
#>
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
        $Result.ComponentUid = $Response.componentUid
        $Result.ComponentName = $Response.componentName
        $Result.ComponentStatus = $Response.componentStatus
        $Result.NumberOfWarnings = $Response.numberOfWarnings
        $Result.HasStdOut = $Response.hasStdOut
        $Result.HasStdErr = $Response.hasStdErr

        return $Result

    }
}

<#
.SYNOPSIS
    Represents a variable associated with a DRMM job component, including its name and value.
.DESCRIPTION
    The DRMMJobComponentVariable class models a variable within a DRMM job component. It includes properties such as Name and Value, which provide details about the variable's identity and configuration. The class also includes a static method to create an instance of DRMMJobComponentVariable from API response data.
#>
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
        $Variable.Name = $Response.name
        $Variable.Value = $Response.value

        return $Variable

    }
}

<#
.SYNOPSIS
    Represents the results of a DRMM job, including job and device identifiers, the time the job ran, deployment status, and component results.
.DESCRIPTION
    The DRMMJobResults class models the outcome of a DRMM job execution. It includes properties such as JobUid, DeviceUid, RanOn, JobDeploymentStatus, and an array of ComponentResults, which provide detailed information about the job's execution and its components. The class also includes a static method to create an instance of DRMMJobResults from API response data.
#>
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
        $Results.JobUid = $Response.jobUid
        $Results.DeviceUid = $Response.deviceUid
        $Results.JobDeploymentStatus = $Response.jobDeploymentStatus

        $RanOnValue = $Response.ranOn
        $Results.RanOn = ([DRMMObject]::ParseApiDate($RanOnValue)).DateTime

        if ($Response.componentResults) {

            $Results.ComponentResults = $Response.componentResults | ForEach-Object {

                [DRMMJobComponentResult]::FromAPIMethod($_)

            }

        }

        return $Results

    }
}

<#
.SYNOPSIS
    Represents standard output or error data associated with a DRMM job component, including job, device, and component identifiers, component name, and the standard data itself.
.DESCRIPTION
    The DRMMJobStdData class models the standard output or error data produced by a component during the execution of a DRMM job. It includes properties such as JobUid, DeviceUid, ComponentUid, ComponentName, and StdData, which provide details about the source and content of the standard data. The class also includes a static method to create an instance of DRMMJobStdData from API response data.
#>
class DRMMJobStdData : DRMMObject {

    [guid]$JobUid
    [guid]$DeviceUid
    [guid]$ComponentUid
    [string]$ComponentName
    [string]$StdData

    DRMMJobStdData() : base() {

    }

    static [DRMMJobStdData] FromAPIMethod([pscustomobject]$Response, [guid]$JobUid, [guid]$DeviceUid) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Result = [DRMMJobStdData]::new()
        $Result.JobUid = $JobUid
        $Result.DeviceUid = $DeviceUid
        $Result.ComponentUid = $Response.componentUid
        $Result.ComponentName = $Response.componentName
        $Result.StdData = $Response.stdData

        return $Result

    }
}
#endregion DRMMJob and related classes

#region DRMMDevice and related classes
<#
.SYNOPSIS
    Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device.
.DESCRIPTION
    The DRMMDevice class models a device within the DRMM platform, providing properties that describe the device's 
    attributes and state, as well as methods to retrieve related information such as alerts and to perform actions 
    like opening the device portal.
#>
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
    [DRMMDeviceUdfs]$Udfs
    [bool]$SnmpEnabled
    [string]$DeviceClass
    [string]$PortalUrl
    [string]$WarrantyDate
    [DRMMDeviceAntivirusInfo]$Antivirus
    [DRMMDevicePatchManagement]$PatchManagement
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
    #>
    [DRMMDeviceAudit] GetAudit() {

        return Get-RMMDeviceAudit -DeviceUid $this.Uid

    }

    <#
    .SYNOPSIS
        Gets the software information for this device.
    .DESCRIPTION
        This method retrieves the software data for the device, which may include installed applications and versions.
    #>
    [DRMMDeviceAuditSoftware[]] GetSoftware() {

        return Get-RMMDeviceSoftware -DeviceUid $this.Uid

    }

    <#
    .SYNOPSIS
        Sets the value of one or more User-Defined Fields (UDFs) for the device.
    .DESCRIPTION
        The SetUDF method takes a hashtable of UDF field names and values, and updates the corresponding UDFs for the device using the Set-RMMDeviceUDF cmdlet. The -Force parameter is used to bypass confirmation prompts.
    #>
    [DRMMDevice] SetUDF([hashtable]$UDFFields) {

        return Set-RMMDeviceUDF -DeviceUid $this.Uid @UDFFields -Force

    }

    <#
    .SYNOPSIS
        Clears the value of a specified User-Defined Field (UDF) for the device.
    .DESCRIPTION
        The ClearUDF method takes a UDF number (1-30) as input and clears the corresponding UDF value for the device by setting it to an empty string using the Set-RMMDeviceUDF cmdlet. The -Force parameter is used to bypass confirmation prompts.
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
    #>
    [DRMMDevice] SetWarranty([datetime]$WarrantyDate) {

        return Set-RMMDeviceWarranty -DeviceUid $this.Uid -WarrantyDate $WarrantyDate -Force

    }


    <#
    .SYNOPSIS
        Runs a quick job on the device for a specified job component and variables.
    .DESCRIPTION
        The RunQuickJob method takes a component unique identifier and a hashtable of variables, and initiates a quick job on the device using the New-RMMQuickJob cmdlet. The -Force parameter is used to bypass confirmation prompts.
    #>
    [DRMMJob] RunQuickJob([guid]$ComponentUid, [hashtable]$Variables) {

        return New-RMMQuickJob -DeviceUid $this.Uid -ComponentUid $ComponentUid -Variables $Variables -Force

    }

    <#
    .SYNOPSIS
        Moves the device to a different site within the DRMM system.
    .DESCRIPTION
        The Move method takes a target site unique identifier as input and moves the device to the specified
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

    [string]$AntivirusProduct
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
    #>
    [bool] IsRunning() {

        return ($this.AntivirusStatus -match '^Running')

    }

    <#
    .SYNOPSIS
        Determines if the antivirus is running and up to date on the device.
    .DESCRIPTION
        The IsUpToDate method checks the AntivirusStatus property to determine if the antivirus is both running and up to date on the device. It returns true if the status indicates that the antivirus is running and up to date, and false otherwise.
    #>
    [bool] IsUpToDate() {

        return ($this.AntivirusStatus -eq 'RunningAndUpToDate')

    }

    <#
    .SYNOPSIS
        Generates a summary string of the antivirus product and its status.
    .DESCRIPTION
        The GetSummary method returns a string that combines the AntivirusProduct and AntivirusStatus properties, providing a concise summary of the antivirus information for the device.
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

<##
.SYNOPSIS
    Represents a device type in the DRMM system.
.DESCRIPTION
    The DRMMDeviceType class models the type information for a device in the DRMM platform. It includes properties such as Category and Type. The class provides a constructor and a static method to create an instance from API response data.
#>
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

<#
.SYNOPSIS
    Represents user-defined fields (UDFs) associated with a device in the DRMM system.
.DESCRIPTION
    The DRMMDeviceUdfs class models the user-defined fields (UDFs) for a device in the DRMM platform. It includes properties for Udf1 through Udf30, which can store custom data defined by the user. The class provides a constructor and a static method to create an instance from API response data, populating the UDF properties based on the response.
#>
class DRMMDeviceUdfs : DRMMObject {

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

    [string]$PatchStatus
    [Nullable[long]]$PatchesApprovedPending
    [Nullable[long]]$PatchesNotApproved
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
#endregion DRMMDevice and related classes

#region DRMMVariable class
<#
.SYNOPSIS
    Represents a variable in the DRMM system, including its name, value, scope, and other attributes.
.DESCRIPTION
    The DRMMVariable class models a variable within the DRMM platform, encapsulating properties such as Id, Name, Value, Scope, SiteUid, and IsSecret. It provides a constructor and a static method to create an instance from API response data. The class also includes methods to determine if the variable is global or site-specific, as well as a method to generate a summary string of the variable's information.
#>
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

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Variable = [DRMMVariable]::new()
        $Variable.Id = $Response.id
        $Variable.Name = $Response.name
        $Variable.Value = $Response.value
        $Variable.IsSecret = $Response.masked
        $Variable.Scope = $Scope
        $Variable.SiteUid = $SiteUid

        return $Variable

    }

    <#
    .SYNOPSIS
        Determines if the variable is global in scope.
    .DESCRIPTION
        The IsGlobal method checks the Scope property of the variable to determine if it is global in scope. It returns true if the Scope is equal to 'Global', and false otherwise.
    #>
    [bool] IsGlobal() { return ($this.Scope -eq 'Global') }

    <#
    .SYNOPSIS
        Determines if the variable is site-specific in scope.
    .DESCRIPTION
        The IsSite method checks the Scope property of the variable to determine if it is site-specific in scope. It returns true if the Scope is equal to 'Site', and false otherwise.
    #>
    [bool] IsSite()   { return ($this.Scope -eq 'Site') }


    <#
    .SYNOPSIS
        Generates a summary string for the variable, including its name, scope, and value.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the variable's name, scope, and value. If the Scope property is not set, it defaults to 'Global'. The method also accounts for secret variables, which are masked in the API response.
    #>
    [string] GetSummary() {

        # API already returns masked values for secret variables
        $ScopeValue = if ($this.Scope) { $this.Scope } else { 'Global' }

        return "$($this.Name) [$ScopeValue] = $($this.Value)"

    }
}
#endregion DRMMVariable class

#region DRMMFilter class
<#
.SYNOPSIS
    Represents a filter in the DRMM system, including its name, description, type, scope, and associated site.
.DESCRIPTION
    The DRMMFilter class models a filter within the DRMM platform, encapsulating properties such as Id, FilterId, Name, Description, Type, Scope, Site (for site-scoped filters), SiteUid, DateCreate, LastUpdated, and PortalUrl. It provides a constructor and a static method to create an instance from API response data. The class also includes methods to determine if the filter is global or site-specific, as well as a method to generate a summary string of the filter's information. Additionally, it includes methods to retrieve devices and alerts associated with the filter.
    
    For site-scoped filters, the Site property provides full context about the associated site, while SiteUid is maintained for backward compatibility.
#>
class DRMMFilter : DRMMObject {

    [long]$Id
    [long]$FilterId
    [string]$Name
    [string]$Description
    [string]$Type
    [string]$Scope
    [Nullable[guid]]$SiteUid
    [DRMMSite]$Site
    [Nullable[datetime]]$DateCreate
    [Nullable[datetime]]$LastUpdated
    [string]$PortalUrl

    DRMMFilter() : base() {

    }

    static [DRMMFilter] FromAPIMethod([pscustomobject]$Response, [string]$Scope, [DRMMSite]$Site, [string]$Platform) {

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
        $Filter.Site = $Site
        
        # Set SiteUid for backward compatibility and when Site object is available
        if ($Site) {
            $Filter.SiteUid = $Site.Uid
        }
        
        # Build PortalUrl with SiteId suffix for site-scoped filters
        if ($Site -and $Scope -eq 'Site') {

            $Filter.PortalUrl = "https://$($Platform.ToLower()).rmm.datto.com/device-filter-results/$($Filter.Id)-$($Site.Id)"

        } else {

            $Filter.PortalUrl = "https://$($Platform.ToLower()).rmm.datto.com/device-filter-results/$($Filter.Id)"

        }

        $CreateDate = [DRMMObject]::ParseApiDate($Response.dateCreate)
        $Filter.DateCreate = $CreateDate.DateTime

        $UpdatedDate = [DRMMObject]::ParseApiDate($Response.lastUpdated)
        $Filter.LastUpdated = $UpdatedDate.DateTime

        return $Filter

    }

    <#
    .SYNOPSIS
        Determines if the variable is global in scope.
    .DESCRIPTION
        The IsGlobal method checks the Scope property of the variable to determine if it is global in scope. It returns true if the Scope is equal to 'Global', and false otherwise.
    #>
    [bool] IsGlobal() {
        
        return ($this.Scope -eq 'Global')
    
    }

    <#
    .SYNOPSIS
        Determines if the variable is site-specific in scope.
    .DESCRIPTION
        The IsSite method checks the Scope property of the variable to determine if it is site-specific in scope. It returns true if the Scope is equal to 'Site', and false otherwise.
    #>
    [bool] IsSite() {
        
        return ($this.Scope -eq 'Site')
    
    }

    <#
    .SYNOPSIS
        Determines if the filter is the default type.
    .DESCRIPTION
        The IsDefault method checks the Type property of the filter to determine if it is the default type. It returns true if the Type is equal to 'rmm_default', and false otherwise.
    #>
    [bool] IsDefault() {
        
        return ($this.Type -eq 'rmm_default')
    
    }

    <#
    .SYNOPSIS
        Determines if the filter is a custom type.
    .DESCRIPTION
        The IsCustom method checks the Type property of the filter to determine if it is a custom type. It returns true if the Type is equal to 'custom', and false otherwise.
    #>
    [bool] IsCustom() {
        
        return ($this.Type -eq 'custom')
    
    }

    <#
    .SYNOPSIS
        Opens the portal URL associated with the filter in the default web browser.
    .DESCRIPTION
        The OpenPortal method launches the portal URL associated with the filter using the default web browser. If the portal URL is not available, a warning is displayed.
    #>
    [void] OpenPortal() {

        if ($this.PortalUrl) {

            Start-Process $this.PortalUrl

        } else {

            Write-Warning "Portal URL is not available for filter $($this.Name)"

        }
    }

    <#
    .SYNOPSIS
        Generates a summary string for the filter, including its name, scope, and type.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the filter's name, scope, and type. If the Scope property is not set, it defaults to 'Global'. If the Type property is not set, it defaults to '-'.
    #>
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

    <#
    .SYNOPSIS
        Retrieves the devices associated with the filter.
    .DESCRIPTION
        The GetDevices method returns an array of DRMMDevice objects associated with the filter. If the filter is site-specific, it retrieves devices for the specified site UID and filter ID. Otherwise, it retrieves devices based on the filter ID alone.
    #>
    [DRMMDevice[]] GetDevices() {

        if ($this.IsSite()) {

            return Get-RMMDevice -SiteUid $this.SiteUid -FilterId $this.FilterId

        } else {

            return Get-RMMDevice -FilterId $this.FilterId

        }
    }

    <#
    .SYNOPSIS
        Retrieves the count of devices associated with the filter.
    .DESCRIPTION
        The GetDeviceCount method returns the number of DRMMDevice objects associated with the filter by calling the GetDevices method and counting the results.
    #>
    [int] GetDeviceCount() {

        return $this.GetDevices().Count

    }

    <#
    .SYNOPSIS
        Retrieves the alerts associated with the filter.
    .DESCRIPTION
        The GetAlerts method returns an array of DRMMAlert objects associated with the filter. It retrieves alerts for each device associated with the filter, defaulting to 'Open' status.
    #>
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

    <#
    .SYNOPSIS
        Retrieves the alerts associated with the filter.
    .DESCRIPTION
        The GetAlerts method returns an array of DRMMAlert objects associated with the filter. It retrieves alerts for each device associated with the filter, optionally filtered by status. The status parameter allows filtering alerts by their status (e.g., 'Open', 'Resolved', 'All').
    #>
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
#endregion DRMMFilter class

#region DRMMSite and related classes
<#
.SYNOPSIS
    Represents a site in the DRMM system, including its properties, settings, and associated devices and variables.
.DESCRIPTION
    The DRMMSite class models a site within the DRMM platform, encapsulating properties such as Id, Uid, AccountUid, Name, Description, Notes, OnDemand status, SplashtopAutoInstall setting, ProxySettings, DevicesStatus, SiteSettings, Variables, Filters, AutotaskCompanyName, AutotaskCompanyId, and PortalUrl. It provides a constructor and a static method to create an instance from API response data. The class also includes methods to generate a summary string of the site's information, update site properties, retrieve associated alerts and devices, and open the site's portal URL in a web browser.
#>
class DRMMSite : DRMMObject {

    [long]$Id
    [guid]$Uid
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

    <#
    .SYNOPSIS
        Generates a summary string for the site, including its name, unique identifier, and device count.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the site's name, unique identifier (UID), and the count of devices associated with the site. If the device count information is not available, it defaults to '0'.
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
    #>
    [DRMMSiteSettings] GetSettings() {

        return Get-RMMSiteSettings -SiteUid $this.Uid

    }

    <#
    .SYNOPSIS
        Sets the proxy settings for the site.
    .DESCRIPTION
        The SetProxy method configures the proxy settings for the site using the Set-RMMSiteProxy cmdlet. It takes the proxy host, port, and type as parameters and returns a DRMMSiteSettings object representing the updated site settings.
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

    <#
    .SYNOPSIS
        Generates a summary string for the general settings, including the on-demand status.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the general settings of the site, specifically indicating whether the site is configured for on-demand access. The summary includes the OnDemand property value.
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

<#
.SYNOPSIS
    Represents a deleted site in the DRMM system, with properties similar to DRMMSite but with a string type for Uid to handle invalid GUIDs.
.DESCRIPTION
    The DRMMDeletedDevicesSite class models a deleted site within the DRMM platform. It includes properties similar to the DRMMSite class, but the Uid property is defined as a string to accommodate cases where the GUID may be invalid or not properly formatted. The class provides a constructor and a static method to create an instance from API response data, allowing for the handling of deleted site information without strict GUID validation.
#>
class DRMMDeletedDevicesSite : DRMMSite {
    
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

    <#
    .SYNOPSIS
        Generates a summary string for the proxy settings, including the type, host, and port information.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the proxy settings for the site. It includes the proxy type, host, and port information if available. If the host is not set, it returns null to indicate that proxy settings are not configured.
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

    <#
    .SYNOPSIS
        Generates a summary string for the site's settings, including on-demand status, proxy information, and mail recipient count.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the site's settings, including the on-demand status from the general settings, proxy information from the proxy settings, and the count of mail recipients. If any of these components are not available, it provides default values in the summary string to indicate their absence.
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

    <#
    .SYNOPSIS
        Generates a summary string for the device status, including counts of total devices, online devices, and offline devices.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the device status for the site, including the total number of devices, the number of online devices, and the number of offline devices. This summary provides a quick overview of the device status for the site, allowing for easy monitoring and assessment of the site's device health.
    #>
    [string] GetSummary() {

        return "Devices: $($this.NumberOfDevices), Online: $($this.NumberOfOnlineDevices), Offline: $($this.NumberOfOfflineDevices)"

    }
}
#endregion DRMMSite and related classes

#region DRMMNetMapping class
<#
.SYNOPSIS
    Represents a network mapping in the DRMM system, including properties such as name, unique identifier, description, associated network IDs, and portal URL.
.DESCRIPTION
    The DRMMNetMapping class models a network mapping within the DRMM platform. It includes properties such as Id, Uid, AccountUid, Name, Description, DatatoNetworkingNetworkIds, and PortalUrl. The class provides a constructor and a static method to create an instance from API response data. Additionally, it includes a method to open the portal URL associated with the network mapping in the default web browser. The class serves as a representation of network mappings within the DRMM system, allowing for easy access and management of network mapping information.
#>
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

    <#
    .SYNOPSIS
        Opens the portal URL associated with the network mapping in the default web browser.
    .DESCRIPTION
        The OpenPortal method checks if the PortalUrl property is set for the network mapping. If it is available, it launches the URL in the default web browser using the Start-Process cmdlet. If the PortalUrl is not set, it issues a warning indicating that the portal URL is not available for the network mapping.
    #>
    [void] OpenPortal() {

        if ($this.PortalUrl) {

            Start-Process $this.PortalUrl

        } else {

            Write-Warning "Portal URL is not available for network mapping $($this.Name)"

        }
    }
}
#endregion DRMMNetMapping class

#region DRMMStatus class
<#
.SYNOPSIS
    Represents the status of the DRMM system, including properties such as version, status, and start time.
.DESCRIPTION
    The DRMMStatus class models the status of the DRMM system, encapsulating properties such as Version, Status, and Started. The class provides a constructor and a static method to create an instance from API response data. The FromAPIMethod static method takes a response object, extracts the relevant information, and populates the properties of the DRMMStatus instance accordingly. The class serves as a representation of the current status of the DRMM system, allowing for easy access to version information, overall status, and the time when the system started.
#>
class DRMMStatus : DRMMObject {

    [string]$Version
    [string]$Status
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
        
        $StartedValue = $Response.started

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
#endregion DRMMStatus class

#region DRMMUser class
<#
.SYNOPSIS
    Represents a user in the DRMM system, including properties such as first name, last name, username, email, telephone, status, creation date, last access date, and disabled status.
.DESCRIPTION
    The DRMMUser class models a user within the DRMM platform, encapsulating properties such as FirstName, LastName, Username, Email, Telephone, Status, Created, LastAccess, and Disabled. The class provides a constructor and a static method to create an instance from API response data. The FromAPIMethod static method takes a response object, extracts the relevant information, and populates the properties of the DRMMUser instance accordingly. The class also includes methods to generate a full name for the user and to provide a summary of the user's information, including their username and disabled status. The DRMMUser class serves as a representation of users within the DRMM system, allowing for easy access to user information and status details.
#>
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

    <#
    .SYNOPSIS
        Generates the full name of the user by combining the first name and last name.
    .DESCRIPTION
        The GetFullName method returns a string that combines the FirstName and LastName properties of the user to create a full name. The method trims any extra whitespace to ensure a clean output, even if one of the name components is missing.
    #>
    [string] GetFullName() {

        return "$($this.FirstName) $($this.LastName)".Trim()

    }

    <#
    .SYNOPSIS
        Generates a summary string for the user, including their full name, username, and disabled status.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the user's information, including their full name (constructed from the first and last name), username, and an indication of whether the user is disabled. If the user is disabled, the summary will include "(Disabled)" next to the username for clarity.
    #>
    [string] GetSummary() {

        $FullName = $this.GetFullName()
        $StatusText = if ($this.Disabled) {" (Disabled)"} else {""}

        return "$FullName ($($this.Username))$StatusText"

    }
}
#endregion DRMMUser class