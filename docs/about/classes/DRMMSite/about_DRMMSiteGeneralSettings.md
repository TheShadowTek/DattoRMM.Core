# about_DRMMSiteGeneralSettings

## SHORT DESCRIPTION

Represents the general settings for a site in the DRMM system, including properties such as name, unique identifier, description, and on-demand status.

## LONG DESCRIPTION

The DRMMSiteGeneralSettings class models the general settings for a site within the DRMM platform. It includes properties such as Name, Uid, Description, and OnDemand status. The class provides a constructor and a static method to create an instance from API response data. Additionally, it includes a method to generate a summary string of the general settings information.

This class inherits from [DRMMObject](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMSiteGeneralSettings class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Name        | string | The name of the site's general settings. |
| Uid         | string | The unique identifier (UID) of the site's general settings. |
| Description | string | The description of the site's general settings. |
| OnDemand    | bool   | Indicates whether the site is on-demand. |

## METHODS

The DRMMSiteGeneralSettings class provides the following methods:

### GetSummary()

Generates a summary string for the general settings, including the on-demand status.

**Returns:** `string` - A summary string that includes the on-demand status of the site's general settings.

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

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMSite/about_DRMMSiteGeneralSettings.md)
