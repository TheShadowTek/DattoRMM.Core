# Get-RMMConfig

## SYNOPSIS
Retrieves the current Datto-RMM module configuration.

## SYNTAX

```
Get-RMMConfig [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMConfig function displays the current configuration settings for the Datto-RMM module,
including both values loaded from the configuration file and their current in-memory values.

This helps verify what defaults are configured and active in the current session.

## EXAMPLES

EXAMPLE 1
```
Get-RMMConfig
```

Displays all current configuration settings.

EXAMPLE 2
```
$Config = Get-RMMConfig
$Config.DefaultPlatform
```

Retrieves the configuration and accesses a specific property.

## PARAMETERS

## INPUTS

None. You cannot pipe objects to Get-RMMConfig.
## OUTPUTS

PSCustomObject. Returns an object with configuration properties and their values.
## NOTES
Configuration is stored at: $HOME/.datto-rmm/config.json

The output shows:
- Configured values from the config file
- Current session values (may differ if changed via Set-RMMConfig during session)
- Default fallback values when no configuration exists

## RELATED LINKS


[Reset-RMMConfig](https://github.com/boabf/Datto-RMM/blob/main/docs/Reset-RMMConfig.md)
[Set-RMMPageSize](https://github.com/boabf/Datto-RMM/blob/main/docs/Set-RMMPageSize.md)

