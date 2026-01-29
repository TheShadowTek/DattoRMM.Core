<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMFilter {
    <#
    .SYNOPSIS
        Retrieves filters from the Datto RMM API.

    .DESCRIPTION
        The Get-RMMFilter function retrieves filters at different scopes: global (account-level) or site-level. Filters can be retrieved by ID, name, or all filters at a given scope.

        Filters in Datto RMM are used to group devices based on criteria and can be applied when retrieving devices with Get-RMMDevice.

        Filters are categorized as either "Default" (built-in system filters) or "Custom" (user-created filters).

    .PARAMETER Site
        A DRMMSite object to retrieve filters for. Accepts pipeline input from Get-RMMSite.

    .PARAMETER SiteUid
        The unique identifier (GUID) of a site to retrieve filters for.

    .PARAMETER Id
        Retrieve a specific filter by its numeric ID.

    .PARAMETER Name
        Retrieve a filter by its name (exact match).

    .PARAMETER FilterType
        Filter the results by type. Valid values: 'All', 'Default', 'Custom'. Default is 'All'.
        Only applicable for global scope queries.

    .EXAMPLE
        Get-RMMFilter

        Retrieves all filters at the account level.

    .EXAMPLE
        Get-RMMFilter -FilterType Custom

        Retrieves only custom (user-created) filters.

    .EXAMPLE
        Get-RMMFilter -Id 12345

        Retrieves a specific filter by its ID.

    .EXAMPLE
        Get-RMMFilter -Name "Windows Servers"

        Retrieves a filter by exact name match.

    .EXAMPLE
        Get-RMMSite -Name "Main Office" | Get-RMMFilter

        Gets all filters for the "Main Office" site.

    .EXAMPLE
        $Filter = Get-RMMFilter -Name "Production Servers"
        Get-RMMDevice -FilterId $Filter.Id

        Retrieves a filter and uses it to get matching devices.

    .EXAMPLE
        Get-RMMSite | Get-RMMFilter -FilterType Custom

        Gets custom filters for all sites.

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite.
        You can also pipe objects with SiteUid properties.

    .OUTPUTS
        DRMMFilter. Returns filter objects with the following properties:
        - Id: Numeric identifier
        - Name: Filter name
        - Description: Filter description
        - Type: 'rmm_default' or 'custom'
        - Scope: 'Global' or 'Site'
        - SiteUid: Site identifier (for site-scoped filters)
        - DateCreate: Creation date
        - LastUpdated: Last modification date

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Filter IDs can be used with Get-RMMDevice -FilterId to retrieve devices matching
        specific criteria.

    .LINK
        about_DRMMFilter

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMSite
    #>
    [CmdletBinding(DefaultParameterSetName = 'GlobalAll')]
    param (
        [Parameter(
            ParameterSetName = 'SiteAll',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteById',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteByName',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMSite]
        $Site,

        [Parameter(
            ParameterSetName = 'SiteAllUid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteUidById',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteUidByName',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Uid')]
        [guid]
        $SiteUid,

        [Parameter(
            ParameterSetName = 'GlobalById',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteById',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteUidById',
            Mandatory = $true
        )]
        [int]
        $Id,

        [Parameter(
            ParameterSetName = 'GlobalByName',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteByName',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteUidByName',
            Mandatory = $true
        )]
        [string]
        $Name,

        [Parameter(
            ParameterSetName = 'GlobalAll'
        )]
        [Parameter(
            ParameterSetName = 'GlobalById'
        )]
        [Parameter(
            ParameterSetName = 'GlobalByName'
        )]
        [ValidateSet('All', 'Default', 'Custom')]
        [string]
        $FilterType = 'All'
    )

    process {

        Write-Debug "Getting RMM filter(s) using parameter set: $($PSCmdlet.ParameterSetName)"

        if ($PSCmdlet.ParameterSetName -match '^Site') {

            if ($Site) {

                $SiteUid = $Site.Uid

            }

            $APIMethod = @{
                Path = "site/$SiteUid/filters"
                Method = 'Get'
                Paginate = $true
                PageElement = 'filters'
            }

            switch ($PSCmdlet.ParameterSetName) {

                {$_ -in 'SiteAll','SiteAllUid'} {

                    Write-Debug "Getting all filters for site UID: $SiteUid"
                    Invoke-APIMethod @APIMethod | ForEach-Object {

                        [DRMMFilter]::FromAPIMethod($_, 'Site', $SiteUid)

                    }
                }

                {$_ -in 'SiteById','SiteUidById'} {

                    Write-Debug "Getting site filter by ID: $Id for site UID: $SiteUid"
                    Invoke-APIMethod @APIMethod | Where-Object {$_.id -eq $Id} | ForEach-Object {

                        [DRMMFilter]::FromAPIMethod($_, 'Site', $SiteUid)

                    }
                }

                {$_ -in 'SiteByName','SiteUidByName'} {

                    Write-Debug "Getting site filter by Name: $Name for site UID: $SiteUid"
                    Invoke-APIMethod @APIMethod | Where-Object {$_.name -eq $Name} | ForEach-Object {

                        [DRMMFilter]::FromAPIMethod($_, 'Site', $SiteUid)

                    }
                }
            }

        } else {

            # Global scope - handle Default, Custom, or All
            $Methods = @()

            switch ($FilterType) {

                'Default' {

                    $Methods += @{
                        Path = 'filter/default-filters'
                        Scope = 'Global'
                    }
                }

                'Custom' {

                    $Methods += @{
                        Path = 'filter/custom-filters'
                        Scope = 'Global'
                    }
                }

                'All' {

                    $Methods += @{
                        Path = 'filter/default-filters'
                        Scope = 'Global'
                    }
                    $Methods += @{
                        Path = 'filter/custom-filters'
                        Scope = 'Global'
                    }
                }
            }

            foreach ($Method in $Methods) {

                $APIMethod = @{
                    Path = $Method.Path
                    Method = 'Get'
                    Paginate = $true
                    PageElement = 'filters'
                }

                switch ($PSCmdlet.ParameterSetName) {

                    'GlobalAll' {

                        Write-Debug "Getting global filters from $($Method.Path)"
                        Invoke-APIMethod @APIMethod | ForEach-Object {

                            [DRMMFilter]::FromAPIMethod($_, $Method.Scope, $null)

                        }
                    }

                    'GlobalById' {

                        Write-Debug "Getting global filter by ID: $Id from $($Method.Path)"
                        Invoke-APIMethod @APIMethod | Where-Object {$_.id -eq $Id} | ForEach-Object {

                            [DRMMFilter]::FromAPIMethod($_, $Method.Scope, $null)

                        }
                    }

                    'GlobalByName' {

                        Write-Debug "Getting global filter by Name: $Name from $($Method.Path)"
                        Invoke-APIMethod @APIMethod | Where-Object {$_.name -eq $Name} | ForEach-Object {

                            [DRMMFilter]::FromAPIMethod($_, $Method.Scope, $null)

                        }
                    }
                }
            }
        }
    }
}

