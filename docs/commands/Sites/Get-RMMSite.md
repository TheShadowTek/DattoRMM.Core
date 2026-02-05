# Get-RMMSite

## SYNOPSIS
Retrieves sites from the Datto RMM API.

## SYNTAX

All (Default)
```
Get-RMMSite [-ExtendedProperties <RMMSiteExtendedProperty[]>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
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

DeletedDevices
```
Get-RMMSite [-DeletedDevices] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMSite function retrieves site information from Datto RMM.
Sites represent
customer organisations or locations within your RMM account.

By default, this function excludes the "Deleted Devices" system site which has an 
invalid GUID.
Use the -DeletedDevices parameter to retrieve only that specific site.

The function supports multiple query modes:
- Get all sites (excludes Deleted Devices)
- Get a specific site by UID
- Search for sites by name
- Get only the Deleted Devices system site
- Include extended properties (settings, variables, filters)

Extended properties allow you to retrieve related data for sites in a single command.

## EXAMPLES

EXAMPLE 1
```
Get-RMMSite
```

Retrieves all sites in the account (excludes the Deleted Devices system site).

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
Get-RMMSite -DeletedDevices
```

Retrieves only the \"Deleted Devices\" system site (if it exists).
Returns a
DRMMDeletedDevicesSite object with string Uid property.
Note that methods like
GetDevices() will fail due to the invalid GUID.

EXAMPLE 8
```
Get-RMMSite | Sort-Object Name | Select-Object Name, Uid
```

Retrieves all sites, sorts by name, and displays name and UID.

EXAMPLE 9
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
Parameter Sets: All, Single, Search
Aliases:
Accepted values: Settings, Variables, Filters

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeletedDevices
Retrieve only the special "Deleted Devices" system site.
This is a system Datto RMM
site that has an invalid GUID.
This switch uses a dedicated parameter set and cannot
be combined with other filtering parameters.

Returns a DRMMDeletedDevicesSite object with a string Uid property instead of guid.

WARNING: Methods inherited from DRMMSite (such as GetDevices(), GetAlerts(), etc.)
will throw errors when called on this object due to the malformed GUID.
This site is
included only for completeness and should not be used in normal operations.

```yaml
Type: SwitchParameter
Parameter Sets: DeletedDevices
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

None. You cannot pipe objects to Get-RMMSite.
## OUTPUTS

DRMMSite. Returns site objects with the following properties:
- Uid: Site unique identifier (guid)
- Id: Site numeric ID
- Name: Site name
- Description: Site description
- OnDemand: Whether site is on-demand
- SplashtopAutoInstall: Splashtop auto-install setting
- ProxySettings: Proxy configuration
- DevicesStatus: Device statistics for the site
- SiteSettings: Site settings (if ExtendedProperties includes Settings)
- Variables: Site variables (if ExtendedProperties includes Variables)
DRMMDeletedDevicesSite. When using -DeletedDevices, returns a derived site object:
- Uid: Site unique identifier (string, invalid GUID format)
- All other properties same as DRMMSite
- WARNING: Inherited methods will fail due to invalid GUID
- Filters: Device filters (if ExtendedProperties includes Filters)
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

Using ExtendedProperties can significantly increase response time and API calls.
Only request extended properties when needed.

## RELATED LINKS


- [about_DRMMSite](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/about_DRMMSite.md)
- [Get-RMMDevice](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//commands/Get-RMMDevice.md)
- [Get-RMMFilter](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//commands/Get-RMMFilter.md)
