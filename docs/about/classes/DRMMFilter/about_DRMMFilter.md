# about_DRMMFilter

## SHORT DESCRIPTION

Represents a filter in the DRMM system, including its name, description, type, scope, and associated site.

## LONG DESCRIPTION

The DRMMFilter class models a filter within the DRMM platform, encapsulating properties such as Id, FilterId, Name, Description, Type, Scope, Site (for site-scoped filters), SiteUid, DateCreate, LastUpdated, and PortalUrl. It provides a constructor and a static method to create an instance from API response data. The class also includes methods to determine if the filter is global or site-specific, as well as a method to generate a summary string of the filter's information. Additionally, it includes methods to retrieve devices and alerts associated with the filter. For site-scoped filters, the Site property provides full context about the associated site, while SiteUid is maintained for backward compatibility.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMFilter class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id          | long               | The identifier of the filter. |
| FilterId    | long               | The unique identifier of the filter. |
| Name        | string             | The name of the filter. |
| Description | string             | A brief description of the filter's purpose or criteria. |
| Type        | string             | The type or category of the filter. |
| Scope       | string             | The scope or context in which the filter is applied. |
| SiteUid     | Nullable[guid]     | The unique identifier of the site associated with the filter. |
| Site        | DRMMSite           | The DRMMSite object associated with the filter when it is site-scoped. Provides full site context for site-specific filters. |
| DateCreate  | Nullable[datetime] | The date and time when the filter was created. |
| LastUpdated | Nullable[datetime] | The date and time when the filter was last updated. |
| PortalUrl   | string             | The URL to access the filter results in the Datto RMM web portal. |

## METHODS

The DRMMFilter class provides the following methods:

### IsGlobal()

Determines if the variable is global in scope.

**Returns:** `bool` - A boolean value indicating whether the filter is global in scope.

### IsSite()

Determines if the variable is site-specific in scope.

**Returns:** `bool` - A boolean value indicating whether the filter is site-specific in scope.

### IsDefault()

Determines if the filter is the default type.

**Returns:** `bool` - A boolean value indicating whether the filter is the default type.

### IsCustom()

Determines if the filter is a custom type.

**Returns:** `bool` - A boolean value indicating whether the filter is a custom type.

### OpenPortal()

Opens the portal URL associated with the filter in the default web browser.

**Returns:** `void` - This method does not return a value. It performs an action to open the portal URL in the default web browser.

### GetSummary()

Generates a summary string for the filter, including its name, scope, and type.

**Returns:** `string` - A summary string that includes the filter's name, scope, and type.

### GetDevices()

Retrieves the devices associated with the filter.

**Returns:** `DRMMDevice[]` - A list of devices associated with the filter.

### GetDeviceCount()

Retrieves the count of devices associated with the filter.

**Returns:** `int` - The count of devices associated with the filter.

### GetAlerts()

Retrieves the alerts associated with the filter.

**Returns:** `DRMMAlert[]` - A list of alerts associated with the filter, optionally filtered by status.

### GetAlerts([String]$Status)

Retrieves the alerts associated with the filter.

**Returns:** `DRMMAlert[]` - A list of alerts associated with the filter, optionally filtered by status.

**Parameters:**
- `[String]$Status` - The status of the alerts to retrieve (e.g., "active", "resolved").

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMFilter/about_DRMMFilter.md)
