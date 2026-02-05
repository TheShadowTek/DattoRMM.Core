# about_DRMMDeviceAntivirusInfo

## SHORT DESCRIPTION

Represents antivirus information for a device in the DRMM system, including the antivirus product name and its status.

## LONG DESCRIPTION

The DRMMDeviceAntivirusInfo class models the antivirus information associated with a device in the DRMM platform. It includes properties such as AntivirusProduct and AntivirusStatus, which provide details about the antivirus software installed on the device and its current status. The class also includes methods to determine if the antivirus is running and up to date, as well as a method to generate a summary string of the antivirus information.

This class inherits from [DRMMObject](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMDeviceAntivirusInfo class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| AntivirusProduct | string | The name of the antivirus product installed on the device. |
| AntivirusStatus  | string | The current status of the antivirus product on the device. |

## METHODS

The DRMMDeviceAntivirusInfo class provides the following methods:

### IsRunning()

Determines if the antivirus is currently running on the device.

**Returns:** `bool` - A boolean value indicating whether the antivirus is currently running on the device.

### IsUpToDate()

Determines if the antivirus is running and up to date on the device.

**Returns:** `bool` - A boolean value indicating whether the antivirus is running and up to date on the device.

### GetSummary()

Generates a summary string of the antivirus product and its status.

**Returns:** `string` - A summary string of the antivirus product and its status.

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

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMDevice/about_DRMMDeviceAntivirusInfo.md)
