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

    .LINK
        Connect-DattoRMM

    .LINK
        Set-RMMSiteProxy

    .LINK
        about_DRMMSite

    .LINK
        Get-RMMSite
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
            'OnDemand' {$Body.onDemand = $OnDemand.IsPresent}
            'SplashtopAutoInstall' {$Body.splashtopAutoInstall = $SplashtopAutoInstall.IsPresent}
        
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
                    $ClearPassword = $true
                    
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

        if ($Response) {

            [DRMMSite]::FromAPIMethod($Response)

        }
    }

    end {

        # Clear plaintext password from memory
        if ($ClearPassword -and $PlainPassword) {

            $PlainPassword = $null
            $ProxySettings.password = $null
            [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode([System.IntPtr]::Zero)

        }
    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCSYZH1vt6ATHhX
# kYkElbwBuQzwXN5ULEcS/h7uvC1jgKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDfwBP9SMf8guGW/KOIw4G5K416I
# W9Bn8Pil2iWByfrzMA0GCSqGSIb3DQEBAQUABIIBAEgrRokdl58bNHwLA+mnUNvX
# eejdIubivGnaj4i2qAo6MJ2y+6yf2plPCfzrCC/ozRn9w0IVIabHLLgnwIgmwfOt
# C/gcf2QSGFV8ryHbJa62lg9UJIImyllaGhE1xEbpa/RU/MZXDXUth2v2Wm4UF+Ja
# QoxCYq99rItXz9pCmg+DcSkDB6h84mAEs06iRCXkmHaT0q41b7X6t8SkYcLWHB93
# 9Vz+9u3Wuw5nv37JMXHV9AU1pvpv3CzrcJC8s6ACLEgOMJOkr97wugByXsgNDhpM
# R4J9i1EW9zTz8NCsynD8cbzFl8sCNSps64M9xKQfvzeHWCrngnVhA2gPeiob584=
# SIG # End signature block
