<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Remove-RMMSiteProxy {
    <#
    .SYNOPSIS
        Removes proxy settings from a Datto RMM site.

    .DESCRIPTION
        The Remove-RMMSiteProxy function deletes the proxy server configuration from a
        specified site. After removal, devices at the site will connect directly to the
        Datto RMM service without going through a proxy.

        The site can be specified by passing a DRMMSite object from the pipeline or by
        providing the SiteUid parameter directly.

    .PARAMETER Site
        A DRMMSite object to configure. Accepts pipeline input from Get-RMMSite.

    .PARAMETER SiteUid
        The unique identifier (GUID) of the site from which to remove proxy settings.

    .PARAMETER Force
        Suppress the confirmation prompt.

    .EXAMPLE
        Remove-RMMSiteProxy -SiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

        Removes proxy settings from the specified site (with confirmation prompt).

    .EXAMPLE
        Get-RMMSite -Name "Branch Office" | Remove-RMMSiteProxy -Force

        Removes proxy settings from the site via pipeline without confirmation.

    .EXAMPLE
        Get-RMMSite | Where-Object {$_.Name -like "Test*"} | Remove-RMMSiteProxy

        Removes proxy settings from all sites with names starting with "Test".

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite.
        You can also pipe objects with SiteUid or Uid properties.

    .OUTPUTS
        None. This function does not return any output.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        After removing proxy settings, devices will need to be able to connect directly
        to the Datto RMM service. Ensure network connectivity is available before removing
        proxy configuration.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Sites/Remove-RMMSiteProxy.md

    .LINK
        about_DRMMSite

    .LINK
        Get-RMMSite

    .LINK
        Set-RMMSiteProxy
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(
            ParameterSetName = 'BySiteObject',
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
        [Alias('Uid')]
        [guid]
        $SiteUid,

        [Parameter()]
        [switch]
        $Force
    )

    process {

        if ($Site) {

            $SiteUid = $Site.Uid

        }

        if (-not $Force -and -not $PSCmdlet.ShouldProcess("Site $SiteUid", "Remove proxy settings")) {

            return

        }

        Write-Debug "Removing proxy settings for site: $SiteUid"

        $APIMethod = @{
            Path = "site/$SiteUid/settings/proxy"
            Method = 'Delete'
        }

        Invoke-APIMethod @APIMethod | Out-Null

        Write-Verbose "Proxy settings removed from site $SiteUid"

    }
}

