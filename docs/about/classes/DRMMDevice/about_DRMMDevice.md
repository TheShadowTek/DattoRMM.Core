# about_DRMMDevice

## SHORT DESCRIPTION

Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device.

## LONG DESCRIPTION

The DRMMDevice class models a device within the DRMM platform, providing properties that describe the device's attributes and state, as well as methods to retrieve related information such as alerts and to perform actions like opening the device portal.

This class inherits from [DRMMObject](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMDevice class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id                         | long                      | Add description |
| Uid                        | guid                      | Add description |
| SiteId                     | long                      | Add description |
| SiteUid                    | guid                      | Add description |
| SiteName                   | string                    | Add description |
| DeviceType                 | DRMMDeviceType            | Add description |
| Hostname                   | string                    | Add description |
| IntIpAddress               | string                    | Add description |
| OperatingSystem            | string                    | Add description |
| LastLoggedInUser           | string                    | Add description |
| Domain                     | string                    | Add description |
| CagVersion                 | string                    | Add description |
| DisplayVersion             | string                    | Add description |
| ExtIpAddress               | string                    | Add description |
| Description                | string                    | Add description |
| A64Bit                     | bool                      | Add description |
| RebootRequired             | bool                      | Add description |
| Online                     | bool                      | Add description |
| Suspended                  | bool                      | Add description |
| Deleted                    | bool                      | Add description |
| LastSeen                   | Nullable[datetime]        | Add description |
| LastReboot                 | Nullable[datetime]        | Add description |
| LastAuditDate              | Nullable[datetime]        | Add description |
| CreationDate               | Nullable[datetime]        | Add description |
| Udfs                       | DRMMDeviceUdfs            | Add description |
| SnmpEnabled                | bool                      | Add description |
| DeviceClass                | string                    | Add description |
| PortalUrl                  | string                    | Add description |
| WarrantyDate               | string                    | Add description |
| Antivirus                  | DRMMDeviceAntivirusInfo   | Add description |
| PatchManagement            | DRMMDevicePatchManagement | Add description |
| SoftwareStatus             | string                    | Add description |
| WebRemoteUrl               | string                    | Add description |
| NetworkProbe               | bool                      | Add description |
| OnboardedViaNetworkMonitor | bool                      | Add description |
| RevealLastLoggedInUser     | bool                      | Add description |

## METHODS

The DRMMDevice class provides the following methods:

### DRMMDevice()

Add method description explaining what this method does

**Returns:** `void` - Describe what this method returns

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


### OpenWebRemote()

Add method description explaining what this method does

**Returns:** `void` - Describe what this method returns

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetUdfAsJson([Int32]$UdfNumber)

Add method description explaining what this method does

**Returns:** `object` - Describe what this method returns

**Parameters:**
- `[Int32]$UdfNumber` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetUdfAsCsv([Int32]$UdfNumber, [String[]]$Headers)

Parse single row of delimited data with custom headers

**Returns:** `pscustomobject` - Describe what this method returns

**Parameters:**
- `[Int32]$UdfNumber` - Describe this parameter
- `[String[]]$Headers` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetUdfAsCsv([Int32]$UdfNumber, [String]$Delimiter, [String[]]$Headers)

Parse single row of delimited data with custom headers

**Returns:** `pscustomobject` - Describe what this method returns

**Parameters:**
- `[Int32]$UdfNumber` - Describe this parameter
- `[String]$Delimiter` - Describe this parameter
- `[String[]]$Headers` - Describe this parameter

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


### ResolveAllAlerts()

Alert Management Methods

**Returns:** `void` - Describe what this method returns

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetAudit()

Gets the most recent audit information for this device.

**Returns:** `DRMMDeviceAudit` - Represents a comprehensive audit of a device, including hardware, software, and network information.

**Example:**

```powershell
# TODO: Add usage example for this method
```


### GetSoftware()

Add method description explaining what this method does

**Returns:** `DRMMDeviceAuditSoftware[]` - Describe what this method returns

**Example:**

```powershell
# TODO: Add usage example for this method
```


### SetUDF([Hashtable]$UDFFields)

Device Management Methods

**Returns:** `DRMMDevice` - Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device.

**Parameters:**
- `[Hashtable]$UDFFields` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### ClearUDF([Int32]$UdfNumber)

Add method description explaining what this method does

**Returns:** `DRMMDevice` - Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device.

**Parameters:**
- `[Int32]$UdfNumber` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### ClearUDFs()

Add method description explaining what this method does

**Returns:** `DRMMDevice` - Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device.

**Example:**

```powershell
# TODO: Add usage example for this method
```


### SetWarranty([DateTime]$WarrantyDate)

Add method description explaining what this method does

**Returns:** `DRMMDevice` - Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device.

**Parameters:**
- `[DateTime]$WarrantyDate` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### RunQuickJob([Guid]$ComponentUid, [Hashtable]$Variables)

Add method description explaining what this method does

**Returns:** `DRMMJob` - region DRMMJob and related classes

**Parameters:**
- `[Guid]$ComponentUid` - Describe this parameter
- `[Hashtable]$Variables` - Describe this parameter

**Example:**

```powershell
# TODO: Add usage example for this method
```


### Move([Guid]$TargetSiteUid)

Add method description explaining what this method does

**Returns:** `DRMMDevice` - Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device.

**Parameters:**
- `[Guid]$TargetSiteUid` - Describe this parameter

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
