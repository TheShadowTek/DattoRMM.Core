<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMSiteSettings {
    <#
    .SYNOPSIS
        Retrieves site settings from the Datto RMM API.

    .DESCRIPTION
        The Get-RMMSiteSettings function retrieves configuration settings for a specific site.
        Site settings include general settings, proxy configuration, mail settings, notification
        settings, and other site-specific configurations.

        This function can accept either a site object from Get-RMMSite or a site UID directly.

    .PARAMETER Site
        A DRMMSite object to retrieve settings for. Accepts pipeline input from Get-RMMSite.

    .PARAMETER SiteUid
        The unique identifier (GUID) of the site to retrieve settings for.

    .EXAMPLE
        Get-RMMSite -Name "Contoso" | Get-RMMSiteSettings

        Retrieves settings for the "Contoso" site.

    .EXAMPLE
        Get-RMMSiteSettings -SiteUid "12067610-8504-48e3-b5de-60e48416aaad"

        Retrieves settings for a site by its unique identifier.

    .EXAMPLE
        $Settings = Get-RMMSite -SiteUid $SiteUid | Get-RMMSiteSettings
        PS > $Settings.GeneralSettings

        Retrieves site settings and displays the general settings section.

    .EXAMPLE
        Get-RMMSite | Get-RMMSiteSettings | Select-Object Name, @{N='Timezone';E={$_.GeneralSettings.Timezone}}

        Retrieves settings for all sites and displays site name and timezone.

    .EXAMPLE
        $Settings = Get-RMMSiteSettings -SiteUid $SiteUid
        PS > $Settings.MailSettings

        Retrieves site settings and displays the mail recipients configuration.

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite.
        System.Guid. You can pipe SiteUid values.

    .OUTPUTS
        DRMMSiteSettings. Returns settings objects with the following properties:
        - SiteUid: Site unique identifier
        - GeneralSettings: General site configuration (timezone, locale, etc.)
        - ProxySettings: Proxy server configuration
        - MailSettings: Email notification settings

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Site settings control how the Datto RMM agent behaves for devices in that site.

    .LINK
        about_DRMMSite

    .LINK
        Get-RMMSite

    .LINK
        Set-RMMSiteProxy
    #>
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
