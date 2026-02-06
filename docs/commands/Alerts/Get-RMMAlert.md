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
Get-RMMAlert -AlertUid <Guid> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMAlert function retrieves alerts at different scopes: global (account-level),
site-level, or device-level.
Alerts can be filtered by status (Open, Resolved, or All) and can
be retrieved for specific objects by UID.

When specifying AlertUid, the function returns both open and resolved alerts for that UID,
regardless of status.
The Status parameter is ignored in this case.

The function supports pipeline input from Get-RMMSite and Get-RMMDevice, making it easy to
retrieve alerts for filtered sets of sites or devices.

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMAlert
```

Retrieves all open alerts at the account level.

EXAMPLE 2
```powershell
Get-RMMDevice -FilterId 12345 | Get-RMMAlert -Status Resolved
```

Gets all devices matching filter 12345 and retrieves their resolved alerts.

EXAMPLE 3
```powershell
Get-RMMSite -Name "Contoso" | Get-RMMAlert -Status All
```

Gets the site named "Contoso" and retrieves all alerts for that site (open and resolved).

EXAMPLE 4
```powershell
Get-RMMSite | Where-Object {$_.Name -like "Branch*"} | Get-RMMAlert
```

Gets all sites with names starting with "Branch" and retrieves all open alerts.

EXAMPLE 5
```powershell
Get-RMMDevice -Hostname "SERVER01" | Get-RMMAlert
```

Gets the device named "SERVER01" and retrieves all its open alerts.

EXAMPLE 6
```powershell
Get-RMMAlert -AlertUid "0e6cf376-e60a-4dc2-95b3-daa122e74de9"
```

Retrieves a specific alert by its unique identifier.
Returns the alert regardless of its state
(open or resolved).
Useful when the alert's status is unknown but the UID is available.

EXAMPLE 7
```powershell
$Site = Get-RMMSite -Name "Main Office"
Get-RMMAlert -SiteUid $Site.Uid
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

```yaml
Type: Guid
Parameter Sets: DeviceAll
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
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
Default is 'Open'.
Note: When AlertUid is specified, Status is not required.

```yaml
Type: String
Parameter Sets: GlobalAll, SiteAll, DeviceAll, SiteAllUid
Aliases:

Required: False
Position: Named
Default value: Open
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


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Alerts/Get-RMMAlert.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Alerts/Get-RMMAlert.md))
- [about_DRMMAlert](../../about/classes/DRMMAlert/about_DRMMAlert.md)
- [Connect-DattoRMM](../Auth/Connect-DattoRMM.md)
- [Get-RMMDevice](../Devices/Get-RMMDevice.md)
- [Get-RMMSite](../Sites/Get-RMMSite.md)
- [Resolve-RMMAlert](./Resolve-RMMAlert.md)
