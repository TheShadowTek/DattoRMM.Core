# about_DRMMEsxiGuest

## SHORT DESCRIPTION

Represents a guest virtual machine on an ESXi host, including its name, processor speed, memory size, number of snapshots, and datastores.

## LONG DESCRIPTION

The DRMMEsxiGuest class models the information about a guest virtual machine running on an ESXi host. It includes properties such as GuestName, ProcessorSpeedTotal, MemorySizeTotal, NumberOfSnapshots, and Datastores, which provide details about the virtual machine's configuration and resource usage. This class is typically used as part of the DRMMEsxiHostAudit to represent the virtual machines running on the ESXi host being audited.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMEsxiGuest class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| GuestName           | string         | The name of the guest virtual machine. |
| ProcessorSpeedTotal | Nullable[int]  | The total processor speed allocated to the guest virtual machine. |
| MemorySizeTotal     | Nullable[long] | The total memory size allocated to the guest virtual machine. |
| NumberOfSnapshots   | Nullable[int]  | The number of snapshots taken for the guest virtual machine. |
| Datastores          | string         | The datastores associated with the guest virtual machine. |

## METHODS

The DRMMEsxiGuest class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMEsxiHostAudit/about_DRMMEsxiGuest.md)
