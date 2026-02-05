# Move-RMMDevice

## SYNOPSIS
Moves a device from one site to another site.

## SYNTAX

ByDeviceObjectSiteUid (Default)
```
Move-RMMDevice -Device <DRMMDevice> -TargetSiteUid <Guid> [-Force] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

ByDeviceObjectSiteObject
```
Move-RMMDevice -Device <DRMMDevice> -TargetSite <DRMMSite> [-Force] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

ByDeviceUidSiteObject
```
Move-RMMDevice -DeviceUid <Guid> -TargetSite <DRMMSite> [-Force] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

ByDeviceUidSiteUid
```
Move-RMMDevice -DeviceUid <Guid> -TargetSiteUid <Guid> [-Force] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Move-RMMDevice function moves a device from its current site to a different target site
within the same Datto RMM account.

This is a significant operation that will change the device's site association and may affect
monitoring, policies, and reporting.

## EXAMPLES

EXAMPLE 1
```
Get-RMMDevice -Id 12345 | Move-RMMDevice -TargetSiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
```

Moves a device to a different site via pipeline.

EXAMPLE 2
```
Move-RMMDevice -DeviceUid "11111111-2222-3333-4444-555555555555" -TargetSiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
```

Moves a device by specifying both device and target site UIDs.

EXAMPLE 3
```
Get-RMMDevice -Hostname "SERVER01" | Move-RMMDevice -TargetSite (Get-RMMSite -Name "New Office")
```

Moves a device to a new site using site objects.

EXAMPLE 4
```
Get-RMMSite -Name "Old Site" | Get-RMMDevice | Move-RMMDevice -TargetSiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -Force
```

Moves all devices from one site to another without confirmation prompts.

## PARAMETERS

### -Device
A DRMMDevice object to move.
Accepts pipeline input from Get-RMMDevice.

```yaml
Type: DRMMDevice
Parameter Sets: ByDeviceObjectSiteUid, ByDeviceObjectSiteObject
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -DeviceUid
The unique identifier (GUID) of the device to move.

```yaml
Type: Guid
Parameter Sets: ByDeviceUidSiteObject, ByDeviceUidSiteUid
Aliases: Uid

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -TargetSite
A DRMMSite object representing the destination site.
Accepts pipeline input from Get-RMMSite.

```yaml
Type: DRMMSite
Parameter Sets: ByDeviceObjectSiteObject, ByDeviceUidSiteObject
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetSiteUid
The unique identifier (GUID) of the destination site.

```yaml
Type: Guid
Parameter Sets: ByDeviceObjectSiteUid, ByDeviceUidSiteUid
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

Moving a device may affect:
- Site-specific policies and configurations
- Monitoring and alerting rules
- Reporting and grouping
- Site-level variables

The device must exist and the target site must exist in your account.

## RELATED LINKS


- [about_DRMMDevice](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/about_DRMMDevice.md)
- [Get-RMMDevice](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//commands/Get-RMMDevice.md)
- [Get-RMMSite](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//commands/Get-RMMSite.md)
