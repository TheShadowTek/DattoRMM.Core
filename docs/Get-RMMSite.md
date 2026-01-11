# Get-RMMSite

## SYNOPSIS
Retrieves sites from the Datto RMM API.

## SYNTAX

All (Default)
```
Get-RMMSite [-All <Boolean>] [-ExtendedProperties <RMMSiteExtendedProperty[]>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

Single
```
Get-RMMSite -SiteUid <Guid> [-ExtendedProperties <RMMSiteExtendedProperty[]>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

Search
```
Get-RMMSite [-SiteName <String>] [-ExtendedProperties <RMMSiteExtendedProperty[]>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMSite function retrieves site information from Datto RMM.
Sites represent
customer organizations or locations within your RMM account.

The function supports multiple query modes:
- Get all sites
- Get a specific site by UID
- Search for sites by name
- Include extended properties (settings, variables, filters)

Extended properties allow you to retrieve related data for sites in a single command.

## EXAMPLES

EXAMPLE 1
```
Get-RMMSite
```

Retrieves all sites in the account.

EXAMPLE 2
```
Get-RMMSite -SiteUid "12067610-8504-48e3-b5de-60e48416aaad"
```

Retrieves a specific site by its unique identifier.

EXAMPLE 3
```
Get-RMMSite -SiteName "Contoso"
```

Searches for sites containing "Contoso" in the name (partial match).

EXAMPLE 4
```
Get-RMMSite -SiteName "Production" | Get-RMMDevice
```

Searches for sites with "Production" in the name and retrieves all devices from those sites.

EXAMPLE 5
```
Get-RMMSite -ExtendedProperties Settings, Variables
```

Retrieves all sites and includes their settings and variables.

EXAMPLE 6
```
$Site = Get-RMMSite -SiteUid $SiteUid -ExtendedProperties Settings
$Site.SiteSettings.GeneralSettings
```

Retrieves a site with its settings and accesses the general settings.

EXAMPLE 7
```
Get-RMMSite | Sort-Object Name | Select-Object Name, Uid
```

Retrieves all sites, sorts by name, and displays name and UID.

EXAMPLE 8
```
$Sites = Get-RMMSite -ExtendedProperties Filters
$Sites | ForEach-Object {
    [PSCustomObject]@{
        SiteName = $_.Name
        FilterCount = $_.Filters.Count
    }
}
```

Retrieves sites with filters and displays the filter count for each.

## PARAMETERS

### -SiteUid
The unique identifier (GUID) of a specific site to retrieve.

```yaml
Type: Guid
Parameter Sets: Single
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
Retrieve all sites in the account.
This is the default behavior.
Set to $false to
disable when using other parameters.

```yaml
Type: Boolean
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -SiteName
Search for sites by name using partial matching (LIKE operator).
Returns all sites
where the name contains the specified value.

```yaml
Type: String
Parameter Sets: Search
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExtendedProperties
Additional properties to retrieve for each site.
Valid values:
- Settings: Include site settings
- Variables: Include site variables
- Filters: Include device filters

Use this to populate the SiteSettings, Variables, and Filters properties of the
returned site objects.

```yaml
Type: RMMSiteExtendedProperty[]
Parameter Sets: (All)
Aliases:
Accepted values: Settings, Variables, Filters

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

None. You cannot pipe objects to Get-RMMSite.
## OUTPUTS

DRMMSite. Returns site objects with the following properties:
- Uid: Site unique identifier
- Id: Site numeric ID
- Name: Site name
- Description: Site description
- OnDemand: Whether site is on-demand
- SplashtopAutoInstall: Splashtop auto-install setting
- ProxySettings: Proxy configuration
- DevicesStatus: Device statistics for the site
- SiteSettings: Site settings (if ExtendedProperties includes Settings)
- Variables: Site variables (if ExtendedProperties includes Variables)
- Filters: Device filters (if ExtendedProperties includes Filters)
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

Using ExtendedProperties can significantly increase response time and API calls.
Only request extended properties when needed.

## RELATED LINKS

[about_DRMMSite]()

[Get-RMMDevice]()

[Get-RMMDeviceFilter]()


