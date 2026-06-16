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
        $Log.Date = [DRMMObject]::ParseApiDateTime($Response.date)

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
        $TargetStr = if ($this.Hostname) { $this.Hostname } elseif ($this.User) { $this.User.Username } else { '' }

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
            
            # DEVICE entity - patch category
            'DEVICE_patch_audit' {[DRMMActivityLogDetailsDevicePatchAudit]::FromActivityLogDetail($DetailsHashtable); break}
            {$_ -match '^DEVICE_patch_'} {[DRMMActivityLogDetailsDevicePatchGeneric]::FromActivityLogDetail($DetailsHashtable); break}
            
            # DEVICE entity - unknown category (entity-level fallback)
            {$_ -match '^DEVICE_'} {[DRMMActivityLogDetailsDeviceGeneric]::FromActivityLogDetail($DetailsHashtable); break}
            
            # USER entity - account category
            'USER_account_change.settings' {[DRMMActivityLogDetailsUserAccountChangeSettings]::FromActivityLogDetail($DetailsHashtable); break}
            'USER_account_login' {[DRMMActivityLogDetailsUserAccountLogin]::FromActivityLogDetail($DetailsHashtable); break}
            {$_ -match '^USER_account_'} {[DRMMActivityLogDetailsUserAccountGeneric]::FromActivityLogDetail($DetailsHashtable); break}
            
            # USER entity - component category
            'USER_component_add.from.comstore' {[DRMMActivityLogDetailsUserComponentAddFromComstore]::FromActivityLogDetail($DetailsHashtable); break}
            {$_ -match '^USER_component_'} {[DRMMActivityLogDetailsUserComponentGeneric]::FromActivityLogDetail($DetailsHashtable); break}
            
            # USER entity - device category
            'USER_device_edit' {[DRMMActivityLogDetailsUserDeviceEdit]::FromActivityLogDetail($DetailsHashtable); break}
            'USER_device_move.device' {[DRMMActivityLogDetailsUserDeviceMoveDevice]::FromActivityLogDetail($DetailsHashtable); break}
            {$_ -match '^USER_device_'} {[DRMMActivityLogDetailsUserDeviceGeneric]::FromActivityLogDetail($DetailsHashtable); break}
            
            # USER entity - monitor category
            'USER_monitor_create' {[DRMMActivityLogDetailsUserMonitorCreate]::FromActivityLogDetail($DetailsHashtable); break}
            'USER_monitor_edit' {[DRMMActivityLogDetailsUserMonitorEdit]::FromActivityLogDetail($DetailsHashtable); break}
            {$_ -match '^USER_monitor_'} {[DRMMActivityLogDetailsUserMonitorGeneric]::FromActivityLogDetail($DetailsHashtable); break}
            
            # USER entity - site category
            'USER_site_create' {[DRMMActivityLogDetailsUserSiteCreate]::FromActivityLogDetail($DetailsHashtable); break}
            {$_ -match '^USER_site_'} {[DRMMActivityLogDetailsUserSiteGeneric]::FromActivityLogDetail($DetailsHashtable); break}
            
            # USER entity - user category
            'USER_user_edit' {[DRMMActivityLogDetailsUserUserEdit]::FromActivityLogDetail($DetailsHashtable); break}
            'USER_user_generate.api.keys' {[DRMMActivityLogDetailsUserUserGenerateApiKeys]::FromActivityLogDetail($DetailsHashtable); break}
            {$_ -match '^USER_user_'} {[DRMMActivityLogDetailsUserUserGeneric]::FromActivityLogDetail($DetailsHashtable); break}
            
            # USER entity - agent category
            'USER_agent_event' {[DRMMActivityLogDetailsUserAgentEvent]::FromActivityLogDetail($DetailsHashtable); break}
            'USER_agent_file' {[DRMMActivityLogDetailsUserAgentFile]::FromActivityLogDetail($DetailsHashtable); break}
            'USER_agent_rs' {[DRMMActivityLogDetailsUserAgentRs]::FromActivityLogDetail($DetailsHashtable); break}
            'USER_agent_shot' {[DRMMActivityLogDetailsUserAgentShot]::FromActivityLogDetail($DetailsHashtable); break}
            {$_ -match '^USER_agent_'} {[DRMMActivityLogDetailsUserAgentGeneric]::FromActivityLogDetail($DetailsHashtable); break}
            
            # USER entity - policy category
            'USER_policy_create.and.push.changes' {[DRMMActivityLogDetailsUserPolicyCreateAndPushChanges]::FromActivityLogDetail($DetailsHashtable); break}
            'USER_policy_edit' {[DRMMActivityLogDetailsUserPolicyEdit]::FromActivityLogDetail($DetailsHashtable); break}
            'USER_policy_edit.and.push.changes' {[DRMMActivityLogDetailsUserPolicyEditAndPushChanges]::FromActivityLogDetail($DetailsHashtable); break}
            'USER_policy_toggle' {[DRMMActivityLogDetailsUserPolicyToggle]::FromActivityLogDetail($DetailsHashtable); break}
            {$_ -match '^USER_policy_'} {[DRMMActivityLogDetailsUserPolicyGeneric]::FromActivityLogDetail($DetailsHashtable); break}
            
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

            if ($Key.IndexOf('date', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue ([DRMMObject]::ParseApiDateTime($ActivityLogDetail[$Key]))

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

        # O(1) membership test for known entity property keys
        $ExcludedKeys = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]@('device.hostname', 'device.uid', 'entity', 'event.action', 'event.category', 'uid'),
            [System.StringComparer]::Ordinal
        )

        # Add any additional properties not in the entity base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($ExcludedKeys.Contains($Key)) {

                continue

            }

            if ($Key.IndexOf('date', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue ([DRMMObject]::ParseApiDateTime($ActivityLogDetail[$Key]))

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
    The DRMMActivityLogEntityUser class serves as a base class for all USER entity activity logs, regardless of category. It encapsulates the 10 core properties that appear in all USER activities: Entity, EventAction, EventCategory, Uid, SourceForwardedIp, UserEmail, UserFirstName, UserId, UserLastName, and UserUsername. These properties are common across all observed USER entity combinations. Category-specific classes (account, agent, component, device, monitor, policy, site, user) inherit from this class and add their category-specific properties.
#>
class DRMMActivityLogEntityUser : DRMMActivityLogDetails {

    # The entity type of the activity log entry (e.g., USER).
    [string]$Entity
    # The specific action that was performed in the user activity.
    [string]$EventAction
    # The category of the user event (e.g., account, agent, policy, site).
    [string]$EventCategory
    # The unique identifier of the activity log detail entry.
    [guid]$Uid
    # The forwarded IP address of the source that performed the user activity.
    [string]$SourceForwardedIp
    # The email address of the user who performed the activity.
    [string]$UserEmail
    # The first name of the user who performed the activity.
    [string]$UserFirstName
    # The identifier of the user who performed the activity.
    [long]$UserId
    # The last name of the user who performed the activity.
    [string]$UserLastName
    # The username of the user who performed the activity.
    [string]$UserUsername

    DRMMActivityLogEntityUser() : base() {

    }

    static [void] PopulateEntityProperties([DRMMActivityLogEntityUser]$Details, [hashtable]$ActivityLogDetail) {

        $Details.Entity = $ActivityLogDetail.'entity'
        $Details.EventAction = $ActivityLogDetail.'event.action'
        $Details.EventCategory = $ActivityLogDetail.'event.category'
        $Details.Uid = $ActivityLogDetail.'uid'
        $Details.SourceForwardedIp = $ActivityLogDetail.'source.forwarded_ip'
        $Details.UserEmail = $ActivityLogDetail.'user.email'
        $Details.UserFirstName = $ActivityLogDetail.'user.firstname'
        $Details.UserId = $ActivityLogDetail.'user.id'
        $Details.UserLastName = $ActivityLogDetail.'user.lastname'
        $Details.UserUsername = $ActivityLogDetail.'user.username'

    }
}

<#
.SYNOPSIS
    Represents a generic USER entity activity log for unknown categories, with entity-level properties and dynamic additional properties.
.DESCRIPTION
    The DRMMActivityLogDetailsUserGeneric class is used for USER entity activity logs where the category is not yet mapped to a dedicated class. It inherits the 10 base properties common to all USER activities (Entity, EventAction, EventCategory, Uid, SourceForwardedIp, UserEmail, UserFirstName, UserId, UserLastName, UserUsername) and dynamically adds any additional properties found in the response. This ensures type safety for known entity-level properties while maintaining flexibility for unknown categories.
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

        # O(1) membership test for known entity property keys
        $ExcludedKeys = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]@(
                'entity',
                'event.action',
                'event.category',
                'uid',
                'source.forwarded_ip',
                'user.email',
                'user.firstname',
                'user.id',
                'user.lastname',
                'user.username'
            ),
            [System.StringComparer]::Ordinal
        )

        # Add any additional properties not in the entity base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($ExcludedKeys.Contains($Key)) {

                continue

            }

            if ($Key.IndexOf('date', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue ([DRMMObject]::ParseApiDateTime($ActivityLogDetail[$Key]))

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
    Base class for USER account-related activity log details, containing properties common to all account actions.
.DESCRIPTION
    The DRMMActivityLogDetailsUserAccount class serves as a base class for USER entity account category activity logs. All observed account actions share only the 10 entity-level properties inherited from DRMMActivityLogEntityUser. No additional category-level properties have been identified. Specific account action types inherit from this class and add their unique properties.
#>
class DRMMActivityLogDetailsUserAccount : DRMMActivityLogEntityUser {

    DRMMActivityLogDetailsUserAccount() : base() {

    }

    static [void] PopulateCategoryProperties([DRMMActivityLogDetailsUserAccount]$Details, [hashtable]$ActivityLogDetail) {

        # Populate entity-level properties
        [DRMMActivityLogEntityUser]::PopulateEntityProperties($Details, $ActivityLogDetail)

    }
}

<#
.SYNOPSIS
    Represents a generic USER account activity log details for unknown account actions, with base properties and dynamic additional properties.
.DESCRIPTION
    The DRMMActivityLogDetailsUserAccountGeneric class is used for USER entity account category activity logs where the specific action is not yet mapped to a dedicated class. It inherits the 10 base properties common to all USER activities and dynamically adds any additional properties found in the response that are not part of the base class. This ensures type safety for known properties while maintaining flexibility for unknown actions.
#>
class DRMMActivityLogDetailsUserAccountGeneric : DRMMActivityLogDetailsUserAccount {

    DRMMActivityLogDetailsUserAccountGeneric() : base() {

    }

    static [DRMMActivityLogDetailsUserAccountGeneric] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        if ($null -eq $ActivityLogDetail) {

            return $null

        }

        $Details = [DRMMActivityLogDetailsUserAccountGeneric]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserAccount]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # O(1) membership test for known base property keys
        $ExcludedKeys = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]@(
                'entity', 'event.action', 'event.category', 'uid',
                'source.forwarded_ip',
                'user.email', 'user.firstname', 'user.id', 'user.lastname', 'user.username'
            ),
            [System.StringComparer]::Ordinal
        )

        # Add any additional properties not in the base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($ExcludedKeys.Contains($Key)) {

                continue

            }

            if ($Key.IndexOf('date', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue ([DRMMObject]::ParseApiDateTime($ActivityLogDetail[$Key]))

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
    Represents an activity log of entity USER, category account, and action change.settings, which includes specific properties related to account settings change activities.
.DESCRIPTION
    The DRMMActivityLogDetailsUserAccountChangeSettings class models the details of a user account settings change activity log entry. It inherits the 10 common USER entity properties from DRMMActivityLogDetailsUserAccount and adds the DataAccessControl property that describes the access control setting that was changed.
#>
class DRMMActivityLogDetailsUserAccountChangeSettings : DRMMActivityLogDetailsUserAccount {

    # The access control setting that was changed during the account settings modification.
    [string]$DataAccessControl

    DRMMActivityLogDetailsUserAccountChangeSettings() : base() {

    }

    static [DRMMActivityLogDetailsUserAccountChangeSettings] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsUserAccountChangeSettings]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserAccount]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Populate change.settings-specific properties
        $Details.DataAccessControl = $ActivityLogDetail.'data.access_control'

        return $Details

    }
}

