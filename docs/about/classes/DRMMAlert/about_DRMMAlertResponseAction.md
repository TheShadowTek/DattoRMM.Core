# about_DRMMAlertResponseAction

## SHORT DESCRIPTION

Represents a response action taken for an alert in the DRMM system, including action time, type, description, and references.

## LONG DESCRIPTION

The DRMMAlertResponseAction class models the response actions specific to alerts in the DRMM platform. It encapsulates properties such as ActionTime, ActionType, Description, ActionReference, and ActionReferenceInt that provide detailed context about the response actions taken for an alert.

This class inherits from [DRMMObject](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMAlertResponseAction class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| ActionTime         | Nullable[datetime] | The time when the action was taken. |
| ActionType         | string             | The type of action taken. |
| Description        | string             | Description of the action taken. |
| ActionReference    | string             | Reference to the action taken. |
| ActionReferenceInt | string             | Internal reference identifier for the action. |

## METHODS

The DRMMAlertResponseAction class provides the following methods:

### GetSummary()

Generates a summary string for the alert response action, including action type and description.

**Returns:** `string` - A summary string for the alert response action, including action type and description.

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

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMAlert/about_DRMMAlertResponseAction.md)
