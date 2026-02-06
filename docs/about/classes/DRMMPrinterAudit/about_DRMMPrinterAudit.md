# about_DRMMPrinterAudit

## SHORT DESCRIPTION

Represents the audit information of a printer, including SNMP info, marker supplies, printer details, system info, and network interfaces.

## LONG DESCRIPTION

The DRMMPrinterAudit class encapsulates detailed information about a printer, such as its unique identifier, portal URL, SNMP information, marker supplies, printer details, system information, and network interfaces. This class is typically used to represent the results of a printer audit operation within the DRMM system.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMPrinterAudit class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DeviceUid             | guid                      | The unique identifier (UID) of the device. |
| PortalUrl             | string                    | The URL of the portal. |
| SnmpInfo              | DRMMPrinterSnmpInfo       | The SNMP information of the printer. |
| PrinterMarkerSupplies | DRMMPrinterMarkerSupply[] | The marker supplies of the printer. |
| Printer               | DRMMPrinter               | The printer associated with the audit. |
| SystemInfo            | DRMMPrinterSystemInfo     | The system information of the printer. |
| Nics                  | DRMMNetworkInterface[]    | The network interfaces of the printer. |

## METHODS

The DRMMPrinterAudit class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMPrinterAudit/about_DRMMPrinterAudit.md)
