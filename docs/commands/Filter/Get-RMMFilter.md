# Get-RMMFilter

## SYNOPSIS
Retrieves filters from the Datto RMM API.

## SYNTAX

GlobalAll (Default)
```
Get-RMMFilter [-FilterType <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteByName
```
Get-RMMFilter -Site <DRMMSite> -Name <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteById
```
Get-RMMFilter -Site <DRMMSite> -Id <Int32> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteAll
```
Get-RMMFilter -Site <DRMMSite> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

GlobalById
```
Get-RMMFilter -Id <Int32> [-FilterType <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

GlobalByName
```
Get-RMMFilter -Name <String> [-FilterType <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMFilter function retrieves filters at different scopes: global (account-level) or site-level.
Filters can be retrieved by ID, name, or all filters at a given scope.

Filters in Datto RMM are used to group devices based on criteria and can be applied when retrieving devices with Get-RMMDevice.

Filters are categorized as either "Default" (built-in system filters) or "Custom" (user-created filters).

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMFilter
```

Retrieves all filters at the account level.

EXAMPLE 2
```powershell
Get-RMMFilter -FilterType Custom
```

Retrieves only custom (user-created) filters.

EXAMPLE 3
```powershell
Get-RMMFilter -Id 12345
```

Retrieves a specific filter by its ID.

EXAMPLE 4
```powershell
Get-RMMFilter -Name "Windows Servers"
```

Retrieves a filter by exact name match.

EXAMPLE 5
```powershell
Get-RMMSite -Name "Main Office" | Get-RMMFilter
```

Gets all filters for the "Main Office" site.

EXAMPLE 6
```powershell
Get-RMMFilter -Name "Production Servers" | Get-RMMDevice
```

Retrieves a filter by name and pipes it to Get-RMMDevice to retrieve matching devices.
Site-scoped filters automatically route to the correct site endpoint.

EXAMPLE 7
```powershell
Get-RMMFilter -Id 12345 | Get-RMMDevice
```

Retrieves a filter by ID and pipes it to Get-RMMDevice.

## PARAMETERS

### -Site
A DRMMSite object to retrieve filters for.
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

### -Id
Retrieve a specific filter by its numeric ID.

```yaml
Type: Int32
Parameter Sets: SiteById, GlobalById
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Retrieve a filter by its name (exact match).

```yaml
Type: String
Parameter Sets: SiteByName, GlobalByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilterType
Filter the results by type.
Valid values: 'All', 'Default', 'Custom'.
Default is 'All'.
Only applicable for global scope queries.

```yaml
Type: String
Parameter Sets: GlobalAll, GlobalById, GlobalByName
Aliases:

Required: False
Position: Named
Default value: All
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

DRMMSite. You can pipe site objects from Get-RMMSite.
## OUTPUTS

DRMMFilter. Returns filter objects with the following properties:
- Id: Numeric identifier
- Name: Filter name
- Description: Filter description
- Type: 'rmm_default' or 'custom'
- Scope: 'Global' or 'Site'
- SiteUid: Site identifier (for site-scoped filters)
- DateCreate: Creation date
- LastUpdated: Last modification date
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

Filter objects can be piped directly to Get-RMMDevice to retrieve matching devices.
Site-scoped filters automatically route to the correct site endpoint.
Alternatively, use Get-RMMDevice -FilterId to retrieve devices by numeric filter ID.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Filter/Get-RMMFilter.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Filter/Get-RMMFilter.md))
- [about_DRMMFilter](../../about/classes/DRMMFilter/about_DRMMFilter.md)
- [Get-RMMDevice](../Devices/Get-RMMDevice.md)
- [Get-RMMSite](../Sites/Get-RMMSite.md)
