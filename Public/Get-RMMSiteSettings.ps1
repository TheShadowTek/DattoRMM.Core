function Get-RMMSiteSettings {
    [CmdletBinding(DefaultParameterSetName = 'Site')]
    
    param (
        [Parameter(
            ParameterSetName = 'Site',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMSite]
        $Site,

        [Parameter(
            ParameterSetName = 'Uid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Uid')]
        [guid]
        $SiteUid
    )

    process {

        if ($PSCmdlet.ParameterSetName -eq 'Site') {

                
            $SiteUid = $Site.Uid

        }

        Write-Debug "Getting settings for site $SiteUid"
        $Response = Invoke-APIMethod -Path "site/$SiteUid/settings"
        [DRMMSiteSettings]::FromAPIMethod($Response, $SiteUid)

    }
}