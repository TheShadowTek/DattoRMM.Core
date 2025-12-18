function Get-RMMRequestRate {

    if (-not $script:RMMAuth) {

        throw "Not connected. Use Connect-DattoRMM first."

    }

    # Check token expiration

    if ((Get-Date) -gt $script:RMMAuth.ExpiresAt) {

        if ($script:RMMAuth.AutoRefresh) {

            # Refresh

            $RefreshBody = "grant_type=password&username=$($script:RMMAuth.Key)&password=$([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($script:RMMAuth.Secret)))"

            $RefreshRequest = @{
                Uri = "$($script:APIUrl)/auth/oauth/token"
                Method = 'Post'
                Body = $RefreshBody
                ContentType = 'application/x-www-form-urlencoded'
            }

            $RefreshResponse = Invoke-WebRequest @RefreshRequest
            $RefreshContent = $RefreshResponse.Content | ConvertFrom-Json
            $script:RMMAuth.AccessToken = $RefreshContent.access_token
            $script:RMMAuth.ExpiresAt = (Get-Date).AddSeconds($RefreshContent.expires_in)

        } else {

            throw "Token expired. Reconnect with Connect-DattoRMM."

        }

    }

    $RequestParams = @{
        Uri = "$($script:API)/system/request_rate"
        Method = 'Get'
        Headers = @{ Authorization = "Bearer $($script:RMMAuth.AccessToken)" }
    }
    $Response = Invoke-WebRequest @RequestParams
    $Content = $Response.Content | ConvertFrom-Json
    return $Content

}