<#
.SYNOPSIS
    Represents an activity log of entity USER, category account, and action login, which includes specific properties related to user login activities.
.DESCRIPTION
    The DRMMActivityLogDetailsUserAccountLogin class models the details of a user account login activity log entry. It inherits the 10 common USER entity properties from DRMMActivityLogDetailsUserAccount and adds the DataSource property that identifies the source or method used for the login.
#>
class DRMMActivityLogDetailsUserAccountLogin : DRMMActivityLogDetailsUserAccount {

    # The source or method used for the login (e.g., web, api).
    [string]$DataSource

    DRMMActivityLogDetailsUserAccountLogin() : base() {

    }

    static [DRMMActivityLogDetailsUserAccountLogin] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsUserAccountLogin]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserAccount]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Populate login-specific properties
        $Details.DataSource = $ActivityLogDetail.'data.source'

        return $Details

    }
}

<#
.SYNOPSIS
    Base class for USER component-related activity log details, containing properties common to all component actions.
.DESCRIPTION
    The DRMMActivityLogDetailsUserComponent class serves as a base class for USER entity component category activity logs. All observed component actions share only the 10 entity-level properties inherited from DRMMActivityLogEntityUser. No additional category-level properties have been identified. Specific component action types inherit from this class and add their unique properties.
#>
class DRMMActivityLogDetailsUserComponent : DRMMActivityLogEntityUser {

    DRMMActivityLogDetailsUserComponent() : base() {

    }

    static [void] PopulateCategoryProperties([DRMMActivityLogDetailsUserComponent]$Details, [hashtable]$ActivityLogDetail) {

        # Populate entity-level properties
        [DRMMActivityLogEntityUser]::PopulateEntityProperties($Details, $ActivityLogDetail)

    }
}

<#
.SYNOPSIS
    Represents a generic USER component activity log details for unknown component actions, with base properties and dynamic additional properties.
.DESCRIPTION
    The DRMMActivityLogDetailsUserComponentGeneric class is used for USER entity component category activity logs where the specific action is not yet mapped to a dedicated class. It inherits the 10 base properties common to all USER activities and dynamically adds any additional properties found in the response that are not part of the base class. This ensures type safety for known properties while maintaining flexibility for unknown actions.
#>
class DRMMActivityLogDetailsUserComponentGeneric : DRMMActivityLogDetailsUserComponent {

    DRMMActivityLogDetailsUserComponentGeneric() : base() {

    }

