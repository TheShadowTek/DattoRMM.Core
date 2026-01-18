
# about_DRMMDeviceAudit

## SHORT DESCRIPTION


Describes the DRMMDeviceAudit class and its methods for accessing device audit data in Datto RMM.

## LONG DESCRIPTION


Datto RMM provides detailed audit snapshots for managed devices. The DRMMDeviceAudit class is used for Windows, macOS, and Linux endpoints.

This class exposes properties and sub-objects relevant to its device type, including hardware, software, network, and system information. Use [Get-RMMDeviceAudit](Get-RMMDeviceAudit.md) to retrieve a DRMMDeviceAudit object for a device.


# Device Audit (DRMMDeviceAudit)

## Properties
| Property         | Type                              | Description                                 |
|------------------|-----------------------------------|---------------------------------------------|
| DeviceUid        | guid                              | Device GUID                                 |
| PortalUrl        | string                            | Device portal URL                           |
| WebRemoteUrl     | string                            | Web remote URL                              |
| SystemInfo       | DRMMDeviceAuditSystemInfo         | System information                          |
| Nics             | DRMMNetworkInterface[]            | Network interfaces                          |
| Bios             | DRMMDeviceAuditBios               | BIOS information                            |
| BaseBoard        | DRMMDeviceAuditBaseBoard          | Base board information                      |
| Displays         | DRMMDeviceAuditDisplay[]          | Display devices                             |
| LogicalDisks     | DRMMDeviceAuditLogicalDisk[]      | Logical disk information                    |
| MobileInfo       | DRMMDeviceAuditMobileInfo[]       | Mobile device info                          |
| Processors       | DRMMDeviceAuditProcessor[]        | Processor information                       |
| VideoBoards      | DRMMDeviceAuditVideoBoard[]       | Video board information                     |
| AttachedDevices  | DRMMDeviceAuditAttachedDevice[]   | Attached devices                            |
| SnmpInfo         | DRMMDeviceAuditSnmpInfo           | SNMP information                            |
| PhysicalMemory   | DRMMDeviceAuditPhysicalMemory[]   | Physical memory modules                     |
| Software         | DRMMDeviceAuditSoftware[]         | Installed software                          |

## Methods
DRMMDeviceAudit does not expose instance methods. All data is accessed via properties and related sub-classes.

## Related Classes
### DRMMDeviceAuditSystemInfo
- Manufacturer `[string]`
- Model `[string]`
- TotalPhysicalMemory `[long]`
- Username `[string]`
- DotNetVersion `[string]`
- TotalCpuCores `[int]`

### DRMMNetworkInterface
- Instance `[string]`
- Ipv4 `[string]`
- Ipv6 `[string]`
- MacAddress `[string]`
- Type `[string]`

### DRMMDeviceAuditBios
- Manufacturer `[string]`
- Name `[string]`
- SerialNumber `[string]`
- SmbiosBiosVersion `[string]`

### DRMMDeviceAuditBaseBoard
- Manufacturer `[string]`
- Product `[string]`
- SerialNumber `[string]`

### DRMMDeviceAuditDisplay
- Instance `[string]`
- ScreenHeight `[int]`
- ScreenWidth `[int]`

### DRMMDeviceAuditLogicalDisk
- Description `[string]`
- DiskIdentifier `[string]`
- Freespace `[long]`
- Size `[long]`

### DRMMDeviceAuditMobileInfo
- Iccid `[string]`
- Imei `[string]`
- Number `[string]`
- Operator `[string]`

### DRMMDeviceAuditProcessor
- Name `[string]`

### DRMMDeviceAuditVideoBoard
- DisplayAdapter `[string]`

### DRMMDeviceAuditAttachedDevice
- Description `[string]`
- Instance `[string]`

### DRMMDeviceAuditSnmpInfo
- Contact `[string]`
- Description `[string]`
- Location `[string]`
- Name `[string]`

### DRMMDeviceAuditPhysicalMemory
- BankLabel `[string]`
- Capacity `[long]`
- Manufacturer `[string]`
- PartNumber `[string]`
- SerialNumber `[string]`
- Speed `[int]`

### DRMMDeviceAuditSoftware
- Name `[string]`
- Version `[string]`



## METHOD CHAINING

Audit objects support method chaining and integration with related classes.

```powershell
# Standard device
$audit = Get-RMMDeviceAudit -DeviceUid $device.Uid
$ramGB = $audit.SystemInfo.TotalPhysicalMemory / 1GB
$biosVersion = $audit.Bios.SmbiosBiosVersion
$firstNic = $audit.Nics[0].Ipv4
```

## EXAMPLES


### Example 1: Get audit and display RAM (Standard device)
```powershell
$audit = Get-RMMDeviceAudit -DeviceUid $device.Uid
Write-Host "RAM: $($audit.SystemInfo.TotalPhysicalMemory / 1GB) GB"
```

### Example 2: List logical disks and free space (Standard device)
```powershell
$audit = Get-RMMDeviceAudit -DeviceUid $device.Uid
foreach ($disk in $audit.LogicalDisks) {
	$freePercent = ($disk.Freespace / $disk.Size) * 100
	Write-Host "$($disk.DiskIdentifier): $([math]::Round($freePercent, 2))% free"
}
```

### Example 3: List installed software (Standard device)
```powershell
$audit = Get-RMMDeviceAudit -DeviceUid $device.Uid
foreach ($app in $audit.Software) {
	Write-Host "$($app.Name) $($app.Version)"
}
```

### Example 4: Show network interfaces (Standard device)
```powershell
$audit = Get-RMMDeviceAudit -DeviceUid $device.Uid
foreach ($nic in $audit.Nics) {
	Write-Host "$($nic.Instance): $($nic.Ipv4)"
}
```


## BEST PRACTICES

1. Cache audit objects when performing multiple queries to avoid repeated API calls.
2. Validate audit data before processing, as some properties may be null depending on device type.
3. Use method chaining to access nested properties efficiently.


## NOTES

- DRMMDeviceAudit is returned by GetAudit() on DRMMDevice objects and by Get-RMMDeviceAudit.
- All sub-classes (SystemInfo, Bios, Nics, etc.) are typed and support property access.
- Some properties may be null or empty depending on device type and audit scope.
- DRMMDeviceAudit inherits from DRMMObject, providing common functionality.

## SEE ALSO

- [Get-RMMDeviceAudit](Get-RMMDeviceAudit.md)
- [Get-RMMDevice](Get-RMMDevice.md)
- [DRMMDevice](about_DRMMDevice.md)
- [DRMMDeviceAuditSoftware](about_DRMMDevice.md#drmmdeviceauditsoftware)
- [DRMMDeviceAuditSystemInfo](about_DRMMDeviceAudit.md#drmmdeviceauditsysteminfo)
- [DRMMDeviceAuditLogicalDisk](about_DRMMDeviceAudit.md#drmmdeviceauditlogicaldisk)
- [DRMMEsxiHostAudit](about_DRMMEsxiHostAudit.md)
- [DRMMPrinterAudit](about_DRMMPrinterAudit.md)
