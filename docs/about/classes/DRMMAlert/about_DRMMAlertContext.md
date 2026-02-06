# about_DRMMAlertContext

## SHORT DESCRIPTION

Represents the context of an alert in the DRMM system, including its class and specific details based on the type of alert.

## LONG DESCRIPTION

The DRMMAlertContext class models the context information associated with an alert in the DRMM platform. It includes a property for the class of the context, which indicates the type of alert context (e

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMAlertContext class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Class | string | The class of the alert context, indicating the type of context information associated with the alert. |

## METHODS

The DRMMAlertContext class provides the following methods:

### GetSummary()

Gets a summary of the alert context.

**Returns:** `string` - A summary string of the alert context.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMAlert/about_DRMMAlertContext.md)
