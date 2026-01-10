# Reset-RMMAPIKeys

## SYNOPSIS
Resets the authenticated user's API access and secret keys in Datto RMM.

## SYNTAX

```
Reset-RMMAPIKeys [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Reset-RMMAPIKeys function regenerates the API access key and secret key for the
currently authenticated user.
This invalidates the existing keys immediately.

WARNING: This operation will immediately invalidate the current API connection.
After
running this function, you will need to:
1.
Log in to the Datto RMM web portal
2.
Navigate to your user settings to retrieve the new API keys
3.
Update your stored credentials with the new keys
4.
Reconnect using Connect-DattoRMM with the new keys

This function is useful for security purposes when:
- API keys may have been compromised
- Regular key rotation as part of security policy
- Revoking access from stolen or exposed credentials

## EXAMPLES

EXAMPLE 1
```
Reset-RMMAPIKeys
```

Resets the API keys with confirmation prompt.
Retrieve new keys from the Datto RMM web portal.

EXAMPLE 2
```
Reset-RMMAPIKeys -Force
```

Resets the API keys without confirmation.
New keys must be retrieved from the web portal.

## PARAMETERS

### -Force
Bypasses the confirmation prompt.
Use with extreme caution as this will invalidate
the current session immediately.

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

None. This function does not accept pipeline input.
## OUTPUTS

None. New keys must be retrieved from the Datto RMM web portal.
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

CRITICAL WARNINGS:
- This function invalidates your current API session immediately
- New keys are NOT returned by the API - you must retrieve them from the web portal
- Access the Datto RMM web portal to view your new API keys after reset
- If you cannot access the web portal, contact Datto support

Best practices:
- Only reset keys when necessary (compromise, rotation policy)
- Have web portal access available before resetting
- Document key resets in your change management system
- Notify team members if shared keys are being rotated
- Update all automation scripts with new keys after reset

## RELATED LINKS
