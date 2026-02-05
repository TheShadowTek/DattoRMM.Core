# about_DRMMActivityLogUser

## SHORT DESCRIPTION

Represents user information associated with a DRMM activity log entry, including user ID, username, and name details.

## LONG DESCRIPTION

The DRMMActivityLogUser class models the user information related to an activity log entry in the DRMM platform. It encapsulates properties such as the user ID, username, first name, and last name. The class provides a static method to create an instance of the class from a typical API response object that contains these user details. Additionally, it includes a method to generate a summary string that combines the user's first name, last name, and username for easy display in contexts where user information is relevant.

This class inherits from [DRMMObject](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMActivityLogUser class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id        | long   | The unique identifier for the user associated with the activity log entry. |
| UserName  | string | The username of the user associated with the activity log entry. |
| FirstName | string | The first name of the user associated with the activity log entry. |
| LastName  | string | The last name of the user associated with the activity log entry. |

## METHODS

The DRMMActivityLogUser class provides the following methods:

### GetSummary()

Generates a summary string for the user, including their first name, last name, and username.

**Returns:** `string` - A summary string combining the user's first name, last name, and username.

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

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMActivityLog/about_DRMMActivityLogUser.md)
