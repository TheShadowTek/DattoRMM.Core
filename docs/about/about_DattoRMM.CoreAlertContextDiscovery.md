# about_DattoRMM.CoreAlertContextDiscovery

## SHORT DESCRIPTION

Describes the alert context type system, explains why some alert contexts are returned as generic, and provides a guide for beta testers to collect and report unrecognised alert context data.

## LONG DESCRIPTION

The Datto RMM API returns alert context data as a polymorphic object, identified by an `@class` property. The DattoRMM.Core module maps each known `@class` value to a dedicated typed class (e.g., `DRMMAlertContextDiskUsage`, `DRMMAlertContextEventLog`). When the `@class` value is not recognised — or is absent — the module falls back to `DRMMAlertContextGeneric`, which captures all properties in a hashtable.

### How the Module Handles Unrecognised Contexts

When the API returns an alert with an `@class` value that is not documented or not yet mapped to a dedicated module class, the module gracefully falls back to `DRMMAlertContextGeneric`. This class captures all properties, their values, and their types in hashtables. No data is lost — the generic context simply does not have named, typed properties like the dedicated classes do, but all information remains accessible via the `Properties` hashtable.

### Recognised vs Unrecognised Context Types

The module recognises 26 alert context types that are documented in the Datto RMM API v2 specification. Additional context types have been discovered through testing but are not yet included as dedicated module classes. These unrecognised types are fully functional — the API returns structured data — and the module captures them in `DRMMAlertContextGeneric` objects.

### Known Unrecognised Context Types

The following `@class` values have been identified through testing and are currently handled as generic contexts:

| @class Value | Known Properties |
|---|---|
| `fs_object_ctx` | path, condition, threshold, sample, objectType |
| `perf_disk_usage_ctx` | totalVolume, unitOfMeasure, diskName, diskNameDesignation, freeSpace |
| `perf_resource_usage_ctx` | percentage, type |
| `process_resource_usage_ctx` | type, processName, sample |
| `process_status_ctx` | status, processName |
| `srvc_resource_usage_ctx` | type, serviceName, sample |
| `srvc_status_ctx` | serviceName, status |

This list is incomplete. There are likely additional undocumented context types for other monitor categories created in the new UI.

### How to Identify Generic Contexts

When alerts are returned with an unrecognised context, the module:

1. Produces a `DRMMAlertContextGeneric` object instead of a dedicated typed class.
2. Emits a `Write-Debug` message with the unrecognised `@class` value and property names (visible when running with `-Debug`).
3. Stores all properties in `.Properties` (hashtable of name/value) and `.PropertyTypes` (hashtable of name/type).

You can identify generic contexts by checking the type name:

```powershell
$Alerts = Get-RMMAlert -Status All
$GenericContexts = $Alerts | Where-Object {$_.AlertContext.GetType().Name -eq 'DRMMAlertContextGeneric'}
$GenericContexts.Count
```

## BETA DATA COLLECTION GUIDE

During the beta period, we need help identifying undocumented alert context types so dedicated classes can be built. The goal is to collect the `@class` value, property names, and property types for each unrecognised context — **without collecting any sensitive or identifying data**.

### Quick Discovery: List All Generic Context Types

This gives you a summary of every unrecognised `@class` in your account:

```powershell
$Alerts = Get-RMMAlert -Status All -Force
$Alerts.AlertContext |
    Where-Object {$_.GetType().Name -eq 'DRMMAlertContextGeneric'} |
    Sort-Object Class -Unique |
    Select-Object Class, @{n='PropertyCount';e={$_.Properties.Count}}
```

### Detailed Collection: Capture Schema Information

This collects the `@class`, property names, and property types for each unique generic context. No values are included — only structural information:

