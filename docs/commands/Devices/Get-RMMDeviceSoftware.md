# Get-RMMDeviceSoftware

## SYNOPSIS
Retrieves installed software for a specific device.

## SYNTAX

```
Get-RMMDeviceSoftware [-DeviceUid] <Guid> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMDeviceSoftware function retrieves a list of all installed software applications
on a specific device.
This includes installed programs, Windows updates, and other software
components detected by the Datto RMM agent.

This function requires a DeviceUid and is typically used after retrieving devices with
Get-RMMDevice or Get-RMMDeviceAudit.

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMDevice -DeviceId 12345 | Get-RMMDeviceSoftware
```

Retrieves all installed software for device 12345.

EXAMPLE 2
```powershell
$Device = Get-RMMDevice -Name "SERVER01"
Get-RMMDeviceSoftware -DeviceUid $Device.Uid
```

Retrieves a device by name and then gets its installed software.

EXAMPLE 3
```powershell
Get-RMMDevice -FilterId 100 | Get-RMMDeviceSoftware | Where-Object {$_.Name -like "*Microsoft*"}
```

Gets all devices matching filter 100 and retrieves their installed Microsoft software.

EXAMPLE 4
```powershell
$Software = Get-RMMDevice -DeviceId 12345 | Get-RMMDeviceSoftware
$Software | Select-Object Name, Version, Publisher | Format-Table
```

Retrieves software and displays it in a formatted table.

EXAMPLE 5
```powershell
Get-RMMDevice -DeviceId 12345 | Get-RMMDeviceSoftware | 
    Group-Object Publisher | Select-Object Name, Count | Sort-Object Count -Descending
```

Retrieves software and groups by publisher to see which vendors have the most applications installed.

## PARAMETERS

### -DeviceUid
The unique identifier (GUID) of the device to retrieve software for.
Accepts pipeline
input from Get-RMMDevice.

```yaml
Type: Guid
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

## INPUTS

System.Guid. You can pipe DeviceUid from Get-RMMDevice.
DRMMDevice. You can pipe device objects from Get-RMMDevice.
## OUTPUTS

DRMMDeviceAuditSoftware. Returns software objects with the following properties:
- Name: Application name
- Version: Application version
- Publisher: Software publisher/vendor
- InstallDate: Date installed (if available)
- InstallLocation: Installation path
- UninstallString: Uninstall command
- Size: Installed size in bytes
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

The software inventory is collected by the Datto RMM agent during regular audit cycles.
Results may not be real-time if the device is offline or hasn't reported recently.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Get-RMMDeviceSoftware.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Get-RMMDeviceSoftware.md))
- [about_DRMMDevice](../../about/classes/DRMMDevice/about_DRMMDevice.md)
- [Get-RMMDevice](./Get-RMMDevice.md)
- [Get-RMMDeviceAudit](./Get-RMMDeviceAudit.md)
