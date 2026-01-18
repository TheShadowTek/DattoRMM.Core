# about_DRMMPrinterAudit

## SHORT DESCRIPTION

Describes the DRMMPrinterAudit class and its methods for accessing printer audit data in Datto RMM.

## LONG DESCRIPTION

Datto RMM provides detailed audit snapshots for network printers. Use [Get-RMMPrinterAudit](Get-RMMPrinterAudit.md) to retrieve a DRMMPrinterAudit object for a printer device. For standard device audits, see [DRMMDeviceAudit](about_DRMMDeviceAudit.md).

# Printer Audit (DRMMPrinterAudit)

## Properties
| Property               | Type                              | Description                                 |
|------------------------|-----------------------------------|---------------------------------------------|
| DeviceUid              | guid                              | Device GUID                                 |
| PortalUrl              | string                            | Device portal URL                           |
| SnmpInfo               | DRMMPrinterSnmpInfo               | SNMP information                            |
| PrinterMarkerSupplies  | DRMMPrinterMarkerSupply[]         | Printer supply levels                       |
| Printer                | DRMMPrinter                       | Printer details                             |
| SystemInfo             | DRMMPrinterSystemInfo             | Printer system information                  |
| Nics                   | DRMMNetworkInterface[]            | Network interfaces                          |

## Methods
DRMMPrinterAudit does not expose instance methods. All data is accessed via properties and related sub-classes.

## Related Classes
### DRMMPrinterSnmpInfo
- SnmpName `[string]`
- SnmpContact `[string]`
- SnmpDescription `[string]`
- SnmpLocation `[string]`
- SnmpUptime `[string]`
- NicManufacturer `[string]`
- ObjectId `[string]`
- SnmpSerial `[string]`

### DRMMPrinterMarkerSupply
- Description `[string]`
- MaxCapacity `[string]`
- SuppliesLevel `[string]`

### DRMMPrinter
- Name `[string]`
- Model `[string]`
- SerialNumber `[string]`

### DRMMPrinterSystemInfo
- Hostname `[string]`
- Manufacturer `[string]`
- Model `[string]`
- FirmwareVersion `[string]`

## METHOD CHAINING

Audit objects support method chaining and integration with related classes. The returned object type depends on the device:

```powershell
# Printer
$printerAudit = Get-RMMPrinterAudit -DeviceUid $printerDevice.Uid
$snmpName = $printerAudit.SnmpInfo.SnmpName
$supplyLevel = $printerAudit.PrinterMarkerSupplies[0].SuppliesLevel
```

## EXAMPLES

### Example 6: Show printer supply levels
```powershell
$printerAudit = Get-RMMPrinterAudit -DeviceUid $printerDevice.Uid
foreach ($supply in $printerAudit.PrinterMarkerSupplies) {
	Write-Host "$($supply.Description): $($supply.SuppliesLevel)"
}
```

## BEST PRACTICES

1. Cache audit objects when performing multiple queries to avoid repeated API calls.
2. Validate audit data before processing, as some properties may be null depending on device type.
3. Use method chaining to access nested properties efficiently.

## NOTES

- DRMMPrinterAudit is returned by GetAudit() on DRMMDevice objects and by Get-RMMPrinterAudit for printers.
- All sub-classes (SystemInfo, Printer, Nics, etc.) are typed and support property access.
- Some properties may be null or empty depending on device type and audit scope.
- DRMMPrinterAudit inherits from DRMMObject, providing common functionality.

## SEE ALSO

- [Get-RMMDevice](Get-RMMDevice.md)
- [DRMMDevice](about_DRMMDevice.md)
- [DRMMDeviceAudit](about_DRMMDeviceAudit.md)
