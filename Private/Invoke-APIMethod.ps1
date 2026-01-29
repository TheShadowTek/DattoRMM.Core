<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
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
    function InvokeRestMethod {
        param(
            [hashtable]
            $Parameters
        )

        $Attempt = 0
        $Success = $false

        while (-not $Success -and $Attempts -le $Script:APIMethodRetry.MaxRetries) {

            try {

                $Response = Invoke-RestMethod @Parameters -ErrorAction Stop
                $Success = $true

            } catch {

                $Attempt ++
                Write-Warning "API Error: $($_.Exception.Message)`n`tRetry in $($Script:APIMethodRetry.RetryIntervalSeconds) seconds. Attempt $Attempt of $($Script:APIMethodRetry.MaxRetries)..."
                Start-Sleep -Seconds $Script:APIMethodRetry.RetryIntervalSeconds

            }
        }

        if ($Success) {

            return $Response

        } else {

            throw "The operation could not be completed due to repeated connection interruptions."

        }
    }

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

        $QueryParams = @($Parameters.GetEnumerator() | ForEach-Object {"$($_.Key)=$($_.Value)"})
        $RequestParams.Uri += '?' + ($QueryParams -join '&')

    }

    # Add page size parameter for paginated requests
    if ($Paginate -and $Script:PageSize) {

        $PageSizeParam = "max=$($Script:PageSize)"

        if ($RequestParams.Uri -match '\?') {

            $RequestParams.Uri += "&$PageSizeParam"

        } else {

            $RequestParams.Uri += "?$PageSizeParam"

        }
    }

    if ($Body) {

        $RequestParams.Body = $Body | ConvertTo-Json
        $RequestParams.ContentType = 'application/json'

    }

    try {

        Write-Debug "Invoking RMM API: $Method $Path"
        Write-Debug "Uri: $($RequestParams.Uri)"

        if ($Paginate) {

            #$Result = Invoke-RestMethod @RequestParams
            $Result = InvokeRestMethod -Parameters $RequestParams

            # Parse the original URI to extract query parameters (excluding max and page)
            $OriginalUri = [System.Uri]$RequestParams.Uri
            $OriginalParams = @{}
            
            if ($OriginalUri.Query) {

                $QueryString = $OriginalUri.Query.TrimStart('?')

                foreach ($Param in $QueryString.Split('&')) {

                    $KeyValue = $Param.Split('=')

                    if ($KeyValue.Count -eq 2 -and $KeyValue[0] -notin @('max', 'page')) {

                        $OriginalParams[$KeyValue[0]] = $KeyValue[1]

                    }
                }
            }

            $Result.$PageElement

            while ($Result.pageDetails.nextPageUrl) {

                $NextUrl = $Result.pageDetails.nextPageUrl

                # If we have original parameters, check which ones are missing from nextPageUrl
                if ($OriginalParams.Count -gt 0) {

                    $NextUri = [System.Uri]$NextUrl
                    $ExistingParams = @()
                    
                    # Parse the nextPageUrl to see what parameters it already has
                    if ($NextUri.Query) {

                        $NextQueryString = $NextUri.Query.TrimStart('?')

                        foreach ($Param in $NextQueryString.Split('&')) {

                            $KeyValue = $Param.Split('=')

                            if ($KeyValue.Count -eq 2) {

                                $ExistingParams += $KeyValue[0]

                            }
                        }
                    }

                    # Only add parameters that are missing from the nextPageUrl
                    $MissingParams = $OriginalParams.GetEnumerator() | Where-Object { $_.Key -notin $ExistingParams }
                    
                    if ($MissingParams) {

                        $AdditionalParams = ($MissingParams | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '&'
                        
                        if ($NextUrl -match '\?') {

                            $NextUrl = "$NextUrl&$AdditionalParams"

                        } else {

                            $NextUrl = "$NextUrl?$AdditionalParams"
                            
                        }
                    }
                }

                Write-Debug "Fetching next page: $NextUrl"

                # Apply throttling for each page request
                if ($Script:RMMThrottle.CheckCount -ge $Script:RMMThrottle.CheckInterval) {

                    $Script:RMMThrottle.CheckCount = 1
                    Write-Debug "Updating request rate status from Datto RMM API."
                    Update-Throttle

                } else {

                    $script:RMMThrottle.CheckCount++

                }

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

                $RequestParams.Uri = $NextUrl
                #$Result = Invoke-RestMethod @RequestParams
                $Result = InvokeRestMethod -Parameters $RequestParams
                $Result.$PageElement

            }

        } else {
            
            #Invoke-RestMethod @RequestParams
            InvokeRestMethod -Parameters $RequestParams

        }

    } catch {

        throw $_

    }
}
