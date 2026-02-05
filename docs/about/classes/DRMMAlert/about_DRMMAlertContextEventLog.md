# about_DRMMAlertContextEventLog

## SHORT DESCRIPTION

Represents the context of an event log alert in the DRMM system, including log name, code, type, source, description, trigger count, last triggered time, and suspension status.

## LONG DESCRIPTION

The DRMMAlertContextEventLog class models the context information specific to event log alerts in the DRMM platform. It encapsulates properties such as the log name, code, type, source, description, trigger count, last triggered time, and whether the event caused a suspension. This information provides detailed insights into the event log conditions that triggered the alert, facilitating better understanding and response to event log-related issues.

This class inherits from [DRMMAlertContext](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMAlert/about_DRMMAlertContext.md).

## PROPERTIES

The DRMMAlertContextEventLog class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| LogName          | string             | The name of the event log. |
| Code             | string             | The code associated with the event log alert. |
| Type             | string             | The type of the event log alert. |
| Source           | string             | The source of the event log alert. |
| Description      | string             | A description of the event log alert. |
| TriggerCount     | int                | The number of times the event log alert has been triggered. |
| LastTriggered    | Nullable[datetime] | The last time the event log alert was triggered. |
| CausedSuspension | bool               | Indicates whether the event caused a suspension. |

## METHODS

The DRMMAlertContextEventLog class provides the following methods:

No public methods defined.

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

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMAlert/about_DRMMAlertContextEventLog.md)
