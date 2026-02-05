# about_DRMMDeviceNetworkInterface

## SHORT DESCRIPTION

Represents a network interface associated with a device in the DRMM system.

## LONG DESCRIPTION

The DRMMDeviceNetworkInterface class models the network interface information for a device in the DRMM platform. It includes properties such as Id, Uid, SiteId, SiteUid, SiteName, DeviceType, Hostname, IntIpAddress, ExtIpAddress, and an array of network interfaces (Nics). The class provides a constructor and a static method to create an instance from API response data.

This class inherits from [DRMMObject](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMDeviceNetworkInterface class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id           | long                   | The unique identifier of the network interface. |
| Uid          | guid                   | The unique identifier (UID) of the network interface. |
| SiteId       | long                   | The unique identifier of the site to which the network interface belongs. |
| SiteUid      | guid                   | The unique identifier (UID) of the site to which the network interface belongs. |
| SiteName     | string                 | The name of the site to which the network interface belongs. |
| DeviceType   | DRMMDeviceType         | The type of the network device. |
| Hostname     | string                 | The hostname associated with the network interface. |
| IntIpAddress | string                 | The internal IP address of the network interface. |
| ExtIpAddress | string                 | The external IP address of the network interface. |
| Nics         | DRMMNetworkInterface[] | The network interface cards associated with the device. |

## METHODS

The DRMMDeviceNetworkInterface class provides the following methods:

No public methods defined.

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

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMDevice/about_DRMMDeviceNetworkInterface.md)
