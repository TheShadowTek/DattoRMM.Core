# about_DRMMSite

## SHORT DESCRIPTION

region DRMMSite and related classes

## LONG DESCRIPTION

Add a detailed description of what this class represents and its purpose

This class inherits from [DRMMObject](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMSite class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id                   | long                  | Add description |
| Uid                  | guid                  | Add description |
| AccountUid           | string                | Add description |
| Name                 | string                | Add description |
| Description          | string                | Add description |
| Notes                | string                | Add description |
| OnDemand             | bool                  | Add description |
| SplashtopAutoInstall | bool                  | Add description |
| ProxySettings        | DRMMSiteProxySettings | Add description |
| DevicesStatus        | DRMMDevicesStatus     | Add description |
| SiteSettings         | DRMMSiteSettings      | Add description |
| Variables            | DRMMVariable[]        | Add description |
| Filters              | DRMMFilter[]          | Add description |
| AutotaskCompanyName  | string                | Add description |
| AutotaskCompanyId    | string                | Add description |
| PortalUrl            | string                | Add description |

## METHODS

The DRMMSite class provides the following methods:

### DRMMSite()

Add method description explaining what this method does

**Returns:** `void` - Describe what this method returns

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetSummary()

Add method description explaining what this method does

**Returns:** `string` - Describe what this method returns

**Example:**

```powershell
# TODO: Add usage example for this method
```


### Set([Hashtable]$Properties)

Add method description explaining what this method does

**Returns:** `DRMMSite` - region DRMMSite and related classes

**Parameters:**
- `[Hashtable]$Properties` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetAlerts()

Add method description explaining what this method does

**Returns:** `DRMMAlert[]` - region DRMMAlert and related classes

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetAlerts([String]$Status)

Add method description explaining what this method does

**Returns:** `DRMMAlert[]` - region DRMMAlert and related classes

**Parameters:**
- `[String]$Status` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### OpenPortal()

Add method description explaining what this method does

**Returns:** `void` - Describe what this method returns

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetDevices()

Device Management Methods

**Returns:** `DRMMDevice[]` - Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device.

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetDevices([Int64]$FilterId)

Device Management Methods

**Returns:** `DRMMDevice[]` - Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device.

**Parameters:**
- `[Int64]$FilterId` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetDeviceCount()

Add method description explaining what this method does

**Returns:** `int` - Describe what this method returns

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetVariables()

Variable Management Methods

**Returns:** `DRMMVariable[]` - region DRMMVariable class

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetVariable([String]$Name)

Add method description explaining what this method does

**Returns:** `DRMMVariable` - region DRMMVariable class

**Parameters:**
- `[String]$Name` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### NewVariable([String]$Name, [String]$Value)

Add method description explaining what this method does

**Returns:** `DRMMVariable` - region DRMMVariable class

**Parameters:**
- `[String]$Name` - Describe this parameter
- `[String]$Value` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### NewVariable([String]$Name, [String]$Value, [Boolean]$Masked)

Add method description explaining what this method does

**Returns:** `DRMMVariable` - region DRMMVariable class

**Parameters:**
- `[String]$Name` - Describe this parameter
- `[String]$Value` - Describe this parameter
- `[Boolean]$Masked` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetFilters()

Filter Management Methods

**Returns:** `DRMMFilter[]` - region DRMMFilter class

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetFilter([String]$Name)

Add method description explaining what this method does

**Returns:** `DRMMFilter` - region DRMMFilter class

**Parameters:**
- `[String]$Name` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetSettings()

Add method description explaining what this method does

**Returns:** `DRMMSiteSettings` - Describe what this method returns

**Example:**

```powershell
# TODO: Add usage example for this method
```


### SetProxy([String]$ProxyHost, [Int32]$Port, [String]$Type)

Add method description explaining what this method does

**Returns:** `DRMMSiteSettings` - Describe what this method returns

**Parameters:**
- `[String]$ProxyHost` - Describe this parameter
- `[Int32]$Port` - Describe this parameter
- `[String]$Type` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### SetProxy([String]$ProxyHost, [Int32]$Port, [String]$Type, [String]$Username, [SecureString]$Password)

Add method description explaining what this method does

**Returns:** `DRMMSiteSettings` - Describe what this method returns

**Parameters:**
- `[String]$ProxyHost` - Describe this parameter
- `[Int32]$Port` - Describe this parameter
- `[String]$Type` - Describe this parameter
- `[String]$Username` - Describe this parameter
- `[SecureString]$Password` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### RemoveProxy()

Add method description explaining what this method does

**Returns:** `DRMMSiteSettings` - Describe what this method returns

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

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMSite/about_DRMMSite.md)
