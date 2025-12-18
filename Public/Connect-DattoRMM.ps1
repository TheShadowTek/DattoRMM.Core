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

            $Script:PageSize = (Invoke-APIMethod @PageSizeMethod).max
            Write-Verbose "Set page size to $Script:PageSize."

    } catch {

        $HttpResponseCode = $_.Exception.Response.StatusCode.value__
        $HttpResponseDescription = $_.Exception.Response.StatusDescription.value__
        throw "Failed to connect to Datto RMM API! Response: $HttpResponseCode $HttpResponseDescription"

    }

    # Get initial rate limit status
    $RateStatus = Get-RMMRequestRate
    $Utilization = 1 - ($RateStatus.accountCount / [math]::Max($RateStatus.accountRateLimit, 1))
    $Script:RMMThrottle.Limit = $RateStatus.accountRateLimit
    $Script:RMMThrottle.Remaining = $RateStatus.accountRateLimit - $RateStatus.accountCount
    $Script:RMMThrottle.Reset = (Get-Date).AddSeconds($RateStatus.slidingTimeWindowSizeSeconds)
    $Script:RMMThrottle.CheckInterval = if ($Utilization -le 0.5) { $Script:RMMThrottle.LowUtilCheckInterval } else { [math]::Max(1, [int](30 * (1 - $Utilization))) }

}