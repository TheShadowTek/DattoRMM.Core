# Remove-RMMConfig

## SYNOPSIS
Deletes the persistent DattoRMM.Core configuration file (factory reset for future sessions).

## SYNTAX

```
Remove-RMMConfig [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Remove-RMMConfig deletes the configuration file at $HOME/.DattoRMM.Core/config.json, removing all saved settings.
This does not affect the current session or in-memory configuration.
To apply defaults in the current session, use Set-RMMConfig -Default or reload the module.

## EXAMPLES

EXAMPLE 1
```
Remove-RMMConfig
```

Prompts for confirmation before deleting the configuration file.

EXAMPLE 2
```
Remove-RMMConfig -Force
```

Deletes the configuration file without prompting for confirmation.

## PARAMETERS

### -Force
Bypasses the confirmation prompt and immediately deletes the configuration file.

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

None. You cannot pipe objects to Remove-RMMConfig.
## OUTPUTS

None. Displays a message indicating success or failure.
## NOTES
Configuration file location: $HOME/.DattoRMM.Core/config.json
This function only deletes the configuration file.
Current session values remain unchanged until the module is reloaded.

## RELATED LINKS

[Save-RMMConfig
Get-RMMConfig]()