    static [DRMMActivityLogDetailsUserComponentGeneric] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        if ($null -eq $ActivityLogDetail) {

            return $null

        }

        $Details = [DRMMActivityLogDetailsUserComponentGeneric]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserComponent]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # O(1) membership test for known base property keys
        $ExcludedKeys = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]@(
                'entity', 'event.action', 'event.category', 'uid',
                'source.forwarded_ip',
                'user.email', 'user.firstname', 'user.id', 'user.lastname', 'user.username'
            ),
            [System.StringComparer]::Ordinal
        )

        # Add any additional properties not in the base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($ExcludedKeys.Contains($Key)) {

                continue

            }

            if ($Key.IndexOf('date', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue ([DRMMObject]::ParseApiDateTime($ActivityLogDetail[$Key]))

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
    Represents an activity log of entity USER, category component, and action add.from.comstore, which includes specific properties related to adding a component from the component store.
.DESCRIPTION
    The DRMMActivityLogDetailsUserComponentAddFromComstore class models the details of a component store addition activity log entry. It inherits the 10 common USER entity properties from DRMMActivityLogDetailsUserComponent and adds three properties identifying the component that was added: its numeric ID, display name, and unique identifier.
#>
class DRMMActivityLogDetailsUserComponentAddFromComstore : DRMMActivityLogDetailsUserComponent {

    # The numeric identifier of the component that was added from the component store.
    [string]$DataComponentId
    # The display name of the component that was added from the component store.
    [string]$DataComponentName
    # The unique identifier (UID) of the component that was added from the component store.
    [string]$DataComponentUid

    DRMMActivityLogDetailsUserComponentAddFromComstore() : base() {

    }

    static [DRMMActivityLogDetailsUserComponentAddFromComstore] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsUserComponentAddFromComstore]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserComponent]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Populate add.from.comstore-specific properties
        $Details.DataComponentId = $ActivityLogDetail.'data.component_id'
        $Details.DataComponentName = $ActivityLogDetail.'data.component_name'
        $Details.DataComponentUid = $ActivityLogDetail.'data.component_uid'

        return $Details

    }
}

<#
.SYNOPSIS
    Base class for USER device-related activity log details, containing properties common to all device actions.
.DESCRIPTION
    The DRMMActivityLogDetailsUserDevice class serves as a base class for USER entity device category activity logs. All observed device actions share only the 10 entity-level properties inherited from DRMMActivityLogEntityUser. No additional category-level properties have been identified. Specific device action types inherit from this class and add their unique properties.
#>
class DRMMActivityLogDetailsUserDevice : DRMMActivityLogEntityUser {

    DRMMActivityLogDetailsUserDevice() : base() {

    }

    static [void] PopulateCategoryProperties([DRMMActivityLogDetailsUserDevice]$Details, [hashtable]$ActivityLogDetail) {

        # Populate entity-level properties
        [DRMMActivityLogEntityUser]::PopulateEntityProperties($Details, $ActivityLogDetail)

    }
}

<#
.SYNOPSIS
    Represents a generic USER device activity log details for unknown device actions, with base properties and dynamic additional properties.
.DESCRIPTION
    The DRMMActivityLogDetailsUserDeviceGeneric class is used for USER entity device category activity logs where the specific action is not yet mapped to a dedicated class. It inherits the 10 base properties common to all USER activities and dynamically adds any additional properties found in the response that are not part of the base class. This ensures type safety for known properties while maintaining flexibility for unknown actions.
#>
class DRMMActivityLogDetailsUserDeviceGeneric : DRMMActivityLogDetailsUserDevice {

    DRMMActivityLogDetailsUserDeviceGeneric() : base() {

    }

    static [DRMMActivityLogDetailsUserDeviceGeneric] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        if ($null -eq $ActivityLogDetail) {

            return $null

        }

        $Details = [DRMMActivityLogDetailsUserDeviceGeneric]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserDevice]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # O(1) membership test for known base property keys
        $ExcludedKeys = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]@(
                'entity', 'event.action', 'event.category', 'uid',
                'source.forwarded_ip',
                'user.email', 'user.firstname', 'user.id', 'user.lastname', 'user.username'
            ),
            [System.StringComparer]::Ordinal
        )

        # Add any additional properties not in the base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($ExcludedKeys.Contains($Key)) {

                continue

            }

            if ($Key.IndexOf('date', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue ([DRMMObject]::ParseApiDateTime($ActivityLogDetail[$Key]))

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
    Represents an activity log of entity USER, category device, and action edit, with dynamic properties for the fields that were changed.
.DESCRIPTION
    The DRMMActivityLogDetailsUserDeviceEdit class models the details of a device edit activity log entry. It inherits the 10 common USER entity properties from DRMMActivityLogDetailsUserDevice and dynamically adds all additional properties returned by the API. The edit payload varies unpredictably — any UDF field (data.udf1 through data.udfN), multiple UDF fields simultaneously, or other device fields may appear depending on what was changed in the UI. No fixed typed properties are defined beyond the entity base; all edit-specific fields are captured as dynamic members.
#>
class DRMMActivityLogDetailsUserDeviceEdit : DRMMActivityLogDetailsUserDevice {

    DRMMActivityLogDetailsUserDeviceEdit() : base() {

    }

    static [DRMMActivityLogDetailsUserDeviceEdit] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        if ($null -eq $ActivityLogDetail) {

            return $null

        }

        $Details = [DRMMActivityLogDetailsUserDeviceEdit]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserDevice]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # O(1) membership test for known base property keys
        $ExcludedKeys = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]@(
                'entity', 'event.action', 'event.category', 'uid',
                'source.forwarded_ip',
                'user.email', 'user.firstname', 'user.id', 'user.lastname', 'user.username'
            ),
            [System.StringComparer]::Ordinal
        )

        # Add all remaining properties dynamically — edit payload is unpredictable (any UDF field, multiple fields, etc.)
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($ExcludedKeys.Contains($Key)) {

                continue

            }

            if ($Key.IndexOf('date', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue ([DRMMObject]::ParseApiDateTime($ActivityLogDetail[$Key]))

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
    Represents an activity log of entity USER, category device, and action move.device, which includes specific properties related to device site move activities.
.DESCRIPTION
    The DRMMActivityLogDetailsUserDeviceMoveDevice class models the details of a user-initiated device site move activity log entry. It inherits the 10 common USER entity properties from DRMMActivityLogDetailsUserDevice and adds properties identifying the device and destination site involved in the move.
#>
class DRMMActivityLogDetailsUserDeviceMoveDevice : DRMMActivityLogDetailsUserDevice {

    # The hostname of the device that was moved.
    [string]$DataDeviceHostname
    # The identifier of the device that was moved.
    [string]$DataDeviceId
    # The unique identifier (UID) of the device that was moved.
    [string]$DataDeviceUid
    # The identifier of the site the device was moved to.
    [string]$DataSiteId
    # The name of the site the device was moved to.
    [string]$DataSiteName
    # The unique identifier (UID) of the site the device was moved to.
    [string]$DataSiteUid

    DRMMActivityLogDetailsUserDeviceMoveDevice() : base() {

    }

    static [DRMMActivityLogDetailsUserDeviceMoveDevice] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsUserDeviceMoveDevice]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserDevice]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Populate move.device-specific properties
        $Details.DataDeviceHostname = $ActivityLogDetail.'data.device_hostname'
        $Details.DataDeviceId = $ActivityLogDetail.'data.device_id'
        $Details.DataDeviceUid = $ActivityLogDetail.'data.device_uid'
        $Details.DataSiteId = $ActivityLogDetail.'data.site_id'
        $Details.DataSiteName = $ActivityLogDetail.'data.site_name'
        $Details.DataSiteUid = $ActivityLogDetail.'data.site_uid'

        return $Details

    }
}

