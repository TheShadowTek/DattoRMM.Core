# about_DRMMDevice

## SHORT DESCRIPTION

Describes the DRMMDevice class used in DattoRMM.Core module.

## LONG DESCRIPTION

The DRMMDevice class represents TODO: describe what this class represents and its purpose.

This class inherits from [DRMMObject](about_DRMMObject.md).

Objects of this type are typically returned by TODO: list relevant cmdlets.

TODO: Add more detailed description of the class's role and usage patterns.

## PROPERTIES

The DRMMDevice class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id                         | long                      | TODO: Add description |\n| Uid                        | guid                      | TODO: Add description |\n| SiteId                     | long                      | TODO: Add description |\n| SiteUid                    | guid                      | TODO: Add description |\n| SiteName                   | string                    | TODO: Add description |\n| DeviceType                 | DRMMDeviceType            | TODO: Add description |\n| Hostname                   | string                    | TODO: Add description |\n| IntIpAddress               | string                    | TODO: Add description |\n| OperatingSystem            | string                    | TODO: Add description |\n| LastLoggedInUser           | string                    | TODO: Add description |\n| Domain                     | string                    | TODO: Add description |\n| CagVersion                 | string                    | TODO: Add description |\n| DisplayVersion             | string                    | TODO: Add description |\n| ExtIpAddress               | string                    | TODO: Add description |\n| Description                | string                    | TODO: Add description |\n| A64Bit                     | bool                      | TODO: Add description |\n| RebootRequired             | bool                      | TODO: Add description |\n| Online                     | bool                      | TODO: Add description |\n| Suspended                  | bool                      | TODO: Add description |\n| Deleted                    | bool                      | TODO: Add description |\n| LastSeen                   | Nullable[datetime]        | TODO: Add description |\n| LastReboot                 | Nullable[datetime]        | TODO: Add description |\n| LastAuditDate              | Nullable[datetime]        | TODO: Add description |\n| CreationDate               | Nullable[datetime]        | TODO: Add description |\n| Udfs                       | DRMMDeviceUdfs            | TODO: Add description |\n| SnmpEnabled                | bool                      | TODO: Add description |\n| DeviceClass                | string                    | TODO: Add description |\n| PortalUrl                  | string                    | TODO: Add description |\n| WarrantyDate               | string                    | TODO: Add description |\n| Antivirus                  | DRMMDeviceAntivirusInfo   | TODO: Add description |\n| PatchManagement            | DRMMDevicePatchManagement | TODO: Add description |\n| SoftwareStatus             | string                    | TODO: Add description |\n| WebRemoteUrl               | string                    | TODO: Add description |\n| NetworkProbe               | bool                      | TODO: Add description |\n| OnboardedViaNetworkMonitor | bool                      | TODO: Add description |\n| RevealLastLoggedInUser     | bool                      | TODO: Add description |\n
## METHODS

The DRMMDevice class provides the following methods:

### DRMMDevice()

**Returns:** `void`

TODO: Add method description explaining what this method does.

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

### OpenWebRemote()

**Returns:** `void`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetUdfAsJson([Int32]$UdfNumber)

**Returns:** `object`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[Int32]$UdfNumber` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetUdfAsCsv([Int32]$UdfNumber, [String[]]$Headers)

**Returns:** `pscustomobject`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[Int32]$UdfNumber` - TODO: Describe this parameter
- `[String[]]$Headers` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetUdfAsCsv([Int32]$UdfNumber, [String]$Delimiter, [String[]]$Headers)

**Returns:** `pscustomobject`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[Int32]$UdfNumber` - TODO: Describe this parameter
- `[String]$Delimiter` - TODO: Describe this parameter
- `[String[]]$Headers` - TODO: Describe this parameter

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

### ResolveAllAlerts()

**Returns:** `void`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetAudit()

**Returns:** `DRMMDeviceAudit`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### GetSoftware()

**Returns:** `DRMMDeviceAuditSoftware[]`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### SetUDF([Hashtable]$UDFFields)

**Returns:** `DRMMDevice`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[Hashtable]$UDFFields` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### ClearUDF([Int32]$UdfNumber)

**Returns:** `DRMMDevice`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[Int32]$UdfNumber` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### ClearUDFs()

**Returns:** `DRMMDevice`

TODO: Add method description explaining what this method does.

**Example:**

```powershell
# TODO: Add usage example for this method
```

### SetWarranty([DateTime]$WarrantyDate)

**Returns:** `DRMMDevice`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[DateTime]$WarrantyDate` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### RunQuickJob([Guid]$ComponentUid, [Hashtable]$Variables)

**Returns:** `DRMMJob`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[Guid]$ComponentUid` - TODO: Describe this parameter
- `[Hashtable]$Variables` - TODO: Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```

### Move([Guid]$TargetSiteUid)

**Returns:** `DRMMDevice`

TODO: Add method description explaining what this method does.

**Parameters:**
- `[Guid]$TargetSiteUid` - TODO: Describe this parameter

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

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMDevice/about_DRMMDevice.md)
