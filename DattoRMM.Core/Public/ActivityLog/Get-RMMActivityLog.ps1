<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
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
        Defaults to 24 hours ago.

    .PARAMETER End
        End date/time for fetching data. Accepts local or UTC; local times are automatically converted
        to UTC for the API. Format: yyyy-MM-ddTHH:mm:ssZ. Required.
        Defaults to the current time.
        
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

    .PARAMETER UseExperimentalDetailClasses
        Enables experimental entity/category-specific detail classes for activity logs. When specified,
        details are parsed into strongly-typed classes based on entity, category, and action combinations
        (e.g., DRMMActivityLogDetailsDeviceJob for DEVICE/job activities). When not specified (default),
        all details use the generic DRMMActivityLogDetailsGeneric class with dynamic properties.

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
        Get-RMMSite | Get-RMMActivityLog

        Retrieves activity logs for last 24 hours for all sites. Prompts for each site, or select Yes to All to proceed without further prompts.

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
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/ActivityLog/Get-RMMActivityLog.md

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
            Mandatory = $false
        )]
        [datetime]$Start = (Get-Date).AddHours(-24),

        [Parameter(
            Mandatory = $false
        )]
        [datetime]$End = (Get-Date),

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
        [string]$Order = 'desc',

        [Parameter()]
        [switch]$UseExperimentalDetailClasses
    )

    begin {

        # Build query parameters (excluding siteIds), initializing with required date range parameters
        $Parameters = @{
            from = $Start.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
            until = $End.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        }

        switch ($PSBoundParameters.Keys) {

            'Entity' {$Parameters['entities'] = ($Entity | ForEach-Object { $_.ToLower() }) -join ','}
            'Category' {$Parameters['categories'] = ($Category | ForEach-Object { $_.ToLower() }) -join ','}
            'Action' {$Parameters['actions'] = ($Action | ForEach-Object { $_.ToLower() }) -join ','}
            'UserId' {$Parameters['userIds'] = $UserId -join ','}
            'Order' {$Parameters['order'] = $Order}
        
        }
        
        # Remove duplicate site IDs to limit unnecessary API calls
        if ($SiteId) {

            $SiteID = $SiteId | Sort-Object -Unique

        }

        [array]$AllSites = @()

    }

    process {

        # Collect sites based on parameter set
        switch ($PSCmdlet.ParameterSetName) {

            'Site' {[array]$AllSites += $Site}
            'SiteId' {[array]$AllSites = Get-RMMSite | Where-Object {$_.Id -in $SiteId}}
            'Global' {[array]$AllSites = Get-RMMSite}

        }
    }

    end {

        # Remove duplicate sites (if any) and confirm processing for each site
        [array]$AllSites = $AllSites | Sort-Object -Property Id -Unique
        $ProcessSites = @()

        foreach ($SiteObject in $AllSites) {

            if ($PSCmdlet.ShouldProcess("Activity logs for site: $($SiteObject.Name) may contain PII or sensitive information. Do you want to continue?", "Confirm Activity Log Retrieval for $($SiteObject.Name)")) {

                $ProcessSites += $SiteObject

            } else {
                
                Write-Warning "Skipping activity log retrieval for site: $($SiteObject.Name)"

            }
        }

        # Batch sites (default 100 per batch)
        $BatchSize = 100

        for ($BatchIndex = 0; $BatchIndex -lt $ProcessSites.Count; $BatchIndex += $BatchSize) {

            $BatchSites = $ProcessSites[$BatchIndex..([Math]::Min($BatchIndex+$BatchSize-1, $ProcessSites.Count-1))]
            $Parameters['siteIds'] = ($BatchSites | ForEach-Object {$_.Id}) -join ','
            $Path = 'activity-logs'

            Invoke-ApiMethod -Method 'GET' -Path $Path -Parameters $Parameters -Paginate -PageElement 'activities' | ForEach-Object {

                [DRMMActivityLog]::FromAPIMethod($_, $UseExperimentalDetailClasses.IsPresent)

            }
        }
    }
}

