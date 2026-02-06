# about_DRMMComponent

## SHORT DESCRIPTION

Represents a component in the DRMM system, including its properties and associated variables.

## LONG DESCRIPTION

The DRMMComponent class models a component within the DRMM platform, encapsulating properties such as Id, Uid, Name, Description, CategoryCode, CredentialsRequired, and an array of associated variables (DRMMComponentVariable). It provides methods to retrieve specific variables and generate summaries of the component's properties.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMComponent class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id                  | int                     | The unique identifier of the component. |
| Uid                 | string                  | The unique identifier string of the component. |
| Name                | string                  | The name of the component. |
| Description         | string                  | A description of the component. |
| CategoryCode        | string                  | The category code that classifies the component within the DRMM system. |
| CredentialsRequired | bool                    | Indicates whether the component requires credentials. |
| Variables           | DRMMComponentVariable[] | An array of variables associated with the component. |

## METHODS

The DRMMComponent class provides the following methods:

### GetVariable([String]$Name)

Retrieves a specific variable from the component by name.

**Returns:** `DRMMComponentVariable` - The DRMMComponentVariable object that matches the specified name, or null if not found.

**Parameters:**
- `[String]$Name` - The name of the variable to retrieve.

### GetInputVariables()

Retrieves all input variables associated with the component.

**Returns:** `DRMMComponentVariable[]` - An array of DRMMComponentVariable objects that are designated as input variables for the component.

### GetOutputVariables()

Retrieves all output variables associated with the component.

**Returns:** `DRMMComponentVariable[]` - An array of DRMMComponentVariable objects that are designated as output variables for the component.

### GetSummary()

Generates a summary string for the component, including its name, variable count, credentials requirement, and category.

**Returns:** `string` - A summary string for the component, including its name, variable count, credentials requirement, and category.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMComponent/about_DRMMComponent.md)
