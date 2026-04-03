<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function New-RMMSite {
    <#
    .SYNOPSIS
        Creates a new site in the Datto RMM account.

    .DESCRIPTION
        The New-RMMSite creates a new site in the authenticated user's account.
        A site represents a customer location or organisational unit within Datto RMM.

        Supports creating sites with proxy settings in a single operation,
        or proxy settings can be configured later using Set-RMMSiteProxy.

    .PARAMETER Name
        The name of the site to create. This parameter is required.

    .PARAMETER Description
        A description of the site.

    .PARAMETER Notes
        Additional notes about the site.

    .PARAMETER OnDemand
        Whether the site should be configured as an on-demand site.

    .PARAMETER SplashtopAutoInstall
        Whether Splashtop should be automatically installed on devices at this site.

    .PARAMETER ProxyHost
        The hostname or IP address of the proxy server.

    .PARAMETER ProxyPort
        The port number of the proxy server.

    .PARAMETER ProxyType
        The type of proxy server. Valid values: 'http', 'socks4', 'socks5'.

    .PARAMETER ProxyUsername
        The username for proxy authentication.

    .PARAMETER ProxyPassword
        The password for proxy authentication (as a SecureString).

    .EXAMPLE
        New-RMMSite -Name "Contoso Main Office"

        Creates a new site with the specified name.

    .EXAMPLE
        New-RMMSite -Name "Branch Office" -Description "West Coast Branch" -OnDemand

        Creates an on-demand site with a description.

    .EXAMPLE
        $ProxyPass = Read-Host -Prompt "Enter proxy password" -AsSecureString
        New-RMMSite -Name "Remote Site" -ProxyHost "proxy.contoso.com" -ProxyPort 8080 -ProxyType http -ProxyUsername "proxyuser" -ProxyPassword $ProxyPass

        Creates a site with HTTP proxy settings configured.

    .EXAMPLE
        New-RMMSite -Name "Test Site" -SplashtopAutoInstall -Notes "Testing environment"

        Creates a site with Splashtop auto-install enabled and notes.

    .INPUTS
        None. You cannot pipe objects to New-RMMSite.

    .OUTPUTS
        DRMMSite. Returns the newly created site object.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Proxy settings can be configured during site creation or added later using Set-RMMSiteProxy.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Sites/New-RMMSite.md
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        [Parameter(Mandatory = $true)]
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
        [string]
        $ProxyHost,

        [Parameter()]
        [ValidateRange(1, 65535)]
        [int]
        $ProxyPort,

        [Parameter()]
        [ValidateSet('http', 'socks4', 'socks5')]
        [string]
        $ProxyType,

        [Parameter()]
        [string]
        $ProxyUsername,

        [Parameter()]
        [SecureString]
        $ProxyPassword
    )

    process {

        if (-not $PSCmdlet.ShouldProcess("Create new site '$Name'", "Create site", "Creating site")) {

            return

        }

        Write-Debug "Creating new RMM site: $Name"

        # Build request body
        $Body = @{
            name = $Name
        }

        switch ($PSBoundParameters.Keys) {

            'Description' {$Body.description = $Description}
            'Notes' {$Body.notes = $Notes}
            'OnDemand' {$Body.onDemand = $true}
            'SplashtopAutoInstall' {$Body.splashtopAutoInstall = $true}
        
        }

        # Build proxy settings if any proxy parameters are specified
        $ProxyParams = @('ProxyHost', 'ProxyPort', 'ProxyType', 'ProxyUsername', 'ProxyPassword')
        $HasProxySettings = $ProxyParams | Where-Object { $PSBoundParameters.ContainsKey($_) }

        if ($HasProxySettings) {

            # Validate required proxy parameters
            $RequiredProxyParams = @('ProxyHost', 'ProxyPort', 'ProxyType')
            $MissingParams = $RequiredProxyParams | Where-Object { -not $PSBoundParameters.ContainsKey($_) }

            if ($MissingParams) {

                throw "When configuring proxy settings, ProxyHost, ProxyPort, and ProxyType are required. Missing: $($MissingParams -join ', ')"

            }

            $ProxySettings = @{}

            switch ($PSBoundParameters.Keys) {

                'ProxyHost' {$ProxySettings.host = $ProxyHost}
                'ProxyPort' {$ProxySettings.port = $ProxyPort}
                'ProxyType' {$ProxySettings.type = $ProxyType}
                'ProxyUsername' {$ProxySettings.username = $ProxyUsername}
                'ProxyPassword' {

                    # Convert SecureString to plain text for API
                    $PlainPassword = ConvertFrom-SecureStringToPlaintext -SecureString $ProxyPassword
                    $ProxySettings.password = $PlainPassword
                    
                }
            }

            $Body.proxySettings = $ProxySettings

        }

        $APIMethod = @{
            Path = 'site'
            Method = 'Put'
            Body = $Body
        }

        $Response = Invoke-ApiMethod @APIMethod

        [DRMMSite]::FromAPIMethod($Response)

    }

    end {

        # Clear plaintext password from memory
        $PlainPassword = $null
        $ProxySettings.password = $null

    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBcoSWPXjbbcQX4
# SwdHBcQBtEtSKm2vLFMaZuc/udGMzKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILecVY8qc4lnbLtYuJyjab3yr7Jb
# WTA+W5bkmT6OjqhOMA0GCSqGSIb3DQEBAQUABIIBAKECXsjjP0IItNXfXwl2U5pi
# RbRWhTb29oX+CWb4upTnT9NWiqdFDSX1RcSb62dLCqs3jGltE6QAWFfz9CbgfbWL
# FIbKT8B7PE8YPKEYqbexwb1ZmGu23xNE0thyNCrVpVq7UIbt2yYHX45VWWJseBJI
# MkXZKXQwWrTAJz+pNzXBDIa3tP+Odsx+QDvjXFNN+qcry8gpHIzruEpDeoWnVDb+
# wQwJEeNzlnqXIdItk3Tb481j9VGU8a0xuF36t9lGaDbGcxhu6buaftp2ZGfT3zzs
# HfKWb7MaYwNgZhG8EqxKCyZxuPaGRBQ4fgMvlam6eQg7k8MLhBgj6ntiMhP26+Q=
# SIG # End signature block
