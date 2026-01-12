# about_DRMMAccount

## SHORT DESCRIPTION

Describes the DRMMAccount class and its related types for representing account-level information in Datto RMM.

## LONG DESCRIPTION


The DRMMAccount class models a Datto RMM account, including identifiers, name, currency, account descriptor, and device status summary.

DRMMAccount objects are returned by [Get-RMMAccount](Get-RMMAccount.md), which retrieves account objects for configuration and statistics. Use Get-RMMAccount to inspect account details and device status programmatically.

## PROPERTIES

| Property         | Type                        | Description                       |
|------------------|----------------------------|-----------------------------------|
| Id               | int                        | Numeric account identifier        |
| Uid              | string                     | Account GUID                      |
| Name             | string                     | Account name                      |
| Currency         | string                     | Account currency                  |
| Descriptor       | DRMMAccountDescriptor      | Account descriptor info           |
| DevicesStatus    | DRMMAccountDevicesStatus   | Device status summary             |

## METHODS

### GetSummary()
Returns a summary string of the account and device status.

**Returns:** `[string]`

## RELATED CLASSES

### DRMMAccountDescriptor
Represents account configuration details.
- BillingEmail `[string]`
- DeviceLimit `[int]`
- TimeZone `[string]`

### DRMMAccountDevicesStatus
Summarizes device statistics for the account.
- NumberOfDevices `[int]`
- NumberOfOnlineDevices `[int]`
- NumberOfOfflineDevices `[int]`
- NumberOfOnDemandDevices `[int]`
- NumberOfManagedDevices `[int]`

#### GetOnlinePercentage()
Returns the percentage of online devices.

**Returns:** `[double]`

#### GetSummary()
Returns a summary string of online devices.

**Returns:** `[string]`

## EXAMPLES

```powershell
$account = Get-RMMAccount
Write-Host $account.GetSummary()
# Output: My MSP - 120/150 online (80%)
```

## NOTES

- DRMMAccount is used for account-level reporting and configuration.
- Device status properties provide a quick overview of fleet health.

## SEE ALSO
- [Get-RMMAccount](Get-RMMAccount.md)
- [about_Datto-RMM](about_Datto-RMM.md)
