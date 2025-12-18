function Invoke-RMMApi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Uri,
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = 'Get',
        [hashtable]$Parameters,
        [object]$Body,
        [hashtable]$Headers = @{},
        [switch]$NoAuth,
        [switch]$Priority  # Reduces delays for priority requests
    )

    if (-not $script:RMMAuth) {
        throw "Not connected. Use Connect-DattoRMM first."
    }

    # Check token expiration
    if ((Get-Date) -gt $script:RMMAuth.ExpiresAt) {
        if ($script:RMMAuth.AutoRefresh) {
            Connect-DattoRMM -Key $script:RMMAuth.Key -Secret $script:RMMAuth.Secret -AutoRefresh
        } else {
            throw "Token expired. Reconnect with Connect-DattoRMM. Use -AutoRefresh to enable automatic token refresh."
        }
    }

    # Throttling
    $Now = Get-Date
    if ($script:RMMThrottle.LastRequest) {
        $Utilization = 1 - ($script:RMMThrottle.Remaining / [math]::Max($script:RMMThrottle.Limit, 1))
        $DelayFactor = if ($Priority) { 5000 } else { 10000 }  # Priority halves the delay factor
        if ($Utilization -gt 0.85) {
            Start-Sleep -Seconds 60
        } else {
            $DelayMs = $Utilization * $DelayFactor  # Math-based delay, max 5s or 10s
            if ($DelayMs -gt 0) {
                Start-Sleep -Milliseconds $DelayMs
            }
        }
    }

    $FullUri = "$($script:DRMMBaseUrl)$Uri"
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