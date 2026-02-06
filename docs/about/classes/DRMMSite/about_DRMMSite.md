# about_DRMMSite

## SHORT DESCRIPTION

Represents a site in the DRMM system, including its properties, settings, and associated devices and variables.

## LONG DESCRIPTION

The DRMMSite class models a site within the DRMM platform, encapsulating properties such as Id, Uid, AccountUid, Name, Description, Notes, OnDemand status, SplashtopAutoInstall setting, ProxySettings, DevicesStatus, SiteSettings, Variables, Filters, AutotaskCompanyName, AutotaskCompanyId, and PortalUrl. It provides a constructor and a static method to create an instance from API response data. The class also includes methods to generate a summary string of the site's information, update site properties, retrieve associated alerts and devices, and open the site's portal URL in a web browser.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMSite class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id                   | long                  | The unique identifier of the site. |
| Uid                  | guid                  | The unique identifier (UID) of the site. |
| AccountUid           | string                | The unique identifier (UID) of the account associated with the site. |
| Name                 | string                | The name of the site. |
| Description          | string                | The description of the site. |
| Notes                | string                | Additional notes about the site. |
| OnDemand             | bool                  | Indicates whether the site is on-demand. |
| SplashtopAutoInstall | bool                  | Indicates whether Splashtop auto-install is enabled for the site. |
| ProxySettings        | DRMMSiteProxySettings | The proxy settings for the site. |
| DevicesStatus        | DRMMDevicesStatus     | The status of the devices associated with the site. |
| SiteSettings         | DRMMSiteSettings      | The settings for the site. |
| Variables            | DRMMVariable[]        | The variables associated with the site. |
| Filters              | DRMMFilter[]          | The filters associated with the site. |
| AutotaskCompanyName  | string                | The name of the Autotask company associated with the site. |
| AutotaskCompanyId    | string                | The identifier of the Autotask company associated with the site. |
| PortalUrl            | string                | The URL of the site portal. |

## METHODS

The DRMMSite class provides the following methods:

### GetSummary()

Generates a summary string for the site, including its name, unique identifier, and device count.

**Returns:** `string` - A summary string that includes the name, unique identifier, and device count for the site.

### Set([Hashtable]$Properties)

Updates the properties of the site based on the provided hashtable of property names and values.

**Returns:** `DRMMSite` - This method does not return a value. It performs an action to update the properties of the site based on the provided hashtable of property names and values.

**Parameters:**
- `[Hashtable]$Properties` - The hashtable of properties to update for the site, where the keys are the property names and the values are the new values to set for those properties.

### GetAlerts()

Retrieves alerts associated with the site, optionally filtered by status.

**Returns:** `DRMMAlert[]` - A collection of alerts associated with the site, optionally filtered by the specified status.

### GetAlerts([String]$Status)

Retrieves alerts associated with the site, optionally filtered by status.

**Returns:** `DRMMAlert[]` - A collection of alerts associated with the site, optionally filtered by the specified status.

**Parameters:**
- `[String]$Status` - The status of the alerts to retrieve (e.g., "active", "resolved").

### OpenPortal()

Opens the portal URL associated with the site in the default web browser.

**Returns:** `void` - This method does not return a value. It performs an action to open the portal URL in the default web browser.

### GetDevices()

Retrieves devices associated with the site, optionally filtered by a specific filter ID.

**Returns:** `DRMMDevice[]` - A collection of devices associated with the site, optionally filtered by the specified filter ID.

### GetDevices([Int64]$FilterId)

Retrieves devices associated with the site, optionally filtered by a specific filter ID.

**Returns:** `DRMMDevice[]` - A collection of devices associated with the site, optionally filtered by the specified filter ID.

**Parameters:**
- `[Int64]$FilterId` - The ID of the filter to apply when retrieving devices.

### GetDeviceCount()

Retrieves the count of devices associated with the site.

**Returns:** `int` - The count of devices associated with the site.

### GetVariables()

Retrieves variables associated with the site.

**Returns:** `DRMMVariable[]` - A collection of variables associated with the site.

### GetVariable([String]$Name)

Retrieves a specific variable associated with the site by name.

**Returns:** `DRMMVariable` - The variable associated with the site that matches the specified name, or null if no matching variable is found.

**Parameters:**
- `[String]$Name` - The name of the variable to retrieve.

### NewVariable([String]$Name, [String]$Value)

Creates a new variable associated with the site, with an option to mask the value.

**Returns:** `DRMMVariable` - The newly created variable associated with the site.

**Parameters:**
- `[String]$Name` - The name of the variable.
- `[String]$Value` - The value of the variable.

### NewVariable([String]$Name, [String]$Value, [Boolean]$Masked)

Creates a new variable associated with the site, with an option to mask the value.

**Returns:** `DRMMVariable` - The newly created variable associated with the site.

**Parameters:**
- `[String]$Name` - The name of the variable.
- `[String]$Value` - The value of the variable.
- `[Boolean]$Masked` - Indicates whether the variable is masked.

### GetFilters()

Retrieves filters associated with the site.

**Returns:** `DRMMFilter[]` - A collection of filters associated with the site.

### GetFilter([String]$Name)

Retrieves a specific filter associated with the site by name.

**Returns:** `DRMMFilter` - The filter associated with the site that matches the specified name, or null if no matching filter is found.

**Parameters:**
- `[String]$Name` - The name of the filter to retrieve.

### GetSettings()

Retrieves the site settings for the site.

**Returns:** `DRMMSiteSettings` - The site settings associated with the site.

### SetProxy([String]$ProxyHost, [Int32]$Port, [String]$Type)

Sets the proxy settings for the site, including authentication credentials.

**Returns:** `DRMMSiteSettings` - This method does not return a value. It performs an action to set the proxy settings for the site, including authentication credentials.

**Parameters:**
- `[String]$ProxyHost` - The hostname or IP address of the proxy server.
- `[Int32]$Port` - The port number for the proxy server.
- `[String]$Type` - The type of proxy (e.g., HTTP, SOCKS).

### SetProxy([String]$ProxyHost, [Int32]$Port, [String]$Type, [String]$Username, [SecureString]$Password)

Sets the proxy settings for the site, including authentication credentials.

**Returns:** `DRMMSiteSettings` - This method does not return a value. It performs an action to set the proxy settings for the site, including authentication credentials.

**Parameters:**
- `[String]$ProxyHost` - The hostname or IP address of the proxy server.
- `[Int32]$Port` - The port number for the proxy server.
- `[String]$Type` - The type of proxy (e.g., HTTP, SOCKS).
- `[String]$Username` - The username for proxy authentication.
- `[SecureString]$Password` - The password for proxy authentication.

### RemoveProxy()

Removes the proxy settings for the site.

**Returns:** `DRMMSiteSettings` - This method does not return a value. It performs an action to remove the proxy settings for the site.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMSite/about_DRMMSite.md)
