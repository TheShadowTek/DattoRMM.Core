# about_DRMMFilter

## SHORT DESCRIPTION

Represents a filter in the DRMM system, including its name, description, type, and scope.

## LONG DESCRIPTION

The DRMMFilter class models a filter within the DRMM platform, encapsulating properties such as Id, FilterId, Name, Description, Type, Scope, SiteUid, DateCreate, LastUpdated, and PortalUrl. It provides a constructor and a static method to create an instance from API response data. The class also includes methods to determine if the filter is global or site-specific, as well as a method to generate a summary string of the filter's information. Additionally, it includes methods to retrieve devices and alerts associated with the filter. For site-scoped filters, the DRMMSiteFilter subclass extends this class with a Site property that provides full context about the associated site.

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
| DateCreate  | Nullable[datetime] | The date and time when the filter was created. |
| LastUpdated | Nullable[datetime] | The date and time when the filter was last updated. |
| PortalUrl   | string             | The URL to access the filter results in the Datto RMM web portal. |

## METHODS

The DRMMFilter class provides the following methods:

### IsGlobal()

Determines if the variable is global in scope.

**Returns:** `bool` - Returns bool

### IsSite()

Determines if the variable is site-specific in scope.

**Returns:** `bool` - Returns bool

### IsDefault()

Determines if the filter is the default type.

**Returns:** `bool` - Returns bool

### IsCustom()

Determines if the filter is a custom type.

**Returns:** `bool` - Returns bool

### OpenPortal()

Opens the portal URL associated with the filter in the default web browser.

**Returns:** `void` - Returns void

### GetSummary()

Generates a summary string for the filter, including its name, scope, and type.

**Returns:** `string` - Returns string

### GetDevices()

Retrieves the devices associated with the filter.

**Returns:** `DRMMDevice[]` - Represents a device in the DRMM system, encapsulating properties and methods for interacting with the device.

### GetDeviceCount()

Retrieves the count of devices associated with the filter.

**Returns:** `int` - Returns int

### GetAlerts()

Retrieves the alerts associated with the filter.

**Returns:** `DRMMAlert[]` - Represents an alert in the DRMM system, including its properties, context, source information, and response actions.

### GetAlerts([String]$Status)

Retrieves the alerts associated with the filter.

**Returns:** `DRMMAlert[]` - Represents an alert in the DRMM system, including its properties, context, source information, and response actions.

**Parameters:**
- `[String]$Status` - TODO: Describe this parameter

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMFilter/about_DRMMFilter.md)

