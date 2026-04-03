# about_DRMMDevice

## SHORT DESCRIPTION

Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device.

## LONG DESCRIPTION

The DRMMDevice class models a device within the DRMM platform, providing properties that describe the device's attributes and state, as well as methods to retrieve related information such as alerts and to perform actions like opening the device portal.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMDevice class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id                         | long                      | The unique identifier of the device. |
| Uid                        | guid                      | The unique identifier (UID) of the device. |
| SiteId                     | long                      | The unique identifier of the site to which the device belongs. |
| SiteUid                    | guid                      | The unique identifier (UID) of the site to which the device belongs. |
| SiteName                   | string                    | The name of the site to which the device belongs. |
| DeviceType                 | DRMMDeviceType            | The type of the device. |
| Hostname                   | string                    | The hostname of the device. |
| IntIpAddress               | string                    | The internal IP address of the device. |
| OperatingSystem            | string                    | The operating system running on the device. |
| LastLoggedInUser           | string                    | The user who last logged into the device. |
| Domain                     | string                    | The domain to which the device belongs. |
| CagVersion                 | string                    | The version of the CAG agent installed on the device. |
| DisplayVersion             | string                    | The display version of the device. |
| ExtIpAddress               | string                    | The external IP address of the device. |
| Description                | string                    | The device's description. |
| A64Bit                     | bool                      | Indicates whether the device is running a 64-bit operating system. |
| RebootRequired             | bool                      | Indicates whether the device requires a reboot. |
| Online                     | bool                      | Indicates whether the device is currently online. |
| Suspended                  | bool                      | Indicates whether the device is currently suspended in the DRMM system. |
| Deleted                    | bool                      | Indicates whether the device has been marked as deleted. |
| LastSeen                   | Nullable[datetime]        | The last time the device was seen online. |
| LastReboot                 | Nullable[datetime]        | The date and time when the device was last rebooted. |
| LastAuditDate              | Nullable[datetime]        | The date when the device was last audited. |
| CreationDate               | Nullable[datetime]        | The date when the device was created in the DRMM system. |
| Udfs                       | DRMMDeviceUdfs            | User-defined fields associated with the device. |
| SnmpEnabled                | bool                      | Indicates whether SNMP is enabled on the device. |
| DeviceClass                | string                    | The class of the device, which may indicate its role or type within the organization. |
| PortalUrl                  | string                    | The URL to access the device's portal in the DRMM system. |
| WarrantyDate               | string                    | The date when the device's warranty expires. |
| Antivirus                  | DRMMDeviceAntivirusInfo   | Information about the device's antivirus software. |
| PatchManagement            | DRMMDevicePatchManagement | Information about the device's patch management status. |
| SoftwareStatus             | string                    | Information about the device's software status. |
| WebRemoteUrl               | string                    | The URL for web remote access to the device. |
| NetworkProbe               | bool                      | Information about the device's network probe status. |
| OnboardedViaNetworkMonitor | bool                      | Indicates whether the device was onboarded via network monitoring. |
| RevealLastLoggedInUser     | bool                      | Indicates whether the last logged in user information is revealed for the device. |

## METHODS

The DRMMDevice class provides the following methods:

### GetAlerts()

Retrieves the alerts associated with the device, filtered by status.

**Returns:** `DRMMAlert[]` - Represents an alert in the DRMM system, including its properties, context, source information, and response actions.

### GetAlerts([String]$Status)

Retrieves the alerts associated with the device, filtered by a specified status.

**Returns:** `DRMMAlert[]` - Represents an alert in the DRMM system, including its properties, context, source information, and response actions.

**Parameters:**
- `[String]$Status` - TODO: Describe this parameter

### OpenPortal()

Opens the device's portal URL in the default web browser.

**Returns:** `void` - Returns void

### OpenWebRemote()

Opens the device's web remote URL in the default web browser.

**Returns:** `void` - Returns void

### GetUdfAsJson([Int32]$UdfNumber)

Retrieves the value of a specified User-Defined Field (UDF) as a JSON object.

**Returns:** `object` - Returns object

**Parameters:**
- `[Int32]$UdfNumber` - TODO: Describe this parameter

### GetUdfAsCsv([Int32]$UdfNumber, [String[]]$Headers)

Retrieves the value of a specified User-Defined Field (UDF) as a CSV object with custom headers.

**Returns:** `pscustomobject` - Returns pscustomobject

**Parameters:**
- `[Int32]$UdfNumber` - TODO: Describe this parameter
- `[String[]]$Headers` - TODO: Describe this parameter

### GetUdfAsCsv([Int32]$UdfNumber, [String]$Delimiter, [String[]]$Headers)

Retrieves the value of a specified User-Defined Field (UDF) as a CSV object with a custom delimiter and headers.

**Returns:** `pscustomobject` - Returns pscustomobject

**Parameters:**
- `[Int32]$UdfNumber` - TODO: Describe this parameter
- `[String]$Delimiter` - TODO: Describe this parameter
- `[String[]]$Headers` - TODO: Describe this parameter

### GetSummary()

Generates a summary string for the device, including its hostname and device type.

**Returns:** `string` - Returns string

### ResolveAllAlerts()

Resolves all open alerts associated with the device.

**Returns:** `void` - Returns void

### GetAudit()

Gets the most recent audit information for this device.

**Returns:** `DRMMDeviceAudit` - Represents a comprehensive audit of a device, including hardware, software, and network information.

### GetSoftware()

Gets the software information for this device.

**Returns:** `DRMMDeviceAuditSoftware[]` - Represents the software information of a device in a device audit, including its name and version.

### SetUDF([Hashtable]$UDFFields)

Sets the value of one or more User-Defined Fields (UDFs) for the device.

**Returns:** `DRMMDevice` - Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device.

**Parameters:**
- `[Hashtable]$UDFFields` - TODO: Describe this parameter

### ClearUDF([Int32]$UdfNumber)

Clears the value of a specified User-Defined Field (UDF) for the device.

**Returns:** `DRMMDevice` - Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device.

**Parameters:**
- `[Int32]$UdfNumber` - TODO: Describe this parameter

### ClearUDFs()

Clears the values of all User-Defined Fields (UDFs) for the device.

**Returns:** `DRMMDevice` - Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device.

### SetWarranty([DateTime]$WarrantyDate)

Sets the warranty date for the device.

**Returns:** `DRMMDevice` - Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device.

**Parameters:**
- `[DateTime]$WarrantyDate` - TODO: Describe this parameter

### RunQuickJob([Guid]$ComponentUid, [Hashtable]$Variables)

Runs a quick job on the device for a specified job component and variables.

**Returns:** `DRMMJob` - Represents a job in the DRMM system, including its ID, unique identifier, name, creation date, and status.

**Parameters:**
- `[Guid]$ComponentUid` - TODO: Describe this parameter
- `[Hashtable]$Variables` - TODO: Describe this parameter

### Move([Guid]$TargetSiteUid)

Moves the device to a different site within the DRMM system.

**Returns:** `DRMMDevice` - Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device.

**Parameters:**
- `[Guid]$TargetSiteUid` - TODO: Describe this parameter

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMDevice/about_DRMMDevice.md)

