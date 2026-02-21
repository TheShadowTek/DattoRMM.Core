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
    $Response = Request-APIToken @TokenRequestParams
    return [DRMMToken]::FromAPIMethod($Response)

}
