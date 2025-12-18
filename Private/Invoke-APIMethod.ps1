function Invoke-APIMethod {
    [CmdletBinding()]

    param (

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = 'Get',

        [hashtable]
        $Parameters,

        [object]
        $Body,

        # Enable pagination
        [Parameter(
            ParameterSetName = 'Paginate',
            Mandatory = $true
        )]
        [switch]
        $Paginate,

        # Name of the element in the response that contains the paginated items
        [Parameter(
            ParameterSetName = 'Paginate',
            Mandatory = $true
        )]
        [string]
        $PageElement
    )

    if (-not $script:RMMAuth) {

        throw "Not connected. Use Connect-DattoRMM first."

    }

    # Check token expiration
    $Now = Get-Date

    if ($Now -gt $script:RMMAuth.ExpiresAt) {

        if ($script:RMMAuth.AutoRefresh) {

            # Refresh
            Connect-DattoRMM -Key $script:RMMAuth.Key -Secret $script:RMMAuth.Secret -AutoRefresh

        } else {

            throw "Token expired. Reconnect with Connect-DattoRMM. Use -AutoRefresh to enable automatic token refresh."

        }
    }

    # Throttling
    if ($script:RMMThrottle.LastRequest) {

        $Utilization = 1 - ($script:RMMThrottle.Remaining / [math]::Max($script:RMMThrottle.Limit, 1))
        Write-Debug "Throttling: Utilization=$([math]::Round($Utilization * 100, 2))%, CheckInterval=$($script:RMMThrottle.CheckInterval), RequestCount=$($script:RMMThrottle.RequestCount), Remaining=$($script:RMMThrottle.Remaining)"

        if ($Utilization -gt 0.5) {

            if ($Utilization -gt 0.85) {

                Write-Warning "High API utilization detected ($([math]::Round($Utilization * 100, 2))%). Pausing requests to avoid throttling."
                Start-Sleep -Seconds 60

            } else {

                $DelayMs = $Utilization * 1000

                if ($DelayMs -gt 0) {

                    Write-Debug "Delaying next request by $DelayMs ms to avoid throttling."
                    Start-Sleep -Milliseconds $DelayMs

                }
            }
        }
    }

    # Invoke the API request

    $RequestParams = @{
        Uri = "$API/$Path"
        Method = $Method
        ContentType = 'application/json'
        Headers = $RMMAuth.AuthHeader
    }

    if ($Parameters) {

        $RequestParams.Uri += '?' + ($Parameters.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '&'

    }

    if ($Body) {

        $RequestParams.Body = $Body | ConvertTo-Json
        $RequestParams.ContentType = 'application/json'

    }

    try {

        Write-Debug "Invoking RMM API: $Method $Path"

        if ($Paginate) {

            $Result = Invoke-RestMethod @RequestParams
            $Result.$PageElement

            while ($Result.pageDetails.nextPageUrl) {

                $RequestParams.Uri = $Result.pageDetails.nextPageUrl
                $Result = Invoke-RestMethod @RequestParams
                $Result.$PageElement

            }

        } else {
            
            Invoke-RestMethod @RequestParams
        }
    } catch {

        throw $_

    }
    

    # Update throttling
    $script:RMMThrottle.RequestCount++

    if ($script:RMMThrottle.RequestCount % $script:RMMThrottle.CheckInterval -eq 0) {

        Write-Debug "Updating request rate status from Datto RMM API."
        $RateInfo = Get-RMMRequestRate
        $script:RMMThrottle.Limit = $RateInfo.accountRateLimit
        $script:RMMThrottle.Remaining = $RateInfo.accountRateLimit - $RateInfo.accountCount
        $script:RMMThrottle.Reset = $Now.AddSeconds($RateInfo.slidingTimeWindowSizeSeconds)
        $Utilization = $RateInfo.accountCount / [math]::Max($RateInfo.accountRateLimit, 1)
        $script:RMMThrottle.CheckInterval = if ($Utilization -le 0.5) { $script:RMMThrottle.LowUtilCheckInterval } else { [math]::Max(1, [int](50 * (1 - $Utilization))) }

    }

    $script:RMMThrottle.LastRequest = $Now

}