<#
.SYNOPSIS
    Base class for USER monitor-related activity log details, containing properties common to all monitor actions.
.DESCRIPTION
    The DRMMActivityLogDetailsUserMonitor class serves as a base class for USER entity monitor category activity logs. It encapsulates two properties common to all observed monitor actions — DataIsDeviceMonitor and DataMonitorId — in addition to the 10 entity-level properties inherited from DRMMActivityLogEntityUser. Specific monitor action types inherit from this class and add their unique properties.
#>
class DRMMActivityLogDetailsUserMonitor : DRMMActivityLogEntityUser {

    # Indicates whether the monitor is a device-level monitor rather than a policy-level monitor.
    [string]$DataIsDeviceMonitor
    # The identifier of the monitor that was created or edited.
    [string]$DataMonitorId

    DRMMActivityLogDetailsUserMonitor() : base() {

    }

    static [void] PopulateCategoryProperties([DRMMActivityLogDetailsUserMonitor]$Details, [hashtable]$ActivityLogDetail) {

        # Populate entity-level properties
        [DRMMActivityLogEntityUser]::PopulateEntityProperties($Details, $ActivityLogDetail)

        # Populate monitor category properties
        $Details.DataIsDeviceMonitor = $ActivityLogDetail.'data.is_device_monitor'
        $Details.DataMonitorId = $ActivityLogDetail.'data.monitor_id'

    }
}

<#
.SYNOPSIS
    Represents a generic USER monitor activity log details for unknown monitor actions, with base properties and dynamic additional properties.
.DESCRIPTION
    The DRMMActivityLogDetailsUserMonitorGeneric class is used for USER entity monitor category activity logs where the specific action is not yet mapped to a dedicated class. It inherits the 12 base properties common to all USER monitor activities and dynamically adds any additional properties found in the response that are not part of the base class. This ensures type safety for known properties while maintaining flexibility for unknown actions.
#>
class DRMMActivityLogDetailsUserMonitorGeneric : DRMMActivityLogDetailsUserMonitor {

    DRMMActivityLogDetailsUserMonitorGeneric() : base() {

    }

    static [DRMMActivityLogDetailsUserMonitorGeneric] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        if ($null -eq $ActivityLogDetail) {

            return $null

        }

        $Details = [DRMMActivityLogDetailsUserMonitorGeneric]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserMonitor]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # O(1) membership test for known base property keys
        $ExcludedKeys = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]@(
                'entity', 'event.action', 'event.category', 'uid',
                'source.forwarded_ip',
                'user.email', 'user.firstname', 'user.id', 'user.lastname', 'user.username',
                'data.is_device_monitor', 'data.monitor_id'
            ),
            [System.StringComparer]::Ordinal
        )

        # Add any additional properties not in the base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($ExcludedKeys.Contains($Key)) {

                continue

            }

            if ($Key.IndexOf('date', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue ([DRMMObject]::ParseApiDateTime($ActivityLogDetail[$Key]))

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
    Represents an activity log of entity USER, category monitor, and action create, which includes specific properties related to monitor creation activities.
.DESCRIPTION
    The DRMMActivityLogDetailsUserMonitorCreate class models the details of a monitor creation activity log entry. It inherits the 12 common USER monitor properties from DRMMActivityLogDetailsUserMonitor and adds the DataPolicyId property that identifies the policy the monitor was created under, if applicable.
#>
class DRMMActivityLogDetailsUserMonitorCreate : DRMMActivityLogDetailsUserMonitor {

    # The identifier of the policy the monitor was created under, if applicable.
    [string]$DataPolicyId

    DRMMActivityLogDetailsUserMonitorCreate() : base() {

    }

    static [DRMMActivityLogDetailsUserMonitorCreate] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsUserMonitorCreate]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserMonitor]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Populate create-specific properties
        $Details.DataPolicyId = $ActivityLogDetail.'data.policy_id'

        return $Details

    }
}

<#
.SYNOPSIS
    Represents an activity log of entity USER, category monitor, and action edit, which includes specific properties related to monitor edit activities.
.DESCRIPTION
    The DRMMActivityLogDetailsUserMonitorEdit class models the details of a monitor edit activity log entry. It inherits the 12 common USER monitor properties from DRMMActivityLogDetailsUserMonitor. No additional properties beyond the category base have been observed for edit actions.
#>
class DRMMActivityLogDetailsUserMonitorEdit : DRMMActivityLogDetailsUserMonitor {

    DRMMActivityLogDetailsUserMonitorEdit() : base() {

    }

    static [DRMMActivityLogDetailsUserMonitorEdit] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsUserMonitorEdit]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserMonitor]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # No edit-specific properties identified beyond category base

        return $Details

    }
}

<#
.SYNOPSIS
    Base class for USER site-related activity log details, containing properties common to all site actions.
.DESCRIPTION
    The DRMMActivityLogDetailsUserSite class serves as a base class for USER entity site category activity logs. All observed site actions share only the 10 entity-level properties inherited from DRMMActivityLogEntityUser. No additional category-level properties have been identified. Specific site action types inherit from this class and add their unique properties.
#>
class DRMMActivityLogDetailsUserSite : DRMMActivityLogEntityUser {

    DRMMActivityLogDetailsUserSite() : base() {

    }

    static [void] PopulateCategoryProperties([DRMMActivityLogDetailsUserSite]$Details, [hashtable]$ActivityLogDetail) {

        # Populate entity-level properties
        [DRMMActivityLogEntityUser]::PopulateEntityProperties($Details, $ActivityLogDetail)

    }
}

<#
.SYNOPSIS
    Represents a generic USER site activity log details for unknown site actions, with base properties and dynamic additional properties.
.DESCRIPTION
    The DRMMActivityLogDetailsUserSiteGeneric class is used for USER entity site category activity logs where the specific action is not yet mapped to a dedicated class. It inherits the 10 base properties common to all USER activities and dynamically adds any additional properties found in the response that are not part of the base class. This ensures type safety for known properties while maintaining flexibility for unknown actions.
#>
class DRMMActivityLogDetailsUserSiteGeneric : DRMMActivityLogDetailsUserSite {

    DRMMActivityLogDetailsUserSiteGeneric() : base() {

    }

    static [DRMMActivityLogDetailsUserSiteGeneric] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        if ($null -eq $ActivityLogDetail) {

            return $null

        }

