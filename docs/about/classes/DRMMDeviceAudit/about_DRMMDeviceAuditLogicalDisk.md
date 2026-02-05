# about_DRMMDeviceAuditLogicalDisk

## SHORT DESCRIPTION

Represents the logical disk information of a device in a device audit, including description, disk identifier, free space, and size.

## LONG DESCRIPTION

The DRMMDeviceAuditLogicalDisk class models the information about the logical disks of the audited system. It includes properties such as Description, DiskIdentifier, Freespace, and Size, which provide details about each logical disk. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.

This class inherits from [DRMMObject](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMDeviceAuditLogicalDisk class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Description    | string | A description of the logical disk. |
| DiskIdentifier | string | The identifier of the logical disk. |
| Freespace      | long   | The free space available on the logical disk. |
| Size           | long   | The total size of the logical disk. |

## METHODS

The DRMMDeviceAuditLogicalDisk class provides the following methods:

No public methods defined.

## USAGE EXAMPLES

### Example 1: Basic usage

```powershell
# TODO: Add comprehensive usage example
```

### Example 2: Advanced usage

```powershell
# TODO: Add advanced usage example
```

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

TODO: Add any additional notes about this class.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMDeviceAudit/about_DRMMDeviceAuditLogicalDisk.md)
