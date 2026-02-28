# Get-RMMPrinterAudit

## SYNOPSIS
Retrieves printer audit data for a specific device.

## SYNTAX

DeviceUid (Default)
```
Get-RMMPrinterAudit -DeviceUid <Guid> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

Device
```
Get-RMMPrinterAudit -Device <DRMMDevice> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMPrinterAudit function retrieves detailed printer information for a device,
including printer hardware details, supply levels (toner/ink), and configuration.

This audit data is collected by the Datto RMM agent from SNMP-enabled network printers
or locally connected printers.
It provides inventory and supply status information
useful for proactive printer management.

This function is called automatically by Get-RMMDeviceAudit when a piped DRMMDevice
object has a DeviceClass of 'printer'.
It can also be called directly with a Device
object or DeviceUid.

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMDevice -DeviceId 12345 | Get-RMMPrinterAudit
```

Retrieves printer audit data for device 12345.

EXAMPLE 2
```powershell
Get-RMMPrinterAudit -DeviceUid "12345678-1234-1234-1234-123456789012"
```

Retrieves printer audit data using a specific device UID.

EXAMPLE 3
```powershell
$Audit = Get-RMMDevice -Name "PRINTER01" | Get-RMMPrinterAudit
$Audit.Printers | Select-Object Name, Model, SupplyLevels
```

Retrieves printer audit data and displays printer names, models, and supply levels.

EXAMPLE 4
```powershell
Get-RMMDevice -FilterId 200 | Get-RMMPrinterAudit | 
    ForEach-Object {$_.Printers} | 
    Where-Object {$_.SupplyLevels.Black -lt 20}
```

Gets devices matching filter 200 and finds printers with low black toner (\<20%).

EXAMPLE 5
```powershell
$PrinterAudit = Get-RMMPrinterAudit -DeviceUid $DeviceUid
$PrinterAudit.SnmpInfo
```

Retrieves printer audit data and displays SNMP information.

## PARAMETERS

### -Device
A DRMMDevice object to retrieve printer audit data for.
Accepts pipeline input from
Get-RMMDevice.

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
The unique identifier (GUID) of the device to retrieve printer audit data for.

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

## INPUTS

DRMMDevice. You can pipe device objects from Get-RMMDevice.
## OUTPUTS

DRMMPrinterAudit. Returns printer audit objects with the following properties:
- DeviceUid: Device unique identifier
- Printers: Array of printer objects with details and supply levels
- SnmpInfo: SNMP configuration and status
- SystemInfo: Device system information
- MarkerSupplies: Detailed supply/consumable information
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

Printer audit data is only available for devices with printers detected by the agent.
SNMP must be enabled on network printers for complete data collection.

When piping a DRMMDevice object to Get-RMMDeviceAudit, devices with DeviceClass
'printer' are automatically routed to this function.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Get-RMMPrinterAudit.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Get-RMMPrinterAudit.md))
- [about_DRMMDevice](../../about/classes/DRMMDevice/about_DRMMDevice.md)
- [Get-RMMDevice](./Get-RMMDevice.md)
- [Get-RMMDeviceAudit](./Get-RMMDeviceAudit.md)
