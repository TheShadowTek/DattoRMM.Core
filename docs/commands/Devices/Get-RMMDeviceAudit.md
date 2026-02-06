# Get-RMMDeviceAudit

## SYNOPSIS
Retrieves detailed audit information for a device.

## SYNTAX

ByDeviceUid (Default)
```
Get-RMMDeviceAudit -DeviceUid <Guid> [-Software] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

ByMacAddress
```
Get-RMMDeviceAudit -MacAddress <String> [-Software] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMDeviceAudit function retrieves comprehensive hardware and software inventory
information for a managed device.
This includes system information, BIOS details, network
interfaces, processors, memory, disks, displays, and optionally installed software.

The audit data can be retrieved by device UID or MAC address.
When querying by MAC address,
if multiple devices share the same MAC address, the function will use the MAC address
endpoint to retrieve all matching devices.

## EXAMPLES

EXAMPLE 1
```
Get-RMMDevice -Hostname "SERVER01" | Get-RMMDeviceAudit
```

Retrieves audit information for SERVER01.

EXAMPLE 2
```
Get-RMMDeviceAudit -DeviceUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
```

Retrieves audit information for a specific device by UID.

EXAMPLE 3
```
Get-RMMDeviceAudit -DeviceUid $device.Uid -Software
```

Retrieves complete audit information including all installed software.

EXAMPLE 4
```
Get-RMMDeviceAudit -MacAddress "00:11:22:33:44:55"
```

Retrieves audit information using the device's MAC address.

EXAMPLE 5
```
Get-RMMDevice -FilterId 12345 | Get-RMMDeviceAudit | Where-Object {$_.SystemInfo.TotalPhysicalMemory -lt 8GB}
```

Gets audit data for filtered devices and finds those with less than 8GB RAM.

EXAMPLE 6
```
$Audit = Get-RMMDeviceAudit -DeviceUid $guid -Software
$Audit.Software | Where-Object {$_.Name -like "*Office*"}
```

Retrieves audit with software and filters for Microsoft Office installations.

## PARAMETERS

### -DeviceUid
The unique identifier (GUID) of the device to audit.
Accepts pipeline input from Get-RMMDevice.

```yaml
Type: Guid
Parameter Sets: ByDeviceUid
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -MacAddress
The MAC address of the device to audit.
Accepts formats: 001122334455, 00:11:22:33:44:55, or 00-11-22-33-44-55.

```yaml
Type: String
Parameter Sets: ByMacAddress
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Software
Include installed software inventory in the audit results.
When specified without -Software,
the Software property will be null.
Use Get-RMMDeviceSoftware for software-only queries.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

You can pipe objects with DeviceUid or MacAddress properties to this function.
## OUTPUTS

DRMMDeviceAudit. Returns a device audit object containing:
- DeviceUid: The device's unique identifier
- PortalUrl: Link to device in the Datto RMM portal
- SystemInfo: Manufacturer, model, memory, CPU cores
- Bios: BIOS information
- BaseBoard: Motherboard information
- Nics: Network interface details
- Processors: CPU information
- PhysicalMemory: RAM module details
- LogicalDisks: Disk partition information
- Displays: Monitor information
- VideoBoards: Graphics card details
- AttachedDevices: Connected peripherals
- SnmpInfo: SNMP details (for network devices)
- MobileInfo: Cellular information (for mobile devices)
- Software: Installed applications (only if -Software specified)
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

The -Software switch can significantly increase response time and data size for devices
with many installed applications.
Use Get-RMMDeviceSoftware if you only need software inventory.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Get-RMMDeviceAudit.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Get-RMMDeviceAudit.md))
- [about_DRMMDevice](../../about/classes/DRMMDevice/about_DRMMDevice.md)
- [Get-RMMDevice](./Get-RMMDevice.md)
- [Get-RMMDeviceSoftware](./Get-RMMDeviceSoftware.md)