        $Details = [DRMMActivityLogDetailsUserSiteGeneric]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserSite]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # O(1) membership test for known base property keys
        $ExcludedKeys = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]@(
                'entity', 'event.action', 'event.category', 'uid',
                'source.forwarded_ip',
                'user.email', 'user.firstname', 'user.id', 'user.lastname', 'user.username'
            ),
            [System.StringComparer]::Ordinal
        )

        # Add any additional properties not in the base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($ExcludedKeys.Contains($Key)) {

                continue

            }

            if ($Key.IndexOf('date', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue ([DRMMObject]::ParseApiDateTime($ActivityLogDetail[$Key]))

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
    Represents an activity log of entity USER, category site, and action create, which includes specific properties related to site creation activities.
.DESCRIPTION
    The DRMMActivityLogDetailsUserSiteCreate class models the details of a site creation activity log entry. It inherits the 10 common USER entity properties from DRMMActivityLogDetailsUserSite and adds four properties describing the newly created site: its description, numeric identifier, display name, and unique identifier.
#>
class DRMMActivityLogDetailsUserSiteCreate : DRMMActivityLogDetailsUserSite {

    # The description provided for the newly created site.
    [string]$DataSiteDescription
    # The numeric identifier assigned to the newly created site.
    [string]$DataSiteId
    # The display name of the newly created site.
    [string]$DataSiteName
    # The unique identifier (UID) assigned to the newly created site.
    [string]$DataSiteUid

    DRMMActivityLogDetailsUserSiteCreate() : base() {

    }

    static [DRMMActivityLogDetailsUserSiteCreate] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsUserSiteCreate]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserSite]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Populate create-specific properties
        $Details.DataSiteDescription = $ActivityLogDetail.'data.site_description'
        $Details.DataSiteId = $ActivityLogDetail.'data.site_id'
        $Details.DataSiteName = $ActivityLogDetail.'data.site_name'
        $Details.DataSiteUid = $ActivityLogDetail.'data.site_uid'

        return $Details

    }
}

<#
.SYNOPSIS
    Base class for USER user-related activity log details, containing properties common to all user management actions.
.DESCRIPTION
    The DRMMActivityLogDetailsUserUser class serves as a base class for USER entity user category activity logs. It encapsulates two properties common to all observed user management actions — DataUserId and DataUserName — in addition to the 10 entity-level properties inherited from DRMMActivityLogEntityUser. Specific user action types inherit from this class and add their unique properties.
#>
class DRMMActivityLogDetailsUserUser : DRMMActivityLogEntityUser {

    # The identifier of the user account that is the subject of the activity.
    [string]$DataUserId
    # The username of the user account that is the subject of the activity.
    [string]$DataUserName

    DRMMActivityLogDetailsUserUser() : base() {

    }

    static [void] PopulateCategoryProperties([DRMMActivityLogDetailsUserUser]$Details, [hashtable]$ActivityLogDetail) {

        # Populate entity-level properties
        [DRMMActivityLogEntityUser]::PopulateEntityProperties($Details, $ActivityLogDetail)

        # Populate user category properties
        $Details.DataUserId = $ActivityLogDetail.'data.user_id'
        $Details.DataUserName = $ActivityLogDetail.'data.user_name'

    }
}

<#
.SYNOPSIS
    Represents a generic USER user activity log details for unknown user management actions, with base properties and dynamic additional properties.
.DESCRIPTION
    The DRMMActivityLogDetailsUserUserGeneric class is used for USER entity user category activity logs where the specific action is not yet mapped to a dedicated class. It inherits the 12 base properties common to all USER user management activities and dynamically adds any additional properties found in the response that are not part of the base class. This ensures type safety for known properties while maintaining flexibility for unknown actions.
#>
class DRMMActivityLogDetailsUserUserGeneric : DRMMActivityLogDetailsUserUser {

    DRMMActivityLogDetailsUserUserGeneric() : base() {

    }

    static [DRMMActivityLogDetailsUserUserGeneric] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        if ($null -eq $ActivityLogDetail) {

            return $null

        }

        $Details = [DRMMActivityLogDetailsUserUserGeneric]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserUser]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # O(1) membership test for known base property keys
        $ExcludedKeys = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]@(
                'entity', 'event.action', 'event.category', 'uid',
                'source.forwarded_ip',
                'user.email', 'user.firstname', 'user.id', 'user.lastname', 'user.username',
                'data.user_id', 'data.user_name'
            ),
            [System.StringComparer]::Ordinal
        )

        # Add any additional properties not in the base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($ExcludedKeys.Contains($Key)) {

                continue

            }

            if ($Key.IndexOf('date', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue ([DRMMObject]::ParseApiDateTime($ActivityLogDetail[$Key]))

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
    Represents an activity log of entity USER, category user, and action edit, which includes specific properties related to user account edit activities.
.DESCRIPTION
    The DRMMActivityLogDetailsUserUserEdit class models the details of a user account edit activity log entry. It inherits the 12 common USER user management properties from DRMMActivityLogDetailsUserUser and adds typed properties for the 6 observed edit fields (roles changed, email, enabled state, first name, last name). Any additional properties not covered by the known typed fields are dynamically added as members, as the edit payload may vary depending on what was changed.
#>
class DRMMActivityLogDetailsUserUserEdit : DRMMActivityLogDetailsUserUser {

    # The roles that were removed from the user account during the edit.
    [string]$DataDeletedRoles
    # The roles that were added to the user account during the edit.
    [string]$DataNewRoles
    # The email address of the user account that was edited.
    [string]$DataUserEmail
    # Indicates whether the user account is enabled after the edit.
    [string]$DataUserEnabled
    # The first name of the user account that was edited.
    [string]$DataUserFirstname
    # The last name of the user account that was edited.
    [string]$DataUserLastname

    DRMMActivityLogDetailsUserUserEdit() : base() {

    }

    static [DRMMActivityLogDetailsUserUserEdit] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        if ($null -eq $ActivityLogDetail) {

            return $null

        }

        $Details = [DRMMActivityLogDetailsUserUserEdit]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserUser]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Populate known edit-specific properties
        $Details.DataDeletedRoles = $ActivityLogDetail.'data.deleted_roles'
        $Details.DataNewRoles = $ActivityLogDetail.'data.new_roles'
        $Details.DataUserEmail = $ActivityLogDetail.'data.user_email'
        $Details.DataUserEnabled = $ActivityLogDetail.'data.user_enabled'
        $Details.DataUserFirstname = $ActivityLogDetail.'data.user_firstname'
        $Details.DataUserLastname = $ActivityLogDetail.'data.user_lastname'

        # O(1) membership test — excludes base + all known edit properties
        $ExcludedKeys = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]@(
                'entity', 'event.action', 'event.category', 'uid',
                'source.forwarded_ip',
                'user.email', 'user.firstname', 'user.id', 'user.lastname', 'user.username',
                'data.user_id', 'data.user_name',
                'data.deleted_roles', 'data.new_roles', 'data.user_email',
                'data.user_enabled', 'data.user_firstname', 'data.user_lastname'
            ),
            [System.StringComparer]::Ordinal
        )

        # Dynamically add any remaining properties not covered by typed fields
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($ExcludedKeys.Contains($Key)) {

                continue

            }

            if ($Key.IndexOf('date', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue ([DRMMObject]::ParseApiDateTime($ActivityLogDetail[$Key]))

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
    Represents an activity log of entity USER, category user, and action generate.api.keys, which includes specific properties related to API key generation activities.
.DESCRIPTION
    The DRMMActivityLogDetailsUserUserGenerateApiKeys class models the details of an API key generation activity log entry. It inherits the 12 common USER user management properties from DRMMActivityLogDetailsUserUser. No additional properties beyond the category base have been observed for this action.
#>
class DRMMActivityLogDetailsUserUserGenerateApiKeys : DRMMActivityLogDetailsUserUser {

    DRMMActivityLogDetailsUserUserGenerateApiKeys() : base() {

    }

    static [DRMMActivityLogDetailsUserUserGenerateApiKeys] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsUserUserGenerateApiKeys]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserUser]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # No generate.api.keys-specific properties identified beyond category base

        return $Details

    }
}

