# Resolve-RMMAlert

## SYNOPSIS
Resolves a Datto RMM alert.

## SYNTAX

```
Resolve-RMMAlert [-AlertUid] <Guid> [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The Resolve-RMMAlert function marks an alert as resolved in Datto RMM.
The alert is identified by its unique alert UID (GUID).

## EXAMPLES

EXAMPLE 1
```
Resolve-RMMAlert -AlertUid '12345678-1234-1234-1234-123456789012'
```

Resolves the alert with the specified UID.

EXAMPLE 2
```
Get-RMMAlert -Scope Global | Where-Object Priority -eq 'Critical' | Resolve-RMMAlert
```

Resolves all critical global alerts with confirmation prompts.

EXAMPLE 3
```
Get-RMMAlert -Scope Global | Where-Object Priority -eq 'Critical' | Resolve-RMMAlert -Force
```

Resolves all critical global alerts without confirmation prompts.

EXAMPLE 4
```
$Alert.Resolve()
```

If $Alert is a DRMMAlert object, you can use its Resolve() method directly.

## PARAMETERS

### -AlertUid
The unique identifier (GUID) of the alert to resolve.
This can be obtained from Get-RMMAlert or from the AlertUid property of an alert object.

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

System.Guid. You can pipe alert UIDs or alert objects (AlertUid property is extracted automatically) to this function.
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


- [about_DRMMAlert](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about_DRMMAlert.md)
- [Get-RMMAlert](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/Get-RMMAlert.md)

