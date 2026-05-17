# Set-RMMDeviceUdf

## SYNOPSIS
Sets user-defined fields on a device in Datto RMM.

## SYNTAX

ByDeviceUidHashtable (Default)
```
Set-RMMDeviceUdf -DeviceUid <Guid> -UdfFields <Hashtable> [-Force] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

ByDeviceObjectSingle
```
Set-RMMDeviceUdf -Device <DRMMDevice> -UdfNumber <Int32> -UdfValue <String> [-Force]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

ByDeviceObjectHashtable
```
Set-RMMDeviceUdf -Device <DRMMDevice> -UdfFields <Hashtable> [-Force] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

ByDeviceUidSingle
```
Set-RMMDeviceUdf -DeviceUid <Guid> -UdfNumber <Int32> -UdfValue <String> [-Force]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Set-RMMDeviceUdf function updates one or more user-defined fields (Udf1-Udf300) on a
device in the Datto RMM system.
UDFs are custom fields that can store additional metadata
about devices for organisational and reporting purposes.

The function supports two modes of operation:
- Hashtable mode: Use -UdfFields to update multiple UDFs at once with a hashtable of
  key-value pairs (e.g., @{udf1='Value1'; udf50='Value50'}).
- Single mode: Use -UdfNumber and -UdfValue to update a single UDF by number.

Important behaviours:
- Fields included in the request with empty values will be cleared (set to null)
- Fields not included in the request will retain their current values
- You only need to specify the fields you want to update
- UDF values are limited to 255 characters

## EXAMPLES

EXAMPLE 1
```powershell
Set-RMMDeviceUdf -DeviceUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -UdfNumber 1 -UdfValue "Department: IT"
```

Sets Udf1 on a device, leaving other UDFs unchanged.

EXAMPLE 2
```powershell
Set-RMMDeviceUdf -DeviceUid $DeviceUid -UdfFields @{udf1='IT Department'; udf2='John Smith'; udf5=''}
```

Updates multiple UDF fields using a hashtable.
Udf5 is cleared.

EXAMPLE 3
```powershell
Set-RMMDeviceUdf -DeviceUid $DeviceUid -UdfNumber 1 -UdfValue '' -Force
```

Clears Udf1 (sets to null) without confirmation.

EXAMPLE 4
```powershell
Get-RMMDevice -FilterId 100 | Set-RMMDeviceUdf -UdfNumber 3 -UdfValue "Datacenter: East"
```

Updates Udf3 for all devices in filter 100.

EXAMPLE 5
```powershell
$UDFs = @{udf10='Production'; udf15='Critical'; udf200='Datacenter: West'}
Get-RMMDevice -Hostname "SERVER*" | Set-RMMDeviceUdf -UdfFields $UDFs -Force
```

Updates multiple UDF fields on all servers matching the hostname pattern without confirmation.

EXAMPLE 6
```powershell
Set-RMMDeviceUdf -DeviceUid $DeviceUid -UdfFields @{udf150='Custom Data'; udf275='Extended'}
```

Sets high-numbered UDFs (available since Datto RMM 14.9.0).

## PARAMETERS

### -Device
A DRMMDevice object to update.
Accepts pipeline input from Get-RMMDevice.

```yaml
Type: DRMMDevice
Parameter Sets: ByDeviceObjectSingle, ByDeviceObjectHashtable
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -DeviceUid
The unique identifier (GUID) of the device to update.

```yaml
Type: Guid
Parameter Sets: ByDeviceUidHashtable, ByDeviceUidSingle
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UdfFields
A hashtable of UDF fields to update.
Keys should be in the format 'udf1', 'udf2', etc.
Values are limited to 255 characters each.
Example: @{udf1='Value1'; udf5='Value5'; udf10=''}
Cannot be used with -UdfNumber/-UdfValue parameters.

```yaml
Type: Hashtable
Parameter Sets: ByDeviceUidHashtable, ByDeviceObjectHashtable
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UdfNumber
The UDF number (1-300) to update.
Must be used with -UdfValue.
Cannot be used with -UdfFields parameter.

```yaml
Type: Int32
Parameter Sets: ByDeviceObjectSingle, ByDeviceUidSingle
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -UdfValue
The value to set for the specified UDF.
Limited to 255 characters.
Set to empty string to clear the field.
Must be used with -UdfNumber.
Cannot be used with -UdfFields parameter.

```yaml
Type: String
Parameter Sets: ByDeviceObjectSingle, ByDeviceUidSingle
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Bypasses the confirmation prompt.

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

DRMMDevice. You can pipe device objects from Get-RMMDevice.
You can also pipe objects with DeviceUid or Uid properties.
## OUTPUTS

None. This function does not return any output.
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

Best practices for UDF usage:
- Establish consistent naming conventions across your organisation
- Document which UDFs are used for what purpose
- Use UDFs for data that doesn't fit standard device properties
- Consider using UDFs for: location, department, owner, cost center, project codes, etc.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Set-RMMDeviceUdf.md)
- [Connect-DattoRMM](../Auth/Connect-DattoRMM.md)
- [about_DRMMDevice](../../about/classes/DRMMDevice/about_DRMMDevice.md)
- [Get-RMMDevice](./Get-RMMDevice.md)
- [about_DRMMDeviceUdfs](../../about/classes/DRMMDevice/about_DRMMDeviceUdfs.md)