<#
.SYNOPSIS
    Base class for USER agent-related activity log details, containing properties common to all agent session actions.
.DESCRIPTION
    The DRMMActivityLogDetailsUserAgent class serves as a base class for USER entity agent category activity logs. It encapsulates 6 properties common to all observed agent session actions — DataDeviceId, DataDeviceName, DataDeviceUid, DataDirect, DataEnd, and DataStart — in addition to the 10 entity-level properties inherited from DRMMActivityLogEntityUser. Specific agent action types inherit from this class and add their unique properties.
#>
class DRMMActivityLogDetailsUserAgent : DRMMActivityLogEntityUser {

    # The identifier of the device the agent session was performed on.
    [string]$DataDeviceId
    # The display name of the device the agent session was performed on.
    [string]$DataDeviceName
    # The unique identifier (UID) of the device the agent session was performed on.
    [string]$DataDeviceUid
    # Indicates whether the agent session was a direct connection.
    [string]$DataDirect
    # The end time or timestamp of the agent session.
    [string]$DataEnd
    # The start time or timestamp of the agent session.
    [string]$DataStart

    DRMMActivityLogDetailsUserAgent() : base() {

    }

    static [void] PopulateCategoryProperties([DRMMActivityLogDetailsUserAgent]$Details, [hashtable]$ActivityLogDetail) {

        # Populate entity-level properties
        [DRMMActivityLogEntityUser]::PopulateEntityProperties($Details, $ActivityLogDetail)

        # Populate agent category properties
        $Details.DataDeviceId = $ActivityLogDetail.'data.device_id'
        $Details.DataDeviceName = $ActivityLogDetail.'data.device_name'
        $Details.DataDeviceUid = $ActivityLogDetail.'data.device_uid'
        $Details.DataDirect = $ActivityLogDetail.'data.direct'
        $Details.DataEnd = $ActivityLogDetail.'data.end'
        $Details.DataStart = $ActivityLogDetail.'data.start'

    }
}

<#
.SYNOPSIS
    Represents a generic USER agent activity log details for unknown agent actions, with base properties and dynamic additional properties.
.DESCRIPTION
    The DRMMActivityLogDetailsUserAgentGeneric class is used for USER entity agent category activity logs where the specific action is not yet mapped to a dedicated class. It inherits the 16 base properties common to all USER agent activities and dynamically adds any additional properties found in the response that are not part of the base class. This ensures type safety for known properties while maintaining flexibility for unknown actions.
#>
class DRMMActivityLogDetailsUserAgentGeneric : DRMMActivityLogDetailsUserAgent {

    DRMMActivityLogDetailsUserAgentGeneric() : base() {

    }

    static [DRMMActivityLogDetailsUserAgentGeneric] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        if ($null -eq $ActivityLogDetail) {

            return $null

        }

        $Details = [DRMMActivityLogDetailsUserAgentGeneric]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserAgent]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # O(1) membership test for known base property keys
        $ExcludedKeys = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]@(
                'entity', 'event.action', 'event.category', 'uid',
                'source.forwarded_ip',
                'user.email', 'user.firstname', 'user.id', 'user.lastname', 'user.username',
                'data.device_id', 'data.device_name', 'data.device_uid',
                'data.direct', 'data.end', 'data.start'
            ),
            [System.StringComparer]::Ordinal
        )

        # Add any additional properties not in the base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($ExcludedKeys.Contains($Key)) {

                continue

            }

            if ($Key.IndexOf('date', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue ([DRMMObject]::ParseApiDateTime($ActivityLogDetail[$Key]))

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
    Represents an activity log of entity USER, category agent, and action event, which includes specific properties related to agent event activities.
.DESCRIPTION
    The DRMMActivityLogDetailsUserAgentEvent class models the details of an agent event activity log entry. It inherits the 16 common USER agent properties from DRMMActivityLogDetailsUserAgent. No additional properties beyond the category base have been observed for event actions.
#>
class DRMMActivityLogDetailsUserAgentEvent : DRMMActivityLogDetailsUserAgent {

    DRMMActivityLogDetailsUserAgentEvent() : base() {

    }

    static [DRMMActivityLogDetailsUserAgentEvent] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsUserAgentEvent]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserAgent]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # No event-specific properties identified beyond category base

        return $Details

    }
}

<#
.SYNOPSIS
    Represents an activity log of entity USER, category agent, and action file, which includes specific properties related to agent file transfer activities.
.DESCRIPTION
    The DRMMActivityLogDetailsUserAgentFile class models the details of an agent file transfer activity log entry. It inherits the 16 common USER agent properties from DRMMActivityLogDetailsUserAgent and adds the DataDetails property containing additional detail about the file transfer operation.
#>
class DRMMActivityLogDetailsUserAgentFile : DRMMActivityLogDetailsUserAgent {

    # Additional detail about the agent file transfer operation.
    [string]$DataDetails

    DRMMActivityLogDetailsUserAgentFile() : base() {

    }

    static [DRMMActivityLogDetailsUserAgentFile] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsUserAgentFile]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserAgent]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Populate file-specific properties
        $Details.DataDetails = $ActivityLogDetail.'data.details'

        return $Details

    }
}

<#
.SYNOPSIS
    Represents an activity log of entity USER, category agent, and action rs (remote support), which includes specific properties related to agent remote support activities.
.DESCRIPTION
    The DRMMActivityLogDetailsUserAgentRs class models the details of an agent remote support activity log entry. It inherits the 16 common USER agent properties from DRMMActivityLogDetailsUserAgent and adds the DataDetails property containing additional detail about the remote support session.
#>
class DRMMActivityLogDetailsUserAgentRs : DRMMActivityLogDetailsUserAgent {

    # Additional detail about the agent remote support session.
    [string]$DataDetails

    DRMMActivityLogDetailsUserAgentRs() : base() {

    }

    static [DRMMActivityLogDetailsUserAgentRs] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsUserAgentRs]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserAgent]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Populate rs-specific properties
        $Details.DataDetails = $ActivityLogDetail.'data.details'

        return $Details

    }
}

<#
.SYNOPSIS
    Represents an activity log of entity USER, category agent, and action shot (screenshot), which includes specific properties related to agent screenshot activities.
.DESCRIPTION
    The DRMMActivityLogDetailsUserAgentShot class models the details of an agent screenshot activity log entry. It inherits the 16 common USER agent properties from DRMMActivityLogDetailsUserAgent and adds the DataDetails property containing additional detail about the screenshot operation.
#>
class DRMMActivityLogDetailsUserAgentShot : DRMMActivityLogDetailsUserAgent {

    # Additional detail about the agent screenshot operation.
    [string]$DataDetails

    DRMMActivityLogDetailsUserAgentShot() : base() {

    }

    static [DRMMActivityLogDetailsUserAgentShot] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsUserAgentShot]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserAgent]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Populate shot-specific properties
        $Details.DataDetails = $ActivityLogDetail.'data.details'

        return $Details

    }
}

<#
.SYNOPSIS
    Base class for USER policy-related activity log details, containing properties common to all policy actions.
.DESCRIPTION
    The DRMMActivityLogDetailsUserPolicy class serves as a base class for USER entity policy category activity logs. It encapsulates 3 properties common to all observed policy actions — DataPolicyId, DataPolicyName, and DataType — in addition to the 10 entity-level properties inherited from DRMMActivityLogEntityUser. Specific policy action types inherit from this class and add their unique properties.
