# about_DRMMAlertContextDiskUsage

## SHORT DESCRIPTION

Represents the context of a disk usage alert in the DRMM system, including details about the disk, total volume, free space, and unit of measure.

## LONG DESCRIPTION

The DRMMAlertContextDiskUsage class models the context information specific to disk usage alerts in the DRMM platform. It encapsulates properties such as the name of the disk, total volume, free space, unit of measure, and disk name designation. This information provides insights into the disk usage conditions that triggered the alert, allowing for better understanding and response to disk-related issues.

This class inherits from [DRMMAlertContext](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMAlert/about_DRMMAlertContext.md).

## PROPERTIES

The DRMMAlertContextDiskUsage class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DiskName            | string | The name of the disk associated with the disk usage alert. |
| TotalVolume         | float  | The total volume or capacity of the disk. |
| FreeSpace           | float  | The amount of free space available on the disk. |
| UnitOfMeasure       | string | The unit of measure used for disk space values (e.g., bytes, megabytes). |
| DiskNameDesignation | string | The designation or label of the disk associated with the disk usage alert. |

## METHODS

The DRMMAlertContextDiskUsage class provides the following methods:

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

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMAlert/about_DRMMAlertContextDiskUsage.md)
