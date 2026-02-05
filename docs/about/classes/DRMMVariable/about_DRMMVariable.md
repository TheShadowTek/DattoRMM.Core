# about_DRMMVariable

## SHORT DESCRIPTION

Represents a variable in the DRMM system, including its name, value, scope, and other attributes.

## LONG DESCRIPTION

The DRMMVariable class models a variable within the DRMM platform, encapsulating properties such as Id, Name, Value, Scope, SiteUid, and IsSecret. It provides a constructor and a static method to create an instance from API response data. The class also includes methods to determine if the variable is global or site-specific, as well as a method to generate a summary string of the variable's information.

This class inherits from [DRMMObject](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMVariable class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id       | long           | The unique identifier of the variable. |
| Name     | string         | The name of the variable. |
| Value    | object         | The value of the variable. |
| Scope    | string         | The scope of the variable. |
| SiteUid  | Nullable[guid] | The unique identifier (UID) of the site associated with the variable. |
| IsSecret | bool           | Indicates whether the variable is a secret variable. |

## METHODS

The DRMMVariable class provides the following methods:

### IsGlobal()

Determines if the variable is global in scope.

**Returns:** `bool` - True if the variable is global in scope; otherwise, false.

### IsSite()

Determines if the variable is site-specific in scope.

**Returns:** `bool` - True if the variable is site-specific in scope; otherwise, false.

### GetSummary()

Generates a summary string for the variable, including its name, scope, and value.

**Returns:** `string` - A summary string that includes the name, scope, and value of the variable.

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

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMVariable/about_DRMMVariable.md)
