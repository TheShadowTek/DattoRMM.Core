# about_DRMMActivityLog

## SHORT DESCRIPTION

Represents an activity log entry in the DRMM system, including details about the activity, associated site and user information, and related context.

## LONG DESCRIPTION

The DRMMActivityLog class models an activity log entry within the DRMM platform, encapsulating properties such as the log ID, entity, category, action, date, site information, device ID, hostname, user information, activity details, and flags indicating the presence of standard output and error. It provides a static method to create an instance of the class from a typical API response object that contains activity log information. The class also includes a method to generate a summary string that combines key properties of the activity log for easy display. The related classes DRMMActivityLogSite and DRMMActivityLogUser represent nested information about the site and user associated with the activity log entry.

This class inherits from [DRMMObject](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMActivityLog class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id        | string              | The unique identifier for the activity log entry. |
| Entity    | string              | The entity associated with the activity. |
| Category  | string              | The category of the activity log entry. |
| Action    | string              | The action performed in the activity log entry. |
| Date      | Nullable[datetime]  | The date and time when the activity occurred. |
| Site      | DRMMActivityLogSite | An instance of the DRMMActivityLogSite class that provides information about the site associated with the activity log entry. |
| DeviceId  | Nullable[long]      | The identifier of the device involved in the activity. |
| Hostname  | string              | The hostname of the device involved in the activity. |
| User      | DRMMActivityLogUser | An instance of the DRMMActivityLogUser class that provides information about the user associated with the activity log entry. |
| Details   | PSCustomObject      | Additional details about the activity. |
| HasStdOut | bool                | Indicates whether the activity log entry includes standard output. |
| HasStdErr | bool                | Indicates whether the activity log entry includes standard error output. |

## METHODS

The DRMMActivityLog class provides the following methods:

### GetSummary()

Generates a summary string for the activity log entry, including key details about the activity.

**Returns:** `string` - A summary string combining key details of the activity log entry.

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

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMActivityLog/about_DRMMActivityLog.md)
