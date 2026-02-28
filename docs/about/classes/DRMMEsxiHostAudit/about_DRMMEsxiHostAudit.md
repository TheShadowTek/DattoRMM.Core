# about_DRMMEsxiHostAudit

## SHORT DESCRIPTION

Represents the audit information of an ESXi host, including system info, guests, processors, network interfaces, physical memory, and datastores.

## LONG DESCRIPTION

The DRMMEsxiHostAudit class encapsulates detailed information about an ESXi host, such as its unique identifier, portal URL, system information, guest virtual machines, processors, network interfaces, physical memory modules, and datastores. This class is typically used to represent the results of an ESXi host audit operation within the DRMM system.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMEsxiHostAudit class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DeviceUid      | guid                     | The unique identifier of the ESXi host. |
| PortalUrl      | string                   | The portal URL of the ESXi host. |
| SystemInfo     | DRMMEsxiSystemInfo       | The system information of the ESXi host. |
| Guests         | DRMMEsxiGuest[]          | The guest virtual machines running on the ESXi host. |
| Processors     | DRMMEsxiProcessor[]      | The processors of the ESXi host. |
| Nics           | DRMMEsxiNic[]            | The network interface cards (NICs) of the ESXi host. |
| PhysicalMemory | DRMMEsxiPhysicalMemory[] | The physical memory modules of the ESXi host. |
| Datastores     | DRMMEsxiDatastore[]      | The datastores associated with the ESXi host. |

## METHODS

The DRMMEsxiHostAudit class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMEsxiHostAudit/about_DRMMEsxiHostAudit.md)
