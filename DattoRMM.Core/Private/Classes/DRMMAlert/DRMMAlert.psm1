using module '..\DRMMObject\DRMMObject.psm1'

<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Represents an alert in the DRMM system, including its properties, context, source information, and response actions.
.DESCRIPTION
    The DRMMAlert class models an alert within the DRMM platform, encapsulating properties such as the alert's unique identifier, priority, diagnostics, resolution status, ticket number, timestamp, and related information about the alert monitor, context, source, and response actions. It provides a static method to create an instance of the class from a typical API response object that contains alert information. The class also includes methods to determine if the alert is open or of certain priority levels, to resolve the alert, and to generate a summary string that combines key properties of the alert for easy display. The related classes DRMMAlertContext, DRMMAlertMonitorInfo, DRMMAlertSourceInfo, and DRMMAlertResponseAction represent nested information about the alert's context, monitoring configuration, source details, and response actions taken, respectively.
.LINK
    Get-RMMAlert
.LINK
    Resolve-RMMAlert
#>
class DRMMAlert : DRMMObject {

    # Unique identifier for the alert.
    [guid]$AlertUid
    # Priority level of the alert.
    [string]$Priority
    # Diagnostic information related to the alert.
    [string]$Diagnostics
    # Indicates whether the alert has been resolved.
    [bool]$Resolved
    # Identifier of the user who resolved the alert.
    [string]$ResolvedBy
    # Timestamp when the alert was resolved.
    [Nullable[datetime]]$ResolvedOn
    # Indicates whether the alert is muted.
    [bool]$Muted
    # Ticket number associated with the alert.
    [string]$TicketNumber
    # Timestamp when the alert was created.
    [Nullable[datetime]]$Timestamp
    # AlertMonitorInfo of the DRMMAlert object, containing details about the alert monitor configuration.
    [DRMMAlertMonitorInfo]$AlertMonitorInfo
    # AlertContext of the DRMMAlert object, providing contextual information about the alert.
    [DRMMAlertContext]$AlertContext
    # AlertSourceInfo of the DRMMAlert object, including information about the source of the alert such as device and site details.
    [DRMMAlertSourceInfo]$AlertSourceInfo
    # Actions taken in response to the alert.
    [DRMMAlertResponseAction[]]$ResponseActions
    # The number of minutes after which the alert will be automatically resolved if not resolved manually.
    [Nullable[int]]$AutoresolveMins
    # The URL to access the alert in the Datto RMM web portal.
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
    .OUTPUTS
        True if the alert is currently open (not resolved), otherwise false.
    #>
    [bool] IsOpen() {return (-not $this.Resolved)}

    <#
    .SYNOPSIS
        Determines if the alert is of priority level "Critical".
    .DESCRIPTION
        The IsCritical method checks the Priority property of the alert to determine if it is classified as "Critical".
    .OUTPUTS
        True if the alert is of priority level "Critical", otherwise false.
    #>
    [bool] IsCritical() {return ($this.Priority -eq 'Critical')}

    <#
    .SYNOPSIS
        Determines if the alert is of priority level "High".
    .DESCRIPTION
        The IsHigh method checks the Priority property of the alert to determine if it is classified as "High".
    .OUTPUTS
        True if the alert is of priority level "High", otherwise false.
    #>
    [bool] IsHigh() {return ($this.Priority -eq 'High')}

