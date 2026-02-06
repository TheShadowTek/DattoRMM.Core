# about_DRMMAlertContextPing

## SHORT DESCRIPTION

Represents the context of a ping alert in the DRMM system, including instance name, roundtrip time, and reasons for the alert.

## LONG DESCRIPTION

The DRMMAlertContextPing class models the context information specific to ping alerts in the DRMM platform. It encapsulates properties such as instance name, roundtrip time, and reasons that provide detailed context about the ping alert.

This class inherits from [DRMMAlertContext](./about_DRMMAlertContext.md).

## PROPERTIES

The DRMMAlertContextPing class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| InstanceName  | string   | The name of the instance associated with the ping alert. |
| RoundtripTime | int      | The roundtrip time of the ping. |
| Reasons       | string[] | The reasons for the ping alert. |

## METHODS

The DRMMAlertContextPing class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMAlert/about_DRMMAlertContextPing.md)
- [DRMMAlert](../../../commands/DRMMAlert.md)
- [DRMMAlertContext](../../../commands/DRMMAlertContext.md)

