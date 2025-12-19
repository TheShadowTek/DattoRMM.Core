function Get-RMMSiteSettings {
    [CmdletBinding(DefaultParameterSetName = 'Site')]
    param (
        [Parameter(
            ParameterSetName = 'BySite',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMSite]
        $Site,

        [Parameter(
            ParameterSetName = 'ByUid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('SiteUid')]
        [guid]
        $Uid
    )

    process {

        switch ($PSCmdlet.ParameterSetName) {

            'ByUid' {

                $SettingsSiteUid = $Uid

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