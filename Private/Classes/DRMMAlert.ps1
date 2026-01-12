using module '.\DRMMObject.psm1'

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
    [Nullable[guid]]$SiteUid

    DRMMAlert() : base() {

    }

    static [DRMMAlert] FromAPIMethod([pscustomobject]$Response, [Nullable[guid]]$SiteUid) {

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
        $Alert.SiteUid = $SiteUid

        $Alert.AlertMonitorInfo = [DRMMAlertMonitorInfo]::FromAPIMethod($Response.alertMonitorInfo)
        $Alert.AlertContext = [DRMMAlertContext]::FromAPIMethod($Response.alertContext)
        $Alert.AlertSourceInfo = [DRMMAlertSourceInfo]::FromAPIMethod($Response.alertSourceInfo)

        if ($null -ne $Response.responseActions) {

            $Alert.ResponseActions = $Response.responseActions | ForEach-Object {

                [DRMMAlertResponseAction]::FromAPIMethod($_)
                
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

    [bool] IsOpen() {return (-not $this.Resolved)}
    [bool] IsCritical() {return ($this.Priority -eq 'Critical')}
    [bool] IsHigh() {return ($this.Priority -eq 'High')}

    [void] Resolve() {
        
        if (-not $this.AlertUid) {

            throw "Alert does not have a valid AlertUid"
            
        }

        Resolve-RMMAlert -AlertUid $this.AlertUid

    }

    [string] GetSummary() {

        $StatusValue = if ($this.Resolved) {'Resolved'} else {'Open'}
        $MutedValue = if ($this.Muted) {' (Muted)'} else {''}
        $DeviceName = if ($this.AlertSourceInfo.DeviceName) {$this.AlertSourceInfo.DeviceName} else {'Unknown'}
        $MonitorCategory = if ($this.AlertMonitorInfo.Category) {$this.AlertMonitorInfo.Category} else {'Unknown'}
        $MonitorDesc = if ($this.AlertMonitorInfo.Description) {$this.AlertMonitorInfo.Description} else {'No description'}

        return "[$StatusValue$MutedValue] $($this.Priority) - $DeviceName - $MonitorCategory`: $MonitorDesc"

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
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Status = [DRMMObject]::GetValue($Response, 'status')
        $Context.ProductName = [DRMMObject]::GetValue($Response, 'productName')

        return $Context

    }
}

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
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.ErrorMessage = [DRMMObject]::GetValue($Response, 'errorMessage')
        $Context.Timeout = [DRMMObject]::GetValue($Response, 'timeout')

        return $Context

    }
}

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
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.DisplayName = [DRMMObject]::GetValue($Response, 'displayName')
        $Context.CurrentValue = [DRMMObject]::GetValue($Response, 'currentValue')
        $Context.MonitorInstance = [DRMMObject]::GetValue($Response, 'monitorInstance')

        return $Context

    }
}

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
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Reason = [DRMMObject]::GetValue($Response, 'reason')
        $Context.Type = [DRMMObject]::GetValue($Response, 'type')

        return $Context

    }
}

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
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.DiskName = [DRMMObject]::GetValue($Response, 'diskName')
        $Context.TotalVolume = [DRMMObject]::GetValue($Response, 'totalVolume')
        $Context.FreeSpace = [DRMMObject]::GetValue($Response, 'freeSpace')
        $Context.UnitOfMeasure = [DRMMObject]::GetValue($Response, 'unitOfMeasure')
        $Context.DiskNameDesignation = [DRMMObject]::GetValue($Response, 'diskNameDesignation')

        return $Context

    }
}

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
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.EsAlertId = [DRMMObject]::GetValue($Response, 'esAlertId')
        $Context.Description = [DRMMObject]::GetValue($Response, 'description')

        return $Context

    }
}

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
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.EsAlertId = [DRMMObject]::GetValue($Response, 'esAlertId')
        $Context.Description = [DRMMObject]::GetValue($Response, 'description')

        return $Context

    }
}

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
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Reason = [DRMMObject]::GetValue($Response, 'reason')
        $Context.Type = [DRMMObject]::GetValue($Response, 'type')

        return $Context

    }
}

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
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Sample = [DRMMObject]::GetValue($Response, 'sample')
        $Context.Threshold = [DRMMObject]::GetValue($Response, 'threshold')
        $Context.Path = [DRMMObject]::GetValue($Response, 'path')
        $Context.ObjectType = [DRMMObject]::GetValue($Response, 'objectType')
        $Context.Condition = [DRMMObject]::GetValue($Response, 'condition')

        return $Context

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

