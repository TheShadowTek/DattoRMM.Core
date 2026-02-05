# about_DRMMJob

## SHORT DESCRIPTION

Describes the DRMMJob class used in DattoRMM.Core module.

## LONG DESCRIPTION

The DRMMJob class represents TODO: describe what this class represents and its purpose.

This class inherits from [DRMMObject](about_DRMMObject.md).

Objects of this type are typically returned by TODO: list relevant cmdlets.

TODO: Add more detailed description of the class's role and usage patterns.

## PROPERTIES

The DRMMJob class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id          | long               | TODO: Add description |\n| Uid         | guid               | TODO: Add description |\n| Name        | string             | TODO: Add description |\n| DateCreated | Nullable[datetime] | TODO: Add description |\n| Status      | string             | TODO: Add description |\n
## METHODS

The DRMMJob class provides the following methods:

### DRMMJob()

**Returns:** `void`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### IsActive()

**Returns:** `bool`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### IsCompleted()

**Returns:** `bool`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetAge()

**Returns:** `timespan`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetComponents()

**Returns:** `DRMMJobComponent[]`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetResults([Guid]$DeviceUid)

**Returns:** `DRMMJobResults`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[Guid]$DeviceUid` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetStdOut([Guid]$DeviceUid)

**Returns:** `DRMMJobStdData[]`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[Guid]$DeviceUid` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetStdErr([Guid]$DeviceUid)

**Returns:** `DRMMJobStdData[]`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[Guid]$DeviceUid` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### Refresh()

**Returns:** `void`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetSummary()

**Returns:** `string`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetStdOutAsJson([Guid]$DeviceUid)

**Returns:** `pscustomobject[]`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[Guid]$DeviceUid` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetStdOutAsCsv([Guid]$DeviceUid)

**Returns:** `pscustomobject[]`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[Guid]$DeviceUid` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetStdOutAsCsv([Guid]$DeviceUid, [Boolean]$FirstRowAsHeader)

**Returns:** `pscustomobject[]`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[Guid]$DeviceUid` - TODO: Describe this parameter
- `[Boolean]$FirstRowAsHeader` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetStdOutAsCsv([Guid]$DeviceUid, [Boolean]$FirstRowAsHeader, [String[]]$Headers)

**Returns:** `pscustomobject[]`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[Guid]$DeviceUid` - TODO: Describe this parameter
- `[Boolean]$FirstRowAsHeader` - TODO: Describe this parameter
- `[String[]]$Headers` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

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
