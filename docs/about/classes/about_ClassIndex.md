# DattoRMM.Core Class Reference

A reference index of all classes and enums defined in the DattoRMM.Core module, organised by domain.

## Contents

- [DRMMAccount](#drmmaccount)
- [DRMMActivityLog](#drmmactivitylog)
- [DRMMAlert](#drmmalert)
- [DRMMAPIKeySecret](#drmmapikeysecret)
- [DRMMComponent](#drmmcomponent)
- [DRMMDevice](#drmmdevice)
- [DRMMDeviceAudit](#drmmdeviceaudit)
- [DRMMEsxiHostAudit](#drmmesxihostaudit)
- [DRMMFilter](#drmmfilter)
- [DRMMJob](#drmmjob)
- [DRMMNetMapping](#drmmnetmapping)
- [DRMMNetworkInterface](#drmmnetworkinterface)
- [DRMMObject](#drmmobject)
- [DRMMPrinterAudit](#drmmprinteraudit)
- [DRMMSite](#drmmsite)
- [DRMMStatus](#drmmstatus)
- [DRMMThrottleStatus](#drmmthrottlestatus)
- [DRMMToken](#drmmtoken)
- [DRMMUser](#drmmuser)
- [DRMMVariable](#drmmvariable)
- [Enums](#enums)

## DRMMAccount

| Class | Synopsis |
| ----- | -------- |
| [`DRMMAccount`](DRMMAccount/about_DRMMAccount.md) | Represents an account in the DRMM system, including its properties and related information. |
| [`DRMMAccountDescriptor`](DRMMAccount/about_DRMMAccountDescriptor.md) | Represents the descriptor information for a DRMM account, including billing and timezone details. |
| [`DRMMAccountDevicesStatus`](DRMMAccount/about_DRMMAccountDevicesStatus.md) | Represents the device status information for a DRMM account, including counts of devices in various states. |

## DRMMActivityLog

| Class | Synopsis |
| ----- | -------- |
| [`DRMMActivityLog`](DRMMActivityLog/about_DRMMActivityLog.md) | Represents an activity log entry in the DRMM system, including details about the activity, associated site and user information, and related context. |
| [`DRMMActivityLogDetails`](DRMMActivityLog/about_DRMMActivityLogDetails.md) | Represents the 'Details' Property of a DRMMActivityLog entry, which can contain arbitrary key-value pairs with additional information about the activity. |
| [`DRMMActivityLogDetailsGeneric`](DRMMActivityLog/about_DRMMActivityLogDetailsGeneric.md) | Represents a generic implementation of the DRMMActivityLogDetails class, which can handle arbitrary key-value pairs from the API response. |
| [`DRMMActivityLogEntityDevice`](DRMMActivityLog/about_DRMMActivityLogEntityDevice.md) | Base class for DEVICE entity activity log details, containing properties common to all DEVICE activities. |
| [`DRMMActivityLogDetailsDeviceGeneric`](DRMMActivityLog/about_DRMMActivityLogDetailsDeviceGeneric.md) | Represents a generic DEVICE entity activity log for unknown categories, with entity-level properties and dynamic additional properties. |
| [`DRMMActivityLogEntityUser`](DRMMActivityLog/about_DRMMActivityLogEntityUser.md) | Base class for USER entity activity log details, containing properties common to all USER activities. |
| [`DRMMActivityLogDetailsUserGeneric`](DRMMActivityLog/about_DRMMActivityLogDetailsUserGeneric.md) | Represents a generic USER entity activity log for unknown categories, with entity-level properties and dynamic additional properties. |
| [`DRMMActivityLogDetailsDeviceJob`](DRMMActivityLog/about_DRMMActivityLogDetailsDeviceJob.md) | Base class for DEVICE job-related activity log details, containing properties common to all job actions. |
| [`DRMMActivityLogDetailsDeviceJobGeneric`](DRMMActivityLog/about_DRMMActivityLogDetailsDeviceJobGeneric.md) | Represents a generic DEVICE job activity log details for unknown job actions, with base properties and dynamic additional properties. |
| [`DRMMActivityLogDetailsDeviceJobDeployment`](DRMMActivityLog/about_DRMMActivityLogDetailsDeviceJobDeployment.md) | Represents an activity log of entity DEVICE, category job, and action deployment, which includes specific properties related to job deployment activities. |
| [`DRMMActivityLogDetailsDeviceJobCreate`](DRMMActivityLog/about_DRMMActivityLogDetailsDeviceJobCreate.md) | Represents an activity log of entity DEVICE, category job, and action create, which includes specific properties related to job creation activities. |
| [`DRMMActivityLogDetailsRemoteSessionDetail`](DRMMActivityLog/about_DRMMActivityLogDetailsRemoteSessionDetail.md) | Represents a detail item within a remote session activity log, including action, detail text, and name. |
| [`DRMMActivityLogDetailsDeviceRemote`](DRMMActivityLog/about_DRMMActivityLogDetailsDeviceRemote.md) | Base class for DEVICE remote-related activity log details, containing properties common to all remote session actions. |
| [`DRMMActivityLogDetailsDeviceRemoteGeneric`](DRMMActivityLog/about_DRMMActivityLogDetailsDeviceRemoteGeneric.md) | Represents a generic DEVICE remote activity log details for unknown remote actions, with base properties and dynamic additional properties. |
| [`DRMMActivityLogDetailsDeviceRemoteChat`](DRMMActivityLog/about_DRMMActivityLogDetailsDeviceRemoteChat.md) | Represents an activity log of entity DEVICE, category remote, and action chat, which includes specific properties related to remote chat session activities. |
| [`DRMMActivityLogDetailsDeviceRemoteJrto`](DRMMActivityLog/about_DRMMActivityLogDetailsDeviceRemoteJrto.md) | Represents an activity log of entity DEVICE, category remote, and action jrto (Jump Remote Take Over), which includes specific properties related to JRTO session activities. |
| [`DRMMActivityLogDetailsDeviceDevice`](DRMMActivityLog/about_DRMMActivityLogDetailsDeviceDevice.md) | Base class for DEVICE device-related activity log details, containing properties common to all device actions. |
| [`DRMMActivityLogDetailsDeviceDeviceGeneric`](DRMMActivityLog/about_DRMMActivityLogDetailsDeviceDeviceGeneric.md) | Represents a generic DEVICE device activity log details for unknown device actions, with base properties and dynamic additional properties. |
| [`DRMMActivityLogDetailsDeviceDeviceMoveDevice`](DRMMActivityLog/about_DRMMActivityLogDetailsDeviceDeviceMoveDevice.md) | Represents an activity log of entity DEVICE, category device, and action move |
| [`DRMMActivityLogSite`](DRMMActivityLog/about_DRMMActivityLogSite.md) | Represents site information associated with a DRMM activity log entry, including site ID and name. |
| [`DRMMActivityLogUser`](DRMMActivityLog/about_DRMMActivityLogUser.md) | Represents user information associated with a DRMM activity log entry, including user ID, username, and name details. |

## DRMMAlert

| Class | Synopsis |
| ----- | -------- |
| [`DRMMAlert`](DRMMAlert/about_DRMMAlert.md) | Represents an alert in the DRMM system, including its properties, context, source information, and response actions. |
| [`DRMMAlertContext`](DRMMAlert/about_DRMMAlertContext.md) | Represents the context of an alert in the DRMM system, including its class and specific details based on the type of alert. |
| [`DRMMAlertContextAction`](DRMMAlert/about_DRMMAlertContextAction.md) | Represents the context of an action alert in the DRMM system, including package name, action type, and version information. |
| [`DRMMAlertContextAntivirus`](DRMMAlert/about_DRMMAlertContextAntivirus.md) | Represents the context of an antivirus alert in the DRMM system, including status and product name. |
| [`DRMMAlertContextBackupManagement`](DRMMAlert/about_DRMMAlertContextBackupManagement.md) | Represents the context of a backup management alert in the DRMM system, including error messages and timeout information. |
| [`DRMMAlertContextCustomSNMP`](DRMMAlert/about_DRMMAlertContextCustomSNMP.md) | Represents the context of a custom SNMP alert in the DRMM system, including display name, current value, and monitor instance information. |
| [`DRMMAlertContextDiskHealth`](DRMMAlert/about_DRMMAlertContextDiskHealth.md) | Represents the context of a disk health alert in the DRMM system, including the reason for the alert and the type of issue detected. |
| [`DRMMAlertContextDiskUsage`](DRMMAlert/about_DRMMAlertContextDiskUsage.md) | Represents the context of a disk usage alert in the DRMM system, including details about the disk, total volume, free space, and unit of measure. |
| [`DRMMAlertContextEndpointSecurityThreat`](DRMMAlert/about_DRMMAlertContextEndpointSecurityThreat.md) | Represents the context of an endpoint security threat alert in the DRMM system, including alert ID and description. |
| [`DRMMAlertContextEndpointSecurityWindowsDefender`](DRMMAlert/about_DRMMAlertContextEndpointSecurityWindowsDefender.md) | Represents the context of an endpoint security Windows Defender alert in the DRMM system, including alert ID and description. |
| [`DRMMAlertContextEventLog`](DRMMAlert/about_DRMMAlertContextEventLog.md) | Represents the context of an event log alert in the DRMM system, including log name, code, type, source, description, trigger count, last triggered time, and suspension status. |
| [`DRMMAlertContextFan`](DRMMAlert/about_DRMMAlertContextFan.md) | Represents the context of a fan alert in the DRMM system, including reason and type. |
| [`DRMMAlertContextFileSystem`](DRMMAlert/about_DRMMAlertContextFileSystem.md) | Represents the context of a file system alert in the DRMM system, including sample value, threshold, path, object type, and condition. |
| [`DRMMAlertContextGeneric`](DRMMAlert/about_DRMMAlertContextGeneric.md) | Represents a generic alert context in the DRMM system when specific context class information is not available. |
| [`DRMMAlertContextNetworkMonitor`](DRMMAlert/about_DRMMAlertContextNetworkMonitor.md) | Represents the context of a network monitor alert in the DRMM system, including a description of the alert. |
| [`DRMMAlertContextOnlineOfflineStatus`](DRMMAlert/about_DRMMAlertContextOnlineOfflineStatus.md) | Represents the context of an online/offline status alert in the DRMM system, including the current status. |
| [`DRMMAlertContextPatch`](DRMMAlert/about_DRMMAlertContextPatch.md) | Represents the context of a patch alert in the DRMM system, including patch UID, policy UID, result, and additional information. |
| [`DRMMAlertContextPing`](DRMMAlert/about_DRMMAlertContextPing.md) | Represents the context of a ping alert in the DRMM system, including instance name, roundtrip time, and reasons for the alert. |
| [`DRMMAlertContextPrinter`](DRMMAlert/about_DRMMAlertContextPrinter.md) | Represents the context of a printer alert in the DRMM system, including IP address, MAC address, marker supply index, and current level. |
| [`DRMMAlertContextPsu`](DRMMAlert/about_DRMMAlertContextPsu.md) | Represents the context of a PSU (Power Supply Unit) alert in the DRMM system, including reason and type of the alert. |
| [`DRMMAlertContextRansomWare`](DRMMAlert/about_DRMMAlertContextRansomWare.md) | Represents the context of a ransomware alert in the DRMM system, including state, confidence factor, affected directories, watch paths, ransomware extension, and alert times. |
| [`DRMMAlertContextResourceUsage`](DRMMAlert/about_DRMMAlertContextResourceUsage.md) | Represents the context of a resource usage alert in the DRMM system, including process name, sample value, and type of resource. |
| [`DRMMAlertContextScript`](DRMMAlert/about_DRMMAlertContextScript.md) | Represents the context of a script alert in the DRMM system, including a hashtable of sample values. |
| [`DRMMAlertContextSecCenter`](DRMMAlert/about_DRMMAlertContextSecCenter.md) | Represents the context of a security center alert in the DRMM system, including product name and alert type. |
| [`DRMMAlertContextSecurityManagement`](DRMMAlert/about_DRMMAlertContextSecurityManagement.md) | Represents the context of a security management alert in the DRMM system, including status, product name, information time, virus name, infected files, and other related properties. |
| [`DRMMAlertContextSNMPProbe`](DRMMAlert/about_DRMMAlertContextSNMPProbe.md) | Represents the context of an SNMP probe alert in the DRMM system, including IP address, OID, rule name, response value, device name, and monitor name. |
| [`DRMMAlertContextStatus`](DRMMAlert/about_DRMMAlertContextStatus.md) | Represents the context of a status alert in the DRMM system, including process name and status information. |
| [`DRMMAlertContextTemperature`](DRMMAlert/about_DRMMAlertContextTemperature.md) | Represents the context of a temperature alert in the DRMM system, including degree and type of temperature issue. |
| [`DRMMAlertContextWindowsPerformance`](DRMMAlert/about_DRMMAlertContextWindowsPerformance.md) | Represents the context of a Windows performance alert in the DRMM system, including a value that indicates the performance metric. |
| [`DRMMAlertContextWmi`](DRMMAlert/about_DRMMAlertContextWmi.md) | Represents the context of a WMI alert in the DRMM system, including a value that indicates the WMI metric or status. |
| [`DRMMAlertMonitorInfo`](DRMMAlert/about_DRMMAlertMonitorInfo.md) | Represents the monitor information for an alert in the DRMM system, including whether the alert sends emails and creates tickets. |
| [`DRMMAlertSourceInfo`](DRMMAlert/about_DRMMAlertSourceInfo.md) | Represents the source information for an alert in the DRMM system, including device and site details. |
| [`DRMMAlertResponseAction`](DRMMAlert/about_DRMMAlertResponseAction.md) | Represents a response action taken for an alert in the DRMM system, including action time, type, description, and references. |

## DRMMAPIKeySecret

| Class | Synopsis |
| ----- | -------- |
| [`DRMMAPIKeySecret`](DRMMAPIKeySecret/about_DRMMAPIKeySecret.md) | Represents API key and secret information for authenticating with the DRMM API. |

## DRMMComponent

| Class | Synopsis |
| ----- | -------- |
| [`DRMMComponent`](DRMMComponent/about_DRMMComponent.md) | Represents a component in the DRMM system, including its properties and associated variables. |
| [`DRMMComponentVariable`](DRMMComponent/about_DRMMComponentVariable.md) | Represents a variable associated with a DRMM component, including its name, type, direction, and other metadata. |

## DRMMDevice

| Class | Synopsis |
| ----- | -------- |
| [`DRMMDevice`](DRMMDevice/about_DRMMDevice.md) | Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device. |
| [`DRMMDeviceAntivirusInfo`](DRMMDevice/about_DRMMDeviceAntivirusInfo.md) | Represents antivirus information for a device in the DRMM system, including the antivirus product name and its status. |
| [`DRMMDeviceNetworkInterface`](DRMMDevice/about_DRMMDeviceNetworkInterface.md) | Represents a network interface associated with a device in the DRMM system. |
| [`DRMMDeviceType`](DRMMDevice/about_DRMMDeviceType.md) | Represents a device type in the DRMM system. |
| [`DRMMDeviceUdfs`](DRMMDevice/about_DRMMDeviceUdfs.md) | Represents user-defined fields (UDFs) associated with a device in the DRMM system. |
| [`DRMMDevicePatchManagement`](DRMMDevice/about_DRMMDevicePatchManagement.md) | Represents patch management information for a device in the DRMM system. |

## DRMMDeviceAudit

| Class | Synopsis |
| ----- | -------- |
| [`DRMMDeviceAudit`](DRMMDeviceAudit/about_DRMMDeviceAudit.md) | Represents a comprehensive audit of a device, including hardware, software, and network information. |
| [`DRMMDeviceAuditAttachedDevice`](DRMMDeviceAudit/about_DRMMDeviceAuditAttachedDevice.md) | Represents an attached device in a device audit, including its description and instance information. |
| [`DRMMDeviceAuditBaseBoard`](DRMMDeviceAudit/about_DRMMDeviceAuditBaseBoard.md) | Represents the baseboard information of a device in a device audit, including manufacturer, product, and serial number. |
| [`DRMMDeviceAuditBios`](DRMMDeviceAudit/about_DRMMDeviceAuditBios.md) | Represents the BIOS information of a device in a device audit, including manufacturer, name, serial number, and SMBIOS BIOS version. |
| [`DRMMDeviceAuditDisplay`](DRMMDeviceAudit/about_DRMMDeviceAuditDisplay.md) | Represents the display information of a device in a device audit, including instance, screen height, and screen width. |
| [`DRMMDeviceAuditLogicalDisk`](DRMMDeviceAudit/about_DRMMDeviceAuditLogicalDisk.md) | Represents the logical disk information of a device in a device audit, including description, disk identifier, free space, and size. |
| [`DRMMDeviceAuditMobileInfo`](DRMMDeviceAudit/about_DRMMDeviceAuditMobileInfo.md) | Represents the mobile information of a device in a device audit, including ICCID, IMEI, number, and operator. |
| [`DRMMDeviceAuditPhysicalMemory`](DRMMDeviceAudit/about_DRMMDeviceAuditPhysicalMemory.md) | Represents the physical memory information of a device in a device audit, including bank label, capacity, manufacturer, part number, serial number, and speed. |
| [`DRMMDeviceAuditProcessor`](DRMMDeviceAudit/about_DRMMDeviceAuditProcessor.md) | Represents the processor information of a device in a device audit, including its name. |
| [`DRMMDeviceAuditSnmpInfo`](DRMMDeviceAudit/about_DRMMDeviceAuditSnmpInfo.md) | Represents the SNMP information of a device in a device audit, including contact, description, location, and name. |
| [`DRMMDeviceAuditSoftware`](DRMMDeviceAudit/about_DRMMDeviceAuditSoftware.md) | Represents the software information of a device in a device audit, including its name and version. |
| [`DRMMDeviceAuditSystemInfo`](DRMMDeviceAudit/about_DRMMDeviceAuditSystemInfo.md) | Represents the system information of a device in a device audit, including manufacturer, model, total physical memory, username, |
| [`DRMMDeviceAuditVideoBoard`](DRMMDeviceAudit/about_DRMMDeviceAuditVideoBoard.md) | Represents the video board information of a device in a device audit, including its display adapter name. |

## DRMMEsxiHostAudit

| Class | Synopsis |
| ----- | -------- |
| [`DRMMEsxiDatastore`](DRMMEsxiHostAudit/about_DRMMEsxiDatastore.md) | Represents the audit information of an ESXi host, including system info, guests, processors, network interfaces, physical memory, and datastores. |
| [`DRMMEsxiGuest`](DRMMEsxiHostAudit/about_DRMMEsxiGuest.md) | Represents a guest virtual machine on an ESXi host, including its name, processor speed, memory size, number of snapshots, and datastores. |
| [`DRMMEsxiHostAudit`](DRMMEsxiHostAudit/about_DRMMEsxiHostAudit.md) | Represents the audit information of an ESXi host, including system info, guests, processors, network interfaces, physical memory, and datastores. |
| [`DRMMEsxiNic`](DRMMEsxiHostAudit/about_DRMMEsxiNic.md) | Represents a network interface card (NIC) on an ESXi host, including its name, IP addresses, MAC address, speed, and type. |
| [`DRMMEsxiPhysicalMemory`](DRMMEsxiHostAudit/about_DRMMEsxiPhysicalMemory.md) | Represents the physical memory information of an ESXi host, including module, size, type, speed, serial number, part number, and bank. |
| [`DRMMEsxiProcessor`](DRMMEsxiHostAudit/about_DRMMEsxiProcessor.md) | Represents the processor information of an ESXi host, including its frequency, name, and number of cores. |
| [`DRMMEsxiSystemInfo`](DRMMEsxiHostAudit/about_DRMMEsxiSystemInfo.md) | Represents the system information of an ESXi host, including manufacturer, model, name, number of snapshots, and service tag. |

## DRMMFilter

| Class | Synopsis |
| ----- | -------- |
| [`DRMMFilter`](DRMMFilter/about_DRMMFilter.md) | Represents a filter in the DRMM system, including its name, description, type, and scope. |

## DRMMJob

| Class | Synopsis |
| ----- | -------- |
| [`DRMMJob`](DRMMJob/about_DRMMJob.md) | Represents a job in the DRMM system, including its ID, unique identifier, name, creation date, and status. |
| [`DRMMJobComponent`](DRMMJob/about_DRMMJobComponent.md) | Represents a component of a DRMM job, including its unique identifier, name, and associated variables. |
| [`DRMMJobComponentResult`](DRMMJob/about_DRMMJobComponentResult.md) | Represents the result of a DRMM job component, including its unique identifier, name, status, number of warnings, and whether it has standard output or error data. |
| [`DRMMJobComponentVariable`](DRMMJob/about_DRMMJobComponentVariable.md) | Represents a variable associated with a DRMM job component, including its name and value. |
| [`DRMMJobResults`](DRMMJob/about_DRMMJobResults.md) | Represents the results of a DRMM job, including job and device identifiers, the time the job ran, deployment status, and component results. |
| [`DRMMJobStdData`](DRMMJob/about_DRMMJobStdData.md) | Represents standard output or error data associated with a DRMM job component, including job, device, and component identifiers, component name, and the standard data itself. |

## DRMMNetMapping

| Class | Synopsis |
| ----- | -------- |
| [`DRMMNetMapping`](DRMMNetMapping/about_DRMMNetMapping.md) | Represents a network mapping in the DRMM system, including properties such as name, unique identifier, description, associated network IDs, and portal URL. |

## DRMMNetworkInterface

| Class | Synopsis |
| ----- | -------- |
| [`DRMMNetworkInterface`](DRMMNetworkInterface/about_DRMMNetworkInterface.md) | region DRMMNetworkInterface class |

## DRMMObject

| Class | Synopsis |
| ----- | -------- |
| [`DRMMObject`](DRMMObject/about_DRMMObject.md) | region DRMMObject - Base Class |

## DRMMPrinterAudit

| Class | Synopsis |
| ----- | -------- |
| [`DRMMPrinter`](DRMMPrinterAudit/about_DRMMPrinter.md) | Represents the audit information of a printer, including SNMP info, marker supplies, printer details, system info, and network interfaces. |
| [`DRMMPrinterAudit`](DRMMPrinterAudit/about_DRMMPrinterAudit.md) | Represents the audit information of a printer, including SNMP info, marker supplies, printer details, system info, and network interfaces. |
| [`DRMMPrinterMarkerSupply`](DRMMPrinterAudit/about_DRMMPrinterMarkerSupply.md) | Represents the marker supply information of a printer, including description, maximum capacity, and supply level. |
| [`DRMMPrinterSnmpInfo`](DRMMPrinterAudit/about_DRMMPrinterSnmpInfo.md) | Represents the SNMP information of a printer, including SNMP name, contact, description, location, uptime, NIC manufacturer, object ID, and serial number. |
| [`DRMMPrinterSystemInfo`](DRMMPrinterAudit/about_DRMMPrinterSystemInfo.md) | Represents the system information of a printer, including manufacturer and model. |

## DRMMSite

| Class | Synopsis |
| ----- | -------- |
| [`DRMMSite`](DRMMSite/about_DRMMSite.md) | Represents a site in the DRMM system, including its properties, settings, and associated devices and variables. |
| [`DRMMSiteGeneralSettings`](DRMMSite/about_DRMMSiteGeneralSettings.md) | Represents the general settings for a site in the DRMM system, including properties such as name, unique identifier, description, and on-demand status. |
| [`DRMMSiteMailRecipient`](DRMMSite/about_DRMMSiteMailRecipient.md) | Represents a mail recipient for site notifications in the DRMM system, including properties such as name, email, and type. |
| [`DRMMDeletedDevicesSite`](DRMMSite/about_DRMMDeletedDevicesSite.md) | Represents a deleted site in the DRMM system, with properties similar to DRMMSite but with a string type for Uid to handle invalid GUIDs. |
| [`DRMMSiteProxySettings`](DRMMSite/about_DRMMSiteProxySettings.md) | Represents the proxy settings for a site in the DRMM system, including properties such as host, port, type, and authentication credentials. |
| [`DRMMSiteSettings`](DRMMSite/about_DRMMSiteSettings.md) | Represents the overall settings for a site in the DRMM system, including general settings, proxy settings, mail recipients, and site UID. |
| [`DRMMDevicesStatus`](DRMMSite/about_DRMMDevicesStatus.md) | Represents the status of devices associated with a site in the DRMM system, including counts of total devices, online devices, and offline devices. |
| [`DRMMSiteFilter`](DRMMSite/about_DRMMSiteFilter.md) | Represents a site-scoped filter in the DRMM system, extending DRMMFilter with a Site property. |

## DRMMStatus

| Class | Synopsis |
| ----- | -------- |
| [`DRMMStatus`](DRMMStatus/about_DRMMStatus.md) | Represents the status of the DRMM system, including properties such as version, status, and start time. |

## DRMMThrottleStatus

| Class | Synopsis |
| ----- | -------- |
| [`DRMMThrottleBucket`](DRMMThrottleStatus/about_DRMMThrottleBucket.md) | Represents a single rate-limit bucket in the DRMM throttle system, covering read, write, or per-operation buckets. |
| [`DRMMThrottleStatus`](DRMMThrottleStatus/about_DRMMThrottleStatus.md) | Represents the combined throttle and rate-limit status for a DRMM account, merging API-reported data with local tracking state. |

## DRMMToken

| Class | Synopsis |
| ----- | -------- |
| [`DRMMToken`](DRMMToken/about_DRMMToken.md) | Represents an OAuth access token response from the Datto RMM API. |

## DRMMUser

| Class | Synopsis |
| ----- | -------- |
| [`DRMMUser`](DRMMUser/about_DRMMUser.md) | Represents a user in the DRMM system, including properties such as first name, last name, username, email, telephone, status, creation date, last access date, and disabled status. |

## DRMMVariable

| Class | Synopsis |
| ----- | -------- |
| [`DRMMVariable`](DRMMVariable/about_DRMMVariable.md) | Represents a variable in the DRMM system, including its name, value, scope, and other attributes. |

## Enums

| Class | Synopsis |
| ----- | -------- |
| [`RMMSiteExtendedProperty`](Enums/about_RMMSiteExtendedProperty.md) | Defines the extended property types that can be requested when retrieving site information. |
| [`RMMScope`](Enums/about_RMMScope.md) | Defines the scope levels available within the Datto RMM platform. |
| [`RMMPlatform`](Enums/about_RMMPlatform.md) | Defines the available Datto RMM platform instances used for API and portal URL construction. |
| [`RMMThrottleProfile`](Enums/about_RMMThrottleProfile.md) | Defines the API request throttling profiles for controlling request rate limits. |

