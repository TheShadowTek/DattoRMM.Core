# about_DRMMAlertContextSNMPProbe

## SHORT DESCRIPTION

Represents the context of an SNMP probe alert in the DRMM system, including IP address, OID, rule name, response value, device name, and monitor name.

## LONG DESCRIPTION

The DRMMAlertContextSNMPProbe class models the context information specific to SNMP probe alerts in the DRMM platform. It encapsulates properties such as IP address, OID, rule name, response value, device name, and monitor name that provide detailed context about the SNMP probe alert.

This class inherits from [DRMMAlertContext](./about_DRMMAlertContext.md).

## PROPERTIES

The DRMMAlertContextSNMPProbe class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| IpAddress     | string | The IP address involved in the SNMP probe alert. |
| Oid           | string | The Object Identifier (OID) relevant to the SNMP probe alert. |
| RuleName      | string | The name of the rule that triggered the SNMP probe alert. |
| ResponseValue | string | The response value received from the SNMP probe. |
| DeviceName    | string | The name of the device associated with the SNMP probe alert. |
| MonitorName   | string | The name of the monitor related to the SNMP probe alert. |

## METHODS

The DRMMAlertContextSNMPProbe class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMAlert/about_DRMMAlertContextSNMPProbe.md)
- [DRMMAlert](./about_DRMMAlert.md)
- [DRMMAlertContext](./about_DRMMAlertContext.md)

