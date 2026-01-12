# about_DRMMStatus

## SHORT DESCRIPTION

Describes the DRMMStatus class for representing Datto RMM service status information.

## LONG DESCRIPTION


The DRMMStatus class models the status of the Datto RMM service, including version, current status, and the time the service was started.

DRMMStatus objects are returned by [Get-RMMStatus](Get-RMMStatus.md), which retrieves service status and health information. Use Get-RMMStatus to inspect service version, status, and uptime programmatically.

## PROPERTIES

| Property   | Type                | Description                       |
|------------|---------------------|-----------------------------------|
| Version    | string              | Service version                   |
| Status     | string              | Current service status            |
| Started    | Nullable[datetime]  | Service start time                |

## METHODS

DRMMStatus does not expose instance methods. All data is accessed via properties.

## EXAMPLES

```powershell
$status = Get-RMMStatus
Write-Host "Service status: $($status.Status) (v$($status.Version))"
```

## NOTES

- DRMMStatus is used for service health and version reporting.
- The Started property may be null if not available.

## SEE ALSO
* [Get-RMMStatus](Get-RMMStatus.md)
* [about_Datto-RMM](about_Datto-RMM.md)
