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
        
        If not specified, uses the default platform configured via Set-RMMConfig.
        If no default is configured, falls back to 'Pinotage'.
        
        To set a persistent default platform: Set-RMMConfig -DefaultPlatform Merlot

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
        You can configure persistent defaults using Set-RMMConfig to avoid specifying them each time:
        - Set-RMMConfig -DefaultPlatform Merlot
        - Set-RMMConfig -DefaultPageSize 100
        
        The configured default page size will be used if it's within your account's maximum limit.
        You can still override these defaults by explicitly specifying the -Platform parameter.

    .LINK
        Disconnect-DattoRMM
        Set-RMMConfig
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
        $Platform
    )

    # Determine platform to use
    if (-not $PSBoundParameters.ContainsKey('Platform')) {

        # User didn't specify platform, check for configured default
        if ($Script:ConfigDefaultPlatform) {

            $Platform = $Script:ConfigDefaultPlatform
            Write-Verbose "Using configured default platform: $Platform"

        } else {

            # Fall back to Pinotage
            $Platform = [RMMPlatform]::Pinotage
            Write-Verbose "Using default platform: $Platform"

        }
    }

    # Build the request body
    $APIServer = "$($Platform.ToString().ToLower())-api"
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

    if ($AutoRefresh) {

        $Script:RMMAuth.Key = $Credential.UserName ?? $Key.ToString()
        $Script:RMMAuth.Secret = $Credential.Password ?? $Secret

    }

    # Test connection and set page size
    Write-Debug "Testing connection to Datto RMM API."
    $PageSizeMethod = @{
        Path = "system/pagination"
        Method = 'Get'
    }

    try {

            $AccountMaxPageSize = (Invoke-APIMethod @PageSizeMethod).max
            $Script:MaxPageSize = $AccountMaxPageSize

            # Check if there's a configured default page size
            if ($Script:ConfigDefaultPageSize -and $Script:ConfigDefaultPageSize -le $AccountMaxPageSize) {

                $Script:PageSize = $Script:ConfigDefaultPageSize
                Write-Verbose "Set page size to configured default: $($Script:PageSize)."

            } elseif ($Script:PageSize -and $Script:PageSize -le $AccountMaxPageSize) {

                # If PageSize was previously set in this session and is within limits, keep it
                Write-Verbose "Retaining previously set page size: $($Script:PageSize)."

            } else {

                $Script:PageSize = $AccountMaxPageSize
                Write-Verbose "Set page size to account maximum: $($Script:PageSize)."

            }

    } catch {

        $HttpResponseCode = $_.Exception.Response.StatusCode.value__
        $HttpResponseDescription = $_.Exception.Response.StatusDescription.value__
        throw "Failed to connect to Datto RMM API! Response: $HttpResponseCode $HttpResponseDescription"

    }
}