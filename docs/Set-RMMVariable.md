# Set-RMMVariable

## SYNOPSIS
Updates an existing variable in the Datto RMM account or site.

## SYNTAX

ByVariableObject (Default)
```
Set-RMMVariable -Variable <DRMMVariable> [-Name <String>] [-Value <String>] [-Force]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

ByVariableId
```
Set-RMMVariable -VariableId <Int64> [-SiteUid <Guid>] -Name <String> -Value <String> [-Force]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Set-RMMVariable function updates the name and/or value of an existing variable at
either the account (global) level or at a specific site level.

NOTE: The Masked property can only be set during variable creation and cannot be
changed after the variable has been created.
Use New-RMMVariable with -Masked to
create a masked variable.

## EXAMPLES

EXAMPLE 1
```
Get-RMMVariable -Name "CompanyName" | Set-RMMVariable -Value "Contoso Corporation"
```

Updates the value of an account-level variable via pipeline.

EXAMPLE 2
```
Set-RMMVariable -VariableId 12345 -Name "CompanyName" -Value "New Company Ltd"
```

Updates both name and value of an account-level variable by ID.

EXAMPLE 3
```
Get-RMMSite -Name "Main Office" | Get-RMMVariable -Name "SiteCode" | Set-RMMVariable -Value "MO002"
```

Updates a site-level variable via pipeline.

EXAMPLE 4
```
Set-RMMVariable -SiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -VariableId 67890 -Value "\\newserver\backup"
```

Updates a site-level variable by specifying site UID and variable ID.

## PARAMETERS

### -Variable
A DRMMVariable object to update.
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
The unique identifier of the variable to update.

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
updating site-level variables by VariableId.

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

### -Name
The new name for the variable.
If not specified when piping a variable object,
the existing name is preserved.

```yaml
Type: String
Parameter Sets: ByVariableObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: ByVariableId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value
The new value for the variable.

```yaml
Type: String
Parameter Sets: ByVariableObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: ByVariableId
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

DRMMVariable. You can pipe variable objects from Get-RMMVariable.
You can also pipe objects with VariableId and SiteUid properties.
## OUTPUTS

DRMMVariable. Returns the updated variable object.
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

The Masked property cannot be changed after a variable is created.
If you need
to change a variable to be masked (or unmasked), you must delete and recreate it.

## RELATED LINKS
