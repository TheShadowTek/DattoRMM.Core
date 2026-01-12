function Get-RMMActivityLog {
    <#
    .SYNOPSIS
        Retrieves activity logs from the Datto RMM API.

    .DESCRIPTION
        The Get-RMMActivityLog function retrieves activity logs with optional filtering by date range,
        entity type (device or user), categories, actions, sites, and users. By default, the API returns
        logs from the last 15 minutes if no date range is specified.

        Activity logs track various activities in the RMM platform including device changes, user actions,
        job executions, and more.

    .PARAMETER From
        Defines the UTC start date for fetching data. Format: yyyy-MM-ddTHH:mm:ssZ
        By default, the API returns logs from the last 15 minutes.

    .PARAMETER Until
        Defines the UTC end date for fetching data. Format: yyyy-MM-ddTHH:mm:ssZ

    .PARAMETER Entity
        Filters activity logs by entity type. Valid values: 'Device', 'User'.
        Can specify multiple values as an array.

    .PARAMETER Category
        Filters activity logs by category (e.g., 'job', 'device').
        Can specify multiple values as an array.

    .PARAMETER Action
        Filters activity logs by action (e.g., 'deployment', 'note').
        Can specify multiple values as an array.

    .PARAMETER SiteId
        Filters activity logs by site ID (integer).
        Can specify multiple values as an array.

    .PARAMETER UserId
        Filters activity logs by user ID (integer).
        Can specify multiple values as an array.

    .PARAMETER Order
        Specifies the order in which records should be returned based on their creation date.
        Valid values: 'asc', 'desc'. Default is 'desc'.

    .EXAMPLE
        Get-RMMActivityLog

        Retrieves activity logs from the last 15 minutes (default behavior).

    .EXAMPLE
        Get-RMMActivityLog -From "2024-01-01T00:00:00Z" -Until "2024-01-02T00:00:00Z"

        Retrieves activity logs for January 1st, 2024.

    .EXAMPLE
        Get-RMMActivityLog -Entity Device -Category job

        Retrieves device-related activity logs in the 'job' category.

    .EXAMPLE
        Get-RMMActivityLog -From "2024-01-01T00:00:00Z" -Category job,device -Action deployment

        Retrieves activity logs for specific categories and action from a start date.

    .EXAMPLE
        Get-RMMSite -SiteName "Main Office" | Get-RMMActivityLog -From "2024-01-01T00:00:00Z"

        Retrieves activity logs for a specific site from January 1st, 2024.

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite (uses the Id property).

    .OUTPUTS
        DRMMActivityLog. Returns activity log objects with details about the activity.

    .NOTES

        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        The API uses integer IDs (not UIDs) for sites and users in this endpoint.
        Results are paginated automatically.

    .LINK
        about_DRMMActivityLog
    #>

    [CmdletBinding(DefaultParameterSetName='Default')]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [long[]]$SiteId,

        [Parameter()]
        [datetime]$From,

        [Parameter()]
        [datetime]$Until,

        [Parameter()]
        [ValidateSet('Device', 'User')]
        [string[]]$Entity,

        [Parameter()]
        [string[]]$Category,

        [Parameter()]
        [string[]]$Action,

        [Parameter()]
        [long[]]$UserId,

        [Parameter()]
        [ValidateSet('asc', 'desc')]
        [string]$Order = 'desc'
    )

    begin {

        # Check for authentication
        if (-not $Script:RMMAuth) {

            throw "Not authenticated. Please run Connect-DattoRMM first."

        }

        # Build query parameters
        $Parameters = @{}

        switch ($PSBoundParameters.Keys) {

            'From' {$Parameters.Add('from', $From.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))}
            'Until' {$Parameters.Add('until', $Until.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))}
            'Entity' {$Parameters.Add('entities', ($Entity | ForEach-Object { $_.ToLower() }) -join ',')}
            'Category' {$Parameters.Add('categories', ($Category | ForEach-Object { $_.ToLower() }) -join ',')}
            'Action' {$Parameters.Add('actions', ($Action | ForEach-Object { $_.ToLower() }) -join ',')}
            'UserId' {$Parameters.Add('userIds', $UserId -join ',')}
            'Order' {$Parameters.Add('order', $Order)}

        }

        # Collect site IDs from pipeline
        $CollectedSiteIds = [System.Collections.Generic.List[long]]::new()

    }

    process {

        if ($SiteId) {

            foreach ($Id in $SiteId) {

                if (-not $CollectedSiteIds.Contains($Id)) {

                    $CollectedSiteIds.Add($Id)

                }
            }
        }
    }

    end {

        # Add collected site IDs to query params
        if ($CollectedSiteIds.Count -gt 0) {

            $Parameters['siteIds'] = $CollectedSiteIds -join ','

        }

        # Call API with pagination
        $Path = 'activity-logs'

        Invoke-APIMethod -Method 'GET' -Path $Path -Parameters $Parameters -Paginate -PageElement 'activities' | ForEach-Object {

            [DRMMActivityLog]::FromAPIMethod($_)

        }
    }
}
