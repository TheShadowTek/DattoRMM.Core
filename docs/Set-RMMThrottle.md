# Set-RMMThrottle

## SYNOPSIS
Sets throttling behavior for the current DattoRMM.Core session.

## SYNTAX

```
Set-RMMThrottle [-ThrottleAggressiveness] <String> [-Persist] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Set-RMMThrottle allows you to adjust the throttling aggressiveness for the active session.
Optionally, use -Persist to save the setting for future sessions (calls Set-RMMConfig).

## EXAMPLES

EXAMPLE 1
```
Set-RMMThrottle -ThrottleAggressiveness Aggressive
```

Sets throttling to aggressive for the current session only.

EXAMPLE 2
```
Set-RMMThrottle -ThrottleAggressiveness Cautious -Persist
```

Sets throttling to cautious for the current session and persists it for future sessions.

## PARAMETERS

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

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Persist
If specified, also saves the setting to the persistent configuration (calls Set-RMMConfig).

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

## INPUTS

None. You cannot pipe objects to Set-RMMThrottle.
## OUTPUTS

None. This function updates session variables and optionally persistent config.
## NOTES
Use Set-RMMConfig to configure other persistent settings.

## RELATED LINKS

