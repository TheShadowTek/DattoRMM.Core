function Connect-DattoRMM {

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
        $AutoRefresh

    )

    # Build the request body

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
        Body = "grant_type=password&username=$authkey&password=$authsecret"
        ContentType = 'application/x-www-form-urlencoded'
    }

    try {

        $Response = Invoke-RestMethod @TokenRequest
        Write-Verbose "Successfully authenticated to Datto RMM API."

    }
    catch {

        throw $_

    }

    # Build the auth hashtable
    $script:RMMAuth = @{
        AccessToken = $Response.access_token
        TokenType = $Response.token_type
        ExpiresAt = (Get-Date).AddSeconds($Response.expires_in)
        AutoRefresh = $AutoRefresh.IsPresent
        AuthHeader = @{ Authorization = "$($Response.token_type) $($Response.access_token)" }
    }

    if ($AutoRefresh) {

        $script:RMMAuth.Key = $AuthKey
        $script:RMMAuth.Secret = $AuthSecret | ConvertTo-SecureString -AsPlainText -Force

    }
    
    # Get initial rate limit status
    $RateStatus = Get-RMMRequestRate
    $Utilization = 1 - ($RateStatus.accountCount / [math]::Max($RateStatus.accountRateLimit, 1))
    $script:RMMThrottle.Limit = $RateStatus.accountRateLimit
    $script:RMMThrottle.Remaining = $RateStatus.accountRateLimit - $RateStatus.accountCount
    $script:RMMThrottle.Reset = (Get-Date).AddSeconds($RateStatus.slidingTimeWindowSizeSeconds)
    $script:RMMThrottle.CheckInterval = [math]::Max(1, [int](30 * (1 - $Utilization)))

}