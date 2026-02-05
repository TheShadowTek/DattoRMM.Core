# about_DRMMJob

## SHORT DESCRIPTION

region DRMMJob and related classes

## LONG DESCRIPTION

Add a detailed description of what this class represents and its purpose

This class inherits from [DRMMObject](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMJob class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id          | long               | Add description |
| Uid         | guid               | Add description |
| Name        | string             | Add description |
| DateCreated | Nullable[datetime] | Add description |
| Status      | string             | Add description |

## METHODS

The DRMMJob class provides the following methods:

### DRMMJob()

Add method description explaining what this method does

**Returns:** `void` - Describe what this method returns

**Example:**

```powershell
# TODO: Add usage example for this method
```


### IsActive()

Status Check Methods

**Returns:** `bool` - Describe what this method returns

**Example:**

```powershell
# TODO: Add usage example for this method
```


### IsCompleted()

Add method description explaining what this method does

**Returns:** `bool` - Describe what this method returns

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetAge()

Time-based Methods

**Returns:** `timespan` - Describe what this method returns

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetComponents()

API Wrapper Methods

**Returns:** `DRMMJobComponent[]` - Describe what this method returns

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetResults([Guid]$DeviceUid)

Add method description explaining what this method does

**Returns:** `DRMMJobResults` - Describe what this method returns

**Parameters:**
- `[Guid]$DeviceUid` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetStdOut([Guid]$DeviceUid)

Add method description explaining what this method does

**Returns:** `DRMMJobStdData[]` - Describe what this method returns

**Parameters:**
- `[Guid]$DeviceUid` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetStdErr([Guid]$DeviceUid)

Add method description explaining what this method does

**Returns:** `DRMMJobStdData[]` - Describe what this method returns

**Parameters:**
- `[Guid]$DeviceUid` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### Refresh()

Refresh Method

**Returns:** `void` - Describe what this method returns

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetSummary()

Utility Methods

**Returns:** `string` - Describe what this method returns

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetStdOutAsJson([Guid]$DeviceUid)

Combine all stdout lines into single string

**Returns:** `pscustomobject[]` - Describe what this method returns

**Parameters:**
- `[Guid]$DeviceUid` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetStdOutAsCsv([Guid]$DeviceUid)

Combine all stdout lines into single string

**Returns:** `pscustomobject[]` - Describe what this method returns

**Parameters:**
- `[Guid]$DeviceUid` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetStdOutAsCsv([Guid]$DeviceUid, [Boolean]$FirstRowAsHeader)

Combine all stdout lines into single string

**Returns:** `pscustomobject[]` - Describe what this method returns

**Parameters:**
- `[Guid]$DeviceUid` - Describe this parameter
- `[Boolean]$FirstRowAsHeader` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetStdOutAsCsv([Guid]$DeviceUid, [Boolean]$FirstRowAsHeader, [String[]]$Headers)

Combine all stdout lines into single string

**Returns:** `pscustomobject[]` - Describe what this method returns

**Parameters:**
- `[Guid]$DeviceUid` - Describe this parameter
- `[Boolean]$FirstRowAsHeader` - Describe this parameter
- `[String[]]$Headers` - Describe this parameter

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
