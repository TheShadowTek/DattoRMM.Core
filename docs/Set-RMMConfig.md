# Set-RMMConfig

## SYNOPSIS
Configures persistent settings for the Datto-RMM module.

## SYNTAX

```
Set-RMMConfig [[-DefaultPlatform] <RMMPlatform>] [[-DefaultPageSize] <Int32>] [[-LowUtilCheckInterval] <Int32>]
 [[-TokenExpireHours] <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Set-RMMConfig function allows you to configure persistent settings that will be 
preserved across PowerShell sessions.
These settings are stored in a configuration file
at $HOME/.datto-rmm/config.json.

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
Set-RMMConfig -LowUtilCheckInterval 100 -TokenExpireHours 50
```

Configures advanced throttling and token refresh settings.

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

### -LowUtilCheckInterval
Sets how often (in requests) to check the API rate limit when utilization is low (\<=50%).
Valid range: 10-100.
Default is 50.
Higher values reduce overhead but may be less responsive to rate limit changes.
Lower values check more frequently for better rate limit awareness.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 0
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
Configuration is stored at: $HOME/.datto-rmm/config.json
At least one parameter must be specified.
Settings take effect immediately and persist across sessions.

## RELATED LINKS

[Connect-DattoRMM
Set-RMMPageSize]()


