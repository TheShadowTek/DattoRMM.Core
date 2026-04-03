# about_DRMMAlertContext

## SHORT DESCRIPTION

Represents the context of an alert in the DRMM system, including its class and specific details based on the type of alert.

## LONG DESCRIPTION

The DRMMAlertContext class models the context information associated with an alert in the DRMM platform. It includes a property for the class of the context, which indicates the type of alert context. The class provides a static method to create an instance of the appropriate context subclass based on the '@class' property in the API response. If the '@class' property is not present or does not match known types, it defaults to creating an instance of DRMMAlertContextGeneric. Each specific context type has its own properties and parsing logic to capture relevant details for that type of alert context.

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

**Returns:** `string` - Returns string

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMAlert/about_DRMMAlertContext.md)
- [DRMMAlertContextAction](./about_DRMMAlertContextAction.md)
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

