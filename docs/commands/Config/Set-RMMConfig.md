# Set-RMMConfig

## SYNOPSIS
Configures the current DattoRMM.Core session and optionally saves settings persistently.

## SYNTAX

Set
```
Set-RMMConfig [-Platform <RMMPlatform>] [-PageSize <Int32>] [-ThrottleProfile <RMMThrottleProfile>]
 [-TokenExpireHours <Int32>] [-APIMaxRetries <Int32>] [-APIRetryIntervalSeconds <Int32>]
 [-APITimeoutSeconds <Int32>] [-Persist] [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

Default
```
Set-RMMConfig [-Persist] [-Default] [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Set-RMMConfig allows you to configure the current session's settings for the DattoRMM.Core module.
You can update platform, page size, throttling, and token expiration for the current session.
Use -Persist to save these settings to the configuration file for future sessions.
Use -Default to reset all settings to module defaults (both in session and config).

The TokenExpireHours setting controls how often the module will proactively refresh the API token before expiry.
Changing this value does not invalidate the current token; it only updates the local refresh interval.
Lower values mean the token is refreshed more frequently, reducing risk of accidental expiration during long sessions.
Higher values mean the same token is reused longer, which may or may not offer a security benefit (less frequent token changes, but not invalidated on update).
Note: The token is only refreshed locally; the previous token remains valid until it naturally expires or is revoked by the API provider.

## EXAMPLES

EXAMPLE 1
```
Set-RMMConfig -Platform Merlot
```

Sets the default platform to Merlot for the current session only.

EXAMPLE 2
```
Set-RMMConfig -Platform Pinotage -PageSize 100 -Persist
```

Sets both the default platform and page size, and saves them for future sessions.

EXAMPLE 3
```
Set-RMMConfig -ThrottleProfile Cautious -TokenExpireHours 50
```

Configures advanced throttling and token refresh settings for the current session only.

EXAMPLE 4
```
Set-RMMConfig -Default
```

Resets all configuration to module defaults, both in session and in the config file.

## PARAMETERS

### -Platform
Sets the default Datto RMM platform region for connections in the current session.
Valid values: Pinotage, Concord, Vidal, Merlot, Zinfandel, Syrah.
Use -Persist to save as the default for future sessions.

```yaml
Type: RMMPlatform
Parameter Sets: Set
Aliases:
Accepted values: Pinotage, Concord, Vidal, Merlot, Zinfandel, Syrah

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
Sets the default page size for API requests in the current session.
Valid range: 1-250 (actual max depends on your Datto RMM account).
Use -Persist to save as the default for future sessions.

```yaml
Type: Int32
Parameter Sets: Set
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ThrottleProfile
Sets the throttling profile for API requests in the current session.
Valid values: Cautious, Medium, Aggressive.
Default is Medium.
Use -Persist to save as the default for future sessions.

```yaml
Type: RMMThrottleProfile
Parameter Sets: Set
Aliases:
Accepted values: Medium, Aggressive, Cautious, DefaultProfile

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TokenExpireHours
Sets the token refresh interval (in hours) for the current session.
Valid range: 1-100.
Default is 100.
Use -Persist to save as the default for future sessions.

```yaml
Type: Int32
Parameter Sets: Set
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -APIMaxRetries
Sets the maximum number of retry attempts for failed API requests.
Valid range: 1-10.
Default is 5.
Use -Persist to save as the default for future sessions.

```yaml
Type: Int32
Parameter Sets: Set
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -APIRetryIntervalSeconds
Sets the wait time in seconds between retry attempts.
Valid range: 1-300.
Default is 10.
Use -Persist to save as the default for future sessions.

```yaml
Type: Int32
Parameter Sets: Set
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -APITimeoutSeconds
Sets the timeout in seconds for API requests.
Valid range: 10-300.
Default is 60.
Use -Persist to save as the default for future sessions.

```yaml
Type: Int32
Parameter Sets: Set
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Persist
If specified, saves the provided settings to the configuration file for future sessions.
Without -Persist, changes apply only to the current session.

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

### -Default
Resets all settings to module defaults in the current session.
If used with -Persist, also deletes the persistent configuration file (full factory reset).
Without -Persist, only the current session is affected and the saved config remains unchanged.

```yaml
Type: SwitchParameter
Parameter Sets: Default
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Skips confirmation prompts for impactful actions (such as resetting or saving configuration).
Use with -Default or -Persist to bypass -Confirm and proceed immediately.

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

None. You cannot pipe objects to Set-RMMConfig.
## OUTPUTS

None. This function updates the session and/or persistent configuration file.
## NOTES
Configuration is stored at: $HOME/.DattoRMM.Core/config.json At least one parameter must be specified unless using -Default.
Settings take effect immediately in the session.
Use -Persist to save for future sessions.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Config/Set-RMMConfig.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Config/Set-RMMConfig.md))
- [Save-RMMConfig](./Save-RMMConfig.md)
- [Get-RMMConfig](./Get-RMMConfig.md)
- [Reset-RMMConfig](../Reset-RMMConfig.md)
- [Set-RMMPageSize](../Set-RMMPageSize.md)
