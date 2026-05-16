<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Request-RMMToken {
    <#
    .SYNOPSIS
        Requests a new Datto RMM API access token and returns a DRMMToken object.

    .DESCRIPTION
        The Request-RMMToken function generates a new access token from the Datto RMM OAuth
        endpoint and returns a strongly-typed DRMMToken object with the token information.
        
        Unlike Connect-DattoRMM, this function does NOT store the token in the module's
        authentication context. It is intended for testing, inspection, or scenarios where
        you need direct access to the token object.

    .PARAMETER Key
        The API key for authentication. Used in conjunction with the Secret parameter.

    .PARAMETER Secret
        The API secret as a SecureString. Used in conjunction with the Key parameter.
        Use Read-Host -AsSecureString to securely capture the secret.

    .PARAMETER Credential
        A PSCredential object containing the API key as the username and the API secret as the password.
        This provides an alternative authentication method to using Key and Secret parameters separately.

    .PARAMETER Platform
        Specifies the Datto RMM platform region to connect to.
        Valid values: Pinotage, Concord, Vidal, Merlot, Zinfandel, Syrah
        
        If not specified, uses the default platform configured via Save-RMMConfig.
        If no default is configured, falls back to 'Pinotage'.

    .PARAMETER Proxy
        Specifies a proxy server for the request, rather than connecting directly to the Datto RMM API.
        Enter the URI of a network proxy server.

    .PARAMETER ProxyCredential
        Specifies a user account that has permission to use the proxy server specified by the Proxy parameter.

    .EXAMPLE
        $Secret = Read-Host -AsSecureString -Prompt "Enter API Secret"
        PS > $TokenResponse = Request-RMMToken -Key "your-api-key" -Secret $Secret
        PS > $TokenResponse

        Requests a new token and displays the DRMMToken object.

    .EXAMPLE
        $Cred = Get-Credential -Message "Enter API credentials"
        PS > $Token = Request-RMMToken -Credential $Cred -Platform Merlot
        PS > $Token | Format-List

        Requests a token using credentials and formats the output for inspection.

    .EXAMPLE
        $Secret = Read-Host -AsSecureString -Prompt "Enter API Secret"
        PS > $TokenResponse = Request-RMMToken -Key "your-api-key" -Secret $Secret
        PS > $TokenResponse.TokenType
        PS > $TokenResponse.ExpiresIn

        Retrieves a token and accesses specific properties of the DRMMToken object.

    .INPUTS
        None. You cannot pipe objects to Request-RMMToken.

    .OUTPUTS
        DRMMToken object containing:
        - AccessToken: The access token as a SecureString
        - TokenType: Type of token (typically "Bearer")
        - ExpiresIn: Token lifetime as a TimeSpan
        - Scope: OAuth scope granted
        - Jti: JWT identifier

    .NOTES
        This function does NOT store the token in $Script:RMMAuth. It is designed for testing
        and inspection purposes. To authenticate the module for API calls, use Connect-DattoRMM.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Request-RMMToken.md

    .LINK
        Connect-DattoRMM

    .LINK
        about_DattoRMM.CoreAuthentication
    #>

    [CmdletBinding(DefaultParameterSetName = 'Key')]

    param (
        [Parameter(
            ParameterSetName = 'Key',
            Mandatory = $true
        )]
        [string]
        $Key,

        [Parameter(
            ParameterSetName = 'Key',
            Mandatory = $true
        )]
        [securestring]
        $Secret,

        [Parameter(
            ParameterSetName = 'Cred',
            Mandatory = $true
        )]
        [Alias("Cred")]
        [pscredential]
        $Credential,

        [Parameter(
            Mandatory = $false
        )]
        [RMMPlatform]
        $Platform,

        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNullOrEmpty()]
        [uri]
        $Proxy,

        [Parameter(
            Mandatory = $false
        )]
        [pscredential]
        $ProxyCredential
    )

    # Determine platform to use
    if (-not $PSBoundParameters.ContainsKey('Platform')) {

        # User didn't specify platform, check for configured default
        if ($null -ne $Script:SessionPlatform) {

            $Platform = $Script:SessionPlatform
            Write-Verbose "Using existing session platform: $Platform"

        } elseif ($null -ne $Script:ConfigPlatform) {

            $Platform = $Script:ConfigPlatform
            Write-Verbose "Using configured default platform: $Platform"

        } else {

            # Fall back to Pinotage
            $Platform = [RMMPlatform]::Pinotage
            Write-Verbose "Using default platform: $Platform"

        }

    } else {

        Write-Verbose "Using specified platform: $Platform"

    }

    # Build the API URL
    $APIServer = "$($Platform.ToString().ToLower())-api"
    $APIUrl = "https://$APIServer.centrastage.net"

    # Build request parameters based on authentication method
    $TokenRequestParams = @{
        APIUrl = $APIUrl
    }

    switch ($PSCmdlet.ParameterSetName) {

        'Cred' {

            $TokenRequestParams.Key = $Credential.UserName
            $TokenRequestParams.Secret = $Credential.Password

        }

        'Key' {

            $TokenRequestParams.Key = $Key
            $TokenRequestParams.Secret = $Secret

        }
    }

    switch ($PSBoundParameters.Keys) {

        'Proxy' {$TokenRequestParams.Proxy = $Proxy}
        'ProxyCredential' {$TokenRequestParams.ProxyCredential = $ProxyCredential}

    }

    # Request new OAuth token and return as DRMMToken object
    $Response = Request-ApiToken @TokenRequestParams
    return [DRMMToken]::FromAPIMethod($Response)

}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBcLGfyBzDrKp99
# fm53iyvKMyMOtfym8f/XFrOj5Uc/6KCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGCwD70jLNZZlnCsDJ1AKfnFrPEi
# skKDF/0XQCHhrjZkMA0GCSqGSIb3DQEBAQUABIIBAEaPz5sJ7bZ+HPFnCxEwwe83
# J1kMf/qr0ZHs7qeWjscfOvjy6VliQ524Lycy7zKKPrIHThuggPoQM9TtkLWDEotX
# UCVX1MQ8qyrZ0FvIflm592zgS7aARLIEw4C/j5/3oNlAKdUpMZwQP3VLVdwIaVJ0
# XF2UP/PbcCP3niOvGLdfMgY59gcd7yM85t2E2C65OaS5gPln3dR4Jc5i/0MLe38G
# N4KjTd6eNCGZToXPQpqLes1g3nbv9dcMTPzYepwYK+d6VtdnfJMmER7JhPYl3rSG
# cbp/Dqz8EfvPb9OsltKZS/MG3q8NJ6camL27sDAN2hwVAgv1nQdixAtPa5p3bos=
# SIG # End signature block
