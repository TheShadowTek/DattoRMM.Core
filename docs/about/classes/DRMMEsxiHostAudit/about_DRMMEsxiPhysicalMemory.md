# about_DRMMEsxiPhysicalMemory

## SHORT DESCRIPTION

Represents the physical memory information of an ESXi host, including module, size, type, speed, serial number, part number, and bank.

## LONG DESCRIPTION

The DRMMEsxiPhysicalMemory class models the information about the physical memory modules of an ESXi host. It includes properties such as Module, Size, Type, Speed, SerialNumber, PartNumber, and Bank, which provide details about each physical memory module installed on the ESXi host. This class is typically used as part of the DRMMEsxiHostAudit to represent the memory configuration of the ESXi host being audited.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMEsxiPhysicalMemory class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Module       | string         | The identifier or name of the physical memory module. |
| Size         | Nullable[long] | The size of the physical memory module. |
| Type         | string         | The type of the physical memory module. |
| Speed        | string         | The speed of the physical memory module. |
| SerialNumber | string         | The serial number of the physical memory module. |
| PartNumber   | string         | The part number of the physical memory module. |
| Bank         | string         | The bank location of the physical memory module. |

## METHODS

The DRMMEsxiPhysicalMemory class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMEsxiHostAudit/about_DRMMEsxiPhysicalMemory.md)

