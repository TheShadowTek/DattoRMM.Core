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
        [Alias('SiteUid')]
        [guid]
        $Uid
    )

    process {

        switch ($PSCmdlet.ParameterSetName) {

            'Uid' {

                $SettingsSiteUid = $Uid

            }

            'Site' {
                
                $SettingsSiteUid = $Site.Uid

            }
        }

        Write-Debug "Getting settings for site $SettingsSiteUid"
        $Response = Invoke-APIMethod -Path "site/$SettingsSiteUid/settings"
        [DRMMSiteSettings]::FromAPIMethod($Response)

    }
}