# Get-RMMDeviceFilter

## SYNOPSIS
Retrieves device filters from the Datto RMM API.

## SYNTAX

GlobalAll (Default)
```
Get-RMMDeviceFilter [-FilterType <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteByName
```
Get-RMMDeviceFilter -Site <DRMMSite> -Name <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteById
```
Get-RMMDeviceFilter -Site <DRMMSite> -Id <Int32> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteAll
```
Get-RMMDeviceFilter -Site <DRMMSite> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteUidByName
```
Get-RMMDeviceFilter -SiteUid <Guid> -Name <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteUidById
```
Get-RMMDeviceFilter -SiteUid <Guid> -Id <Int32> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteAllUid
```
Get-RMMDeviceFilter -SiteUid <Guid> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

GlobalById
```
Get-RMMDeviceFilter -Id <Int32> [-FilterType <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

GlobalByName
```
Get-RMMDeviceFilter -Name <String> [-FilterType <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMDeviceFilter function retrieves device filters at different scopes: global
(account-level) or site-level.
Filters can be retrieved by ID, name, or all filters
at a given scope.

Device filters in Datto RMM are used to group devices based on criteria and can be
applied when retrieving devices with Get-RMMDevice.

Filters are categorized as either "Default" (built-in system filters) or "Custom"
(user-created filters).

## EXAMPLES

EXAMPLE 1
```
Get-RMMDeviceFilter
```

Retrieves all device filters at the account level.

EXAMPLE 2
```
Get-RMMDeviceFilter -FilterType Custom
```

Retrieves only custom (user-created) device filters.

EXAMPLE 3
```
Get-RMMDeviceFilter -Id 12345
```

Retrieves a specific filter by its ID.

EXAMPLE 4
```
Get-RMMDeviceFilter -Name "Windows Servers"
```

Retrieves a filter by exact name match.

EXAMPLE 5
```
Get-RMMSite -Name "Main Office" | Get-RMMDeviceFilter
```

Gets all device filters for the "Main Office" site.

EXAMPLE 6
```
$Filter = Get-RMMDeviceFilter -Name "Production Servers"
Get-RMMDevice -FilterId $Filter.Id
```

Retrieves a filter and uses it to get matching devices.

EXAMPLE 7
```
Get-RMMSite | Get-RMMDeviceFilter | Where-Object {$_.Type -eq 'custom'}
```

Gets custom filters for all sites.

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

### -SiteUid
The unique identifier (GUID) of a site to retrieve filters for.

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
Retrieve a specific filter by its numeric ID.

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
Retrieve a filter by its name (exact match).

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
You can also pipe objects with SiteUid properties.
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

Filter IDs can be used with Get-RMMDevice -FilterId to retrieve devices matching
specific criteria.

## RELATED LINKS


- [about_DRMMFilter](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about_DRMMFilter.md)
- [Get-RMMDevice](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/Get-RMMDevice.md)
- [Get-RMMSite](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/Get-RMMSite.md)

