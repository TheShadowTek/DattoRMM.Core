# Set-RMMConfig

## SYNOPSIS
Configures persistent settings for the DattoRMM.Core module.

## SYNTAX

```
Set-RMMConfig [[-DefaultPlatform] <RMMPlatform>] [[-DefaultPageSize] <Int32>]
 [[-ThrottleAggressiveness] <String>] [[-TokenExpireHours] <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The Set-RMMConfig function allows you to configure persistent settings that will be 
preserved across PowerShell sessions.
These settings are stored in a configuration file
at $HOME/.DattoRMM.Core/config.json.

## EXAMPLES

EXAMPLE 1
```
Set-RMMConfig -DefaultPlatform Merlot
```

Sets the default platform to Merlot.
Future calls to Connect-DattoRMM will use this platform
unless explicitly overridden.

EXAMPLE 2
```
Set-RMMConfig -DefaultPlatform Pinotage -DefaultPageSize 100
```

Sets both the default platform and page size.

EXAMPLE 3
```
Set-RMMConfig -ThrottleAggressiveness Cautious -TokenExpireHours 50
```

Configures advanced throttling and token refresh settings for maximum safety.

## PARAMETERS

### -DefaultPlatform
Sets the default Datto RMM platform region for connections.
Valid values: Pinotage, Concord, Vidal, Merlot, Zinfandel, Syrah

```yaml
Type: RMMPlatform
Parameter Sets: (All)
Aliases:
Accepted values: Pinotage, Concord, Vidal, Merlot, Zinfandel, Syrah

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultPageSize
Sets the default page size for API requests.
This will be used when connecting to the API,
but will be capped at the account's maximum page size limit.
Valid range: 1-250.
The actual limit depends on your Datto RMM account settings.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ThrottleAggressiveness
Controls how aggressively the module throttles API requests when nearing rate limits.
Cautious: Maximum delay, checks rate limit frequently (safest, slowest).
Medium: Balanced delay and check frequency.
Aggressive: Minimal delay, checks rate limit less often (fastest, riskier).
Valid values: Cautious, Medium, Aggressive.
Default is Medium.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TokenExpireHours
Sets the token refresh interval in hours.
Valid range: 1-100.
Default is 100.
Lower values refresh tokens more frequently, reducing risk of expiration but increasing API overhead.
Higher values reduce API calls but may risk token expiration in long-running sessions.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

None. You cannot pipe objects to Set-RMMConfig.
## OUTPUTS

None. This function updates the persistent configuration file.
## NOTES
Configuration is stored at: $HOME/.DattoRMM.Core/config.json
At least one parameter must be specified.
Settings take effect immediately and persist across sessions.

## RELATED LINKS


- [Set-RMMPageSize](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/Set-RMMPageSize.md)
- [Get-RMMPageSize](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/Get-RMMPageSize.md)
- [Get-RMMConfig](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/Get-RMMConfig.md)
- [Reset-RMMConfig](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/Reset-RMMConfig.md)
- [Set-RMMPageSize](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/Set-RMMPageSize.md)

