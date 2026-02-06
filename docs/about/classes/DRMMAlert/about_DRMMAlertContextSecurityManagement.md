# about_DRMMAlertContextSecurityManagement

## SHORT DESCRIPTION

Represents the context of a security management alert in the DRMM system, including status, product name, information time, virus name, infected files, and other related properties.

## LONG DESCRIPTION

The DRMMAlertContextSecurityManagement class models the context information specific to security management alerts in the DRMM platform. It encapsulates properties such as status, product name, information time, virus name, infected files, and other related properties that provide detailed context about the security management alert.

This class inherits from [DRMMAlertContext](./about_DRMMAlertContext.md).

## PROPERTIES

The DRMMAlertContextSecurityManagement class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Status                        | int      | The current status of the security management alert. |
| ProductName                   | string   | The name of the product generating the security management alert. |
| InfoTime                      | int      | The time when the information was recorded. |
| VirusName                     | string   | The name of the virus associated with the alert. |
| InfectedFiles                 | string[] | The files infected by the security threat. |
| ProductNotUpdatedForDays      | int      | The number of days the product has not been updated. |
| SystemRemainsInfectedForHours | int      | The number of hours the system remains infected. |
| ExpiryLicenseForDays          | int      | The number of days until the license expires. |

## METHODS

The DRMMAlertContextSecurityManagement class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMAlert/about_DRMMAlertContextSecurityManagement.md)
- [DRMMAlert](../../../commands/DRMMAlert.md)
- [DRMMAlertContext](../../../commands/DRMMAlertContext.md)

