# about_DRMMAccountDevicesStatus

## SHORT DESCRIPTION

Represents the device status information for a DRMM account, including counts of devices in various states.

## LONG DESCRIPTION

The DRMMAccountDevicesStatus class encapsulates information about the number of devices associated with a DRMM account, including the total number of devices, the number of online devices, offline devices, on-demand devices, and managed devices. It provides a static method to create an instance of the class from a typical API response object that contains these device status details. The class also includes methods to calculate the percentage of online devices and to generate a summary string that combines this information for easy display. This class is used as a property within the DRMMAccount class to provide insights into the account's device status.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMAccountDevicesStatus class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| NumberOfDevices         | int | The total number of devices associated with the account. |
| NumberOfOnlineDevices   | int | The number of devices that are currently online. |
| NumberOfOfflineDevices  | int | The number of devices that are currently offline. |
| NumberOfOnDemandDevices | int | The number of devices that are on-demand. |
| NumberOfManagedDevices  | int | The number of devices that are managed within the account. |

## METHODS

The DRMMAccountDevicesStatus class provides the following methods:

### GetOnlinePercentage()

Calculates the percentage of online devices for the account.

**Returns:** `double` - The percentage of online devices as a double value.

### GetSummary()

Generates a summary string for the device status, including the count of online devices and total devices.

**Returns:** `string` - A summary string combining the count of online devices and total devices.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMAccount/about_DRMMAccountDevicesStatus.md)
- [DRMMAccount](./about_DRMMAccount.md)
- [Get-RMMAccount](../../../commands/Account/Get-RMMAccount.md)

