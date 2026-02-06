# Reset-RMMAPIKeys

## SYNOPSIS
Resets the authenticated user's API access and secret keys in Datto RMM.

## SYNTAX

```
Reset-RMMAPIKeys [-ReturnNewKey] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Reset-RMMAPIKeys function regenerates the API access key and secret key for the
currently authenticated user.
This invalidates the existing keys immediately.

When using -ReturnNewKey, the API secret key (as shown in the Datto RMM UI) will NOT be returned in plain text, but as a SecureString for security.
To convert the SecureString to plain text (not recommended unless absolutely necessary), use:
    Windows:
    \[Runtime.InteropServices.Marshal\]::PtrToStringBSTR(\[Runtime.InteropServices.Marshal\]::SecureStringToBSTR($newKeys.ApiSecret))

    Linux/macOS:
    (New-Object System.Management.Automation.PSCredential('user', $newKeys.ApiSecret)).GetNetworkCredential().Password

Only do this in a secure environment, and immediately clear any script or session logs that may contain the secret.
Avoid exposing the secret in plain text whenever possible.

WARNING: If you do not use -ReturnNewKey, this operation will immediately invalidate the current API connection.
After running you will need to:
    1.
Log in to the Datto RMM web portal
    2.
Navigate to your user settings
    3.
Generate or view your new API keys
    4.
Update your stored credentials with the new keys
    5.
Reconnect using Connect-DattoRMM with the new keys

    WARNING: This operation will immediately invalidate the current API connection.
    If you use -ReturnNewKey and capture the output, you will receive the new API key and secret (the secret as a SecureString).
    If you do not use -ReturnNewKey, the new keys will be discarded and you must retrieve new API keys from the Datto RMM web portal.
To do this:

This function is useful for security purposes when:
- API keys may have been compromised
- Regular key rotation as part of security policy
- Revoking access from stolen or exposed credentials

## EXAMPLES

EXAMPLE 1
```
$newKeys = Reset-RMMAPIKeys -ReturnNewKey
```

Resets the API keys and returns the new key/secret object.
Capture the output to retrieve the new secret.

EXAMPLE 2
```
Reset-RMMAPIKeys
```

Resets the API keys with confirmation prompt.
If -ReturnNewKey is not specified, the new keys are discarded.
New keys must be retrieved from the Datto RMM web portal.

## PARAMETERS

### -ReturnNewKey
If specified, returns the new API key and secret as a DRMMAPIKeySecret object (with the secret as a SecureString).
You should capture the output in a variable to retrieve the new secret.
If not specified, the new keys will be discarded.

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

DRMMAPIKeySecret (if -ReturnNewKey is specified), otherwise None.
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

CRITICAL WARNINGS:
- This function invalidates your current API session immediately
- If you do not capture the new keys (with -ReturnNewKey), you must generate new keys via the Datto RMM web portal
- If you lose the new secret, you will need to reset the keys again or generate new ones in the web portal
- If you cannot access the web portal, contact Datto support

Best practices:
- Only reset keys when necessary (compromise, rotation policy)
- Have web portal access available before resetting
- Document key resets in your change management system
- Notify team members if shared keys are being rotated
- Update all automation scripts with new keys after reset

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Reset-RMMAPIKeys.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Reset-RMMAPIKeys.md))
