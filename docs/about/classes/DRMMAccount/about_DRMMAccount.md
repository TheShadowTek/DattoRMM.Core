# about_DRMMAccount

## SHORT DESCRIPTION

Represents an account in the DRMM system, including its properties and related information.

## LONG DESCRIPTION

The DRMMAccount class models an account within the DRMM platform, encapsulating properties such as the account ID, unique identifier, name, currency, and related descriptors and device status. It provides a static method to create an instance of the class from a typical API response object that contains account information. The class also includes a method to generate a summary string that combines the account name with its device status for easy display. The DRMMAccountDescriptor and DRMMAccountDevicesStatus classes represent related information about the account, such as billing details and device status, respectively.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMAccount class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id            | int                      | The unique identifier for the account. |
| Uid           | string                   | The unique identifier string for the account. |
| Name          | string                   | The name of the account. |
| Currency      | string                   | The currency associated with the account, typically represented as a three-letter ISO currency code. |
| Descriptor    | DRMMAccountDescriptor    | An instance of the DRMMAccountDescriptor class that provides additional details about the account, such as billing email, device limit, and time zone. |
| DevicesStatus | DRMMAccountDevicesStatus | An instance of the DRMMAccountDevicesStatus class that provides information about the number of devices associated with the account and their status (online, offline, on-demand, managed). |

## METHODS

The DRMMAccount class provides the following methods:

### GetSummary()

Generates a summary string for the account, including its name and device status.

**Returns:** `string` - A summary string combining the account name and device status.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMAccount/about_DRMMAccount.md)
- [DRMMAccountDescriptor](./about_DRMMAccountDescriptor.md)
- [DRMMAccountDevicesStatus](./about_DRMMAccountDevicesStatus.md)
- [Get-RMMAccount](../../../commands/Account/Get-RMMAccount.md)

