# about_DRMMAlertContext

## SHORT DESCRIPTION

Represents the context of an alert in the DRMM system, including its class and specific details based on the type of alert.

## LONG DESCRIPTION

The DRMMAlertContext class models the context information associated with an alert in the DRMM platform. It includes a property for the class of the context, which indicates the type of alert context (e

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMAlertContext class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Class | string | The class of the alert context, indicating the type of context information associated with the alert. |

## METHODS

The DRMMAlertContext class provides the following methods:

### GetSummary()

Gets a summary of the alert context.

**Returns:** `string` - A summary string of the alert context.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMAlert/about_DRMMAlertContext.md)
- [DRMMAlert](../../../commands/DRMMAlert.md)
- [DRMMAlertContextAntivirus](../../../commands/DRMMAlertContextAntivirus.md)
- [DRMMAlertContextBackupManagement](../../../commands/DRMMAlertContextBackupManagement.md)
- [DRMMAlertContextCustomSNMP](../../../commands/DRMMAlertContextCustomSNMP.md)
- [DRMMAlertContextDiskHealth](../../../commands/DRMMAlertContextDiskHealth.md)
- [DRMMAlertContextDiskUsage](../../../commands/DRMMAlertContextDiskUsage.md)
- [DRMMAlertContextEndpointSecurityThreat](../../../commands/DRMMAlertContextEndpointSecurityThreat.md)
- [DRMMAlertContextEndpointSecurityWindowsDefender](../../../commands/DRMMAlertContextEndpointSecurityWindowsDefender.md)
- [DRMMAlertContextEventLog](../../../commands/DRMMAlertContextEventLog.md)
- [DRMMAlertContextFan](../../../commands/DRMMAlertContextFan.md)
- [DRMMAlertContextFileSystem](../../../commands/DRMMAlertContextFileSystem.md)
- [DRMMAlertContextGeneric](../../../commands/DRMMAlertContextGeneric.md)
- [DRMMAlertContextNetworkMonitor](../../../commands/DRMMAlertContextNetworkMonitor.md)
- [DRMMAlertContextOnlineOfflineStatus](../../../commands/DRMMAlertContextOnlineOfflineStatus.md)
- [DRMMAlertContextPatch](../../../commands/DRMMAlertContextPatch.md)
- [DRMMAlertContextPing](../../../commands/DRMMAlertContextPing.md)
- [DRMMAlertContextPrinter](../../../commands/DRMMAlertContextPrinter.md)
- [DRMMAlertContextPsu](../../../commands/DRMMAlertContextPsu.md)
- [DRMMAlertContextRansomWare](../../../commands/DRMMAlertContextRansomWare.md)
- [DRMMAlertContextResourceUsage](../../../commands/DRMMAlertContextResourceUsage.md)
- [DRMMAlertContextScript](../../../commands/DRMMAlertContextScript.md)
- [DRMMAlertContextSecCenter](../../../commands/DRMMAlertContextSecCenter.md)
- [DRMMAlertContextSecurityManagement](../../../commands/DRMMAlertContextSecurityManagement.md)
- [DRMMAlertContextSNMPProbe](../../../commands/DRMMAlertContextSNMPProbe.md)
- [DRMMAlertContextStatus](../../../commands/DRMMAlertContextStatus.md)
- [DRMMAlertContextTemperature](../../../commands/DRMMAlertContextTemperature.md)
- [DRMMAlertContextWindowsPerformance](../../../commands/DRMMAlertContextWindowsPerformance.md)
- [DRMMAlertContextWmi](../../../commands/DRMMAlertContextWmi.md)

