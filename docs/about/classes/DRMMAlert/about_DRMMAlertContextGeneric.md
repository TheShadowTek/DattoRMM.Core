# about_DRMMAlertContextGeneric

## SHORT DESCRIPTION

Represents a generic alert context in the DRMM system when specific context class information is not available.

## LONG DESCRIPTION

The DRMMAlertContextGeneric class models a generic alert context in the DRMM platform. It is used when specific context class information is not available, encapsulating a hashtable of properties that provide detailed information about the alert context, along with a companion hashtable that records the

This class inherits from [DRMMAlertContext](./about_DRMMAlertContext.md).

## PROPERTIES

The DRMMAlertContextGeneric class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Properties    | hashtable | A hashtable containing properties that provide detailed information about the alert context when specific context class information is not available. |
| PropertyTypes | hashtable | Add description |

## METHODS

The DRMMAlertContextGeneric class provides the following methods:

### GetSummary()

Gets a summary of the generic alert context, including the class name and property names.

**Returns:** `string` - Describe what this method returns

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMAlert/about_DRMMAlertContextGeneric.md)
- [DRMMAlert](./about_DRMMAlert.md)
- [DRMMAlertContext](./about_DRMMAlertContext.md)

