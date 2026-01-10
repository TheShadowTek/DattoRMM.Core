function Set-RMMSite {
    <#
    .SYNOPSIS
        Updates an existing site in the Datto RMM account.

    .DESCRIPTION
        The Set-RMMSite function updates properties of an existing site in the authenticated
        user's account. The site can be specified by passing a DRMMSite object from the pipeline
        or by providing the SiteUid parameter directly.

        Note: Proxy settings cannot be updated using this function. Use Set-RMMSiteProxy or
        Remove-RMMSiteProxy to manage proxy settings.

    .PARAMETER Site
        A DRMMSite object to update. Accepts pipeline input from Get-RMMSite.

    .PARAMETER SiteUid
        The unique identifier (GUID) of the site to update.

    .PARAMETER Name
        The new name for the site. This parameter is required.

    .PARAMETER Description
        The new description for the site.

    .PARAMETER Notes
        The new notes for the site.

    .PARAMETER OnDemand
        Whether the site should be configured as an on-demand site.

    .PARAMETER SplashtopAutoInstall
        Whether Splashtop should be automatically installed on devices at this site.

    .PARAMETER Force
        Suppress the confirmation prompt.

    .EXAMPLE
        Set-RMMSite -SiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -Name "Updated Site Name"

        Updates the name of the specified site.

    .EXAMPLE
        Get-RMMSite -Name "Old Name" | Set-RMMSite -Name "New Name" -Description "Updated description"

        Updates the name and description of a site via pipeline.

    .EXAMPLE
        $Site = Get-RMMSite -Name "Test Site"
        Set-RMMSite -Site $Site -Name "Test Site" -OnDemand -Force

        Enables on-demand for a site without confirmation prompt.

    .EXAMPLE
        Get-RMMSite | Where-Object {$_.Name -like "Branch*"} | Set-RMMSite -SplashtopAutoInstall

        Enables Splashtop auto-install for all sites with names starting with "Branch".

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite.
        You can also pipe objects with SiteUid or Uid properties.

    .OUTPUTS
        DRMMSite. Returns the updated site object.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        This function does not support updating proxy settings. Use Set-RMMSiteProxy or
        Remove-RMMSiteProxy for proxy configuration changes.

    .LINK
        about_DRMMSite

    .LINK
        Get-RMMSite

    .LINK
        Set-RMMSiteProxy
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
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

        [Parameter(
            ParameterSetName = 'ByUid',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'BySiteObject'
        )]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Description,

        [Parameter()]
        [string]
        $Notes,

        [Parameter()]
        [switch]
        $OnDemand,

        [Parameter()]
        [switch]
        $SplashtopAutoInstall,

        [Parameter()]
        [switch]
        $Force
    )

    process {

        if ($Site) {

            $SiteUid = $Site.Uid

            # Use existing values if not specified to prevent wiping them
            $ParamsToCheck = @('Name', 'Description', 'Notes', 'OnDemand', 'SplashtopAutoInstall')

            foreach ($ParamName in $ParamsToCheck) {

                if ($PSBoundParameters.ContainsKey($ParamName)) {

                    continue

                }

                switch ($ParamName) {

                    'Name' {$Name = $Site.Name}
                    'Description' {$Description = $Site.Description}
                    'Notes' {$Notes = $Site.Notes}
                    'OnDemand' {$OnDemand = $Site.OnDemand}
                    'SplashtopAutoInstall' {$SplashtopAutoInstall = $Site.SplashtopAutoInstall}
                    
                }
            }
        }

        if (-not $Force -and -not $PSCmdlet.ShouldProcess("Site $SiteUid", "Update site properties")) {

            return

        }

        Write-Debug "Updating RMM site: $SiteUid"

        # Build request body - always include name
        $Body = @{
            name = $Name
        }

        # Add description if it has a value
        if ($PSBoundParameters.ContainsKey('Description') -or ($Site -and $Description)) {

            $Body.description = $Description

        }

        # Add notes if it has a value
        if ($PSBoundParameters.ContainsKey('Notes') -or ($Site -and $Notes)) {

            $Body.notes = $Notes

        }

        # Handle boolean fields - use .IsPresent for explicit params, direct value for piped site
        if ($PSBoundParameters.ContainsKey('OnDemand')) {

            $Body.onDemand = $OnDemand.IsPresent

        } elseif ($Site -and $null -ne $OnDemand) {

            $Body.onDemand = [bool]$OnDemand

        }

        if ($PSBoundParameters.ContainsKey('SplashtopAutoInstall')) {

            $Body.splashtopAutoInstall = $SplashtopAutoInstall.IsPresent

        } elseif ($Site -and $null -ne $SplashtopAutoInstall) {

            $Body.splashtopAutoInstall = [bool]$SplashtopAutoInstall

        }

        $APIMethod = @{
            Path = "site/$SiteUid"
            Method = 'Post'
            Body = $Body
        }

        $Response = Invoke-APIMethod @APIMethod
        [DRMMSite]::FromAPIMethod($Response)

    }
}
