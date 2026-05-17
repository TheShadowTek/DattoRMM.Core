# Get-RMMUser

## SYNOPSIS
Retrieves user accounts from the Datto RMM API.

## SYNTAX

```
Get-RMMUser [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMUser function retrieves all user accounts in the Datto RMM system.
This
includes user information such as email addresses, phone numbers, roles, and access levels.

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMUser
```

Retrieves all users after confirmation.

EXAMPLE 2
```powershell
Get-RMMUser | Where-Object {$_.Role -eq 'Administrator'}
```

Retrieves all administrator users.

EXAMPLE 3
```powershell
Get-RMMUser | Select-Object Name, Email, Role
```

Retrieves all users and displays selected properties.

EXAMPLE 4
```powershell
$Users = Get-RMMUser
$Users | Group-Object Role | Select-Object Name, Count | Format-Table -AutoSize
```

Retrieves users and groups them by role to show user counts per role.

## PARAMETERS

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

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMUser.md)
- [Connect-DattoRMM](../Auth/Connect-DattoRMM.md)
