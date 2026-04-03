<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '..\DRMMObject\DRMMObject.psm1'
<#
.SYNOPSIS
    Represents an activity log entry in the DRMM system, including details about the activity, associated site and user information, and related context.
.DESCRIPTION
    The DRMMActivityLog class models an activity log entry within the DRMM platform, encapsulating properties such as the log ID, entity, category, action, date, site information, device ID, hostname, user information, activity details, and flags indicating the presence of standard output and error. It provides a static method to create an instance of the class from a typical API response object that contains activity log information. The class also includes a method to generate a summary string that combines key properties of the activity log for easy display. The related classes DRMMActivityLogSite and DRMMActivityLogUser represent nested information about the site and user associated with the activity log entry.
.LINK
    Get-RMMActivityLog
#>
class DRMMActivityLog : DRMMObject {

    # The unique identifier for the activity log entry.
    [string]$Id
    # The entity associated with the activity.
    [string]$Entity
    # The category of the activity log entry.
    [string]$Category
    # The action performed in the activity log entry.
    [string]$Action
    # The date and time when the activity occurred.
    [Nullable[datetime]]$Date
    # An instance of the DRMMActivityLogSite class that provides information about the site associated with the activity log entry.
    [DRMMActivityLogSite]$Site
    # The identifier of the device involved in the activity.
    [Nullable[long]]$DeviceId
    # The hostname of the device involved in the activity.
    [string]$Hostname
    # An instance of the DRMMActivityLogUser class that provides information about the user associated with the activity log entry.
    [DRMMActivityLogUser]$User
    # Additional details about the activity.
    [PSCustomObject]$Details
    # Indicates whether the activity log entry includes standard output.
    [bool]$HasStdOut
    # Indicates whether the activity log entry includes standard error output.
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
    .OUTPUTS
        A summary string combining key details of the activity log entry.
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

    # The hostname of the device associated with the activity.
    [string]$DeviceHostname
    # The unique identifier (UID) of the device associated with the activity.
    [guid]$DeviceUid
    # The entity type of the activity log entry (e.g., DEVICE).
    [string]$Entity
    # The specific action that was performed (e.g., deployment, create, move.device).
    [string]$EventAction
    # The category of the event (e.g., job, remote, device).
    [string]$EventCategory
    # The unique identifier of the activity log detail entry.
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

    # The entity type of the activity log entry (e.g., USER).
    [string]$Entity
    # The specific action that was performed in the user activity.
    [string]$EventAction
    # The category of the user event.
    [string]$EventCategory
    # The unique identifier of the activity log detail entry.
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

    # The numeric identifier of the job associated with the activity.
    [long]$JobId
    # The name of the job associated with the activity.
    [string]$JobName
    # The status of the job at the time of the activity (e.g., completed, failed).
    [string]$JobStatus
    # The unique identifier (UID) of the job associated with the activity.
    [guid]$JobUid
    # The name of the site where the job was executed.
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

    # The identifier of the job deployment.
    [long]$JobDeploymentId
    # The identifier of the scheduled job associated with the deployment.
    [long]$JobScheduledJobId
    # The unique identifier (UID) of the scheduled job associated with the deployment.
    [guid]$JobScheduledJobUid
    # An optional note or comment associated with the job deployment.
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

    # The date and time when the job was created.
    [nullable[datetime]]$JobDateCreated
    # The email address of the user who created the job.
    [string]$UserEmail
    # The first name of the user who created the job.
    [string]$UserFirstName
    # The identifier of the user who created the job.
    [long]$UserId
    # The last name of the user who created the job.
    [string]$UserLastName
    # The username of the user who created the job.
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

    # The action type performed during this step of the remote session.
    [string]$Action
    # The detail text describing the specific event or step within the remote session.
    [string]$Detail
    # The name associated with this detail item in the remote session.
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

    # An array of DRMMActivityLogDetailsRemoteSessionDetail objects describing individual events or steps within the remote session.
    [DRMMActivityLogDetailsRemoteSessionDetail[]]$RemoteSessionDetails
    # The numeric identifier of the remote session.
    [long]$RemoteSessionId
    # The date and time when the remote session started.
    [nullable[datetime]]$RemoteSessionStartDate
    # The type of remote session (e.g., chat, jrto).
    [string]$RemoteSessionType
    # The name of the site associated with the remote session.
    [string]$SiteName
    # The forwarded IP address of the source that initiated the remote session.
    [string]$SourceForwardedIp
    # The email address of the user who initiated the remote session.
    [string]$UserEmail
    # The first name of the user who initiated the remote session.
    [string]$UserFirstName
    # The identifier of the user who initiated the remote session.
    [long]$UserId
    # The last name of the user who initiated the remote session.
    [string]$UserLastName
    # The username of the user who initiated the remote session.
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

    # The forwarded IP address of the source that initiated the device activity.
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

    # The identifier of the site the device was moved from.
    [long]$DataFromSiteId
    # The name of the site the device was moved from.
    [string]$DataFromSiteName
    # The unique identifier (UID) of the site the device was moved from.
    [guid]$DataFromSiteUid
    # The identifier of the site the device was moved to.
    [long]$DataToSiteId
    # The name of the site the device was moved to.
    [string]$DataToSiteName
    # The unique identifier (UID) of the site the device was moved to.
    [guid]$DataToSiteUid
    # The name of the site associated with the device move operation.
    [string]$SiteName
    # The email address of the user who performed the device move.
    [string]$UserEmail
    # The first name of the user who performed the device move.
    [string]$UserFirstName
    # The identifier of the user who performed the device move.
    [long]$UserId
    # The last name of the user who performed the device move.
    [string]$UserLastName
    # The username of the user who performed the device move.
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
.LINK
    Get-RMMActivityLog
#>
class DRMMActivityLogSite : DRMMObject {

    # The unique identifier for the site associated with the activity log entry.
    [long]$Id
    # The name of the site associated with the activity log entry.
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
.LINK
    Get-RMMActivityLog
#>
class DRMMActivityLogUser : DRMMObject {

    # The unique identifier for the user associated with the activity log entry.
    [long]$Id
    # The username of the user associated with the activity log entry.
    [string]$UserName
    # The first name of the user associated with the activity log entry.
    [string]$FirstName
    # The last name of the user associated with the activity log entry.
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
    .OUTPUTS
        A summary string combining the user's first name, last name, and username.
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