<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
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
        Get-RMMDevice -DeviceId 12345 | Move-RMMDevice -TargetSiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

        Moves a device to a different site via pipeline.

    .EXAMPLE
        Move-RMMDevice -DeviceUid "11111111-2222-3333-4444-555555555555" -TargetSiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

        Moves a device by specifying both device and target site UIDs.

    .EXAMPLE
        Get-RMMDevice -Hostname "SERVER01" | Move-RMMDevice -TargetSite (Get-RMMSite -SiteName "New Office")

        Moves a device to a new site using site objects.

    .EXAMPLE
        Get-RMMSite -SiteName "Old Site" | Get-RMMDevice | Move-RMMDevice -TargetSiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -Force

        Moves all devices from one site to another without confirmation prompts.

    .INPUTS
        DRMMDevice. You can pipe device objects from Get-RMMDevice.

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
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Move-RMMDevice.md

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
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceUidSiteObject',
            Mandatory = $true
        )]
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

        Invoke-ApiMethod @APIMethod | Out-Null

    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAsttT27LPdD9Pa
# Z2rIgP4hjb6DI9kjtvDytClMETCWBKCCA04wggNKMIICMqADAgECAhB464iXHfI6
# gksEkDDTyrNsMA0GCSqGSIb3DQEBCwUAMD0xFjAUBgNVBAoMDVJvYmVydCBGYWRk
# ZXMxIzAhBgNVBAMMGkRhdHRvUk1NLkNvcmUgQ29kZSBTaWduaW5nMB4XDTI2MDMz
# MTAwMTMzMFoXDTI4MDMzMTAwMjMzMFowPTEWMBQGA1UECgwNUm9iZXJ0IEZhZGRl
# czEjMCEGA1UEAwwaRGF0dG9STU0uQ29yZSBDb2RlIFNpZ25pbmcwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQChn1EpMYQgl1RgWzQj2+wp2mvdfb3UsaBS
# nxEVGoQ0gj96tJ2MHAF7zsITdUjwaflKS1vE6wAlOg5EI1V79tJCMxzM0bFpOdR1
# L5F2HE/ovIAKNkHxFUF5qWU8vVeAsOViFQ4yhHpzLen0WLF6vhmc9eH23dLQy5fy
# tELZQEc2WbQFa4HMAitP/P9kHAu6CUx5s4woLIOyyR06jkr3l9vk0sxcbCxx7+dF
# RrsSLyPYPH+bUAB8+a0hs+6qCeteBuUfLvGzpMhpzKAsY82WZ3Rd9X38i32dYj+y
# dYx+nx+UEMDLjDJrZgnVa8as4RojqVLcEns5yb/XTjLxDc58VatdAgMBAAGjRjBE
# MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU
# H+B0vf97dYXqdUX1YMcWhFsY6fcwDQYJKoZIhvcNAQELBQADggEBAJmD4EEGNmcD
# 1JtFoRGxuLJaTHxDwBsjqcRQRE1VPZNGaiwIm8oSQdHVjQg0oIyK7SEb02cs6n6Y
# NZbwf7B7WZJ4aKYbcoLug1k1x9SoqwBmfElECeJTKXf6dkRRNmrAodpGCixR4wMH
# KXqwqP5F+5j7bdnQPiIVXuMesxc4tktz362ysph1bqKjDQSCBpwi0glEIH7bv5Ms
# Ey9Gl3fe+vYC5W06d2LYVebEfm9+7766hsOgpdDVgdtnN+e6uwIJjG/6PTG6TMDP
# y+pr5K6LyUVYJYcWWUTZRBqqwBHiLGekPbxrjEVfxUY32Pq4QfLzUH5hhUCAk4HN
# XpF9pOzFLMUxggIDMIIB/wIBATBRMD0xFjAUBgNVBAoMDVJvYmVydCBGYWRkZXMx
# IzAhBgNVBAMMGkRhdHRvUk1NLkNvcmUgQ29kZSBTaWduaW5nAhB464iXHfI6gksE
# kDDTyrNsMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKEC
# gAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwG
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHObrqDZEUsKgCqUjdzaNciBRKs0
# 0T9n597K6KpZsDcqMA0GCSqGSIb3DQEBAQUABIIBAC8CeoSNlo6y1MUeut6mkKUi
# H5j9x9iFwsjSdVbRX1N881nbuyB90LdicuNt33q0alMZsN7Qp3HAgkUPDIbyfQnq
# Hgv+Rr38TttH/QTV4o0SOX2oVjseiEZmI3dpna2dHzx0DPcNsX/xnKJ0Zy6RHK74
# TVUKlROc500GvTs1ia0YcXIWpYS/qrTsinhvnwRqAizhHoWMmayNXxLKyJGxX9Xm
# vNDIC+A7IsL0OaXm0lscShNSEzIt1j6yhu9saBv3u2R8dyeiVaUp0vDv30pJRldh
# e1euO4Qt+1y09m+MgRu7UEN6wps61bDm5oMsJGjyUtVet2GRmScs6uHGM52zRZE=
# SIG # End signature block
