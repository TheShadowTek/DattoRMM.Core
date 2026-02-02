<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Connect-DattoRMM {
    <#
    .SYNOPSIS
        Connects to the Datto RMM API and authenticates using API credentials.

    .DESCRIPTION
        The Connect-DattoRMM function establishes a connection to the Datto RMM API using either
        an API key and secret combination or a PSCredential object. Upon successful authentication,
        an access token is obtained and stored for subsequent API requests.

        The function supports automatic token refresh and allows selection of different Datto RMM
        platform regions.

    .PARAMETER Key
        The API key for authentication. Used in conjunction with the Secret parameter.

    .PARAMETER Secret
        The API secret as a SecureString. Used in conjunction with the Key parameter.
        Use Read-Host -AsSecureString to securely capture the secret.

    .PARAMETER Credential
        A PSCredential object containing the API key as the username and the API secret as the password.
        This provides an alternative authentication method to using Key and Secret parameters separately.

    .PARAMETER AutoRefresh
        When specified, the function will store credentials and automatically refresh the access token
        when it expires during subsequent API calls.

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

        When AutoRefresh is enabled, credentials are stored securely and the token will be automatically
        refreshed when it expires.

        On module removal, the authentication information is cleared from memory.

        Default Platform and Page Size:
        You can configure persistent defaults using Save-RMMConfig to avoid specifying them each time:
        - Save-RMMConfig -DefaultPlatform Merlot
        - Save-RMMConfig -DefaultPageSize 100
        
        The configured default page size will be used if it's within your account's maximum limit.
        You can still override these defaults by explicitly specifying the -Platform parameter.

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

    # Build the request body
    $APIServer = "$($Platform.ToString().ToLower())-api"
    $Script:SessionPlatform = $Platform
    $Script:APIUrl = "https://$APIServer.centrastage.net"
    $Script:API = "$APIUrl/api/v2"

    switch ($PSCmdlet.ParameterSetName) {

        'Cred' {

            $AuthKey = $Credential.UserName
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)
            $AuthSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

        }

        'Key' {

            $AuthKey = $Key.ToString()
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secret)
            $AuthSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

        }
    }

    # Make the request
    $PublicCredential = [PSCredential]::new('public-client', ('public' | ConvertTo-SecureString -AsPlainText -Force))
    $TokenRequest = @{
        Credential = $PublicCredential
        Uri = "$APIUrl/auth/oauth/token"
        Method = 'Post'
        Body = "grant_type=password&username=$AuthKey&password=$AuthSecret"
        ContentType = 'application/x-www-form-urlencoded'
        TimeoutSec = $Script:APIMethodRetry.TimeoutSeconds
    }

    if ($PSBoundParameters.ContainsKey('Proxy')) {

        $TokenRequest.Proxy = $Proxy

    }

    if ($PSBoundParameters.ContainsKey('ProxyCredential')) {

        $TokenRequest.ProxyCredential = $ProxyCredential
        
    }

    try {

        $Response = Invoke-RestMethod @TokenRequest
        Write-Verbose "Successfully authenticated to Datto RMM API."

    } catch {

        throw $_

    } finally {

        # Clear plaintext credentials from memory
        $AuthKey = $null
        $AuthSecret = $null

    }

    # Build the auth hashtable
    $Script:RMMAuth = @{
        AccessToken = $Response.access_token
        TokenType = $Response.token_type
        ExpiresAt = (Get-Date).AddSeconds($Response.expires_in)
        AutoRefresh = $AutoRefresh.IsPresent
        AuthHeader = @{ Authorization = "$($Response.token_type) $($Response.access_token)" }
    }

    if ($PSBoundParameters.ContainsKey('Proxy')) {

        $Script:RMMAuth.Proxy = $Proxy

    }

    if ($PSBoundParameters.ContainsKey('ProxyCredential')) {

        $Script:RMMAuth.ProxyCredential = $ProxyCredential
        
    }

    if ($AutoRefresh) {

        if ($PSCmdlet.ParameterSetName -eq 'Cred') {

            $Script:RMMAuth.Key = $Credential.UserName
            $Script:RMMAuth.Secret = $Credential.Password

        } else {

            $Script:RMMAuth.Key = $Key
            $Script:RMMAuth.Secret = $Secret

        }
    }

    # Test connection and set page size
    Write-Debug "Testing connection to Datto RMM API & setting maxpage size."
    $PageSizeMethod = @{
        Path = "system/pagination"
        Method = 'Get'
    }

    try {

            #$AccountMaxPageSize = (Invoke-APIMethod @PageSizeMethod -ErrorAction Stop).max
            $AccountMaxPageSize = (Invoke-APIMethod @PageSizeMethod).max
            $Script:MaxPageSize = $AccountMaxPageSize

            # Check if there's a configured default page size
            If ($null -ne $Script:SessionPageSize -and $Script:SessionPageSize -le $AccountMaxPageSize) {

                $Script:PageSize = $Script:SessionPageSize
                Write-Verbose "Set page size to existing session value: $($Script:PageSize)."

            } elseif ($null -ne $Script:ConfigPageSize -and $Script:ConfigPageSize -le $AccountMaxPageSize) {

                $Script:PageSize = $Script:ConfigPageSize
                Write-Verbose "Set page size to configured default: $($Script:PageSize)."

            } elseif ($null -ne $Script:PageSize -and $Script:PageSize -le $AccountMaxPageSize) {

                # If PageSize was previously set in this session and is within limits, keep it
                Write-Verbose "Retaining previously set page size: $($Script:PageSize)."

            } else {

                $Script:PageSize = $AccountMaxPageSize
                Write-Verbose "Set page size to account maximum: $($Script:PageSize)."

            }

            $Script:SessionPageSize = $Script:PageSize
            Write-Verbose "Using page size: $($Script:PageSize)."

    } catch {

        throw "Failed to connect to Datto RMM API. Exception: $($_.Exception.Message)"

    }
}
