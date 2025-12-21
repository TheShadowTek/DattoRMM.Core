function Get-RMMSite {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param (
        [Parameter(
            ParameterSetName = 'Single',
            Mandatory
        )]
        [guid]
        $SiteUid,

        [Parameter(
            ParameterSetName = 'All',
            Mandatory = $false
        )]
        [bool]
        $All = $true,

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