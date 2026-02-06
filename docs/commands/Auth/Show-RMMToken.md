# Show-RMMToken

## SYNOPSIS
Displays the current Datto RMM API token and authentication details.

## SYNTAX

```
Show-RMMToken [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Shows the contents of $Script:RMMAuth, including the access token, expiry, and other details.
WARNING: The access token is sensitive.
Do not share or publish this information.

## EXAMPLES

EXAMPLE 1
```powershell
Show-RMMToken
Displays the current API token and related details.
```

## PARAMETERS

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

## OUTPUTS

## NOTES
This command requires confirmation and has ConfirmImpact set to Low.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Show-RMMToken.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Show-RMMToken.md))
