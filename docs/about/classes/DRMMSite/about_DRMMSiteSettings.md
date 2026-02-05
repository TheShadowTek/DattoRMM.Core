# about_DRMMSiteSettings

## SHORT DESCRIPTION

Represents the overall settings for a site in the DRMM system, including general settings, proxy settings, mail recipients, and site UID.

## LONG DESCRIPTION

The DRMMSiteSettings class models the overall settings for a site within the DRMM platform. It includes properties such as GeneralSettings, ProxySettings, MailRecipients, and SiteUid. The class provides a constructor and a static method to create an instance from API response data. Additionally, it includes a method to generate a summary string of the site's settings information, combining details from the general settings, proxy settings, and mail recipients. The class serves as a comprehensive representation of the site's configuration, allowing for easy access and management of various settings related to the site.

This class inherits from [DRMMObject](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMSiteSettings class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| GeneralSettings | DRMMSiteGeneralSettings | The general settings of the site. |
| ProxySettings   | DRMMSiteProxySettings   | The proxy settings for the site. |
| MailRecipients  | DRMMSiteMailRecipient[] | Reuse existing class |
| SiteUid         | guid                    | Reuse existing class |

## METHODS

The DRMMSiteSettings class provides the following methods:

### GetSummary()

Generates a summary string for the site's settings, including on-demand status, proxy information, and mail recipient count.

**Returns:** `string` - A summary string that includes the on-demand status, proxy information, and mail recipient count for the site.

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

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMSite/about_DRMMSiteSettings.md)
