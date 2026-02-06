# about_DRMMAlertContextCustomSNMP

## SHORT DESCRIPTION

Represents the context of a custom SNMP alert in the DRMM system, including display name, current value, and monitor instance information.

## LONG DESCRIPTION

The DRMMAlertContextCustomSNMP class models the context information specific to custom SNMP alerts in the DRMM platform. It encapsulates properties such as the display name of the alert, the current value that triggered the alert, and the monitor instance associated with the alert.

This class inherits from [DRMMAlertContext](./about_DRMMAlertContext.md).

## PROPERTIES

The DRMMAlertContextCustomSNMP class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DisplayName     | string | The display name of the custom SNMP alert. |
| CurrentValue    | string | The current value that triggered the custom SNMP alert. |
| MonitorInstance | string | The monitor instance associated with the custom SNMP alert. |

## METHODS

The DRMMAlertContextCustomSNMP class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMAlert/about_DRMMAlertContextCustomSNMP.md)
- [DRMMAlert](../../../commands/DRMMAlert.md)
- [DRMMAlertContext](../../../commands/DRMMAlertContext.md)