    <#
    .SYNOPSIS
        Resolves the alert.
    .DESCRIPTION
        The Resolve method marks the alert as resolved by calling the Resolve-RMMAlert cmdlet with the alert's unique identifier.
    .OUTPUTS
        An updated instance of the DRMMAlert class with the alert marked as resolved.
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
    .OUTPUTS
        A summary string combining key properties of the alert for easy display.
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
    .OUTPUTS
        This method does not return a value. It performs an action to open the portal URL in the default web browser.
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
    The DRMMAlertContext class models the context information associated with an alert in the DRMM platform. It includes a property for the class of the context, which indicates the type of alert context. The class provides a static method to create an instance of the appropriate context subclass based on the '@class' property in the API response. If the '@class' property is not present or does not match known types, it defaults to creating an instance of DRMMAlertContextGeneric. Each specific context type has its own properties and parsing logic to capture relevant details for that type of alert context.
.LINK
    DRMMAlertContextAction
.LINK
    DRMMAlertContextAntivirus
.LINK
    DRMMAlertContextBackupManagement
.LINK
    DRMMAlertContextCustomSNMP
.LINK
    DRMMAlertContextDiskHealth
.LINK
    DRMMAlertContextDiskUsage
.LINK
    DRMMAlertContextEndpointSecurityThreat
.LINK
    DRMMAlertContextEndpointSecurityWindowsDefender
.LINK
    DRMMAlertContextEventLog
.LINK
    DRMMAlertContextFan
.LINK
    DRMMAlertContextFileSystem
.LINK
    DRMMAlertContextNetworkMonitor
.LINK
    DRMMAlertContextOnlineOfflineStatus
.LINK
    DRMMAlertContextPatch
.LINK
    DRMMAlertContextPing
.LINK
    DRMMAlertContextPrinter
.LINK
    DRMMAlertContextPsu
.LINK
    DRMMAlertContextRansomWare
.LINK
    DRMMAlertContextResourceUsage
.LINK
    DRMMAlertContextScript
.LINK
    DRMMAlertContextSecCenter
.LINK
    DRMMAlertContextSecurityManagement
.LINK
    DRMMAlertContextSNMPProbe
.LINK
    DRMMAlertContextStatus
.LINK
    DRMMAlertContextTemperature
.LINK
    DRMMAlertContextWindowsPerformance
.LINK
    DRMMAlertContextWmi
#>
class DRMMAlertContext : DRMMObject {

    # The class of the alert context, indicating the type of context information associated with the alert.
    [string]$Class

    DRMMAlertContext() : base() {

    }

    <#
    .SYNOPSIS
        Gets a summary of the alert context.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the alert context by including the class of the context. This provides a quick overview of the type of context associated with the alert, which can be useful for display purposes and when examining the alert's details in a list or summary view.
    .OUTPUTS
        A summary string of the alert context.
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

            '^action_ctx$' { [DRMMAlertContextAction]::FromAPIMethod($Response) }
            '^online_offline_status_ctx$' { [DRMMAlertContextOnlineOfflineStatus]::FromAPIMethod($Response) }
            '^ransomware_ctx$' { [DRMMAlertContextRansomWare]::FromAPIMethod($Response) }
            '^eventlog_ctx$' { [DRMMAlertContextEventLog]::FromAPIMethod($Response) }
            '^comp_script_ctx' { [DRMMAlertContextScript]::FromAPIMethod($Response) }
            '^antivirus_ctx$' { [DRMMAlertContextAntivirus]::FromAPIMethod($Response) }
            '^backup_management_ctx$' { [DRMMAlertContextBackupManagement]::FromAPIMethod($Response) }
            '^custom_snmp_ctx$' { [DRMMAlertContextCustomSNMP]::FromAPIMethod($Response) }
            '^disk_health_ctx$' { [DRMMAlertContextDiskHealth]::FromAPIMethod($Response) }
            '^(disk_usage|perf_disk_usage)_ctx$' { [DRMMAlertContextDiskUsage]::FromAPIMethod($Response) }
            '^endpoint_security_threat_ctx$' { [DRMMAlertContextEndpointSecurityThreat]::FromAPIMethod($Response) }
            '^endpoint_security_windows_defender_ctx$' { [DRMMAlertContextEndpointSecurityWindowsDefender]::FromAPIMethod($Response) }
            '^fan_ctx$' { [DRMMAlertContextFan]::FromAPIMethod($Response) }
            '^(filesystem|fs_object)_ctx$' { [DRMMAlertContextFileSystem]::FromAPIMethod($Response) }
            '^network_monitor_ctx$' { [DRMMAlertContextNetworkMonitor]::FromAPIMethod($Response) }
            '^patch_ctx$' { [DRMMAlertContextPatch]::FromAPIMethod($Response) }
            '^ping_ctx$' { [DRMMAlertContextPing]::FromAPIMethod($Response) }
            '^printer_ctx$' { [DRMMAlertContextPrinter]::FromAPIMethod($Response) }
            '^psu_ctx$' { [DRMMAlertContextPsu]::FromAPIMethod($Response) }
            '^(resource_usage|process_resource_usage)_ctx$' { [DRMMAlertContextResourceUsage]::FromAPIMethod($Response) }
            '^snmp_probe_ctx$' { [DRMMAlertContextSNMPProbe]::FromAPIMethod($Response) }
            '^seccenter_ctx$' { [DRMMAlertContextSecCenter]::FromAPIMethod($Response) }
            '^security_management_ctx$' { [DRMMAlertContextSecurityManagement]::FromAPIMethod($Response) }
            '^(status|process_status)_ctx$' { [DRMMAlertContextStatus]::FromAPIMethod($Response) }
            '^temperature_ctx$' { [DRMMAlertContextTemperature]::FromAPIMethod($Response) }
            '^windows_performance_ctx$' { [DRMMAlertContextWindowsPerformance]::FromAPIMethod($Response) }
            '^wmi_ctx$' { [DRMMAlertContextWmi]::FromAPIMethod($Response) }
            default {

                Write-Debug "AlertContext: Unrecognised @class '$ClassValue' — using DRMMAlertContextGeneric. Properties: $($Response.PSObject.Properties.Name -join ', ')"
                [DRMMAlertContextGeneric]::FromAPIMethod($Response)

            }

        }

