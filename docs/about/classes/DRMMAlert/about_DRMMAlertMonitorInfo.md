# about_DRMMAlertMonitorInfo

## SHORT DESCRIPTION

Represents the monitor information for an alert in the DRMM system, including whether the alert sends emails and creates tickets.

## LONG DESCRIPTION

The DRMMAlertMonitorInfo class models the monitor information specific to alerts in the DRMM platform. It encapsulates properties such as SendsEmails and CreatesTicket that provide detailed context about the alert's monitoring configuration.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMAlertMonitorInfo class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| SendsEmails   | bool | Indicates whether the alert sends emails. |
| CreatesTicket | bool | Indicates whether the alert creates a ticket. |

## METHODS

The DRMMAlertMonitorInfo class provides the following methods:

### GetSummary()

Generates a summary string for the alert monitor information, indicating whether it sends emails and creates tickets.

**Returns:** `string` - A summary string indicating the email and ticket creation configuration of the alert monitor.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMAlert/about_DRMMAlertMonitorInfo.md)
