# Get-RMMUser

## SYNOPSIS
Retrieves user accounts from the Datto RMM API.

## SYNTAX

```
Get-RMMUser [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMUser function retrieves all user accounts in the Datto RMM system.
This
includes user information such as email addresses, phone numbers, roles, and access levels.

PRIVACY NOTICE: This function retrieves personally identifiable information (PII)
including user email addresses and phone numbers.
By default, this function requires
confirmation before executing.
Use -Force to bypass the confirmation prompt.

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMUser
```

Retrieves all users after confirmation.

EXAMPLE 2
```powershell
Get-RMMUser -Force
```

Retrieves all users without confirmation prompt.

EXAMPLE 3
```powershell
Get-RMMUser -Force | Where-Object {$_.Role -eq 'Administrator'}
```

Retrieves all administrator users.

EXAMPLE 4
```powershell
Get-RMMUser -Force | Select-Object Name, Email, Role
```

Retrieves all users and displays selected properties.

EXAMPLE 5
```powershell
$Users = Get-RMMUser -Force
$Users | Group-Object Role | Select-Object Name, Count
```

Retrieves users and groups them by role to show user counts per role.

## PARAMETERS

### -Force
Bypasses the confirmation prompt.
Use this when automating scripts where interactive
confirmation is not possible.

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

None. You cannot pipe objects to Get-RMMUser.
## OUTPUTS

DRMMUser. Returns user objects with the following properties:
- Id: User numeric ID
- Uid: User unique identifier
- Name: User full name
- Email: User email address
- Phone: User phone number
- Role: User role/permission level
- Enabled: Whether the user account is active
- LastLogin: Last login timestamp
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

This function retrieves PII and requires high-impact confirmation by default.
Handle user data in compliance with your organisation's privacy policies.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMUser.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMUser.md))