        return $Result

    }
}

<#
.SYNOPSIS
    Represents the context of an action alert in the DRMM system, including package name, action type, and version information.
.DESCRIPTION
    The DRMMAlertContextAction class models the context information specific to software action alerts in the DRMM platform. It encapsulates properties such as the package name, action type (installed, uninstalled, or version changed), previous version, and current version that provide detailed context about the software action that triggered the alert.
#>
class DRMMAlertContextAction : DRMMAlertContext {

    # The name of the software package associated with the action alert.
    [string]$PackageName
    # The type of action that triggered the alert (e.g., INSTALLED, UNINSTALLED, VERSION_CHANGED).
    [string]$ActionType
    # The previous version of the software package before the action.
    [string]$PrevVersion
    # The current version of the software package after the action.
    [string]$Version

    DRMMAlertContextAction() : base() {

    }

    static [DRMMAlertContextAction] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextAction]::new()
        $Context.Class = $Response.'@class'
        $Context.PackageName = $Response.packageName
        $Context.ActionType = $Response.actionType
        $Context.PrevVersion = $Response.prevVersion
        $Context.Version = $Response.version

        return $Context

    }
}

<#
.SYNOPSIS
    Represents the context of an antivirus alert in the DRMM system, including status and product name.
.DESCRIPTION
    The DRMMAlertContextAntivirus class models the context information specific to antivirus alerts in the DRMM platform. It encapsulates properties such as the antivirus status and product name that provide detailed context about the antivirus alert.
#>
class DRMMAlertContextAntivirus : DRMMAlertContext {

    # The current status of the antivirus alert context.
    [string]$Status
    # The name of the antivirus product associated with the alert context.
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

    # The error message associated with the backup management alert context.
    [string]$ErrorMessage
    # The timeout value related to the backup management alert context.
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

    # The display name of the custom SNMP alert.
    [string]$DisplayName
    # The current value that triggered the custom SNMP alert.
    [string]$CurrentValue
    # The monitor instance associated with the custom SNMP alert.
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

    # The reason for the disk health alert.
    [string]$Reason
    # The type of disk health issue detected.
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

