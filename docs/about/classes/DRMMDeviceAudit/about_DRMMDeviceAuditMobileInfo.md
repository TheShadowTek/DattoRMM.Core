# about_DRMMDeviceAuditMobileInfo

## SHORT DESCRIPTION

Represents the mobile information of a device in a device audit, including ICCID, IMEI, number, and operator.

## LONG DESCRIPTION

The DRMMDeviceAuditMobileInfo class models the information about the mobile connectivity of the audited system. It includes properties such as Iccid, Imei, Number, and Operator, which provide details about the mobile network information of the device. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMDeviceAuditMobileInfo class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Iccid    | string | The ICCID (Integrated Circuit Card Identifier) of the mobile device. |
| Imei     | string | The IMEI (International Mobile Equipment Identity) of the mobile device. |
| Number   | string | The phone number associated with the mobile device. |
| Operator | string | The mobile network operator of the device. |

## METHODS

The DRMMDeviceAuditMobileInfo class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMDeviceAudit/about_DRMMDeviceAuditMobileInfo.md)
