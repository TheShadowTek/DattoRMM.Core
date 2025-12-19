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

        [ExtendedProperty[]]
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

            Invoke-APIMethod @APIMethod | ForEach-Object {

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

        [ExtendedProperty[]]
        $ExtendedProperties
    )

    if ($ExtendedProperties -contains [ExtendedProperty]::Settings) {

        Write-Debug "Getting settings for site $($Site.Name) ($($Site.Uid))"
        $SettingsResponse = Invoke-APIMethod -Path "site/$($Site.Uid)/settings"
        $Site.SiteSettings = [DRMMSiteSettings]::FromAPIMethod($SettingsResponse)

    }

    if ($ExtendedProperties -contains [ExtendedProperty]::Variables) {

        Write-Debug "Getting variables for site $($Site.Name) ($($Site.Uid))"
        $VariablesResponse = Invoke-APIMethod -Path "site/$($Site.Uid)/variable" -Paginate -PageElement 'variables'
        $Site.Variables = $VariablesResponse | ForEach-Object {[DRMMVariable]::FromAPIMethod($_, 'Site', $Site.Uid)}

    }

    if ($ExtendedProperties -contains [ExtendedProperty]::Filters) {

        Write-Debug "Getting filters for site $($Site.Name) ($($Site.Uid))"
        $FiltersResponse = Invoke-APIMethod -Path "site/$($Site.Uid)/filters" -Paginate -PageElement 'filters'
        $Site.Filters = $FiltersResponse  # Assuming direct assignment; adjust if schema defines structure
        
    }
}