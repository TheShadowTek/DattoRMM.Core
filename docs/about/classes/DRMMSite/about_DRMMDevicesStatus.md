# about_DRMMDevicesStatus

## SHORT DESCRIPTION

Represents the status of devices associated with a site in the DRMM system, including counts of total devices, online devices, and offline devices.

## LONG DESCRIPTION

The DRMMDevicesStatus class models the status of devices for a site within the DRMM platform. It includes properties such as NumberOfDevices, NumberOfOnlineDevices, and NumberOfOfflineDevices. The class provides a constructor and a static method to create an instance from API response data. Additionally, it includes a method to generate a summary string of the device status information, providing an overview of the total number of devices and their online/offline status for the site.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMDevicesStatus class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| NumberOfDevices        | long | The total number of devices. |
| NumberOfOnlineDevices  | long | The number of devices that are currently online. |
| NumberOfOfflineDevices | long | The number of devices that are currently offline. |

## METHODS

The DRMMDevicesStatus class provides the following methods:

### GetSummary()

Generates a summary string for the device status, including counts of total devices, online devices, and offline devices.

**Returns:** `string` - A summary string that includes the total number of devices, the number of online devices, and the number of offline devices for the site.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMSite/about_DRMMDevicesStatus.md)
