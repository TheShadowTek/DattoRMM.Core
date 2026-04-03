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
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Sites/Get-RMMSiteSettings.md

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
        $Response = Invoke-ApiMethod -Path "site/$SiteUid/settings"
        [DRMMSiteSettings]::FromAPIMethod($Response, $SiteUid)

    }
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCgNpIWLnjxyQUY
# ON+X/Ka4flHoidsVxsibeU2JAHzxnqCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAuiSSTvcp+9kRUDvI6NdO2q1TlZ
# h14j0+e5Gat2wErXMA0GCSqGSIb3DQEBAQUABIIBAJpmKwordQFqgKBXMChwh+By
# Z/8erl5OZW2bblhQq9pcT0uWlqoSObUjUdZ7dKUV/Tt4oU8LLnFMVBVy9Tf8SdRQ
# Mkg8HD3jbuHHHUr+xj0PLjgcPr04n1sP3FPUK/tvcJ6+VMkRWZWRSLuTcqvZzcxa
# lPLUFsJvJzwe3Z9yywAS1cAMqS0xYJupfDCBKpHw7qvinpJda4+hY94Mz2IoDJQR
# NQLT1aR+FopAwecTABA7YWzYm8GK3ESiAlGtpCIud4oaauI2IRrnHCiGGTgZv6Ur
# uGu8B14fDDGBXsoEMTZNYKtBcg5kYBc0mKWCQ3JuyPyXlghQtvjZq76BOI+FyzY=
# SIG # End signature block
