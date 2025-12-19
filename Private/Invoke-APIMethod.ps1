function Invoke-APIMethod {
    [CmdletBinding(DefaultParameterSetName = 'Default')]

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
            Mandatory = $false
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

    # Throttle review
    if ($Script:RMMThrottle.CheckCount -ge $Script:RMMThrottle.CheckInterval) {

        $Script:RMMThrottle.CheckCount = 1
        Write-Debug "Updating request rate status from Datto RMM API."
        Update-Throttle

    } else {

        $script:RMMThrottle.CheckCount++

    }

    # Apply throttling if required
    if ($Script:RMMThrottle.Throttle) {

        while ($Script:RMMThrottle.Pause) {

            Write-Warning "High API Utilisation detected ($([math]::Round($Script:RMMThrottle.Utilisation * 100, 2))%). Pausing requests to avoid throttling."
            Start-Sleep -Seconds 60
            Update-Throttle
            
        }

        if ($Script:RMMThrottle.DelayMS -gt 0) {

            Write-Debug "Delaying next request by $($Script:RMMThrottle.DelayMS) ms to avoid throttling."
            Start-Sleep -Milliseconds $Script:RMMThrottle.DelayMS

        }
    }

    # Invoke the API method

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
        Write-Debug "Uri: $($RequestParams.Uri)"

        if ($Paginate) {

            $Result = Invoke-RestMethod @RequestParams
            $Result.$PageElement

            while ($Result.pageDetails.nextPageUrl) {

                Write-Debug "Fetching next page: $($Result.pageDetails.nextPageUrl)"
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
}