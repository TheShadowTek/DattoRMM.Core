function Get-RMMActivityLog {
    <#
    .SYNOPSIS
        Retrieves activity logs from the Datto RMM API.

    .DESCRIPTION
        Retrieves activity logs for one or more sites, with optional filtering by date range, entity type,
        categories, actions, and users. Supports global (all sites) or site-specific queries. Site IDs are
        batched for large environments to avoid API limits.

        You can specify sites by:
        - Piping DRMMSite objects (from Get-RMMSite)
        - Passing SiteId(s) directly
        - Omitting both for global (all sites) scope

        The function prompts for confirmation before retrieving logs for each site, including in global
        mode. Supports Yes/No/Yes to All/No to All responses for safe handling of PII.

    .PARAMETER Site
        One or more DRMMSite objects (from Get-RMMSite) to retrieve activity logs for. Accepts pipeline
        input.

    .PARAMETER SiteId
        One or more site IDs (integer) to retrieve activity logs for.

    .PARAMETER Start
        Start date/time for fetching data. Accepts local or UTC; local times are automatically converted
        to UTC for the API. Format: yyyy-MM-ddTHH:mm:ssZ. Required.

    .PARAMETER End
        End date/time for fetching data. Accepts local or UTC; local times are automatically converted
        to UTC for the API. Format: yyyy-MM-ddTHH:mm:ssZ. Required.

    .PARAMETER Entity
        Filters activity logs by entity type. Valid values: 'Device', 'User'.

    .PARAMETER Category
        Filters activity logs by category (e.g., 'job', 'device').

    .PARAMETER Action
        Filters activity logs by action (e.g., 'deployment', 'note').

    .PARAMETER UserId
        Filters activity logs by user ID (integer).

    .PARAMETER Order
        Specifies the order in which records are returned by creation date. Valid values: 'asc', 'desc'.
        Default is 'desc'.

    .EXAMPLE
        Get-RMMActivityLog -Start "2024-01-01T00:00:00Z" -End "2024-01-02T00:00:00Z"

        Retrieves activity logs for all sites for January 1st, 2024. Prompts for each site.

    .EXAMPLE
        $Start = Get-Date '2024-01-01T00:00:00Z'
        PS > $End = Get-Date '2024-01-02T00:00:00Z'
        PS > Get-RMMSite -SiteName "Main Office" | Get-RMMActivityLog -Start $Start -End $End

        Retrieves activity logs for the "Main Office" site. Prompts for confirmation.

    .EXAMPLE
        Get-RMMActivityLog -SiteId 1234,5678 -Start (Get-Date '2024-01-01') -End (Get-Date '2024-01-02')

        Retrieves activity logs for sites with IDs 1234 and 5678. Prompts for each site.

    .EXAMPLE
        $Start = Get-Date '2024-01-01'
        PS > $End = Get-Date '2024-01-02'
        PS > Get-RMMActivityLog -SiteId 1234,5678 -Start $Start -End $End -Confirm:$false

        Retrieves activity logs for sites with IDs 1234 and 5678 without confirmation prompts (for automation).

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite (uses the Id property).

    .OUTPUTS
        DRMMActivityLog. Returns activity log objects with details about the activity.

    .NOTES
        - Requires an active connection to the Datto RMM API (use Connect-DattoRMM first).
        - Site IDs are batched in groups of 100 to avoid API/query length limits.
        - Confirmation prompt appears for each site (Yes/No/Yes to All/No to All supported).
        - The API uses integer IDs (not UIDs) for sites and users in this endpoint.
        - Results are paginated automatically.

    .LINK
        about_DRMMActivityLog
    #>

    [CmdletBinding(DefaultParameterSetName='Global', SupportsShouldProcess = $true, ConfirmImpact='High')]

    param(
        [Parameter(
            ParameterSetName = 'Site',
            ValueFromPipeline = $true
        )]
        [DRMMSite[]]
        $Site,

        [Parameter(ParameterSetName = 'SiteId')]
        [long[]]$SiteId,

        [Parameter(
            Mandatory = $true
        )]
        [datetime]$Start,

        [Parameter(
            Mandatory = $true
        )]
        [datetime]$End,

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

        # Build query parameters (excluding siteIds)
        $Parameters = @{}
        
        if ($Start) {

            $Parameters['from'] = $Start.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

        }

        if ($End) {

            $Parameters['until'] = $End.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

        }

        if ($Entity) {

            $Parameters['entities'] = ($Entity | ForEach-Object { $_.ToLower() }) -join ','

        }

        if ($Category) {

            $Parameters['categories'] = ($Category | ForEach-Object { $_.ToLower() }) -join ','

        }

        if ($Action) {

            $Parameters['actions'] = ($Action | ForEach-Object { $_.ToLower() }) -join ','

        }

        if ($UserId) {

            $Parameters['userIds'] = $UserId -join ','

        }

        if ($Order) {

            $Parameters['order'] = $Order

        }

        $AllSites = @()

    }

    process {

        if ($PSCmdlet.ParameterSetName -eq 'Site') {

            $AllSites += $Site

        } elseif ($PSCmdlet.ParameterSetName -eq 'SiteId') {
            
            $AllSites = Get-RMMSite | Where-Object {$_.Id -in $SiteId}

        }
    }

    end {

        # If no site(s) specified, treat as global: get all sites
        if ($PSCmdlet.ParameterSetName -eq 'Global') {

            $AllSites = Get-RMMSite

        }

        $ProcessSites = @()

        foreach ($SiteObject in $AllSites) {

            if ($PSCmdlet.ShouldProcess("Activity logs for site: $($SiteObject.Name) may contain PII or sensitive information. Do you want to continue?", "Confirm Activity Log Retrieval for $($SiteObject.Name)")) {

                $ProcessSites += $SiteObject

            } else {
                
                Write-Warning 'Operation cancelled by user.'
                return

            }
        }

        # Batch sites (default 100 per batch)
        $BatchSize = 100

        for ($BatchIndex = 0; $BatchIndex -lt $ProcessSites.Count; $BatchIndex += $BatchSize) {

            $BatchSites = $ProcessSites[$BatchIndex..([Math]::Min($BatchIndex+$BatchSize-1, $ProcessSites.Count-1))]
            $Parameters['siteIds'] = ($BatchSites | ForEach-Object { $_.Id }) -join ','
            $Path = 'activity-logs'

            Invoke-APIMethod -Method 'GET' -Path $Path -Parameters $Parameters -Paginate -PageElement 'activities' | ForEach-Object {

                [DRMMActivityLog]::FromAPIMethod($_)

            }
        }
    }
}
