# about_DRMMSite

## SHORT DESCRIPTION

Describes the DRMMSite class used in DattoRMM.Core module.

## LONG DESCRIPTION

The DRMMSite class represents TODO: describe what this class represents and its purpose.

This class inherits from [DRMMObject](about_DRMMObject.md).

Objects of this type are typically returned by TODO: list relevant cmdlets.

TODO: Add more detailed description of the class's role and usage patterns.

## PROPERTIES

The DRMMSite class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id                   | long                  | TODO: Add description |\n| Uid                  | guid                  | TODO: Add description |\n| AccountUid           | string                | TODO: Add description |\n| Name                 | string                | TODO: Add description |\n| Description          | string                | TODO: Add description |\n| Notes                | string                | TODO: Add description |\n| OnDemand             | bool                  | TODO: Add description |\n| SplashtopAutoInstall | bool                  | TODO: Add description |\n| ProxySettings        | DRMMSiteProxySettings | TODO: Add description |\n| DevicesStatus        | DRMMDevicesStatus     | TODO: Add description |\n| SiteSettings         | DRMMSiteSettings      | TODO: Add description |\n| Variables            | DRMMVariable[]        | TODO: Add description |\n| Filters              | DRMMFilter[]          | TODO: Add description |\n| AutotaskCompanyName  | string                | TODO: Add description |\n| AutotaskCompanyId    | string                | TODO: Add description |\n| PortalUrl            | string                | TODO: Add description |\n
## METHODS

The DRMMSite class provides the following methods:

### DRMMSite()

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

### Set([Hashtable]$Properties)

**Returns:** `DRMMSite`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[Hashtable]$Properties` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetAlerts()

**Returns:** `DRMMAlert[]`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetAlerts([String]$Status)

**Returns:** `DRMMAlert[]`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[String]$Status` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### OpenPortal()

**Returns:** `void`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetDevices()

**Returns:** `DRMMDevice[]`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetDevices([Int64]$FilterId)

**Returns:** `DRMMDevice[]`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[Int64]$FilterId` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetDeviceCount()

**Returns:** `int`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetVariables()

**Returns:** `DRMMVariable[]`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetVariable([String]$Name)

**Returns:** `DRMMVariable`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[String]$Name` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### NewVariable([String]$Name, [String]$Value)

**Returns:** `DRMMVariable`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[String]$Name` - TODO: Describe this parameter
- `[String]$Value` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### NewVariable([String]$Name, [String]$Value, [Boolean]$Masked)

**Returns:** `DRMMVariable`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[String]$Name` - TODO: Describe this parameter
- `[String]$Value` - TODO: Describe this parameter
- `[Boolean]$Masked` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetFilters()

**Returns:** `DRMMFilter[]`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetFilter([String]$Name)

**Returns:** `DRMMFilter`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[String]$Name` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetSettings()

**Returns:** `DRMMSiteSettings`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### SetProxy([String]$ProxyHost, [Int32]$Port, [String]$Type)

**Returns:** `DRMMSiteSettings`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[String]$ProxyHost` - TODO: Describe this parameter
- `[Int32]$Port` - TODO: Describe this parameter
- `[String]$Type` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### SetProxy([String]$ProxyHost, [Int32]$Port, [String]$Type, [String]$Username, [SecureString]$Password)

**Returns:** `DRMMSiteSettings`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[String]$ProxyHost` - TODO: Describe this parameter
- `[Int32]$Port` - TODO: Describe this parameter
- `[String]$Type` - TODO: Describe this parameter
- `[String]$Username` - TODO: Describe this parameter
- `[SecureString]$Password` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### RemoveProxy()

**Returns:** `DRMMSiteSettings`

TODO: Add method description explaining what this method does.

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