```powershell
$Alerts = Get-RMMAlert -Status All -Force

$SchemaReport = $Alerts.AlertContext |
    Where-Object {$_.GetType().Name -eq 'DRMMAlertContextGeneric'} |
    Sort-Object Class -Unique |
    ForEach-Object {

        $Context = $_

        $PropertyDetail = foreach ($Key in $Context.Properties.Keys) {

            "$Key [$($Context.PropertyTypes[$Key])]"

        }

        [pscustomobject][ordered]@{
            Class      = $Context.Class
            Properties = $PropertyDetail -join '; '
        }
    }

$SchemaReport | Format-Table -AutoSize -Wrap
```

Example output:

```
Class                      Properties
-----                      ----------
fs_object_ctx              path [String]; condition [<null>]; threshold [Double]; sample [Double]; objectType [<null>]
perf_disk_usage_ctx        totalVolume [Double]; unitOfMeasure [String]; diskName [String]; diskNameDesignation [String]; freeSpace [Double]
perf_resource_usage_ctx    percentage [Double]; type [String]
process_resource_usage_ctx type [String]; processName [String]; sample [Double]
```

### Export for Reporting

Export the schema report to CSV for easy sharing:

```powershell
$SchemaReport | Export-Csv -Path "AlertContextSchemaReport.csv" -NoTypeInformation
```

Or copy to clipboard:

```powershell
$SchemaReport | ConvertTo-Csv -NoTypeInformation | Set-Clipboard
```

### Using Debug Output

For real-time visibility during alert retrieval, use the `-Debug` parameter. The module emits a debug message for every unrecognised context:

```powershell
Get-RMMAlert -Status Open -Debug
```

Debug output example:

```
DEBUG: AlertContext: Unrecognised @class 'perf_disk_usage_ctx' — using DRMMAlertContextGeneric. Properties: @class, totalVolume, unitOfMeasure, diskName, diskNameDesignation, freeSpace
```

### Using GetSummary()

Each `DRMMAlertContextGeneric` object has a `GetSummary()` method that provides a concise overview:

```powershell
$Alerts = Get-RMMAlert -Status Open -Force
$Alerts | Where-Object {$_.AlertContext.GetType().Name -eq 'DRMMAlertContextGeneric'} |
    ForEach-Object {$_.AlertContext.GetSummary()}
```

Output example:

```
[Generic] perf_disk_usage_ctx — Properties: totalVolume, unitOfMeasure, diskName, diskNameDesignation, freeSpace
[Generic] srvc_status_ctx — Properties: serviceName, status
```

### What to Report

When reporting unrecognised contexts, please include:

1. **The CSV or table output** from the schema collection script above.
2. **The number of alerts** for each unrecognised `@class` (helps prioritise which classes to implement first).
3. **Any `@class` values not in the Known Undocumented list** above — these are the most valuable finds.

To count alerts per unrecognised context type:

```powershell
$Alerts.AlertContext |
    Where-Object {$_.GetType().Name -eq 'DRMMAlertContextGeneric'} |
    Group-Object Class |
    Select-Object Count, Name |
    Sort-Object Count -Descending
```

> [!IMPORTANT]
> Do not include property **values** in your report. The schema report scripts above deliberately capture only property names and types. Alert context values may contain hostnames, IP addresses, file paths, or other environment-specific information.

## WORKING WITH GENERIC CONTEXT DATA

While generic contexts do not have named properties, their data is fully accessible via the `Properties` hashtable:

```powershell
# Access a specific property
$Alert.AlertContext.Properties['diskName']

# Iterate all properties
$Alert.AlertContext.Properties.GetEnumerator() | ForEach-Object {
    "$($_.Key) = $($_.Value)"
}

# Filter alerts by a property value within the generic context
$Alerts | Where-Object {
    $_.AlertContext.GetType().Name -eq 'DRMMAlertContextGeneric' -and
    $_.AlertContext.Properties['type'] -eq 'CPU'
}
```

## SEE ALSO

- [about_DRMMAlertContext](classes/DRMMAlert/about_DRMMAlertContext.md)
- [about_DRMMAlertContextGeneric](classes/DRMMAlert/about_DRMMAlertContextGeneric.md)
- [about_DRMMAlert](classes/DRMMAlert/about_DRMMAlert.md)
- [Get-RMMAlert](../commands/Get-RMMAlert.md)