#>
class DRMMActivityLogDetailsUserPolicy : DRMMActivityLogEntityUser {

    # The identifier of the policy that was affected.
    [string]$DataPolicyId
    # The display name of the policy that was affected.
    [string]$DataPolicyName
    # The type of the policy that was affected.
    [string]$DataType

    DRMMActivityLogDetailsUserPolicy() : base() {

    }

    static [void] PopulateCategoryProperties([DRMMActivityLogDetailsUserPolicy]$Details, [hashtable]$ActivityLogDetail) {

        # Populate entity-level properties
        [DRMMActivityLogEntityUser]::PopulateEntityProperties($Details, $ActivityLogDetail)

        # Populate policy category properties
        $Details.DataPolicyId = $ActivityLogDetail.'data.policy_id'
        $Details.DataPolicyName = $ActivityLogDetail.'data.policy_name'
        $Details.DataType = $ActivityLogDetail.'data.type'

    }
}

<#
.SYNOPSIS
    Represents a generic USER policy activity log details for unknown policy actions, with base properties and dynamic additional properties.
.DESCRIPTION
    The DRMMActivityLogDetailsUserPolicyGeneric class is used for USER entity policy category activity logs where the specific action is not yet mapped to a dedicated class. It inherits the 13 base properties common to all USER policy activities and dynamically adds any additional properties found in the response that are not part of the base class. This ensures type safety for known properties while maintaining flexibility for unknown actions.
#>
class DRMMActivityLogDetailsUserPolicyGeneric : DRMMActivityLogDetailsUserPolicy {

    DRMMActivityLogDetailsUserPolicyGeneric() : base() {

    }

    static [DRMMActivityLogDetailsUserPolicyGeneric] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        if ($null -eq $ActivityLogDetail) {

            return $null

        }

        $Details = [DRMMActivityLogDetailsUserPolicyGeneric]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserPolicy]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # O(1) membership test for known base property keys
        $ExcludedKeys = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]@(
                'entity', 'event.action', 'event.category', 'uid',
                'source.forwarded_ip',
                'user.email', 'user.firstname', 'user.id', 'user.lastname', 'user.username',
                'data.policy_id', 'data.policy_name', 'data.type'
            ),
            [System.StringComparer]::Ordinal
        )

        # Add any additional properties not in the base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($ExcludedKeys.Contains($Key)) {

                continue

            }

            if ($Key.IndexOf('date', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue ([DRMMObject]::ParseApiDateTime($ActivityLogDetail[$Key]))

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
    Represents an activity log of entity USER, category policy, and action create.and.push.changes, which includes specific properties related to policy creation and push activities.
.DESCRIPTION
    The DRMMActivityLogDetailsUserPolicyCreateAndPushChanges class models the details of a policy create-and-push activity log entry. It inherits the 13 common USER policy properties from DRMMActivityLogDetailsUserPolicy. No additional properties beyond the category base have been observed for this action.
#>
class DRMMActivityLogDetailsUserPolicyCreateAndPushChanges : DRMMActivityLogDetailsUserPolicy {

    DRMMActivityLogDetailsUserPolicyCreateAndPushChanges() : base() {

    }

    static [DRMMActivityLogDetailsUserPolicyCreateAndPushChanges] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsUserPolicyCreateAndPushChanges]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserPolicy]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # No create.and.push.changes-specific properties identified beyond category base

        return $Details

    }
}

<#
.SYNOPSIS
    Represents an activity log of entity USER, category policy, and action edit, which includes specific properties related to policy edit activities.
.DESCRIPTION
    The DRMMActivityLogDetailsUserPolicyEdit class models the details of a policy edit activity log entry. It inherits the 13 common USER policy properties from DRMMActivityLogDetailsUserPolicy. No additional properties beyond the category base have been observed for this action.
#>
class DRMMActivityLogDetailsUserPolicyEdit : DRMMActivityLogDetailsUserPolicy {

    DRMMActivityLogDetailsUserPolicyEdit() : base() {

    }

    static [DRMMActivityLogDetailsUserPolicyEdit] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsUserPolicyEdit]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserPolicy]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # No edit-specific properties identified beyond category base

        return $Details

    }
}

<#
.SYNOPSIS
    Represents an activity log of entity USER, category policy, and action edit.and.push.changes, which includes specific properties related to policy edit-and-push activities.
.DESCRIPTION
    The DRMMActivityLogDetailsUserPolicyEditAndPushChanges class models the details of a policy edit-and-push activity log entry. It inherits the 13 common USER policy properties from DRMMActivityLogDetailsUserPolicy. No additional properties beyond the category base have been observed for this action.
#>
class DRMMActivityLogDetailsUserPolicyEditAndPushChanges : DRMMActivityLogDetailsUserPolicy {

    DRMMActivityLogDetailsUserPolicyEditAndPushChanges() : base() {

    }

    static [DRMMActivityLogDetailsUserPolicyEditAndPushChanges] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsUserPolicyEditAndPushChanges]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserPolicy]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # No edit.and.push.changes-specific properties identified beyond category base

        return $Details

    }
}

<#
.SYNOPSIS
    Represents an activity log of entity USER, category policy, and action toggle, which includes specific properties related to policy toggle activities.
.DESCRIPTION
    The DRMMActivityLogDetailsUserPolicyToggle class models the details of a policy toggle activity log entry. It inherits the 13 common USER policy properties from DRMMActivityLogDetailsUserPolicy and adds the DataActive property that indicates the new active state of the policy after the toggle.
#>
class DRMMActivityLogDetailsUserPolicyToggle : DRMMActivityLogDetailsUserPolicy {

    # The active state of the policy after the toggle operation.
    [string]$DataActive

    DRMMActivityLogDetailsUserPolicyToggle() : base() {

    }

