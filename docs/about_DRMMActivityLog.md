# about_DRMMActivityLog

## SHORT DESCRIPTION

Describes the DRMMActivityLog class and its related types for representing activity log entries in Datto RMM.

## LONG DESCRIPTION


The DRMMActivityLog class models a single activity log entry in Datto RMM, capturing actions, events, and changes across devices, users, and sites. Activity logs are highly flexible, with the Details property dynamically parsed from JSON and varying based on the log category and action. This allows the class to represent a wide range of audit and event records.

DRMMActivityLog objects are returned by [Get-RMMActivityLog](Get-RMMActivityLog.md), which retrieves activity log entries for audit and event tracking. Use Get-RMMActivityLog to list, filter, and analyze activity logs programmatically.

## PROPERTIES

| Property     | Type                      | Description                                      |
|--------------|---------------------------|--------------------------------------------------|
| Id           | string                    | Log entry identifier                             |
| Entity       | string                    | Entity type (e.g., Device, User, Site)           |
| Category     | string                    | Log category (e.g., Job, Alert, Config)          |
| Action       | string                    | Action performed (e.g., Created, Updated)        |
| Date         | Nullable[datetime]        | Date and time of the event                       |
| Site         | DRMMActivityLogSite       | Site associated with the event                   |
| DeviceId     | Nullable[long]            | Device ID (if applicable)                        |
| Hostname     | string                    | Device hostname (if applicable)                  |
| User         | DRMMActivityLogUser       | User associated with the event                   |
| Details      | PSCustomObject            | Dynamic details, parsed from JSON                |
| HasStdOut    | bool                      | True if log has standard output attached         |
| HasStdErr    | bool                      | True if log has standard error attached          |

## METHODS

### GetSummary()
Returns a summary string of the log entry, including entity, category, action, and target.

**Returns:** `[string]`

## RELATED CLASSES

### DRMMActivityLogSite
Represents a site associated with the log entry.
- Id `[long]`
- Name `[string]`

### DRMMActivityLogUser
Represents a user associated with the log entry.
- Id `[long]`
- UserName `[string]`
- FirstName `[string]`
- LastName `[string]`

#### GetSummary()
Returns a formatted string for the user.

**Returns:** `[string]`

## DETAILS PROPERTY

The Details property is a dynamic PSCustomObject parsed from JSON. Its structure varies based on the log category and action, and may include additional date fields, configuration changes, job results, or other context. Date fields within Details are automatically parsed to datetime objects when possible.

If JSON parsing fails, Details will contain a RawDetails property with the original string.

## EXAMPLES

```powershell
$log = Get-RMMActivityLog | Select-Object -First 1
Write-Host $log.GetSummary()
# Output: [Device] Job: Created - SERVER01

# Access dynamic details
if ($log.Details.JobResult) {
    Write-Host "Job Result: $($log.Details.JobResult)"
}
```

## NOTES

DRMMActivityLog is designed to handle a wide variety of log formats and categories.
The Details property may contain different fields depending on the event type.
Use GetSummary() for a quick overview of the log entry.

## SEE ALSO
- [Get-RMMActivityLog](Get-RMMActivityLog.md)
- [about_Datto-RMM](about_Datto-RMM.md)
