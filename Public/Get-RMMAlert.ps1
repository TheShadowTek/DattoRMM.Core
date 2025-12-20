function Get-RMMAlert {
    [CmdletBinding(DefaultParameterSetName = 'GlobalAll')]
    param (
        [Parameter(
            ParameterSetName = 'SiteAll',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteByUid',
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
            ParameterSetName = 'SiteUidByUid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Uid')]
        [guid]
        $SiteUid,

        [Parameter(
            ParameterSetName = 'GlobalByUid',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteByUid',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteUidByUid',
            Mandatory = $true
        )]
        [string]
        $AlertUid,

        [Parameter(
            ParameterSetName = 'GlobalAll'
        )]
        [Parameter(
            ParameterSetName = 'GlobalByUid'
        )]
        [Parameter(
            ParameterSetName = 'SiteAll'
        )]
        [Parameter(
            ParameterSetName = 'SiteAllUid'
        )]
        [Parameter(
            ParameterSetName = 'SiteByUid'
        )]
        [Parameter(
            ParameterSetName = 'SiteUidByUid'
        )]
        [ValidateSet('All', 'Open', 'Resolved')]
        [string]
        $Status = 'All'
    )

    process {

        Write-Debug "Getting RMM alert(s) using parameter set: $($PSCmdlet.ParameterSetName)"

        if ($PSCmdlet.ParameterSetName -match '^Site') {

            if ($Site) {

                $SiteUid = $Site.Uid

            }

            # Site scope - handle Open, Resolved, or All
            $Methods = @()

            switch ($Status) {

                'Open' {

                    $Methods += @{
                        Path = "site/$SiteUid/alerts/open"
                        Scope = 'Site'
                    }
                }

                'Resolved' {

                    $Methods += @{
                        Path = "site/$SiteUid/alerts/resolved"
                        Scope = 'Site'
                    }
                }

                'All' {

                    $Methods += @{
                        Path = "site/$SiteUid/alerts/open"
                        Scope = 'Site'
                    }
                    $Methods += @{
                        Path = "site/$SiteUid/alerts/resolved"
                        Scope = 'Site'
                    }
                }
            }

            foreach ($Method in $Methods) {

                $APIMethod = @{
                    Path = $Method.Path
                    Method = 'Get'
                    Paginate = $true
                    PageElement = 'alerts'
                }

                switch ($PSCmdlet.ParameterSetName) {

                    {$_ -in 'SiteAll','SiteAllUid'} {

                        Write-Debug "Getting site alerts from $($Method.Path)"
                        Invoke-APIMethod @APIMethod | ForEach-Object {

                            [DRMMAlert]::FromAPIMethod($_, $Method.Scope, $SiteUid)

                        }
                    }

                    {$_ -in 'SiteByUid','SiteUidByUid'} {

                        Write-Debug "Getting site alert by UID: $AlertUid from $($Method.Path)"
                        Invoke-APIMethod @APIMethod | Where-Object {$_.alertUid -eq $AlertUid} | ForEach-Object {

                            [DRMMAlert]::FromAPIMethod($_, $Method.Scope, $SiteUid)

                        }
                    }
                }
            }

        } else {

            # Global scope - handle Open, Resolved, or All
            $Methods = @()

            switch ($Status) {

                'Open' {

                    $Methods += @{
                        Path = 'account/alerts/open'
                        Scope = 'Global'
                    }
                }

                'Resolved' {

                    $Methods += @{
                        Path = 'account/alerts/resolved'
                        Scope = 'Global'
                    }
                }

                'All' {

                    $Methods += @{
                        Path = 'account/alerts/open'
                        Scope = 'Global'
                    }
                    $Methods += @{
                        Path = 'account/alerts/resolved'
                        Scope = 'Global'
                    }
                }
            }

            foreach ($Method in $Methods) {

                $APIMethod = @{
                    Path = $Method.Path
                    Method = 'Get'
                    Paginate = $true
                    PageElement = 'alerts'
                }

                switch ($PSCmdlet.ParameterSetName) {

                    'GlobalAll' {

                        Write-Debug "Getting global alerts from $($Method.Path)"
                        Invoke-APIMethod @APIMethod | ForEach-Object {

                            [DRMMAlert]::FromAPIMethod($_, $Method.Scope, $null)

                        }
                    }

                    'GlobalByUid' {

                        Write-Debug "Getting global alert by UID: $AlertUid from $($Method.Path)"
                        Invoke-APIMethod @APIMethod | Where-Object {$_.alertUid -eq $AlertUid} | ForEach-Object {

                            [DRMMAlert]::FromAPIMethod($_, $Method.Scope, $null)

                        }
                    }
                }
            }
        }
    }
}
