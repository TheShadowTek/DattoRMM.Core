# Remove-RMMVariable

## SYNOPSIS
Deletes a variable from the Datto RMM account or site.

## SYNTAX

ByVariableObject (Default)
```
Remove-RMMVariable -Variable <DRMMVariable> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

ByVariableId
```
Remove-RMMVariable -VariableId <Int64> [-SiteUid <Guid>] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Remove-RMMVariable function permanently deletes a variable from either the
account (global) level or from a specific site.

This is a destructive operation that cannot be undone.
Use the -Confirm parameter
to prompt for confirmation before deleting each variable.

## EXAMPLES

EXAMPLE 1
```
Get-RMMVariable -Name "OldVariable" | Remove-RMMVariable
```

Deletes an account-level variable via pipeline.

EXAMPLE 2
```
Remove-RMMVariable -VariableId 12345 -Confirm:$false
```

Deletes an account-level variable by ID without prompting for confirmation.

EXAMPLE 3
```
Get-RMMSite -Name "Closed Office" | Get-RMMVariable | Remove-RMMVariable -Confirm
```

Deletes all variables from a site with confirmation prompts.

EXAMPLE 4
```
Remove-RMMVariable -SiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -VariableId 67890
```

Deletes a site-level variable by specifying site UID and variable ID.

## PARAMETERS

### -Variable
A DRMMVariable object to delete.
Accepts pipeline input from Get-RMMVariable.

```yaml
Type: DRMMVariable
Parameter Sets: ByVariableObject
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -VariableId
The unique identifier of the variable to delete.

```yaml
Type: Int64
Parameter Sets: ByVariableId
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SiteUid
The unique identifier (GUID) of the site containing the variable.
Required when
deleting site-level variables by VariableId.

```yaml
Type: Guid
Parameter Sets: ByVariableId
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
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

DRMMVariable. You can pipe variable objects from Get-RMMVariable.
You can also pipe objects with VariableId and SiteUid properties.
## OUTPUTS

None. This function does not return any output.
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

This operation is permanent and cannot be undone.
Variables are immediately
deleted from the Datto RMM system.

## RELATED LINKS