class DRMMAlertContextNetworkMonitor : DRMMAlertContext {

    [string]$Description

    DRMMAlertContextNetworkMonitor() : base() {

    }

    static [DRMMAlertContextNetworkMonitor] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextNetworkMonitor]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Description = [DRMMObject]::GetValue($Response, 'description')

        return $Context

    }
}

class DRMMAlertContextOnlineOfflineStatus : DRMMAlertContext {

    [string]$Status

    DRMMAlertContextOnlineOfflineStatus() : base() {

    }

    static [DRMMAlertContextOnlineOfflineStatus] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextOnlineOfflineStatus]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Status = [DRMMObject]::GetValue($Response, 'status')

        return $Context

    }
}

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
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.PatchUid = [DRMMObject]::GetValue($Response, 'patchUid')
        $Context.PolicyUid = [DRMMObject]::GetValue($Response, 'policyUid')
        $Context.Result = [DRMMObject]::GetValue($Response, 'result')
        $Context.Info = [DRMMObject]::GetValue($Response, 'info')

        return $Context

    }
}

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
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.InstanceName = [DRMMObject]::GetValue($Response, 'instanceName')
        $Context.RoundtripTime = [DRMMObject]::GetValue($Response, 'roundtripTime')
        $Context.Reasons = [DRMMObject]::GetValue($Response, 'reasons')

        return $Context

    }
}

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
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.IpAddress = [DRMMObject]::GetValue($Response, 'ipAddress')
        $Context.MacAddress = [DRMMObject]::GetValue($Response, 'macAddress')
        $Context.MarkerSupplyIndex = [DRMMObject]::GetValue($Response, 'markerSupplyIndex')
        $Context.CurrentLevel = [DRMMObject]::GetValue($Response, 'currentLevel')

        return $Context

    }
}

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
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Reason = [DRMMObject]::GetValue($Response, 'reason')
        $Context.Type = [DRMMObject]::GetValue($Response, 'type')

        return $Context

    }
}

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
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.ProcessName = [DRMMObject]::GetValue($Response, 'processName')
        $Context.Sample = [DRMMObject]::GetValue($Response, 'sample')
        $Context.Type = [DRMMObject]::GetValue($Response, 'type')

        return $Context

    }
}

class DRMMAlertContextScript : DRMMAlertContext {

    [hashtable]$Samples

    DRMMAlertContextScript() : base() {

    }

    static [DRMMAlertContextScript] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextScript]::new()
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
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.ProductName = [DRMMObject]::GetValue($Response, 'productName')
        $Context.AlertType = [DRMMObject]::GetValue($Response, 'alertType')

        return $Context

    }
}

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
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.ProcessName = [DRMMObject]::GetValue($Response, 'processName')
        $Context.Status = [DRMMObject]::GetValue($Response, 'status')

        return $Context

    }
}

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
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Degree = [DRMMObject]::GetValue($Response, 'degree')
        $Context.Type = [DRMMObject]::GetValue($Response, 'type')

        return $Context

    }
}

class DRMMAlertContextWindowsPerformance : DRMMAlertContext {

    [float]$Value

    DRMMAlertContextWindowsPerformance() : base() {

    }

    static [DRMMAlertContextWindowsPerformance] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextWindowsPerformance]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Value = [DRMMObject]::GetValue($Response, 'value')

        return $Context

    }
}

class DRMMAlertContextWmi : DRMMAlertContext {

    [string]$Value

    DRMMAlertContextWmi() : base() {

    }

    static [DRMMAlertContextWmi] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Context = [DRMMAlertContextWmi]::new()
        $Context.Class = [DRMMObject]::GetValue($Response, '@class')
        $Context.Value = [DRMMObject]::GetValue($Response, 'value')

        return $Context

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

    [string] GetSummary() {

        $Type = if ($this.ActionType) { $this.ActionType } else { 'Unknown' }
        $Desc = if ($this.Description) { $this.Description } else { '' }

        return "${Type}: ${Desc}"

    }
}

