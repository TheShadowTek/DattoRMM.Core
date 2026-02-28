# Get-RMMDeviceAudit

## SYNOPSIS
Retrieves detailed audit information for a device.

## SYNTAX

DeviceUid (Default)
```
Get-RMMDeviceAudit -DeviceUid <Guid> [-Software] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

Device
```
Get-RMMDeviceAudit -Device <DRMMDevice> [-Software] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMDeviceAudit function retrieves comprehensive hardware and software inventory
information for a managed device.
This includes system information, BIOS details, network
interfaces, processors, memory, disks, displays, and optionally installed software.

When a DRMMDevice object is piped in, the function inspects the DeviceClass property and
automatically routes to the correct audit endpoint.
ESXi hosts are routed to
Get-RMMEsxiHostAudit, printers are routed to Get-RMMPrinterAudit, and all other device
classes (device, rmmnetworkdevice, unknown) use the standard device audit endpoint.

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMDevice -Hostname "SERVER01" | Get-RMMDeviceAudit
```

Retrieves audit information for SERVER01.
Routes to the correct audit endpoint based on
the device's DeviceClass.

EXAMPLE 2
```powershell
Get-RMMDeviceAudit -DeviceUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
```

Retrieves device audit information for a specific device by UID.

EXAMPLE 3
```powershell
Get-RMMDeviceAudit -DeviceUid $device.Uid -Software
```

Retrieves complete audit information including all installed software.

EXAMPLE 4
```powershell
Get-RMMDevice -FilterId 12345 | Get-RMMDeviceAudit | Where-Object {$_.SystemInfo.TotalPhysicalMemory -lt 8GB}
```

Gets audit data for filtered devices and finds those with less than 8GB RAM.
ESXi hosts
and printers in the results are automatically routed to their respective audit endpoints.

EXAMPLE 5
```powershell
$Audit = Get-RMMDeviceAudit -DeviceUid $guid -Software
$Audit.Software | Where-Object {$_.Name -like "*Office*"}
```

Retrieves audit with software and filters for Microsoft Office installations.

## PARAMETERS

### -Device
A DRMMDevice object to retrieve audit data for.
Accepts pipeline input from Get-RMMDevice.
The DeviceClass property determines which audit endpoint is used.

```yaml
Type: DRMMDevice
Parameter Sets: Device
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -DeviceUid
The unique identifier (GUID) of the device to audit.

```yaml
Type: Guid
Parameter Sets: DeviceUid
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Software
Include installed software inventory in the audit results.
When not specified, the Software
property will be null.
Only applies to standard device audits.
Use Get-RMMDeviceSoftware
for software-only queries.

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

DRMMDevice. You can pipe device objects from Get-RMMDevice.
## OUTPUTS

DRMMDeviceAudit. Returns a device audit object when DeviceClass is device, rmmnetworkdevice,
or unknown.
DRMMEsxiHostAudit. Returns an ESXi host audit object when DeviceClass is esxihost.
DRMMPrinterAudit. Returns a printer audit object when DeviceClass is printer.
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

When piping DRMMDevice objects, the DeviceClass property determines routing:
- esxihost: Routes to Get-RMMEsxiHostAudit
- printer: Routes to Get-RMMPrinterAudit
- device, rmmnetworkdevice, unknown: Uses the standard device audit endpoint

The -Software switch can significantly increase response time and data size for devices
with many installed applications.
Use Get-RMMDeviceSoftware if you only need software inventory.

The -Software switch is only applicable to standard device audits.
When the Device parameter
routes to an ESXi or printer audit endpoint, the -Software switch is ignored.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Get-RMMDeviceAudit.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Get-RMMDeviceAudit.md))
- [about_DRMMDevice](../../about/classes/DRMMDevice/about_DRMMDevice.md)
- [Get-RMMDevice](./Get-RMMDevice.md)
- [Get-RMMDeviceSoftware](./Get-RMMDeviceSoftware.md)
- [Get-RMMEsxiHostAudit](./Get-RMMEsxiHostAudit.md)
- [Get-RMMPrinterAudit](./Get-RMMPrinterAudit.md)
