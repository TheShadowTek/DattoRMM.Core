function Invoke-RMMApi {

    [CmdletBinding()]

    param (

        [Parameter(Mandatory)]

        [string]$Uri,

        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = 'Get',

        [object]$Body,

        [hashtable]$Headers = @{},

        [switch]$NoAuth

    )

    if (-not $NoAuth -and -not $script:RMMAuth) {

        throw "Not connected. Use Connect-DattoRMM first."

    }

    # Check token expiration

    if (-not $NoAuth -and (Get-Date) -gt $script:RMMAuth.ExpiresAt) {

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

    # Throttling
    $Now = Get-Date

    if ($script:RMMThrottle.LastRequest) {

        $Utilization = 1 - ($script:RMMThrottle.Remaining / [math]::Max($script:RMMThrottle.Limit, 1))

        if ($Utilization -gt 0.85) {

            Start-Sleep -Seconds 60

        } else {

            $DelayMs = $Utilization * 10000 # milliseconds, max 10 seconds

            if ($DelayMs -gt 0) {

                Start-Sleep -Milliseconds $DelayMs

            }

        }

    }

    $FullUri = "$($script:API)$Uri"
    $RequestParams = @{
        Uri = $FullUri
        Method = $Method
        Headers = $Headers
    }

    if (-not $NoAuth) {

        $RequestParams.Headers['Authorization'] = "Bearer $($script:RMMAuth.AccessToken)"

    }

    if ($Body) {

        $RequestParams.Body = $Body | ConvertTo-Json
        $RequestParams.ContentType = 'application/json'

    }

    $Response = Invoke-WebRequest @RequestParams
    $Content = $Response.Content | ConvertFrom-Json

    # Update throttling
    $script:RMMThrottle.RequestCount++

    if ($script:RMMThrottle.RequestCount % $script:RMMThrottle.CheckInterval -eq 0) {

        $RateInfo = Get-RMMRequestRate
        $script:RMMThrottle.Limit = $RateInfo.accountRateLimit
        $script:RMMThrottle.Remaining = $RateInfo.accountRateLimit - $RateInfo.accountCount
        $script:RMMThrottle.Reset = (Get-Date).AddSeconds($RateInfo.slidingTimeWindowSizeSeconds)
        $Utilization = 1 - ($RateInfo.accountCount / [math]::Max($RateInfo.accountRateLimit, 1))
        $script:RMMThrottle.CheckInterval = [math]::Max(1, [int](30 * (1 - $Utilization)))

    }

    $script:RMMThrottle.LastRequest = Get-Date

    return $Content

}