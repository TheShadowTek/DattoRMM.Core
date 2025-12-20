function Get-RMMFilter {
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
