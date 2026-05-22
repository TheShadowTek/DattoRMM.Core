# Get-RMMActivityLog

## SYNOPSIS
Retrieves activity logs from the Datto RMM API.

## SYNTAX

Global (Default)
```
Get-RMMActivityLog [-Start <DateTime>] [-End <DateTime>] [-Entity <String[]>] [-Category <String[]>]
 [-Action <String[]>] [-UserId <Int64[]>] [-Order <String>] [-SearchQuery <String>]
 [-UseExperimentalDetailClasses] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

Site
```
Get-RMMActivityLog -Site <DRMMSite> [-Start <DateTime>] [-End <DateTime>] [-Entity <String[]>]
 [-Category <String[]>] [-Action <String[]>] [-UserId <Int64[]>] [-Order <String>] [-SearchQuery <String>]
 [-UseExperimentalDetailClasses] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

SiteId
```
Get-RMMActivityLog -SiteId <Int64> [-Start <DateTime>] [-End <DateTime>] [-Entity <String[]>]
 [-Category <String[]>] [-Action <String[]>] [-UserId <Int64[]>] [-Order <String>] [-SearchQuery <String>]
 [-UseExperimentalDetailClasses] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves activity logs for one or more sites, with optional filtering by date range, entity type,
categories, actions, and users.
Supports global (all sites) or site-specific queries.
Site IDs are
batched for large environments to avoid API limits.

You can specify sites by:
- Piping DRMMSite objects (from Get-RMMSite)
- Passing SiteId(s) directly
- Omitting both for global (all sites) scope

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMActivityLog -Start "2024-01-01T00:00:00Z" -End "2024-01-02T00:00:00Z"
```

Retrieves activity logs for all sites for January 1st, 2024.

EXAMPLE 2
```powershell
$Start = Get-Date '2024-01-01T00:00:00Z'
$End = Get-Date '2024-01-02T00:00:00Z'
Get-RMMSite -SiteName "Main Office" | Get-RMMActivityLog -Start $Start -End $End
```

Retrieves activity logs for the "Main Office" site.

EXAMPLE 3
```powershell
Get-RMMActivityLog -SiteId 1234,5678 -Start (Get-Date '2024-01-01') -End (Get-Date '2024-01-02')
```

Retrieves activity logs for sites with IDs 1234 and 5678.

EXAMPLE 4
```powershell
Get-RMMSite | Get-RMMActivityLog
```

Retrieves activity logs for last 24 hours for all sites.

EXAMPLE 5
```powershell
Get-RMMActivityLog -Start (Get-Date).AddDays(-7) -End (Get-Date) -SearchQuery 'data.filter_id : "filterId" AND device.hostname : "hostname"'
```

Retrieves activity logs for the past 7 days matching a specific filter ID and hostname using
a Lucene-style search expression.

## PARAMETERS

### -Site
A DRMMSite object to retrieve activity logs for.
Accepts pipeline input from Get-RMMSite.

```yaml
Type: DRMMSite
Parameter Sets: Site
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -SiteId
The numeric ID of a site to retrieve activity logs for.

```yaml
Type: Int64
Parameter Sets: SiteId
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Start
Start date/time for fetching data.
Accepts local or UTC; local times are automatically converted
to UTC for the API.
Format: yyyy-MM-ddTHH:mm:ssZ.
Required.
Defaults to 24 hours ago.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-Date).AddHours(-24)
Accept pipeline input: False
Accept wildcard characters: False
```

### -End
End date/time for fetching data.
Accepts local or UTC; local times are automatically converted
to UTC for the API.
Format: yyyy-MM-ddTHH:mm:ssZ.
Required.
Defaults to the current time.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-Date)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Entity
Filters activity logs by entity type.
Valid values: 'Device', 'User'.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Category
Filters activity logs by category (e.g., 'job', 'device').

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Action
Filters activity logs by action (e.g., 'deployment', 'note').

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserId
Filters activity logs by user ID (integer).

```yaml
Type: Int64[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Order
Specifies the order in which records are returned by creation date.
Valid values: 'asc', 'desc'.
Default is 'desc'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Desc
Accept pipeline input: False
Accept wildcard characters: False
```

### -SearchQuery
Filters activity logs using an advanced Lucene-style search expression, identical to the
Activity Log UI search bar.
Accepts field searches, wildcards, boolean operators, fuzzy
matching, and grouped expressions.
Passed through verbatim - no client-side parsing or
validation is applied.

See https://rmm.datto.com/help/en/Content/3NEWUI/Analytics/ActivityLog.htm for supported fields and syntax.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseExperimentalDetailClasses
Enables experimental entity/category-specific detail classes for activity logs.
When specified,
details are parsed into strongly-typed classes based on entity, category, and action combinations
(e.g., DRMMActivityLogDetailsDeviceJob for DEVICE/job activities).
When not specified (default),
all details use the generic DRMMActivityLogDetailsGeneric class with dynamic properties.

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

## INPUTS

DRMMSite. You can pipe site objects from Get-RMMSite (uses the Id property).
## OUTPUTS

DRMMActivityLog. Returns activity log objects with details about the activity.
## NOTES
- Requires an active connection to the Datto RMM API (use Connect-DattoRMM first).
- The API uses integer IDs (not UIDs) for sites and users in this endpoint.
- Results are paginated automatically.
- UserId accepts up to 750 values. This safely stays within URL length limits
  (750 × 7 chars ≈ 5,250 chars, well within the 6KB safe threshold).

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/ActivityLog/Get-RMMActivityLog.md)
- [Connect-DattoRMM](../Auth/Connect-DattoRMM.md)
- [Get-RMMSite](../Sites/Get-RMMSite.md)
- [about_DRMMActivityLog](../../about/classes/DRMMActivityLog/about_DRMMActivityLog.md)
