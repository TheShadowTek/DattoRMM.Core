function Get-RMMSiteSettings {
    [CmdletBinding(DefaultParameterSetName = 'ByUid')]
    param (
        [Parameter(
            ParameterSetName = 'ByUid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [guid]
        $SiteUid,

        [Parameter(
            ParameterSetName = 'BySite',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMSite]
        $Site
    )

    process {

        switch ($PSCmdlet.ParameterSetName) {

            'ByUid' {

                Write-Debug "Getting site object for UID $SiteUid"
                $SettingsSiteUid = $SiteUid

            }

            'BySite' {
                
                $SettingsSiteUid = $Site.Uid

            }
        }

        Write-Debug "Getting settings for site $SettingsSiteUid"
        $Response = Invoke-APIMethod -Path "site/$SettingsSiteUid/settings"
        [DRMMSiteSettings]::FromAPIMethod($Response)

    }
}