    # The name of the disk associated with the disk usage alert.
    [string]$DiskName
    # The total volume or capacity of the disk.
    [float]$TotalVolume
    # The amount of free space available on the disk.
    [float]$FreeSpace
    # The unit of measure used for disk space values (e.g., bytes, megabytes).
    [string]$UnitOfMeasure
    # The designation or label of the disk associated with the disk usage alert.
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

    # The unique identifier for the endpoint security alert.
    [string]$EsAlertId
    # A description of the endpoint security threat.
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

    # The unique identifier for the endpoint security Windows Defender alert.
    [string]$EsAlertId
    # A description of the endpoint security Windows Defender threat.
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

    # The name of the event log.
    [string]$LogName
    # The code associated with the event log alert.
    [string]$Code
    # The type of the event log alert.
    [string]$Type
    # The source of the event log alert.
    [string]$Source
    # A description of the event log alert.
    [string]$Description
    # The number of times the event log alert has been triggered.
    [int]$TriggerCount
    # The last time the event log alert was triggered.
    [Nullable[datetime]]$LastTriggered
    # Indicates whether the event caused a suspension.
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

    # The reason for the fan alert.
    [string]$Reason
    # The type of fan issue detected.
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

    # A sample value that triggered the alert.
    [float]$Sample
    # The threshold that was exceeded to trigger the alert.
    [float]$Threshold
    # The path of the file or directory involved in the alert.
    [string]$Path
    # The type of object involved in the alert (e.g., file or directory).
    [string]$ObjectType
    # The condition that caused the file system alert.
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
    The DRMMAlertContextGeneric class models a generic alert context in the DRMM platform. It is used when specific context class information is not available, encapsulating a hashtable of properties that provide detailed information about the alert context, along with a companion hashtable that records the .NET type name of each property value. This supports both flexible handling of unrecognised alert context types and schema discovery during beta testing, where the property names, values, and types of undocumented contexts need to be captured for analysis. The GetSummary method provides a quick visual indicator of what data was captured.
#>
class DRMMAlertContextGeneric : DRMMAlertContext {

    # A hashtable containing properties that provide detailed information about the alert context when specific context class information is not available.
    [hashtable]$Properties
    [hashtable]$PropertyTypes

    DRMMAlertContextGeneric() : base() {

    }

    <#
    .SYNOPSIS
        Gets a summary of the generic alert context, including the class name and property names.
    .DESCRIPTION
        The GetSummary method returns a string summarising the generic alert context. It includes the @class value and a list of property names captured from the API response. This provides a quick visual indicator that a generic (unrecognised) context was returned and what data it contains, which is useful for identifying undocumented alert context types during beta testing.
    #>
    [string] GetSummary() {

        $PropertyNames = if ($this.Properties -and $this.Properties.Count -gt 0) {

            $this.Properties.Keys -join ', '

        } else {

            'none'

        }

        $ClassLabel = if ($this.Class) {$this.Class} else {'<no @class>'}

        return "[Generic] $ClassLabel — Properties: $PropertyNames"

    }

    static [DRMMAlertContextGeneric] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextGeneric]::new()
        $Context.Class = $Response.'@class'
        
