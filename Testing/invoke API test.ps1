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

    if (-not $Script:RMMAuth) {
        throw "Not connected. Use Connect-DattoRMM first."
    }

    # Check token expiration
    if ((Get-Date) -gt $Script:RMMAuth.ExpiresAt) {

        if ($Script:RMMAuth.AutoRefresh) {

            Connect-DattoRMM -Key $Script:RMMAuth.Key -Secret $Script:RMMAuth.Secret -AutoRefresh

        } else {

            throw "Token expired. Reconnect with Connect-DattoRMM. Use -AutoRefresh to enable automatic token refresh."
            
        }
    }

    # Throttling
    $Now = Get-Date
    if ($Script:RMMThrottle.LastRequest) {

        $Utilization = 1 - ($Script:RMMThrottle.Remaining / [math]::Max($Script:RMMThrottle.Limit, 1))
        $DelayFactor = if ($Priority) { 5000 } else { 10000 }  # Priority halves the delay factor

        if ($Utilization -ge 0.85) {

            Start-Sleep -Seconds 60

        } else {

            $DelayMs = $Utilization * $DelayFactor  # Math-based delay, max 5s or 10s

            if ($DelayMs -gt 0) {

                Start-Sleep -Milliseconds $DelayMs

            }
        }
    }

#!! CALL API !!#

    # Update throttling
    $Script:RMMThrottle.RequestCount++
    if ($Script:RMMThrottle.RequestCount % $Script:RMMThrottle.CheckInterval -eq 0) {
        $RateInfo = Get-RMMRequestRate
        $Script:RMMThrottle.Limit = $RateInfo.accountRateLimit
        $Script:RMMThrottle.Remaining = $RateInfo.accountRateLimit - $RateInfo.accountCount
        $Script:RMMThrottle.Reset = (Get-Date).AddSeconds($RateInfo.slidingTimeWindowSizeSeconds)
        $Utilization = 1 - ($RateInfo.accountCount / [math]::Max($RateInfo.accountRateLimit, 1))
        $Script:RMMThrottle.CheckInterval = [math]::Max(1, [int](30 * (1 - $Utilization)))
    }

    $Script:RMMThrottle.LastRequest = Get-Date
    return $Content
}