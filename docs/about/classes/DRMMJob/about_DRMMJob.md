# about_DRMMJob

## SHORT DESCRIPTION

Represents a job in the DRMM system, including its ID, unique identifier, name, creation date, and status.

## LONG DESCRIPTION

The DRMMJob class models a job within the DRMM platform. It includes properties such as Id, Uid, Name, DateCreated, and Status. This class provides methods to interact with job components, results, standard output, and error data. It also includes utility methods to check the job's status, calculate its age, refresh its data, and generate a summary string. The class is used to represent and manage jobs in the DRMM system.

This class inherits from [DRMMObject](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMJob class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id          | long               | The unique identifier of the job. |
| Uid         | guid               | The unique identifier (UID) of the job. |
| Name        | string             | The name of the job. |
| DateCreated | Nullable[datetime] | The date and time when the job was created. |
| Status      | string             | The current status of the job. |

## METHODS

The DRMMJob class provides the following methods:

### IsActive()

Checks if the job is currently active.

**Returns:** `bool` - Indicates whether the job is currently active (true/false).

### IsCompleted()

Checks if the job is completed.

**Returns:** `bool` - Indicates whether the job is completed (true/false).

### GetAge()

Calculates the age of the job based on its creation date.

**Returns:** `timespan` - The age of the job as a TimeSpan object, representing the time elapsed since the job was created.

### GetComponents()

Retrieves the components associated with the job.

**Returns:** `DRMMJobComponent[]` - A list of components associated with the job.

### GetResults([Guid]$DeviceUid)

Retrieves the results associated with the job for a specific device.

**Returns:** `DRMMJobResults` - The results associated with the job for the specified device.

**Parameters:**
- `[Guid]$DeviceUid` - The unique identifier of the device for which to retrieve job results.

### GetStdOut([Guid]$DeviceUid)

Retrieves the standard output data associated with the job for a specific device.

**Returns:** `DRMMJobStdData[]` - The standard output data associated with the job for the specified device.

**Parameters:**
- `[Guid]$DeviceUid` - The unique identifier of the device for which to retrieve standard output data.

### GetStdErr([Guid]$DeviceUid)

Retrieves the standard error data associated with the job for a specific device.

**Returns:** `DRMMJobStdData[]` - The standard error data associated with the job for the specified device.

**Parameters:**
- `[Guid]$DeviceUid` - The unique identifier of the device for which to retrieve standard error data.

### Refresh()

Refreshes the job's data by fetching the latest information from the API.

**Returns:** `void` - The updated job object with refreshed data.

### GetSummary()

Generates a summary string for the job.

**Returns:** `string` - A summary string representing the job.

### GetStdOutAsJson([Guid]$DeviceUid)

Retrieves the standard output data associated with the job for a specific device.

**Returns:** `pscustomobject[]` - The standard output data associated with the job for the specified device, parsed from JSON into a PowerShell object.

**Parameters:**
- `[Guid]$DeviceUid` - The unique identifier of the device for which to retrieve standard output data.

### GetStdOutAsCsv([Guid]$DeviceUid)

Retrieves the standard output data associated with the job for a specific device.

**Returns:** `pscustomobject[]` - The standard output data associated with the job for the specified device, parsed from CSV into a PowerShell object.

**Parameters:**
- `[Guid]$DeviceUid` - The unique identifier of the device for which to retrieve standard output data.

### GetStdOutAsCsv([Guid]$DeviceUid, [Boolean]$FirstRowAsHeader)

Retrieves the standard output data associated with the job for a specific device.

**Returns:** `pscustomobject[]` - The standard output data associated with the job for the specified device, parsed from CSV into a PowerShell object.

**Parameters:**
- `[Guid]$DeviceUid` - The unique identifier of the device for which to retrieve standard output data.
- `[Boolean]$FirstRowAsHeader` - Indicates whether the first row of the output should be treated as a header (true/false).

### GetStdOutAsCsv([Guid]$DeviceUid, [Boolean]$FirstRowAsHeader, [String[]]$Headers)

Retrieves the standard output data associated with the job for a specific device.

**Returns:** `pscustomobject[]` - The standard output data associated with the job for the specified device, parsed from CSV into a PowerShell object.

**Parameters:**
- `[Guid]$DeviceUid` - The unique identifier of the device for which to retrieve standard output data.
- `[Boolean]$FirstRowAsHeader` - Indicates whether the first row of the output should be treated as a header (true/false).
- `[String[]]$Headers` - An optional array of headers to use for the CSV output. If not provided, default headers will be used.

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

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMJob/about_DRMMJob.md)
