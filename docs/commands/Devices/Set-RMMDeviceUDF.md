# Set-RMMDeviceUDF

## SYNOPSIS
Sets user-defined fields on a device in Datto RMM.

## SYNTAX

ByDeviceUidIndividual (Default)
```
Set-RMMDeviceUDF -DeviceUid <Guid> [-UDF1 <String>] [-UDF2 <String>] [-UDF3 <String>] [-UDF4 <String>]
 [-UDF5 <String>] [-UDF6 <String>] [-UDF7 <String>] [-UDF8 <String>] [-UDF9 <String>] [-UDF10 <String>]
 [-UDF11 <String>] [-UDF12 <String>] [-UDF13 <String>] [-UDF14 <String>] [-UDF15 <String>] [-UDF16 <String>]
 [-UDF17 <String>] [-UDF18 <String>] [-UDF19 <String>] [-UDF20 <String>] [-UDF21 <String>] [-UDF22 <String>]
 [-UDF23 <String>] [-UDF24 <String>] [-UDF25 <String>] [-UDF26 <String>] [-UDF27 <String>] [-UDF28 <String>]
 [-UDF29 <String>] [-UDF30 <String>] [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

ByDeviceObjectHashtable
```
Set-RMMDeviceUDF -Device <DRMMDevice> -UDFFields <Hashtable> [-Force] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

ByDeviceObjectIndividual
```
Set-RMMDeviceUDF -Device <DRMMDevice> [-UDF1 <String>] [-UDF2 <String>] [-UDF3 <String>] [-UDF4 <String>]
 [-UDF5 <String>] [-UDF6 <String>] [-UDF7 <String>] [-UDF8 <String>] [-UDF9 <String>] [-UDF10 <String>]
 [-UDF11 <String>] [-UDF12 <String>] [-UDF13 <String>] [-UDF14 <String>] [-UDF15 <String>] [-UDF16 <String>]
 [-UDF17 <String>] [-UDF18 <String>] [-UDF19 <String>] [-UDF20 <String>] [-UDF21 <String>] [-UDF22 <String>]
 [-UDF23 <String>] [-UDF24 <String>] [-UDF25 <String>] [-UDF26 <String>] [-UDF27 <String>] [-UDF28 <String>]
 [-UDF29 <String>] [-UDF30 <String>] [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

ByDeviceUidHashtable
```
Set-RMMDeviceUDF -DeviceUid <Guid> -UDFFields <Hashtable> [-Force] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Set-RMMDeviceUDF function updates one or more user-defined fields (UDF1-UDF30) on a
device in the Datto RMM system.
UDFs are custom fields that can store additional metadata
about devices for organisational and reporting purposes.

Important behaviors:
- Fields included in the request with empty values will be cleared (set to null)
- Fields not included in the request will retain their current values
- You only need to specify the fields you want to update

## EXAMPLES

EXAMPLE 1
```
Set-RMMDeviceUDF -DeviceUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -UDF1 "Department: IT" -UDF2 "Owner: John"
```

Sets UDF1 and UDF2 on a device, leaving other UDFs unchanged.

EXAMPLE 2
```
Get-RMMDevice -Hostname "SERVER01" | Set-RMMDeviceUDF -UDF5 "Production" -UDF10 "Critical"
```

Updates UDF5 and UDF10 via pipeline.

EXAMPLE 3
```
Set-RMMDeviceUDF -DeviceUid $DeviceUid -UDF1 "" -Force
```

Clears UDF1 (sets to null) without confirmation.

EXAMPLE 4
```
Get-RMMDevice -FilterId 100 | Set-RMMDeviceUDF -UDF3 "Datacenter: East"
```

Updates UDF3 for all devices in filter 100.

EXAMPLE 5
```
Set-RMMDeviceUDF -DeviceUid $DeviceUid -UDFFields @{udf1='IT Department'; udf2='John Smith'; udf5=''}
```

Updates multiple UDF fields using a hashtable.
UDF5 is cleared.

EXAMPLE 6
```
$UDFs = @{udf10='Production'; udf15='Critical'; udf20='Datacenter: West'}
Get-RMMDevice -Hostname "SERVER*" | Set-RMMDeviceUDF -UDFFields $UDFs -Force
```

Updates multiple UDF fields on all servers matching the hostname pattern without confirmation.

## PARAMETERS

### -Device
A DRMMDevice object to update.
Accepts pipeline input from Get-RMMDevice.

```yaml
Type: DRMMDevice
Parameter Sets: ByDeviceObjectHashtable, ByDeviceObjectIndividual
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
Parameter Sets: ByDeviceUidIndividual, ByDeviceUidHashtable
Aliases: Uid

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -UDFFields
A hashtable of UDF fields to update.
Keys should be in the format 'udf1', 'udf2', etc.
Example: @{udf1='Value1'; udf5='Value5'; udf10=''}
Cannot be used with individual UDF parameters.

```yaml
Type: Hashtable
Parameter Sets: ByDeviceObjectHashtable, ByDeviceUidHashtable
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF1
{{ Fill UDF1 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF2
{{ Fill UDF2 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF3
{{ Fill UDF3 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF4
{{ Fill UDF4 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF5
{{ Fill UDF5 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF6
{{ Fill UDF6 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF7
{{ Fill UDF7 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF8
{{ Fill UDF8 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF9
{{ Fill UDF9 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF10
{{ Fill UDF10 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF11
{{ Fill UDF11 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF12
{{ Fill UDF12 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF13
{{ Fill UDF13 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF14
{{ Fill UDF14 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF15
{{ Fill UDF15 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF16
{{ Fill UDF16 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF17
{{ Fill UDF17 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF18
{{ Fill UDF18 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF19
{{ Fill UDF19 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF20
{{ Fill UDF20 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF21
{{ Fill UDF21 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF22
{{ Fill UDF22 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF23
{{ Fill UDF23 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF24
{{ Fill UDF24 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF25
{{ Fill UDF25 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF26
{{ Fill UDF26 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF27
{{ Fill UDF27 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF28
{{ Fill UDF28 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF29
{{ Fill UDF29 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UDF30
{{ Fill UDF30 Description }}

```yaml
Type: String
Parameter Sets: ByDeviceUidIndividual, ByDeviceObjectIndividual
Aliases:

Required: False
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


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Set-RMMDeviceUDF.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Set-RMMDeviceUDF.md))
- [about_DRMMDevice](../../about/classes/DRMMDevice/about_DRMMDevice.md)
- [Get-RMMDevice](./Get-RMMDevice.md)
