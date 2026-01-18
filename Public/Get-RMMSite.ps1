<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMSite {
    <#
    .SYNOPSIS
        Retrieves sites from the Datto RMM API.

    .DESCRIPTION
        The Get-RMMSite function retrieves site information from Datto RMM. Sites represent
        customer organizations or locations within your RMM account.

        The function supports multiple query modes:
        - Get all sites
        - Get a specific site by UID
        - Search for sites by name
        - Include extended properties (settings, variables, filters)

        Extended properties allow you to retrieve related data for sites in a single command.

    .PARAMETER SiteUid
        The unique identifier (GUID) of a specific site to retrieve.

    .PARAMETER All
        Retrieve all sites in the account. This is the default behavior. Set to $false to
        disable when using other parameters.

    .PARAMETER SiteName
        Search for sites by name using partial matching (LIKE operator). Returns all sites
        where the name contains the specified value.

    .PARAMETER ExtendedProperties
        Additional properties to retrieve for each site. Valid values:
        - Settings: Include site settings
        - Variables: Include site variables
        - Filters: Include device filters

        Use this to populate the SiteSettings, Variables, and Filters properties of the
        returned site objects.

    .EXAMPLE
        Get-RMMSite

        Retrieves all sites in the account.

    .EXAMPLE
        Get-RMMSite -SiteUid "12067610-8504-48e3-b5de-60e48416aaad"

        Retrieves a specific site by its unique identifier.

    .EXAMPLE
        Get-RMMSite -SiteName "Contoso"

        Searches for sites containing "Contoso" in the name (partial match).

    .EXAMPLE
        Get-RMMSite -SiteName "Production" | Get-RMMDevice

        Searches for sites with "Production" in the name and retrieves all devices from those sites.

    .EXAMPLE
        Get-RMMSite -ExtendedProperties Settings, Variables

        Retrieves all sites and includes their settings and variables.

    .EXAMPLE
        $Site = Get-RMMSite -SiteUid $SiteUid -ExtendedProperties Settings
        PS > $Site.SiteSettings.GeneralSettings

        Retrieves a site with its settings and accesses the general settings.


    .EXAMPLE
        Get-RMMSite | Sort-Object Name | Select-Object Name, Uid

        Retrieves all sites, sorts by name, and displays name and UID.

    .EXAMPLE
        $Sites = Get-RMMSite -ExtendedProperties Filters
        PS > $Sites | ForEach-Object {
        >>     [PSCustomObject]@{
        >>         SiteName = $_.Name
        >>         FilterCount = $_.Filters.Count
        >>     }
        >> }

        Retrieves sites with filters and displays the filter count for each.

    .INPUTS
        None. You cannot pipe objects to Get-RMMSite.

    .OUTPUTS
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

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Using ExtendedProperties can significantly increase response time and API calls.
        Only request extended properties when needed.

    .LINK
        about_DRMMSite

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMDeviceFilter
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param (
        [Parameter(
            ParameterSetName = 'Single',
            Mandatory
        )]
        [guid]
        $SiteUid,

        # Parameter help description
        [Parameter(
            ParameterSetName = 'Search',
            Mandatory = $false
        )]
        [string]
        $SiteName,

        [RMMSiteExtendedProperty[]]
        $ExtendedProperties
    )

    $APIMethod = @{
        Path = ''
        Method = 'Get'
    }

    switch ($PSCmdlet.ParameterSetName) {

        'Single' {

            $APIMethod.Path = "site/$SiteUid"
            $Response = Invoke-APIMethod @APIMethod
            $Site = [DRMMSite]::FromAPIMethod($Response)

            if ($ExtendedProperties.Count -gt 0) {
                
                Add-SiteExtendedProperties -Site $Site -ExtendedProperties $ExtendedProperties

            }

            return $Site

        }

        {$_ -in 'All', 'Search'} {

            $APIMethod.Path = 'account/sites'
            $APIMethod.Paginate = $true
            $APIMethod.PageElement = 'sites'

            if ($SiteName) {

                $APIMethod.Parameters = @{siteName = $SiteName}

            }

            Invoke-APIMethod @APIMethod | Where-Object {try {[void][guid]$_.uid; $true} catch {$false}} | ForEach-Object {

                $Site = [DRMMSite]::FromAPIMethod($_)

                if ($ExtendedProperties.Count -gt 0) {

                    Add-SiteExtendedProperties -Site $Site -ExtendedProperties $ExtendedProperties

                }

                $Site

            }
        }
    }
}

function Add-SiteExtendedProperties {
    param (
        [DRMMSite]
        $Site,

        [RMMSiteExtendedProperty[]]
        $ExtendedProperties
    )

    if ($ExtendedProperties -contains [RMMSiteExtendedProperty]::Settings) {

        $Site.SiteSettings = Get-RMMSiteSettings -SiteUid $Site.Uid

    }

    if ($ExtendedProperties -contains [RMMSiteExtendedProperty]::Variables) {

        $Site.Variables = Get-RMMVariable -SiteUid $Site.Uid

    }

    if ($ExtendedProperties -contains [RMMSiteExtendedProperty]::Filters) {

        $Site.Filters = Get-RMMDeviceFilter -SiteUid $Site.Uid
        
    }
}
