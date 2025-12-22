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
        Specifies the Datto RMM platform region to connect to. Default is 'Pinotage'.
        Valid values: Pinotage, Concord, Vidal, Merlot, Zinfandel, Syrah

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

    .LINK
        Disconnect-RMM
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
        $Platform = [RMMPlatform]::Pinotage
    )

    # Build the request body
    $APIServer = "$($Platform.ToString().ToLower())-api"
    $Script:APIUrl = "https://$APIServer.centrastage.net"
    $Script:API = "$APIUrl/api/v2"

    switch ($PSCmdlet.ParameterSetName) {

        'Cred' {

            $AuthKey = $Credential.UserName
            $AuthSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))

        }

        'Key' {

            $AuthKey = $Key.ToString()
            $AuthSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secret))

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

        $Script:RMMAuth.Key = $AuthKey
        $Script:RMMAuth.Secret = $AuthSecret | ConvertTo-SecureString -AsPlainText -Force

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

            # If PageSize was previously set and is within limits, keep it
            if ($Script:PageSize -and $Script:PageSize -le $AccountMaxPageSize) {

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