        # Store all properties and their types except @class
        $Context.Properties = @{}
        $Context.PropertyTypes = @{}
        foreach ($Property in $Response.PSObject.Properties) {

            if ($Property.Name -ne '@class') {

                $Context.Properties[$Property.Name] = $Property.Value

                if ($null -ne $Property.Value) {

                    $Context.PropertyTypes[$Property.Name] = $Property.Value.GetType().Name

                } else {

                    $Context.PropertyTypes[$Property.Name] = '<null>'

                }
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

    # A description of the network monitor alert.
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

    # The current online or offline status associated with the alert.
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

    # The unique identifier for the patch.
    [string]$PatchUid
    # The unique identifier for the policy associated with the patch.
    [string]$PolicyUid
    # The result of the patch operation.
    [string]$Result
    # Additional information about the patch alert.
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

    # The name of the instance associated with the ping alert.
    [string]$InstanceName
    # The roundtrip time of the ping.
    [int]$RoundtripTime
    # The reasons for the ping alert.
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

    # The IP address of the printer.
    [string]$IpAddress
    # The MAC address of the printer.
    [string]$MacAddress
    # The index of the marker supply in the printer.
    [int]$MarkerSupplyIndex
    # The current level of the printer marker supply.
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

    # The reason for the PSU alert.
    [string]$Reason
    # The type of PSU alert.
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

    # The current state of the ransomware alert.
    [int]$State
    # The confidence factor indicating the likelihood of a ransomware event.
    [int]$ConfidenceFactor
    # The directories affected by the ransomware.
    [string[]]$AffectedDirectories
    # The paths being watched for ransomware activity.
    [string[]]$WatchPaths
    # The ransomware extension associated with the alert.
    [string]$Rwextension
    # The time when the meta alert related to the ransomware was generated.
    [Nullable[datetime]]$MetaAlertTime
    # The time when the ransomware alert was generated.
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

    # The name of the process associated with the resource usage alert.
    [string]$ProcessName
    # The sample value indicating the resource usage.
    [float]$Sample
    # The type of resource being monitored.
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

    # A hashtable of sample values associated with the script alert.
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

    # The name of the product generating the security center alert.
    [string]$ProductName
    # The type of the security center alert.
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

    # The current status of the security management alert.
    [int]$Status
    # The name of the product generating the security management alert.
    [string]$ProductName
    # The time when the information was recorded.
    [int]$InfoTime
    # The name of the virus associated with the alert.
    [string]$VirusName
    # The files infected by the security threat.
    [string[]]$InfectedFiles
    # The number of days the product has not been updated.
    [int]$ProductNotUpdatedForDays
    # The number of hours the system remains infected.
    [int]$SystemRemainsInfectedForHours
    # The number of days until the license expires.
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

    # The IP address involved in the SNMP probe alert.
    [string]$IpAddress
    # The Object Identifier (OID) relevant to the SNMP probe alert.
    [string]$Oid
    # The name of the rule that triggered the SNMP probe alert.
    [string]$RuleName
    # The response value received from the SNMP probe.
    [string]$ResponseValue
    # The name of the device associated with the SNMP probe alert.
    [string]$DeviceName
    # The name of the monitor related to the SNMP probe alert.
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
        $Context.Oid = $Response.oid
        $Context.RuleName = $Response.ruleName
        $Context.ResponseValue = $Response.responseValue
        $Context.DeviceName = $Response.deviceName
        $Context.MonitorName = $Response.monitorName

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

    # The name of the process associated with the status alert.
    [string]$ProcessName
    # The current status of the process.
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

    # The degree of the temperature alert.
    [float]$Degree
    # The type of temperature alert.
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

    # The value that indicates the Windows performance metric.
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

    # The value that indicates the WMI metric or status.
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

    # Indicates whether the alert sends emails.
    [bool]$SendsEmails
    # Indicates whether the alert creates a ticket.
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
    .OUTPUTS
        A summary string indicating the email and ticket creation configuration of the alert monitor.
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

    # The unique identifier of the device associated with the alert.
    [string]$DeviceUid
    # The name of the device associated with the alert.
    [string]$DeviceName
    # The unique identifier of the site associated with the alert.
    [string]$SiteUid
    # The name of the site associated with the alert.
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
    .OUTPUTS
        A summary string for the alert source information, including device and site details.
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

    # The time when the action was taken.
    [Nullable[datetime]]$ActionTime
    # The type of action taken.
    [string]$ActionType
    # Description of the action taken.
    [string]$Description
    # Reference to the action taken.
    [string]$ActionReference
    # Internal reference identifier for the action.
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
    .OUTPUTS
        A summary string for the alert response action, including action type and description.
    #>
    [string] GetSummary() {

        $Type = if ($this.ActionType) { $this.ActionType } else { 'Unknown' }
        $Desc = if ($this.Description) { $this.Description } else { '' }

        return "${Type}: ${Desc}"

    }
}