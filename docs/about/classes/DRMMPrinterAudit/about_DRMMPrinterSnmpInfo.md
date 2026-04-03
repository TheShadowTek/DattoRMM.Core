# about_DRMMPrinterSnmpInfo

## SHORT DESCRIPTION

Represents the SNMP information of a printer, including SNMP name, contact, description, location, uptime, NIC manufacturer, object ID, and serial number.

## LONG DESCRIPTION

The DRMMPrinterSnmpInfo class models the SNMP-related information of a printer. It includes properties such as SnmpName, SnmpContact, SnmpDescription, SnmpLocation, SnmpUptime, NicManufacturer, ObjectId, and SnmpSerial. This class is typically used as part of the DRMMPrinterAudit to represent the SNMP details of the printer.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMPrinterSnmpInfo class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| SnmpName        | string | The name of the printer as reported by SNMP. |
| SnmpContact     | string | The contact information for SNMP communication with the printer. |
| SnmpDescription | string | The description of the SNMP configuration for the printer. |
| SnmpLocation    | string | The physical location of the printer as reported by SNMP. |
| SnmpUptime      | string | The uptime of the printer as reported by SNMP. |
| NicManufacturer | string | The manufacturer of the network interface card (NIC) used for SNMP communication. |
| ObjectId        | string | The SNMP object identifier (OID) associated with the printer. |
| SnmpSerial      | string | The serial number of the printer as reported by SNMP. |

## METHODS

The DRMMPrinterSnmpInfo class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMPrinterAudit/about_DRMMPrinterSnmpInfo.md)

