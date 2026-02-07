<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMAlert {
    <#
    .SYNOPSIS
        Retrieves alerts from the Datto RMM API.

    .DESCRIPTION
        The Get-RMMAlert function retrieves alerts at different scopes: global (account-level),
        site-level, or device-level. Alerts can be filtered by status (Open, Resolved, or All) and can
        be retrieved for specific objects by UID.

        When specifying AlertUid, the function returns both open and resolved alerts for that UID,
        regardless of status. The Status parameter is ignored in this case.

        The function supports pipeline input from Get-RMMSite and Get-RMMDevice, making it easy to
        retrieve alerts for filtered sets of sites or devices.

    .PARAMETER Site
        A DRMMSite object to retrieve alerts for. Accepts pipeline input from Get-RMMSite.

    .PARAMETER SiteUid
        The unique identifier (GUID) of a site to retrieve alerts for.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of a device to retrieve alerts for.

    .PARAMETER AlertUid
        The unique identifier of a specific alert to retrieve.

    .PARAMETER Status
        Filter alerts by status. Valid values: 'All', 'Open', 'Resolved'. Default is 'Open'.
        Note: When AlertUid is specified, Status is not required.

    .EXAMPLE
        Get-RMMAlert

        Retrieves all open alerts at the account level.

    .EXAMPLE
        Get-RMMDevice -FilterId 12345 | Get-RMMAlert -Status Resolved

        Gets all devices matching filter 12345 and retrieves their resolved alerts.

    .EXAMPLE
        Get-RMMSite -Name "Contoso" | Get-RMMAlert -Status All

        Gets the site named "Contoso" and retrieves all alerts for that site (open and resolved).

    .EXAMPLE
        Get-RMMSite | Where-Object {$_.Name -like "Branch*"} | Get-RMMAlert

        Gets all sites with names starting with "Branch" and retrieves all open alerts.

    .EXAMPLE
        Get-RMMDevice -Hostname "SERVER01" | Get-RMMAlert

        Gets the device named "SERVER01" and retrieves all its open alerts.

    .EXAMPLE
        Get-RMMAlert -AlertUid "0e6cf376-e60a-4dc2-95b3-daa122e74de9"

        Retrieves a specific alert by its unique identifier. Returns the alert regardless of its state
        (open or resolved). Useful when the alert's status is unknown but the UID is available.

    .EXAMPLE
        $Site = Get-RMMSite -Name "Main Office"
        PS > Get-RMMAlert -SiteUid $Site.Uid

        Retrieves open alerts for a specific site using its UID.

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite.
        You can also pipe objects with DeviceUid or SiteUid properties.

    .OUTPUTS
        DRMMAlert. Returns alert objects with details about the alert status, priority, source, and more.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        When piping devices or sites, the Status parameter applies to all objects in the pipeline.

        The function retrieves alerts in batches and automatically handles pagination.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Alerts/Get-RMMAlert.md

    .LINK
        Resolve-RMMAlert

    .LINK
        about_DRMMAlert

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMSite
    #>

    [CmdletBinding(DefaultParameterSetName = 'Global')]
    param (
        [Parameter(
            ParameterSetName = 'Site',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMSite]
        $Site,

        [Parameter(
            ParameterSetName = 'SiteUid',
            Mandatory = $true
        )]
        [guid]
        $SiteUid,
        
        [Parameter(
            ParameterSetName = 'Device',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMDevice]
        $Device,

        [Parameter(
            ParameterSetName = 'DeviceUid',
            Mandatory = $true
        )]
        [guid]
        $DeviceUid,

        [Parameter(
            ParameterSetName = 'Alert',
            Mandatory = $true
        )]
        [guid]
        $AlertUid,

        [Parameter(
            Mandatory = $false
        )]
        [ValidateSet(
            'All',
            'Open',
            'Resolved'
        )]
        [string]
        $Status = 'Open'
    )

    begin {

        Write-Verbose "Getting alerts with parameter set: $($PSCmdlet.ParameterSetName)"
        
    }

    process {

        # Set base alert uri path
        switch -Regex ($PSCmdlet.ParameterSetName) {

            '^Alert' {

                $MethodBasePath = "alert/$AlertUid"
            
            }

            '^Global' {

                $MethodBasePath = "account/alerts"
            
            }

            '^Site' {

                if ($Site) {

                    $SiteUid = $Site.Uid

                }

                $MethodBasePath = "site/$($SiteUid)/alerts"
                
            }

            '^Device' {

                if ($Device) {

                    $DeviceUid = $Device.Uid

                }

                $MethodBasePath = "device/$($DeviceUid)/alerts"

            }
        }

        # Set method paths based on parameter set and status
        [array]$MethodPaths = @()

        if ($PSCmdlet.ParameterSetName -ne 'Alert') {

            if ($Status -eq 'All') {

                $MethodPaths += "$MethodBasePath/open"
                $MethodPaths += "$MethodBasePath/resolved"

            } else {

                $MethodPaths += "$MethodBasePath/$($Status.ToLower())"

            }

        } else {

            $MethodPaths += $MethodBasePath

        }

        # Iterate method paths and get alerts
        foreach ($MethodPath in $MethodPaths) {

            $APIMethod = @{
                Path = $MethodPath
                Method = 'Get'
                Paginate = $true
                PageElement = 'alerts'
            }

            Invoke-APIMethod @APIMethod | ForEach-Object {

                [DRMMAlert]::FromAPIMethod($_, $Script:SessionPlatform)

            }
        }
    }
}