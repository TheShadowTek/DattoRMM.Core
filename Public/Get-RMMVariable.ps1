function Get-RMMVariable {
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
        $Name
    )

    Write-Debug "Getting RMM variable(s) using parameter set: $($PSCmdlet.ParameterSetName)"

    if ($PSCmdlet.ParameterSetName -match '^Site') {

        if ($Site) {

            $SiteUid = $Site.Uid

        }

        $APIMethod = @{
            Path = "site/$SiteUid/variables"
            Method = 'Get'
            Paginate = $true
            PageElement = 'variables'
        }

        switch ($PSCmdlet.ParameterSetName) {

            {$_ -in 'SiteAll','SiteAllUid'} {

                Invoke-APIMethod @APIMethod | ForEach-Object {

                    Write-Debug "Getting all variables for site UID: $SiteUid"
                    [DRMMVariable]::FromAPIMethod($_, 'Site', $SiteUid)

                }
            }

            {$_ -in 'SiteById','SiteUidById'} {

                Invoke-APIMethod @APIMethod | Where-Object {$_.id -eq $Id} | ForEach-Object {

                    Write-Debug "Getting site variable by ID: $Id for site UID: $SiteUid"
                    [DRMMVariable]::FromAPIMethod($_, 'Site', $SiteUid)

                }
            }

            {$_ -in 'SiteByName','SiteUidByName'} {

                Invoke-APIMethod @APIMethod | Where-Object {$_.name -eq $Name} | ForEach-Object {

                    Write-Debug "Getting site variable by Name: $Name for site UID: $SiteUid"
                    [DRMMVariable]::FromAPIMethod($_, 'Site', $SiteUid)

                }
            }
        }

    } else {

        $APIMethod = @{
            Path = 'account/variables'
            Method = 'Get'
            Paginate = $true
            PageElement = 'variables'
        }

        switch ($PSCmdlet.ParameterSetName) {

            'GlobalAll' {

                Invoke-APIMethod @APIMethod | ForEach-Object {

                    Write-Debug "Getting all global variables"
                    [DRMMVariable]::FromAPIMethod($_, 'Global', $null)

                }
            }

            'GlobalById' {

                Invoke-APIMethod @APIMethod | Where-Object {$_.id -eq $Id} | ForEach-Object {

                    Write-Debug "Getting global variable by ID: $Id"
                    [DRMMVariable]::FromAPIMethod($_, 'Global', $null)

                }
            }

            'GlobalByName' {

                Invoke-APIMethod @APIMethod | Where-Object {$_.name -eq $Name} | ForEach-Object {

                    Write-Debug "Getting global variable by Name: $Name"
                    [DRMMVariable]::FromAPIMethod($_, 'Global', $null)

                }
            }
        }
    }
}


<#
function Get-RMMVariable {
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
        $Name
    )

    Write-Debug "Getting RMM variable(s) using parameter set: $($PSCmdlet.ParameterSetName)"

}
#>