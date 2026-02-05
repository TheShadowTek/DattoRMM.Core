# about_DRMMComponentVariable

## SHORT DESCRIPTION

Represents a variable associated with a DRMM component, including its name, type, direction, and other metadata.

## LONG DESCRIPTION

The DRMMComponentVariable class models a variable that can be used as input or output for a DRMM component. It includes properties for the variable's name, default value, type, direction (input/output), description, and index within the component's variable list. Methods allow for instantiation from API responses and for generating a summary string describing the variable.

This class inherits from [DRMMObject](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMComponentVariable class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Name         | string | The name of the variable. |
| DefaultValue | string | The default value of the variable. |
| Type         | string | The data type of the variable. |
| Direction    | bool   | The direction of the variable (input or output). |
| Description  | string | A description of the variable. |
| Index        | int    | The index of the variable within the component's variable list. |

## METHODS

The DRMMComponentVariable class provides the following methods:

### GetSummary()

Generates a summary string for the component variable.

**Returns:** `string` - A summary string for the component variable.

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

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMComponent/about_DRMMComponentVariable.md)
