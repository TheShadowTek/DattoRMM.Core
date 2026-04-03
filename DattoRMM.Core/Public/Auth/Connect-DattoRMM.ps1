<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Connect-DattoRMM {
    <#
    .SYNOPSIS
        Connects to the Datto RMM API and authenticates using API credentials.

    .DESCRIPTION
        The Connect-DattoRMM function establishes a connection to the Datto RMM API using one of three
        authentication methods:
        
        1. API Key and Secret: Generates a new access token via OAuth
        2. PSCredential: Uses username as key, password as secret to generate a new token
        3. API Token: Uses an existing access token (no token generation or refresh)
        
        Methods 1 and 2 support automatic token refresh when enabled. Method 3 is a stateless
        "bring your own token" mode intended for scenarios where token lifecycle is managed externally
        (e.g., Azure Key Vault, CI/CD pipelines).

        The function allows selection of different Datto RMM platform regions.

    .PARAMETER Key
        The API key for authentication. Used in conjunction with the Secret parameter.

    .PARAMETER Secret
        The API secret as a SecureString. Used in conjunction with the Key parameter.
        Use Read-Host -AsSecureString to securely capture the secret.

    .PARAMETER Credential
        A PSCredential object containing the API key as the username and the API secret as the password.
        This provides an alternative authentication method to using Key and Secret parameters separately.

    .PARAMETER ApiToken
        An existing Datto RMM API access token as a SecureString. When using this parameter, the function
        will NOT generate a new token and will NOT refresh the token automatically. This is intended for
        scenarios where token lifecycle is managed externally (e.g., Azure Key Vault, CI/CD).
        
        Cannot be used with AutoRefresh. The token must be valid for the duration of your session.

    .PARAMETER AutoRefresh
        When specified, the function will store credentials and automatically refresh the access token
        when it expires during subsequent API calls.
        
        Only valid with Key/Secret or Credential authentication. Cannot be used with ApiToken.

    .PARAMETER Platform
        Specifies the Datto RMM platform region to connect to.
        Valid values: Pinotage, Concord, Vidal, Merlot, Zinfandel, Syrah
        
        If not specified, uses the default platform configured via Save-RMMConfig.
        If no default is configured, falls back to 'Pinotage'.
        
        To set a persistent default platform: Save-RMMConfig -DefaultPlatform Merlot

    .PARAMETER Proxy
        Specifies a proxy server for the request, rather than connecting directly to the Datto RMM API.
        Enter the URI of a network proxy server. This parameter is optional and only needed if your
        network requires proxy access.

    .PARAMETER ProxyCredential
        Specifies a user account that has permission to use the proxy server specified by the Proxy parameter.
        This parameter is optional and can be used with or without the Proxy parameter (for transparent proxies
        that still require authentication).

    .EXAMPLE
        $Secret = Read-Host -Prompt "Enter API Secret" -AsSecureString
        PS > Connect-DattoRMM -Key "your-api-key" -Secret $Secret

        Connects to the Datto RMM API using an API key and securely prompted secret.

    .EXAMPLE
        $Secret = Read-Host -AsSecureString -Prompt "Enter API Secret"
        PS > Connect-DattoRMM -Key "your-api-key" -Secret $Secret -AutoRefresh

        Connects to the API with automatic token refresh enabled.

    .EXAMPLE
        $Cred = Get-Credential -Message "Enter API Key as username and API Secret as password"
        PS > Connect-DattoRMM -Credential $Cred

        Connects using a PSCredential object where the username is the API key and password is the secret.

    .EXAMPLE
        $Secret = Read-Host -AsSecureString -Prompt "Enter API Secret"
        PS > Connect-DattoRMM -Key "your-api-key" -Secret $Secret -Platform Merlot

        Connects to the Merlot platform region.

    .EXAMPLE
        $Cred = Get-Credential -Message "Enter Datto RMM API credentials"
        PS > Connect-DattoRMM -Credential $Cred -AutoRefresh -Platform Pinotage

        Creates a credential object using Get-Credential and connects with auto-refresh to the Pinotage platform.

    .EXAMPLE
        $Token = Read-Host -AsSecureString -Prompt "Enter API Token"
        PS > Connect-DattoRMM -ApiToken $Token

        Connects using an existing API token. The token will not be refreshed automatically.
        Useful for automation scenarios where tokens are managed externally.

    .EXAMPLE
        # Retrieve token from Azure Key Vault
        PS > $Token = (Get-AzKeyVaultSecret -VaultName 'MyVault' -Name 'DattoRMMToken').SecretValue
        PS > Connect-DattoRMM -ApiToken $Token -Platform Merlot

        Connects using a token retrieved from Azure Key Vault.

    .EXAMPLE
        $Secret = Read-Host -AsSecureString -Prompt "Enter API Secret"
        PS > $ProxyCred = Get-Credential -Message "Enter proxy credentials"
        PS > Connect-DattoRMM -Key "your-api-key" -Secret $Secret -Proxy "http://proxy.company.com:8080" -ProxyCredential $ProxyCred

        Connects to the API through a proxy server with authentication.

    .INPUTS
        None. You cannot pipe objects to Connect-DattoRMM.

    .OUTPUTS
        None. This function does not generate output but stores authentication information in module scope.

    .NOTES
        The function stores the authentication token in the module's script scope. This token is used by all
        subsequent API calls made through the module.

        Authentication Methods:
        - Key/Secret and Credential methods generate new tokens and support AutoRefresh
        - ApiToken method uses existing tokens and does NOT support AutoRefresh
        - When AutoRefresh is enabled (Key/Secret or Credential only), credentials are stored securely
          and the token will be automatically refreshed when it expires
        - ApiToken mode is stateless and does not store credentials or track token expiry

        On module removal, the authentication information is cleared from memory.

        Default Platform and Page Size:
        You can configure persistent defaults using Save-RMMConfig to avoid specifying them each time:
        - Save-RMMConfig -DefaultPlatform Merlot
        - Save-RMMConfig -DefaultPageSize 100
        
        The configured default page size will be used if it's within your account's maximum limit.
        You can still override these defaults by explicitly specifying the -Platform parameter.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Connect-DattoRMM.md

    .LINK
        Disconnect-DattoRMM
        Save-RMMConfig
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
            Mandatory = $true)]
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
            ParameterSetName = 'ApiToken',
            Mandatory = $true
        )]
        [securestring]
        $ApiToken,

        [Parameter(
            ParameterSetName = 'Key'
        )]
        [Parameter(
            ParameterSetName = 'Cred'
        )]
        [switch]
        $AutoRefresh,

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

    # Build token request parameters and set script-level variables for API URL and platform
    $APIServer = "$($Platform.ToString().ToLower())-api"
    $Script:SessionPlatform = $Platform
    $Script:APIUrl = "https://$APIServer.centrastage.net"
    $Script:API = "$APIUrl/api/v2"

    # Generate new token for Key/Cred parameter sets, or use provided token for ApiToken set
    if ($PSCmdlet.ParameterSetName -in @('Key', 'Cred')) {

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

        # Request new OAuth token
        $ResponseToken = Request-ApiToken @TokenRequestParams

        # Build the auth hashtable
        $Script:RMMAuth = @{
            AccessToken = $ResponseToken.access_token
            TokenType = $ResponseToken.token_type
            ExpiresAt = [datetime]::UtcNow.AddSeconds($ResponseToken.expires_in)
            AutoRefresh = $AutoRefresh.IsPresent
            AuthHeader = @{Authorization = "$($ResponseToken.token_type) $($ResponseToken.access_token)"}
        }

    } elseif ($PSCmdlet.ParameterSetName -eq 'ApiToken') {

        # Using provided token - assume Bearer type, no expiry tracking
        Write-Verbose "Using provided API token."

        $ProvidedToken = ConvertFrom-SecureStringToPlaintext -SecureString $ApiToken
        
        $Script:RMMAuth = @{
            AccessToken = $ProvidedToken
            TokenType = 'Bearer'
            ExpiresAt = [datetime]::new([datetime]::MaxValue.Ticks, [System.DateTimeKind]::Utc)
            AutoRefresh = $false
            AuthHeader = @{Authorization = "Bearer $ProvidedToken"}
        }

        # Clear plaintext token from memory
        $ProvidedToken = $null

    }

    # Set proxy settings if provided
    switch ($PSBoundParameters.Keys) {

        'Proxy' {$Script:RMMAuth.Proxy = $Proxy}
        'ProxyCredential' {$Script:RMMAuth.ProxyCredential = $ProxyCredential}

    }

    # Store credentials for AutoRefresh (only for Key/Cred parameter sets)
    if ($AutoRefresh) {

        switch ($PSCmdlet.ParameterSetName) {

            'cred' {

                $Script:RMMAuth.Key = $Credential.UserName
                $Script:RMMAuth.Secret = $Credential.Password

            }

            'Key' {

                $Script:RMMAuth.Key = $Key
                $Script:RMMAuth.Secret = $Secret

            }
        }
    }

    # Discover rate limits and initialise multi-bucket throttle state
    try {

        Initialize-ThrottleState

        # Perform an explicit calibration on connect so throttle state is synchronised
        # before the first workload request and debug output is available immediately.
        Write-Debug "Throttle: Performing initial calibration during connect."
        Update-Throttle

    } catch {

        Write-Warning "Failed to initialise throttle state: $($_.Exception.Message). Using defaults."

    }

    # Test connection and set page size
    try {

        Initialize-PageSize

    } catch {

        throw "Failed to connect to Datto RMM API. Exception: $($_.Exception.Message)"

    }
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB19Eeq8UHpcEhf
# 6frk3G8qMB6NsmYcWYeazaSObY2JhqCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIF+ZO6B/GVHOZ+PNmp4zgEyUhjdz
# RT4/RI6PAyUAIAquMA0GCSqGSIb3DQEBAQUABIIBAJ6Q7Gh021hMiTlv7ezoNrV2
# 31xTJxr3OzPmMgJxn9bj3ncjy+dIO5i34rWHmCKvtiyXbLD/byUT3MFFHZ/AbfVn
# t+Q91SUslw82zJ3aiyLva6r/3rDW0jINr7DB1FgA57PT+E6RI+r5S1ioaSyliPdt
# 8SY0Fx2dFIVEQkYSM4y5gH/CGKl6pZMuyctC4Ck221tmAyzd89EweFPG9hEh9Xry
# q2TAQA++7YcL/MfQJH+xsG4Hfqyoq0RZss5D85ncVLYKyVvYB9sSUo7ip0mbi45r
# l2qaUdtU/Kg5MOI7/JAK8A/76lCKvEMofG9HuyLfhltHrmqcOUpxUznP/69ajX8=
# SIG # End signature block
