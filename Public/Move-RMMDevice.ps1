function Move-RMMDevice {
    <#
    .SYNOPSIS
        Moves a device from one site to another site.

    .DESCRIPTION
        The Move-RMMDevice function moves a device from its current site to a different target site
        within the same Datto RMM account.

        This is a significant operation that will change the device's site association and may affect
        monitoring, policies, and reporting.

    .PARAMETER Device
        A DRMMDevice object to move. Accepts pipeline input from Get-RMMDevice.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of the device to move.

    .PARAMETER TargetSite
        A DRMMSite object representing the destination site. Accepts pipeline input from Get-RMMSite.

    .PARAMETER TargetSiteUid
        The unique identifier (GUID) of the destination site.

    .PARAMETER Force
        Bypasses the confirmation prompt.

    .EXAMPLE
        Get-RMMDevice -Id 12345 | Move-RMMDevice -TargetSiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

        Moves a device to a different site via pipeline.

    .EXAMPLE
        Move-RMMDevice -DeviceUid "11111111-2222-3333-4444-555555555555" -TargetSiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

        Moves a device by specifying both device and target site UIDs.

    .EXAMPLE
        Get-RMMDevice -Hostname "SERVER01" | Move-RMMDevice -TargetSite (Get-RMMSite -Name "New Office")

        Moves a device to a new site using site objects.

    .EXAMPLE
        Get-RMMSite -Name "Old Site" | Get-RMMDevice | Move-RMMDevice -TargetSiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -Force

        Moves all devices from one site to another without confirmation prompts.

    .INPUTS
        DRMMDevice. You can pipe device objects from Get-RMMDevice.
        You can also pipe objects with DeviceUid or Uid properties.

    .OUTPUTS
        None. This function does not return any output.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Moving a device may affect:
        - Site-specific policies and configurations
        - Monitoring and alerting rules
        - Reporting and grouping
        - Site-level variables

        The device must exist and the target site must exist in your account.

    .LINK
        about_DRMMDevice

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMSite
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByDeviceObjectSiteUid', SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(
            ParameterSetName = 'ByDeviceObjectSiteUid',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceObjectSiteObject',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMDevice]
        $Device,

        [Parameter(
            ParameterSetName = 'ByDeviceUidSiteUid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceUidSiteObject',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Uid')]
        [guid]
        $DeviceUid,

        [Parameter(
            ParameterSetName = 'ByDeviceObjectSiteObject',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceUidSiteObject',
            Mandatory = $true
        )]
        [DRMMSite]
        $TargetSite,

        [Parameter(
            ParameterSetName = 'ByDeviceObjectSiteUid',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceUidSiteUid',
            Mandatory = $true
        )]
        [guid]
        $TargetSiteUid,

        [Parameter()]
        [switch]
        $Force
    )

    process {

        if ($Device) {

            $DeviceUid = $Device.Uid
            $DeviceName = $Device.Hostname

        } else {

            $DeviceName = "{$DeviceUid}"

        }

        if ($TargetSite) {

            $TargetSiteUid = $TargetSite.Uid
            $TargetSiteName = $TargetSite.Name

        } else {

            $TargetSiteName = "{$TargetSiteUid}"

        }

        $Target = "device '$DeviceName' (UID: $DeviceUid)"

        if (-not $PSCmdlet.ShouldProcess($Target, "Move to $TargetSiteName")) {

            return

        }

        Write-Debug "Moving RMM device $DeviceUid to site $TargetSiteUid"

        $APIMethod = @{
            Path = "device/$DeviceUid/site/$TargetSiteUid"
            Method = 'Put'
        }

        Invoke-APIMethod @APIMethod | Out-Null

    }
}
