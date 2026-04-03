# about_DRMMAlertSourceInfo

## SHORT DESCRIPTION

Represents the source information for an alert in the DRMM system, including device and site details.

## LONG DESCRIPTION

The DRMMAlertSourceInfo class models the source information specific to alerts in the DRMM platform. It encapsulates properties such as DeviceUid, DeviceName, SiteUid, and SiteName that provide detailed context about the alert's source.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMAlertSourceInfo class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DeviceUid  | string | The unique identifier of the device associated with the alert. |
| DeviceName | string | The name of the device associated with the alert. |
| SiteUid    | string | The unique identifier of the site associated with the alert. |
| SiteName   | string | The name of the site associated with the alert. |

## METHODS

The DRMMAlertSourceInfo class provides the following methods:

### GetSummary()

Generates a summary string for the alert source information, including device and site details.

**Returns:** `string` - Returns string

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMAlert/about_DRMMAlertSourceInfo.md)

