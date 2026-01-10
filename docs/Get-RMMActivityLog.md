# Get-RMMActivityLog

## SYNOPSIS
Retrieves activity logs from the Datto RMM API.

## SYNTAX

```
Get-RMMActivityLog [[-SiteId] <Int64[]>] [[-From] <DateTime>] [[-Until] <DateTime>] [[-Entity] <String[]>]
 [[-Category] <String[]>] [[-Action] <String[]>] [[-UserId] <Int64[]>] [[-Order] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMActivityLog function retrieves activity logs with optional filtering by date range,
entity type (device or user), categories, actions, sites, and users.
By default, the API returns
logs from the last 15 minutes if no date range is specified.

Activity logs track various activities in the RMM platform including device changes, user actions,
job executions, and more.

## EXAMPLES

EXAMPLE 1
```
Get-RMMActivityLog
```

Retrieves activity logs from the last 15 minutes (default behavior).

EXAMPLE 2
```
Get-RMMActivityLog -From "2024-01-01T00:00:00Z" -Until "2024-01-02T00:00:00Z"
```

Retrieves activity logs for January 1st, 2024.

EXAMPLE 3
```
Get-RMMActivityLog -Entity Device -Category job
```

Retrieves device-related activity logs in the 'job' category.

EXAMPLE 4
```
Get-RMMActivityLog -From "2024-01-01T00:00:00Z" -Category job,device -Action deployment
```

Retrieves activity logs for specific categories and action from a start date.

EXAMPLE 5
```
Get-RMMSite -SiteName "Main Office" | Get-RMMActivityLog -From "2024-01-01T00:00:00Z"
```

Retrieves activity logs for a specific site from January 1st, 2024.

## PARAMETERS

### -SiteId
Filters activity logs by site ID (integer).
Can specify multiple values as an array.

```yaml
Type: Int64[]
Parameter Sets: (All)
Aliases: Id

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -From
Defines the UTC start date for fetching data.
Format: yyyy-MM-ddTHH:mm:ssZ
By default, the API returns logs from the last 15 minutes.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Until
Defines the UTC end date for fetching data.
Format: yyyy-MM-ddTHH:mm:ssZ

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Entity
Filters activity logs by entity type.
Valid values: 'Device', 'User'.
Can specify multiple values as an array.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Category
Filters activity logs by category (e.g., 'job', 'device').
Can specify multiple values as an array.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Action
Filters activity logs by action (e.g., 'deployment', 'note').
Can specify multiple values as an array.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserId
Filters activity logs by user ID (integer).
Can specify multiple values as an array.

```yaml
Type: Int64[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Order
Specifies the order in which records should be returned based on their creation date.
Valid values: 'asc', 'desc'.
Default is 'desc'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: Desc
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

DRMMSite. You can pipe site objects from Get-RMMSite (uses the Id property).
## OUTPUTS

DRMMActivityLog. Returns activity log objects with details about the activity.
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

The API uses integer IDs (not UIDs) for sites and users in this endpoint.
Results are paginated automatically.

## RELATED LINKS
