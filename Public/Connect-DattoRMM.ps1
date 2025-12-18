function Connect-DattoRMM {

    [CmdletBinding(DefaultParameterSetName = 'Key')]

    param (

        [Parameter(
            ParameterSetName = 'Key',
            Mandatory = $true
        )]
        [guid]$Key,

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
        $AutoRefresh

    )

    # Build the request body

    switch ($PSCmdlet.ParameterSetName) {

        'Cred' {

                $AuthKey = $Cred.UserName
                $AuthSecret = $Cred.GetNetworkCredential().Password
        }

        'Key' {

                $AuthKey = $Key.ToString()
                $AuthSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secret))

        }
    }

    # Request body
    $Body = @{
        publicKey = $AuthKey
        secretKey = $AuthSecret
    }            

    # Make the request
    $TokenRequest = @{
        Uri = $script:DRMMBaseUrl/account/accesstoken
        Method = 'Post'
        Body = ($Body | ConvertTo-Json)
        ContentType = 'application/json'
    }

    try {

        $Response = Invoke-RestMethod @TokenRequest

    }
    catch {

        throw $_

    }


    # Build the auth hashtable
    $script:DRMMAuth = @{
        AccessToken = $Response.access_token
        TokenType = $Response.token_type
        ExpiresAt = (Get-Date).AddSeconds($Response.expires_in)
        AutoRefresh = $AutoRefresh.IsPresent
    }

    if ($AutoRefresh) {

        $script:DRMMAuth.Key = $AuthKey
        $script:DRMMAuth.Secret = $AuthSecret
        
    }
}