# about_DRMMSiteProxySettings

## SHORT DESCRIPTION

Represents the proxy settings for a site in the DRMM system, including properties such as host, port, type, and authentication credentials.

## LONG DESCRIPTION

The DRMMSiteProxySettings class models the proxy settings for a site within the DRMM platform. It includes properties such as Host, Port, Type, Username, and Password. The class provides a constructor and a static method to create an instance from API response data. Additionally, it includes a method to generate a summary string of the proxy settings information. The class handles the conversion of password data from the API response, ensuring that it is stored as a secure string when appropriate.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMSiteProxySettings class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Host     | string       | The host address of the proxy server. |
| Username | string       | The username for the proxy server. |
| Password | securestring | The password for the proxy server. |
| Port     | int          | The port number of the proxy server. |
| Type     | string       | The type of the proxy server (e.g., HTTP, SOCKS). |

## METHODS

The DRMMSiteProxySettings class provides the following methods:

### GetSummary()

Generates a summary string for the proxy settings, including the type, host, and port information.

**Returns:** `string` - A summary string that includes the type, host, and port information of the site's proxy settings.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMSite/about_DRMMSiteProxySettings.md)
