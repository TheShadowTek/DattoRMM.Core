# Get-RMMAlert

## SYNOPSIS
Retrieves alerts from the Datto RMM API.

## SYNTAX

GlobalAll (Default)
```
Get-RMMAlert [-Status <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteAll
```
Get-RMMAlert -Site <DRMMSite> [-Status <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

DeviceAll
```
Get-RMMAlert -DeviceUid <Guid> [-Status <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteAllUid
```
Get-RMMAlert -SiteUid <Guid> [-Status <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

GlobalByUid
```
Get-RMMAlert -AlertUid <Guid> [-Status <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMAlert function retrieves alerts at different scopes: global (account-level),
site-level, or device-level.
Alerts can be filtered by status (Open, Resolved, or All)
and can be retrieved for specific objects by UID.

The function supports pipeline input from Get-RMMSite and Get-RMMDevice, making it easy
to retrieve alerts for filtered sets of sites or devices.

## EXAMPLES

EXAMPLE 1
```
Get-RMMAlert
```

Retrieves all alerts (both open and resolved) at the account level.

EXAMPLE 2
```
Get-RMMAlert -Status Open
```

Retrieves only open alerts at the account level.

EXAMPLE 3
```
Get-RMMDevice -FilterId 12345 | Get-RMMAlert -Status Open
```

Gets all devices matching filter 12345 and retrieves their open alerts.

EXAMPLE 4
```
Get-RMMDevice -Name 'Servers' | Get-RMMDevice | Get-RMMAlert -Status Open
```

Gets all devices matching filter 'Servers' and retrieves their open alerts.

EXAMPLE 5
```
Get-RMMSite -Name "Contoso" | Get-RMMAlert -Status Resolved
```

Gets the site named "Contoso" and retrieves all resolved alerts for that site.

EXAMPLE 6
```
Get-RMMSite | Where-Object {$_.Name -like "Branch*"} | Get-RMMAlert
```

Gets all sites with names starting with "Branch" and retrieves all alerts (open and resolved).

EXAMPLE 7
```
Get-RMMDevice -Hostname "SERVER01" | Get-RMMAlert -Status All
```

Gets the device named "SERVER01" and retrieves all its alerts.

EXAMPLE 8
```
Get-RMMAlert -AlertUid "0e6cf376-e60a-4dc2-95b3-daa122e74de9"
```

Retrieves a specific alert by its unique identifier.

EXAMPLE 9
```
$Site = Get-RMMSite -Name "Main Office"
Get-RMMAlert -SiteUid $Site.Uid -Status Open
```

Retrieves open alerts for a specific site using its UID.

## PARAMETERS

### -Site
A DRMMSite object to retrieve alerts for.
Accepts pipeline input from Get-RMMSite.

```yaml
Type: DRMMSite
Parameter Sets: SiteAll
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -DeviceUid
The unique identifier (GUID) of a device to retrieve alerts for.
Accepts pipeline input
from Get-RMMDevice.

```yaml
Type: Guid
Parameter Sets: DeviceAll
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SiteUid
The unique identifier (GUID) of a site to retrieve alerts for.

```yaml
Type: Guid
Parameter Sets: SiteAllUid
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AlertUid
The unique identifier of a specific alert to retrieve.

```yaml
Type: Guid
Parameter Sets: GlobalByUid
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Status
Filter alerts by status.
Valid values: 'All', 'Open', 'Resolved'.
Default is 'All'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: All
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

DRMMSite. You can pipe site objects from Get-RMMSite.
You can also pipe objects with DeviceUid or SiteUid properties.
## OUTPUTS

DRMMAlert. Returns alert objects with details about the alert status, priority, source, and more.
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

When piping devices or sites, the Status parameter applies to all objects in the pipeline.

The function retrieves alerts in batches and automatically handles pagination.

## RELATED LINKS


- [about_DRMMAlert](https://github.com/boabf/Datto-RMM/blob/main/docs/about_DRMMAlert.md)
- [Connect-DattoRMM](https://github.com/boabf/Datto-RMM/blob/main/docs/Connect-DattoRMM.md)
- [Get-RMMDevice](https://github.com/boabf/Datto-RMM/blob/main/docs/Get-RMMDevice.md)
- [Get-RMMSite](https://github.com/boabf/Datto-RMM/blob/main/docs/Get-RMMSite.md)
- [Resolve-RMMAlert](https://github.com/boabf/Datto-RMM/blob/main/docs/Resolve-RMMAlert.md)

