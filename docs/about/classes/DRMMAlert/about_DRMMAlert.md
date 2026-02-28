# about_DRMMAlert

## SHORT DESCRIPTION

Represents an alert in the DRMM system, including its properties, context, source information, and response actions.

## LONG DESCRIPTION

The DRMMAlert class models an alert within the DRMM platform, encapsulating properties such as the alert's unique identifier, priority, diagnostics, resolution status, ticket number, timestamp, and related information about the alert monitor, context, source, and response actions. It provides a static method to create an instance of the class from a typical API response object that contains alert information. The class also includes methods to determine if the alert is open or of certain priority levels, to resolve the alert, and to generate a summary string that combines key properties of the alert for easy display. The related classes DRMMAlertContext, DRMMAlertMonitorInfo, DRMMAlertSourceInfo, and DRMMAlertResponseAction represent nested information about the alert's context, monitoring configuration, source details, and response actions taken, respectively.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMAlert class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| AlertUid         | guid                      | Unique identifier for the alert. |
| Priority         | string                    | Priority level of the alert. |
| Diagnostics      | string                    | Diagnostic information related to the alert. |
| Resolved         | bool                      | Indicates whether the alert has been resolved. |
| ResolvedBy       | string                    | Identifier of the user who resolved the alert. |
| ResolvedOn       | Nullable[datetime]        | Timestamp when the alert was resolved. |
| Muted            | bool                      | Indicates whether the alert is muted. |
| TicketNumber     | string                    | Ticket number associated with the alert. |
| Timestamp        | Nullable[datetime]        | Timestamp when the alert was created. |
| AlertMonitorInfo | DRMMAlertMonitorInfo      | AlertMonitorInfo of the DRMMAlert object, containing details about the alert monitor configuration. |
| AlertContext     | DRMMAlertContext          | AlertContext of the DRMMAlert object, providing contextual information about the alert. |
| AlertSourceInfo  | DRMMAlertSourceInfo       | AlertSourceInfo of the DRMMAlert object, including information about the source of the alert such as device and site details. |
| ResponseActions  | DRMMAlertResponseAction[] | Actions taken in response to the alert. |
| AutoresolveMins  | Nullable[int]             | The number of minutes after which the alert will be automatically resolved if not resolved manually. |
| PortalUrl        | string                    | The URL to access the alert in the Datto RMM web portal. |

## METHODS

The DRMMAlert class provides the following methods:

### IsOpen()

Determines if the alert is currently open (not resolved).

**Returns:** `bool` - True if the alert is currently open (not resolved), otherwise false.

### IsCritical()

Determines if the alert is of priority level "Critical".

**Returns:** `bool` - True if the alert is of priority level "Critical", otherwise false.

### IsHigh()

Determines if the alert is of priority level "High".

**Returns:** `bool` - True if the alert is of priority level "High", otherwise false.

### Resolve()

Resolves the alert.

**Returns:** `void` - An updated instance of the DRMMAlert class with the alert marked as resolved.

### GetSummary()

Gets a summary of the alert.

**Returns:** `string` - A summary string combining key properties of the alert for easy display.

### OpenPortal()

Opens the alert's portal URL in the default web browser.

**Returns:** `void` - This method does not return a value. It performs an action to open the portal URL in the default web browser.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMAlert/about_DRMMAlert.md)
- [DRMMAlertContext](./about_DRMMAlertContext.md)
- [DRMMAlertMonitorInfo](./about_DRMMAlertMonitorInfo.md)
- [DRMMAlertSourceInfo](./about_DRMMAlertSourceInfo.md)
- [DRMMAlertResponseAction](./about_DRMMAlertResponseAction.md)
- [Get-RMMAlert](../../../commands/Alerts/Get-RMMAlert.md)
- [Resolve-RMMAlert](../../../commands/Alerts/Resolve-RMMAlert.md)

