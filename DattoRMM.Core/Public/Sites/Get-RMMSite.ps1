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
        customer organisations or locations within your RMM account.

        By default, this function excludes the "Deleted Devices" system site which has an 
        invalid GUID. Use the -DeletedDevices parameter to retrieve only that specific site.

        The function supports multiple query modes:
        - Get all sites (excludes Deleted Devices)
        - Get a specific site by UID
        - Search for sites by name
        - Get only the Deleted Devices system site
        - Include extended properties (settings, variables, filters)

        Extended properties allow you to retrieve related data for sites in a single command.

    .PARAMETER SiteUid
        The unique identifier (GUID) of a specific site to retrieve.

    .PARAMETER All
        Retrieve all sites in the account. This is the default behaviour. Set to $false to
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

    .PARAMETER DeletedDevices
        Retrieve only the special "Deleted Devices" system site. This is a system Datto RMM
        site that has an invalid GUID. This switch uses a dedicated parameter set and cannot
        be combined with other filtering parameters.
        
        Returns a DRMMDeletedDevicesSite object with a string Uid property instead of guid.
        
        WARNING: Methods inherited from DRMMSite (such as GetDevices(), GetAlerts(), etc.)
        will throw errors when called on this object due to the malformed GUID. This site is
        included only for completeness and should not be used in normal operations.

    .EXAMPLE
        Get-RMMSite

        Retrieves all sites in the account (excludes the Deleted Devices system site).

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
        Get-RMMSite -DeletedDevices

        Retrieves only the \"Deleted Devices\" system site (if it exists). Returns a
        DRMMDeletedDevicesSite object with string Uid property. Note that methods like
        GetDevices() will fail due to the invalid GUID.

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

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Using ExtendedProperties can significantly increase response time and API calls.
        Only request extended properties when needed.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Sites/Get-RMMSite.md

    .LINK
        about_DRMMSite

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMFilter
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param (
        [Parameter(
            ParameterSetName = 'Single',
            Mandatory
        )]
        [guid]
        $SiteUid,

        [Parameter(
            ParameterSetName = 'Search',
            Mandatory = $false
        )]
        [string]
        $SiteName,

        [Parameter(
            ParameterSetName = 'All'
        )]
        [Parameter(
            ParameterSetName = 'Single'
        )]
        [Parameter(
            ParameterSetName = 'Search'
        )]
        [RMMSiteExtendedProperty[]]
        $ExtendedProperties,

        [Parameter(
            ParameterSetName = 'DeletedDevices',
            Mandatory
        )]
        [switch]
        $DeletedDevices
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

        'DeletedDevices' {
            
            $APIMethod.Path = 'account/sites'
            $APIMethod.Paginate = $true
            $APIMethod.PageElement = 'sites'
            
            # Return only sites with invalid GUIDs (e.g., "Deleted Devices" system site)
            Invoke-APIMethod @APIMethod | Where-Object {try {[void][guid]$_.uid; $false} catch {$true}} | ForEach-Object {
                
                [DRMMDeletedDevicesSite]::FromAPIMethod($_)
                
            }
        }

        {$_ -in 'All', 'Search'} {

            $APIMethod.Path = 'account/sites'
            $APIMethod.Paginate = $true
            $APIMethod.PageElement = 'sites'

            if ($SiteName) {

                $APIMethod.Parameters = @{siteName = $SiteName}

            }

            # Process sites - filter out invalid GUIDs
            Invoke-APIMethod @APIMethod | Where-Object {try {[void][guid]$_.uid; $true} catch {$false}} | ForEach-Object {

                Write-Verbose "Processing site: $($_.name)"
                $Site = [DRMMSite]::FromAPIMethod($_)
                
                if ($ExtendedProperties.Count -gt 0) {

                    Add-SiteExtendedProperties -Site $Site -ExtendedProperties $ExtendedProperties

                }

                return $Site

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

        $Site.Filters = Get-RMMFilter -SiteUid $Site.Uid
        
    }
}
