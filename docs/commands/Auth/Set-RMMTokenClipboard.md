# Set-RMMTokenClipboard

## SYNOPSIS
Copies the current Datto RMM API access token to the clipboard.

## SYNTAX

```
Set-RMMTokenClipboard [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Copies the current session access token to the system clipboard.
No token value is written to the console, terminal output, or transcript.

WARNING: The access token is sensitive.
Clipboard managers, cloud clipboard
synchronisation (Windows 11 Cloud Clipboard), and other applications running in
the same user session may access clipboard content.
Clear the clipboard after use.

If Windows Cloud Clipboard synchronisation is enabled, the token may be transmitted
to Microsoft servers.
Disable Cloud Clipboard before using this command in
sensitive environments.

## EXAMPLES

EXAMPLE 1
```powershell
Set-RMMTokenClipboard
Copies the current API access token to the clipboard after confirmation.
```

EXAMPLE 2
```powershell
Set-RMMTokenClipboard -Force
Copies the token to the clipboard without prompting for confirmation.
```

## PARAMETERS

### -Force
{{ Fill Force Description }}

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

## OUTPUTS

## NOTES
This command requires confirmation and has ConfirmImpact set to High.
Use -Force to suppress the confirmation prompt in automation scripts.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Set-RMMTokenClipboard.md)
- [Connect-DattoRMM](./Connect-DattoRMM.md)
- [Disconnect-DattoRMM](./Disconnect-DattoRMM.md)
- [about_DattoRMM.CoreAuthentication](../../about/about_DattoRMM.CoreAuthentication.md)
