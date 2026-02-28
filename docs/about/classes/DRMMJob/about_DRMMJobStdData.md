# about_DRMMJobStdData

## SHORT DESCRIPTION

Represents standard output or error data associated with a DRMM job component, including job, device, and component identifiers, component name, and the standard data itself.

## LONG DESCRIPTION

The DRMMJobStdData class models the standard output or error data produced by a component during the execution of a DRMM job. It includes properties such as JobUid, DeviceUid, ComponentUid, ComponentName, and StdData, which provide details about the source and content of the standard data. The class also includes a static method to create an instance of DRMMJobStdData from API response data.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMJobStdData class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| JobUid        | guid   | The unique identifier (UID) of the job. |
| DeviceUid     | guid   | The unique identifier (UID) of the device. |
| ComponentUid  | guid   | The unique identifier (UID) of the job component. |
| ComponentName | string | The name of the job component. |
| StdData       | string | The standard data output of the job component. |
| StdType       | string | The type of standard data, indicating whether it is standard output (StdOut) or standard error (StdErr). |

## METHODS

The DRMMJobStdData class provides the following methods:

### GetStdDataAsJson()

Retrieves the standard data associated with a completed job component, parsed from JSON format.

**Returns:** `pscustomobject` - A PSCustomObject representing the parsed JSON data, or null if the standard type is not StdOut or the data is empty.

### GetStdDataAsCsv()

Retrieves the standard data associated with a completed job component, parsed from CSV format.

**Returns:** `pscustomobject[]` - An array of PSCustomObject instances representing the parsed CSV data, or an empty array if the standard type is not StdOut or the data is empty.

### GetStdDataAsCsv([String[]]$Headers)

Retrieves the standard data associated with a completed job component, parsed from CSV format.

**Returns:** `pscustomobject[]` - An array of PSCustomObject instances representing the parsed CSV data, or an empty array if the standard type is not StdOut or the data is empty.

**Parameters:**
- `[String[]]$Headers` - Describe this parameter

### GetStdDataAsCsv([String[]]$Headers, [Boolean]$RemoveFirstRow)

Retrieves the standard data associated with a completed job component, parsed from CSV format.

**Returns:** `pscustomobject[]` - An array of PSCustomObject instances representing the parsed CSV data, or an empty array if the standard type is not StdOut or the data is empty.

**Parameters:**
- `[String[]]$Headers` - Describe this parameter
- `[Boolean]$RemoveFirstRow` - Describe this parameter

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMJob/about_DRMMJobStdData.md)
