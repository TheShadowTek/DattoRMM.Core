# about_DRMMAlertContextFileSystem

## SHORT DESCRIPTION

Represents the context of a file system alert in the DRMM system, including sample value, threshold, path, object type, and condition.

## LONG DESCRIPTION

The DRMMAlertContextFileSystem class models the context information specific to file system alerts in the DRMM platform. It encapsulates properties such as a sample value that triggered the alert, the threshold that was exceeded, the path of the file or directory involved, the type of object (file or directory), and the condition that caused the alert. This information provides detailed insights into the file system conditions that triggered the alert, facilitating better understanding and response to file system-related issues.

This class inherits from [DRMMAlertContext](./about_DRMMAlertContext.md).

## PROPERTIES

The DRMMAlertContextFileSystem class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Sample     | float  | A sample value that triggered the alert. |
| Threshold  | float  | The threshold that was exceeded to trigger the alert. |
| Path       | string | The path of the file or directory involved in the alert. |
| ObjectType | string | The type of object involved in the alert (e.g., file or directory). |
| Condition  | string | The condition that caused the file system alert. |

## METHODS

The DRMMAlertContextFileSystem class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMAlert/about_DRMMAlertContextFileSystem.md)
- [DRMMAlert](./about_DRMMAlert.md)
- [DRMMAlertContext](./about_DRMMAlertContext.md)

