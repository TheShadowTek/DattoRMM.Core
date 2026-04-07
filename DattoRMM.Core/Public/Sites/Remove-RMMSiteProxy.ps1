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
            Mandatory = $true
        )]
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

        Invoke-ApiMethod @APIMethod | Out-Null

        Write-Verbose "Proxy settings removed from site $SiteUid"

    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBpC+r58QrP0+La
# nkpzexDJU/Y0nzl+BineC17UenA1uKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIK8Yo4ymV6jwJWPW0uBmDwA+2hfk
# jeCmRmOzQuqbxamIMA0GCSqGSIb3DQEBAQUABIIBABC5BcmNg71416SkBJqPhwH4
# +Drlkgs8xhOk5/40/zsefPdvmvIFptSh0guaHWk/XxG0e8EVZku8NXm/0azm41o9
# UBEHblaUwUsoJ8QAu1Gp5v5tVWnmibjpkDhP2jUhTsMevyJxnE7l/b32nnLsABGA
# PIQ+m9cUGiTsdKCuI6+IM/8P8wv7fC9RsYGFCZdM0rkE/Sj48bnMaPkPZoEvcpYC
# wB7C7gwyMNOZ1d+lE2bzNhB7/KbEB/0DlFsqDTY5pcf/o7Bz3JsojgsXvfBuHVHX
# 5cOJSwPFdht9s6RLYBFcqZR4QNO2skX1PBoQ4qr0v+Y/HKKErNdmQtZbpv0qfXo=
# SIG # End signature block
