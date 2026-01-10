# Reset-RMMConfig

## SYNOPSIS
Resets Datto-RMM module configuration to defaults.

## SYNTAX

```
Reset-RMMConfig [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Reset-RMMConfig function clears the persistent configuration file, resetting all
settings to their default values.
This affects future PowerShell sessions but does not
modify the current session's runtime values.

To reset configuration in the current session, reload the module after running this function.

## EXAMPLES

EXAMPLE 1
```
Reset-RMMConfig
```

Prompts for confirmation before resetting the configuration.

EXAMPLE 2
```
Reset-RMMConfig -Force
```

Resets the configuration without prompting for confirmation.

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

None. You cannot pipe objects to Reset-RMMConfig.
## OUTPUTS

None. Displays a message indicating success or failure.
## NOTES
Configuration file location: $HOME/.datto-rmm/config.json

This function only deletes the configuration file.
Current session values remain unchanged
until the module is reloaded.

Default values after reset:
- DefaultPlatform: Pinotage
- DefaultPageSize: Account Maximum
- LowUtilCheckInterval: 50
- TokenExpireHours: 100

## RELATED LINKS

[Set-RMMConfig
Get-RMMConfig]()

