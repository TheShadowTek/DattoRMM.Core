# Get-RMMVariable

## SYNOPSIS
Retrieves variables from the Datto RMM API.

## SYNTAX

GlobalAll (Default)
```
Get-RMMVariable [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteByName
```
Get-RMMVariable -Site <DRMMSite> -Name <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteById
```
Get-RMMVariable -Site <DRMMSite> -Id <Int32> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteAll
```
Get-RMMVariable -Site <DRMMSite> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteUidByName
```
Get-RMMVariable -SiteUid <Guid> -Name <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteUidById
```
Get-RMMVariable -SiteUid <Guid> -Id <Int32> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteAllUid
```
Get-RMMVariable -SiteUid <Guid> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

GlobalById
```
Get-RMMVariable -Id <Int32> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

GlobalByName
```
Get-RMMVariable -Name <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMVariable function retrieves variables at different scopes: global
(account-level) or site-level.
Variables can be retrieved by ID, name, or all
variables at a given scope.

Variables in Datto RMM are used by components (scripts/monitors) to store and
retrieve configuration values and data.
They can be defined globally for the
entire account or at the site level.

## EXAMPLES

EXAMPLE 1
```
Get-RMMVariable
```

Retrieves all global (account-level) variables.

EXAMPLE 2
```
Get-RMMVariable -Id 12345
```

Retrieves a specific global variable by its ID.

EXAMPLE 3
```
Get-RMMVariable -Name "CompanyAPIKey"
```

Retrieves a global variable by exact name match.

EXAMPLE 4
```
Get-RMMSite -Name "Contoso" | Get-RMMVariable
```

Gets all variables for the "Contoso" site.

EXAMPLE 5
```
Get-RMMVariable -SiteUid $SiteUid -Name "ServerPassword"
```

Retrieves a specific site variable by name.

EXAMPLE 6
```
$Variables = Get-RMMSite | Get-RMMVariable
$Variables | Group-Object SiteUid | Select-Object Name, Count
```

Retrieves variables for all sites and groups by site.

EXAMPLE 7
```
Get-RMMVariable | Where-Object {$_.Name -like "*Password*"}
```

Retrieves all global variables with "Password" in the name.

EXAMPLE 8
```
$Var = Get-RMMVariable -Name "ConfigSetting"
$Var.Value
```

Retrieves a variable and displays its value.

## PARAMETERS

### -Site
A DRMMSite object to retrieve variables for.
Accepts pipeline input from Get-RMMSite.

```yaml
Type: DRMMSite
Parameter Sets: SiteByName, SiteById, SiteAll
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -SiteUid
The unique identifier (GUID) of a site to retrieve variables for.

```yaml
Type: Guid
Parameter Sets: SiteUidByName, SiteUidById, SiteAllUid
Aliases: Uid

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Id
Retrieve a specific variable by its numeric ID.

```yaml
Type: Int32
Parameter Sets: SiteById, SiteUidById, GlobalById
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Retrieve a variable by its name (exact match).

```yaml
Type: String
Parameter Sets: SiteByName, SiteUidByName, GlobalByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

DRMMSite. You can pipe site objects from Get-RMMSite.
System.Guid. You can pipe SiteUid values.
## OUTPUTS

DRMMVariable. Returns variable objects with the following properties:
- Id: Variable numeric ID
- Name: Variable name
- Value: Variable value
- Scope: 'Global' or 'Site'
- SiteUid: Site identifier (for site-scoped variables)
- Type: Variable data type
- Masked: Whether value is masked/hidden
- Description: Variable description
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

Variables can be referenced in components using the variable name.
Site-level variables override global variables with the same name.

## RELATED LINKS
