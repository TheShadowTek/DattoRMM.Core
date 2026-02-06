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

Retrieves the alerts associated with the device, filtered by a specified status.

**Returns:** `DRMMAlert[]` - An array of alerts associated with the device that match the specified status.

### GetAlerts([String]$Status)

Retrieves the alerts associated with the device, filtered by a specified status.

**Returns:** `DRMMAlert[]` - An array of alerts associated with the device that match the specified status.

**Parameters:**
- `[String]$Status` - The status to filter alerts by.

### OpenPortal()

Opens the device's portal URL in the default web browser.

**Returns:** `void` - This method does not return a value. It performs an action to open the portal URL in the default web browser.

### OpenWebRemote()

Opens the device's web remote URL in the default web browser.

**Returns:** `void` - This method does not return a value. It performs an action to open the web remote URL in the default web browser.

### GetUdfAsJson([Int32]$UdfNumber)

Retrieves the value of a specified User-Defined Field (UDF) as a JSON object.

**Returns:** `object` - A JSON object containing the value of the specified UDF.

**Parameters:**
- `[Int32]$UdfNumber` - The number of the User-Defined Field (UDF) to retrieve as JSON.

### GetUdfAsCsv([Int32]$UdfNumber, [String[]]$Headers)

Retrieves the value of a specified User-Defined Field (UDF) as a CSV object with a custom delimiter and headers.

**Returns:** `pscustomobject` - A CSV object containing the value of the specified UDF, formatted with the provided delimiter and headers.

**Parameters:**
- `[Int32]$UdfNumber` - The number of the User-Defined Field (UDF) to retrieve as CSV.
- `[String[]]$Headers` - An array of headers to include in the CSV output.

### GetUdfAsCsv([Int32]$UdfNumber, [String]$Delimiter, [String[]]$Headers)

Retrieves the value of a specified User-Defined Field (UDF) as a CSV object with a custom delimiter and headers.

**Returns:** `pscustomobject` - A CSV object containing the value of the specified UDF, formatted with the provided delimiter and headers.

**Parameters:**
- `[Int32]$UdfNumber` - The number of the User-Defined Field (UDF) to retrieve as CSV.
- `[String]$Delimiter` - The delimiter to use in the CSV output (e.g., comma, semicolon).
- `[String[]]$Headers` - An array of headers to include in the CSV output.

### GetSummary()

Generates a summary string for the device, including its hostname and device type.

**Returns:** `string` - A summary string for the device, including its hostname and device type.

### ResolveAllAlerts()

Resolves all open alerts associated with the device.

**Returns:** `void` - This method does not return a value. It performs an action to resolve all open alerts associated with the device.

### GetAudit()

Gets the most recent audit information for this device.

**Returns:** `DRMMDeviceAudit` - The most recent audit information for this device.

### GetSoftware()

Gets the software information for this device.

**Returns:** `DRMMDeviceAuditSoftware[]` - The software information for this device.

### SetUDF([Hashtable]$UDFFields)

Sets the value of one or more User-Defined Fields (UDFs) for the device.

**Returns:** `DRMMDevice` - This method does not return a value. It performs an action to set the specified UDFs for the device.

**Parameters:**
- `[Hashtable]$UDFFields` - A hashtable of User-Defined Fields (UDFs) to set for the device.

### ClearUDF([Int32]$UdfNumber)

Clears the value of a specified User-Defined Field (UDF) for the device.

**Returns:** `DRMMDevice` - This method does not return a value. It performs an action to clear the specified UDF.

**Parameters:**
- `[Int32]$UdfNumber` - The number of the User-Defined Field (UDF) to clear.

### ClearUDFs()

Clears the values of all User-Defined Fields (UDFs) for the device.

**Returns:** `DRMMDevice` - This method does not return a value. It performs an action to clear all UDFs.

### SetWarranty([DateTime]$WarrantyDate)

Sets the warranty date for the device.

**Returns:** `DRMMDevice` - This method does not return a value. It performs an action to set the warranty date for the device.

**Parameters:**
- `[DateTime]$WarrantyDate` - The warranty date to set for the device.

### RunQuickJob([Guid]$ComponentUid, [Hashtable]$Variables)

Runs a quick job on the device for a specified job component and variables.

**Returns:** `DRMMJob` - A DRMMJob object representing the job that was run on the device.

**Parameters:**
- `[Guid]$ComponentUid` - The unique identifier of the job component to run.
- `[Hashtable]$Variables` - A hashtable of variables to pass to the job component.

### Move([Guid]$TargetSiteUid)

Moves the device to a different site within the DRMM system.

**Returns:** `DRMMDevice` - This method does not return a value. It performs an action to move the device to the specified site.

**Parameters:**
- `[Guid]$TargetSiteUid` - The unique identifier of the target site to move the device to.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMDevice/about_DRMMDevice.md)
