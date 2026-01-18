# Get-RMMActivityLog

## SYNOPSIS
Retrieves activity logs from the Datto RMM API.

## SYNTAX

Global (Default)
```
Get-RMMActivityLog -Start <DateTime> -End <DateTime> [-Entity <String[]>] [-Category <String[]>]
 [-Action <String[]>] [-UserId <Int64[]>] [-Order <String>] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

Site
```
Get-RMMActivityLog [-Site <DRMMSite[]>] -Start <DateTime> -End <DateTime> [-Entity <String[]>]
 [-Category <String[]>] [-Action <String[]>] [-UserId <Int64[]>] [-Order <String>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

SiteId
```
Get-RMMActivityLog [-SiteId <Int64[]>] -Start <DateTime> -End <DateTime> [-Entity <String[]>]
 [-Category <String[]>] [-Action <String[]>] [-UserId <Int64[]>] [-Order <String>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
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

The function prompts for confirmation before retrieving logs for each site, including in global
mode.
Supports Yes/No/Yes to All/No to All responses for safe handling of PII.

## EXAMPLES

EXAMPLE 1
```
Get-RMMActivityLog -Start "2024-01-01T00:00:00Z" -End "2024-01-02T00:00:00Z"
```

Retrieves activity logs for all sites for January 1st, 2024.
Prompts for each site.

EXAMPLE 2
```
$Start = Get-Date '2024-01-01T00:00:00Z'
$End = Get-Date '2024-01-02T00:00:00Z'
Get-RMMSite -SiteName "Main Office" | Get-RMMActivityLog -Start $Start -End $End
```

Retrieves activity logs for the "Main Office" site.
Prompts for confirmation.

EXAMPLE 3
```
Get-RMMActivityLog -SiteId 1234,5678 -Start (Get-Date '2024-01-01') -End (Get-Date '2024-01-02')
```

Retrieves activity logs for sites with IDs 1234 and 5678.
Prompts for each site.

EXAMPLE 4
```
$Start = Get-Date '2024-01-01'
$End = Get-Date '2024-01-02'
Get-RMMActivityLog -SiteId 1234,5678 -Start $Start -End $End -Confirm:$false
```

Retrieves activity logs for sites with IDs 1234 and 5678 without confirmation prompts (for automation).

## PARAMETERS

### -Site
One or more DRMMSite objects (from Get-RMMSite) to retrieve activity logs for.
Accepts pipeline
input.

```yaml
Type: DRMMSite[]
Parameter Sets: Site
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -SiteId
One or more site IDs (integer) to retrieve activity logs for.

```yaml
Type: Int64[]
Parameter Sets: SiteId
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Start
Start date/time for fetching data.
Accepts local or UTC; local times are automatically converted
to UTC for the API.
Format: yyyy-MM-ddTHH:mm:ssZ.
Required.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -End
End date/time for fetching data.
Accepts local or UTC; local times are automatically converted
to UTC for the API.
Format: yyyy-MM-ddTHH:mm:ssZ.
Required.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

DRMMSite. You can pipe site objects from Get-RMMSite (uses the Id property).
## OUTPUTS

DRMMActivityLog. Returns activity log objects with details about the activity.
## NOTES
- Requires an active connection to the Datto RMM API (use Connect-DattoRMM first).
- Site IDs are batched in groups of 100 to avoid API/query length limits.
- Confirmation prompt appears for each site (Yes/No/Yes to All/No to All supported).
- The API uses integer IDs (not UIDs) for sites and users in this endpoint.
- Results are paginated automatically.

## RELATED LINKS


- [about_DRMMActivityLog](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about_DRMMActivityLog.md)

