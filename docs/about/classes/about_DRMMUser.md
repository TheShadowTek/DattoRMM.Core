# about_DRMMUser

## SHORT DESCRIPTION

Describes the DRMMUser class and its methods for working with users in Datto RMM.

## LONG DESCRIPTION

The DRMMUser class represents a user account within Datto RMM. User objects contain information about account holders, including contact details, status, and access times.

DRMMUser objects are returned by [Get-RMMUser](Get-RMMUser.md) and provide methods for inspecting user details and generating summaries.

## PROPERTIES

The DRMMUser class exposes the following properties:

| Property   | Type               | Description                                 |
|------------|--------------------|---------------------------------------------|
| FirstName  | string             | User's first name                           |
| LastName   | string             | User's last name                            |
| Username   | string             | Account username                            |
| Email      | string             | Email address                               |
| Telephone  | string             | Telephone number                            |
| Status     | string             | Account status                              |
| Created    | Nullable[datetime] | Account creation date                       |
| LastAccess | Nullable[datetime] | Last access date                            |
| Disabled   | bool               | True if the account is disabled             |

## METHODS

### Name and Summary

#### GetFullName()
Returns the user's full name (first and last name).

**Returns:** `[string]`

#### GetSummary()
Returns a string summary of the user, including full name, username, and disabled status.

**Returns:** `[string]`

```powershell
$user = Get-RMMUser -Username "jsmith"
Write-Host $user.GetSummary()
```
