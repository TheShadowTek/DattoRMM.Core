# Resolve-RMMAlert

## SYNOPSIS
Resolves a Datto RMM alert.

## SYNTAX

Alert (Default)
```
Resolve-RMMAlert -Alert <DRMMAlert> [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

AlertUid
```
Resolve-RMMAlert -AlertUid <Guid> [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The Resolve-RMMAlert function marks an alert as resolved in Datto RMM.
Accepts either full \`DRMMAlert\` objects via pipeline or specific alert UIDs (GUIDs).

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMAlert | Where-Object { $_.Priority -eq 'Low' } | Resolve-RMMAlert
```

Resolves all low priority alerts with confirmation prompts (medium impact).

EXAMPLE 2
```powershell
Get-RMMAlert  | Where-Object { $_.Priority -eq 'High' }  | Resolve-RMMAlert -Force
```

Resolves all high priority alerts without confirmation prompts.

EXAMPLE 3
```powershell
Resolve-RMMAlert -AlertUid '12345678-1234-1234-1234-123456789012'
```

Resolves the alert with the specified UID.

## PARAMETERS

### -Alert
A DRMMAlert object to resolve.
Accepts pipeline input.
Obtained from Get-RMMAlert or passed directly from alert queries.

```yaml
Type: DRMMAlert
Parameter Sets: Alert
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -AlertUid
The unique identifier (GUID) of the alert to resolve.
Use this parameter when not piping a DRMMAlert object.
Can be obtained from Get-RMMAlert or the AlertUid property of an alert object.

```yaml
Type: Guid
Parameter Sets: AlertUid
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Bypasses the confirmation prompt and immediately resolves the alert.

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

DRMMAlert. You can pipe alert objects from Get-RMMAlert to this function.
## OUTPUTS

None. This function does not return any output on success.
## NOTES
Requires an active connection to the Datto RMM API (Connect-DattoRMM).

The function will throw an error if:
- Not connected to the API
- Alert UID is invalid
- User doesn't have permission to resolve the alert
- Alert doesn't exist

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Alerts/Resolve-RMMAlert.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Alerts/Resolve-RMMAlert.md))
- [Get-RMMAlert](./Get-RMMAlert.md)
- [about_DRMMAlert](../../about/classes/DRMMAlert/about_DRMMAlert.md)