    static [DRMMActivityLogDetailsUserPolicyToggle] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsUserPolicyToggle]::new()

        # Populate base properties
        [DRMMActivityLogDetailsUserPolicy]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Populate toggle-specific properties
        $Details.DataActive = $ActivityLogDetail.'data.active'

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

        # O(1) membership test for known base property keys
        $ExcludedKeys = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]@(
                'device.hostname', 'device.uid', 'entity', 'event.action', 'event.category', 'uid',
                'job.id', 'job.name', 'job.status', 'job.uid', 'site.name'
            ),
            [System.StringComparer]::Ordinal
        )

        # Add any additional properties not in the base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($ExcludedKeys.Contains($Key)) {

                continue

            }

            if ($Key.IndexOf('date', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue ([DRMMObject]::ParseApiDateTime($ActivityLogDetail[$Key]))

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

            $Details.JobDateCreated = [DRMMObject]::ParseApiDateTime($ActivityLogDetail.'job.date_created')

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

            $Details.RemoteSessionStartDate = [DRMMObject]::ParseApiDateTime($ActivityLogDetail.'remote_session.start_date')

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

        # O(1) membership test for known base property keys
        $ExcludedKeys = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]@(
                'device.hostname', 'device.uid', 'entity', 'event.action', 'event.category', 'uid',
                'remote_session.id', 'remote_session.type', 'remote_session.start_date', 'remote_session.details',
                'site.name', 'source.forwarded_ip',
                'user.email', 'user.firstname', 'user.id', 'user.lastname', 'user.username'
            ),
            [System.StringComparer]::Ordinal
        )

        # Add any additional properties not in the base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($ExcludedKeys.Contains($Key)) {

                continue

            }

            if ($Key.IndexOf('date', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue ([DRMMObject]::ParseApiDateTime($ActivityLogDetail[$Key]))

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

        # O(1) membership test for known base property keys
        $ExcludedKeys = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]@('device.hostname', 'device.uid', 'entity', 'event.action', 'event.category', 'uid', 'source.forwarded_ip'),
            [System.StringComparer]::Ordinal
        )

        # Add any additional properties not in the base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($ExcludedKeys.Contains($Key)) {

                continue

            }

            if ($Key.IndexOf('date', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue ([DRMMObject]::ParseApiDateTime($ActivityLogDetail[$Key]))

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
    Base class for DEVICE patch-related activity log details, containing properties common to all patch actions.
.DESCRIPTION
    The DRMMActivityLogDetailsDevicePatch class serves as a base class for DEVICE entity patch category activity logs. It encapsulates properties that are common across different patch actions, including patch activity result, status, run date, site information, and source forwarding details, in addition to the entity-level DEVICE properties inherited from DRMMActivityLogEntityDevice. Specific patch action types inherit from this class and add their unique properties.
#>
class DRMMActivityLogDetailsDevicePatch : DRMMActivityLogEntityDevice {

    # Informational message associated with the patch activity.
    [string]$PatchActivityInfo
    # The result description of the patch activity.
    [string]$PatchActivityResult
    # The date and time when the patch activity ran.
    [nullable[datetime]]$PatchActivityRunDate
    # Indicates whether the patch activity completed successfully.
    [bool]$PatchActivitySuccess
    # The name of the site where the patch activity occurred.
    [string]$SiteName
    # The forwarded IP address of the source that initiated the patch activity.
    [string]$SourceForwardedIp

    DRMMActivityLogDetailsDevicePatch() : base() {

    }

    static [void] PopulateCategoryProperties([DRMMActivityLogDetailsDevicePatch]$Details, [hashtable]$ActivityLogDetail) {

        # Populate entity-level properties
        [DRMMActivityLogEntityDevice]::PopulateEntityProperties($Details, $ActivityLogDetail)

        # Populate patch category properties
        $Details.PatchActivityInfo = $ActivityLogDetail.'patch_activity.info'
        $Details.PatchActivityResult = $ActivityLogDetail.'patch_activity.result'
        $Details.SiteName = $ActivityLogDetail.'site.name'
        $Details.SourceForwardedIp = $ActivityLogDetail.'source.forwarded_ip'
        $Details.PatchActivitySuccess = $ActivityLogDetail.'patch_activity.success'

        if ($null -ne $ActivityLogDetail.'patch_activity.run_date') {

            $Details.PatchActivityRunDate = [DRMMObject]::ParseApiDateTime($ActivityLogDetail.'patch_activity.run_date')

        } else {

            $Details.PatchActivityRunDate = $null

        }

    }
}

<#
.SYNOPSIS
    Represents a generic DEVICE patch activity log details for unknown patch actions, with base properties and dynamic additional properties.
.DESCRIPTION
    The DRMMActivityLogDetailsDevicePatchGeneric class is used for DEVICE entity patch category activity logs where the specific action is not yet mapped to a dedicated class. It inherits the 12 base properties common to all DEVICE patch activities and dynamically adds any additional properties found in the response that are not part of the base class. This ensures type safety for known properties while maintaining flexibility for unknown actions.
#>
class DRMMActivityLogDetailsDevicePatchGeneric : DRMMActivityLogDetailsDevicePatch {

    DRMMActivityLogDetailsDevicePatchGeneric() : base() {

    }

    static [DRMMActivityLogDetailsDevicePatchGeneric] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        if ($null -eq $ActivityLogDetail) {

            return $null

        }

        $Details = [DRMMActivityLogDetailsDevicePatchGeneric]::new()

        # Populate base properties
        [DRMMActivityLogDetailsDevicePatch]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # O(1) membership test for known base property keys
        $ExcludedKeys = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]@(
                'device.hostname', 'device.uid', 'entity', 'event.action', 'event.category', 'uid',
                'patch_activity.info', 'patch_activity.result', 'patch_activity.run_date', 'patch_activity.success',
                'site.name', 'source.forwarded_ip'
            ),
            [System.StringComparer]::Ordinal
        )

        # Add any additional properties not in the base class
        foreach ($Key in $ActivityLogDetail.Keys) {

            if ($ExcludedKeys.Contains($Key)) {

                continue

            }

            if ($Key.IndexOf('date', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and $null -ne $ActivityLogDetail[$Key]) {

                try {

                    $Details | Add-Member -NotePropertyName $Key -NotePropertyValue ([DRMMObject]::ParseApiDateTime($ActivityLogDetail[$Key]))

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
    Represents an activity log of entity DEVICE, category patch, and action audit, which includes specific properties related to patch audit activities.
.DESCRIPTION
    The DRMMActivityLogDetailsDevicePatchAudit class models the details of a patch audit activity log entry. It inherits common patch properties from DRMMActivityLogDetailsDevicePatch and adds the audit-specific DataPatchAudit property that identifies the patch audit entry associated with the activity.
#>
class DRMMActivityLogDetailsDevicePatchAudit : DRMMActivityLogDetailsDevicePatch {

    # The identifier or descriptor of the patch audit entry associated with the activity.
    [string]$DataPatchAudit

    DRMMActivityLogDetailsDevicePatchAudit() : base() {

    }

    static [DRMMActivityLogDetailsDevicePatchAudit] FromActivityLogDetail([hashtable]$ActivityLogDetail) {

        $Details = [DRMMActivityLogDetailsDevicePatchAudit]::new()

        # Populate base properties
        [DRMMActivityLogDetailsDevicePatch]::PopulateCategoryProperties($Details, $ActivityLogDetail)

        # Populate audit-specific properties
        $Details.DataPatchAudit = $ActivityLogDetail.'data.patch_audit'

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
    [string]$Username
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
        $User.Username = $Response.userName
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

            return "$($this.FirstName) $($this.LastName) ($($this.Username))"

        } elseif ($this.Username) {

            return $this.Username

        } else {

            return "User $($this.Id)"

        }
    }
}
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA0X9mHAzNmQe8L
# odeQuzMHUHfzVG5kTx/bDcfc2O1C0qCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGssY3+GRsOjarApo/0LmxdNyyRl
# d2tAi4269wDbl/ORMA0GCSqGSIb3DQEBAQUABIIBACA2+tmUCDyxeJ5fFIKu+H1l
# vFok3XTQa7kY3Tt++xzRSJSkd/m9SlhIfcZa3XIt0ry9yAm/Bj+csMDomZ+D9rgR
# EmXoBuA6iUCNrYFSKt4UDtwDM6j/oNzykWejadJESW770/GTpkS9Ux0cZL+26IU3
# 4qWQIe3IWd+XvBoeGg7pJSSKqnRjn1f9naKlM0e8O6vwujVlTXI4x6x3/6Him12h
# Fd+f7rArx/BLPcJoalJG5MYIRqoANf/biE7GaLvwuLBA1qTT2ANbn6oSxxnwmWpg
# uc7/RglX6Prj50+V5pIz3hphsu/aQBTFm/KCWI9M0CmpaCHVLLQF/rMWaC0+duM=
# SIG # End signature block
