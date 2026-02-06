# Save-RMMConfig

## SYNOPSIS
Saves the current in-memory DattoRMM.Core configuration to disk.

## SYNTAX

```
Save-RMMConfig [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Save-RMMConfig writes the current session's configuration (platform, page size, throttle profile, token expiry, etc.) to the persistent configuration file at $HOME/.DattoRMM.Core/config.json.

For removing the config file and resetting to defaults, use Reset-RMMConfig.

## EXAMPLES

EXAMPLE 1
```powershell
Save-RMMConfig
```

Saves the current session's configuration to the config file.

## PARAMETERS

## INPUTS

None. You cannot pipe objects to Save-RMMConfig.
## OUTPUTS

None. Writes to the config file.
## NOTES
Configuration is stored at: $HOME/.DattoRMM.Core/config.json
Use Reset-RMMConfig to delete the config file and reset persistent settings.
Current session values are not changed by Reset-RMMConfig.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Config/Save-RMMConfig.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Config/Save-RMMConfig.md))
- [Reset-RMMConfig](../Reset-RMMConfig.md)
- [Get-RMMConfig](./Get-RMMConfig.md)
