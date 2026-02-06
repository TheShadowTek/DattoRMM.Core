# about_DRMMAlertContextAntivirus

## SHORT DESCRIPTION

Represents a generic alert context in the DRMM system when specific context class information is not available.

## LONG DESCRIPTION

The DRMMAlertContextGeneric class models a generic alert context for cases where the specific context class information is not available or does not match known types. It captures the raw response data and provides a summary that includes the class if available. This allows for handling of alert contexts that may not fit into predefined categories while still retaining the original information for reference.

This class inherits from [DRMMAlertContext](./about_DRMMAlertContext.md).

## PROPERTIES

The DRMMAlertContextAntivirus class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Status      | string | The current status of the antivirus alert context. |
| ProductName | string | The name of the antivirus product associated with the alert context. |

## METHODS

The DRMMAlertContextAntivirus class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMAlert/about_DRMMAlertContextAntivirus.md)
- [DRMMAlert](../../../commands/DRMMAlert.md)
- [DRMMAlertContext](../../../commands/DRMMAlertContext.md)

