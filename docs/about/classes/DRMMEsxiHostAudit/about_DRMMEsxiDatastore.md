# about_DRMMEsxiDatastore

## SHORT DESCRIPTION

Represents the audit information of an ESXi host, including system info, guests, processors, network interfaces, physical memory, and datastores.

## LONG DESCRIPTION

The DRMMEsxiHostAudit class encapsulates detailed information about an ESXi host, such as its unique identifier, portal URL, system information, guest virtual machines, processors, network interfaces, physical memory modules, and datastores. This class is typically used to represent the results of an ESXi host audit operation within the DRMM system.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMEsxiDatastore class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DatastoreName       | string         | The name of the datastore. |
| SubscriptionPercent | Nullable[int]  | The percentage of subscription used in the datastore. |
| FreeSpace           | Nullable[long] | The amount of free space available in the datastore. |
| Size                | Nullable[long] | The total size of the datastore. |
| FileSystem          | string         | The file system type of the datastore. |
| Status              | string         | The current status of the datastore. |

## METHODS

The DRMMEsxiDatastore class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMEsxiHostAudit/about_DRMMEsxiDatastore.md)

