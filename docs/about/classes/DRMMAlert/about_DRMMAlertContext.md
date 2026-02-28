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

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMAlert/about_DRMMAlertContext.md)
- [DRMMAlert](./about_DRMMAlert.md)
- [DRMMAlertContextAntivirus](./about_DRMMAlertContextAntivirus.md)
- [DRMMAlertContextBackupManagement](./about_DRMMAlertContextBackupManagement.md)
- [DRMMAlertContextCustomSNMP](./about_DRMMAlertContextCustomSNMP.md)
- [DRMMAlertContextDiskHealth](./about_DRMMAlertContextDiskHealth.md)
- [DRMMAlertContextDiskUsage](./about_DRMMAlertContextDiskUsage.md)
- [DRMMAlertContextEndpointSecurityThreat](./about_DRMMAlertContextEndpointSecurityThreat.md)
- [DRMMAlertContextEndpointSecurityWindowsDefender](./about_DRMMAlertContextEndpointSecurityWindowsDefender.md)
- [DRMMAlertContextEventLog](./about_DRMMAlertContextEventLog.md)
- [DRMMAlertContextFan](./about_DRMMAlertContextFan.md)
- [DRMMAlertContextFileSystem](./about_DRMMAlertContextFileSystem.md)
- [DRMMAlertContextGeneric](./about_DRMMAlertContextGeneric.md)
- [DRMMAlertContextNetworkMonitor](./about_DRMMAlertContextNetworkMonitor.md)
- [DRMMAlertContextOnlineOfflineStatus](./about_DRMMAlertContextOnlineOfflineStatus.md)
- [DRMMAlertContextPatch](./about_DRMMAlertContextPatch.md)
- [DRMMAlertContextPing](./about_DRMMAlertContextPing.md)
- [DRMMAlertContextPrinter](./about_DRMMAlertContextPrinter.md)
- [DRMMAlertContextPsu](./about_DRMMAlertContextPsu.md)
- [DRMMAlertContextRansomWare](./about_DRMMAlertContextRansomWare.md)
- [DRMMAlertContextResourceUsage](./about_DRMMAlertContextResourceUsage.md)
- [DRMMAlertContextScript](./about_DRMMAlertContextScript.md)
- [DRMMAlertContextSecCenter](./about_DRMMAlertContextSecCenter.md)
- [DRMMAlertContextSecurityManagement](./about_DRMMAlertContextSecurityManagement.md)
- [DRMMAlertContextSNMPProbe](./about_DRMMAlertContextSNMPProbe.md)
- [DRMMAlertContextStatus](./about_DRMMAlertContextStatus.md)
- [DRMMAlertContextTemperature](./about_DRMMAlertContextTemperature.md)
- [DRMMAlertContextWindowsPerformance](./about_DRMMAlertContextWindowsPerformance.md)
- [DRMMAlertContextWmi](./about_DRMMAlertContextWmi.md)

