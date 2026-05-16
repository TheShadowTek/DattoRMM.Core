<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Set-RMMSiteProxy {
    <#
    .SYNOPSIS
        Creates or updates proxy settings for a Datto RMM site.

    .DESCRIPTION
        The Set-RMMSiteProxy function creates or updates the proxy server configuration for
        a specified site. The site can be specified by passing a DRMMSite object from the
        pipeline or by providing the SiteUid parameter directly.

        Proxy settings control how devices at the site connect through a proxy server to
        reach the Datto RMM service.

    .PARAMETER Site
        A DRMMSite object to configure. Accepts pipeline input from Get-RMMSite.

    .PARAMETER SiteUid
        The unique identifier (GUID) of the site to configure.

    .PARAMETER ProxyHost
        The hostname or IP address of the proxy server.

    .PARAMETER Port
        The port number of the proxy server (1-65535).

    .PARAMETER Type
        The type of proxy server. Valid values: 'http', 'socks4', 'socks5'.

    .PARAMETER Username
        The username for proxy authentication.

    .PARAMETER Password
        The password for proxy authentication (as a SecureString).

    .PARAMETER Force
        Suppress the confirmation prompt.

    .EXAMPLE
        Set-RMMSiteProxy -SiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -ProxyHost "proxy.contoso.com" -Port 8080 -Type http

        Configures an HTTP proxy without authentication for the specified site.

    .EXAMPLE
        $ProxyPass = Read-Host -Prompt "Enter proxy password" -AsSecureString
        Get-RMMSite -SiteName "Branch Office" | Set-RMMSiteProxy -ProxyHost "proxy.branch.com" -Port 3128 -Type http -Username "proxyuser" -Password $ProxyPass

        Configures an HTTP proxy with authentication via pipeline.

    .EXAMPLE
        Get-RMMSite | Where-Object {$_.Name -like "Remote*"} | Set-RMMSiteProxy -ProxyHost "proxy.corp.com" -Port 1080 -Type socks5 -Force

        Configures a SOCKS5 proxy for all sites with names starting with "Remote" without confirmation.

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite.
        You can also pipe objects with SiteUid or Uid properties.

    .OUTPUTS
        None. This function does not return any output.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        All proxy parameters are optional. You can update individual proxy settings by
        specifying only the parameters you want to change.

        Use Remove-RMMSiteProxy to delete proxy settings entirely.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Sites/Set-RMMSiteProxy.md

    .LINK
        about_DRMMSite

    .LINK
        Get-RMMSite

    .LINK
        Remove-RMMSiteProxy
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
            Mandatory = $true
        )]
        [Alias('Uid')]
        [guid]
        $SiteUid,

        [Parameter()]
        [string]
        $ProxyHost,
        
        [Parameter()]
        [ValidateRange(1, 65535)]
        [int]
        $Port,

        [Parameter()]
        [ValidateSet('http', 'socks4', 'socks5')]
        [string]
        $Type,

        [Parameter()]
        [string]
        $Username,

        [Parameter()]
        [SecureString]
        $Password,

        [Parameter()]
        [switch]
        $Force
    )

    begin {

        # Validate that if any proxy parameter is specified, required ones are present
        $ProxyParams = @('ProxyHost', 'Port', 'Type', 'Username', 'Password')
        $HasProxySettings = $ProxyParams | Where-Object { $PSBoundParameters.ContainsKey($_) }

        if ($HasProxySettings) {

            $RequiredProxyParams = @('ProxyHost', 'Port', 'Type')
            $MissingParams = $RequiredProxyParams | Where-Object { -not $PSBoundParameters.ContainsKey($_) }

            if ($MissingParams) {

                throw "When configuring proxy settings, ProxyHost, Port, and Type are required. Missing: $($MissingParams -join ', ')"
                
            }
        }
    }

    process {

        if ($Site) {

            $SiteUid = $Site.Uid

        }

        if (-not $Force -and -not $PSCmdlet.ShouldProcess("Site $SiteUid", "Configure proxy settings")) {

            return

        }

        Write-Debug "Configuring proxy settings for site: $SiteUid"

        # Build request body with only specified parameters
        $Body = @{}

        switch ($PSBoundParameters.Keys) {

            'ProxyHost' {$Body.host = $ProxyHost}
            'Port' {$Body.port = $Port}
            'Type' {$Body.type = $Type}
            'Username' {$Body.username = $Username}
            'Password' {

                # Convert SecureString to plain text for API
                $PlainPassword = ConvertFrom-SecureStringToPlaintext -SecureString $Password
                $Body.password = $PlainPassword

            }
        }

        $APIMethod = @{
            Path = "site/$SiteUid/settings/proxy"
            Method = 'Post'
            Body = $Body
        }

        Invoke-ApiMethod @APIMethod | Out-Null

        Write-Verbose "Proxy settings configured for site $SiteUid"

    }

    end {

        # Clear plaintext password from memory
        $PlainPassword = $null
        $Body.password = $null

    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCATkLuw3J1xFxu+
# sZ9IoMJJiw/ge68UyAvynejVGgqj8aCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIE7+unXwLIP1d+xejdXki5ibZCz1
# VIK3U4/ABcky0yQ8MA0GCSqGSIb3DQEBAQUABIIBAJO4RUp5OGcs/slYdjnSrRuG
# MKxIhsWo09EZfkAFmVDre+XHNMrwLt78ErGyTta0FNjkdv4LQVXMjZhHLLnQwGyh
# xr9wqJJfMiGdFehHOqIr/qvWhRQSudtCSHft6veocKxEzP/O1jmrx3MOHnKclWNm
# 3cxFYI83MyyuAbDCYQEMdrxQ7DwcENepWDycD0WFE3E32PvEVTGa2HrxCRjOAymH
# VfTqHK8lSEolLu4fuMMkyLLGBlDvrSVbAkHvjvTgiwEP4dMwZu6dGPJgIL6xzTvG
# 44SGe145CY5GNSqDCNEAfroeC8m/lrg+rp8R/9227ojwImJZbUQ2iDypsZlwxs4=
# SIG # End signature block
