# about_DRMMAlertContextPrinter

## SHORT DESCRIPTION

Represents the context of a printer alert in the DRMM system, including IP address, MAC address, marker supply index, and current level.

## LONG DESCRIPTION

The DRMMAlertContextPrinter class models the context information specific to printer alerts in the DRMM platform. It encapsulates properties such as IP address, MAC address, marker supply index, and current level that provide detailed context about the printer alert.

This class inherits from [DRMMAlertContext](./about_DRMMAlertContext.md).

## PROPERTIES

The DRMMAlertContextPrinter class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| IpAddress         | string | The IP address of the printer. |
| MacAddress        | string | The MAC address of the printer. |
| MarkerSupplyIndex | int    | The index of the marker supply in the printer. |
| CurrentLevel      | int    | The current level of the printer marker supply. |

## METHODS

The DRMMAlertContextPrinter class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMAlert/about_DRMMAlertContextPrinter.md)
- [DRMMAlert](../../../commands/DRMMAlert.md)
- [DRMMAlertContext](../../../commands/DRMMAlertContext.md)

