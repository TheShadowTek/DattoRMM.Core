<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Invokes an API method, building the request parameters and handling authentication, and pagination as needed.
.DESCRIPTION
    This function constructs the necessary parameters for an API request, including authentication headers and query
    parameters. It checks for token expiration and refreshes the token if auto-refresh is enabled. It also supports 
    paginated requests by automatically fetching subsequent pages until all data is retrieved.

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
    
    # Ensure we are connected and have a valid token before making the API call
    if (-not $script:RMMAuth) {

        throw "Not connected. Use Connect-DattoRMM first."

    }

    # Check token expiration
    $Now = Get-Date

    if ($Now -gt $script:RMMAuth.ExpiresAt) {

        if ($script:RMMAuth.AutoRefresh) {

            # Refresh
            $RefreshConnectParams = @{
                Key = $script:RMMAuth.Key
                Secret = $script:RMMAuth.Secret
                AutoRefresh = $true
            }

            switch ($Script:RMMAuth.Keys) {

                'Proxy' {$RefreshConnectParams.Proxy = $script:RMMAuth.Proxy}
                'ProxyCredential' {$RefreshConnectParams.ProxyCredential = $script:RMMAuth.ProxyCredential}

            }

            Connect-DattoRMM @RefreshConnectParams

        } else {

            throw "Token expired. Reconnect with Connect-DattoRMM. Use -AutoRefresh to enable automatic token refresh."

        }
    }

    # Build the request parameters for Invoke-RestMethod, including authentication headers and any query parameters
    $RequestParams = @{
        Uri = "$API/$Path"
        Method = $Method
        ContentType = 'application/json'
        Headers = $RMMAuth.AuthHeader
        TimeoutSec = $Script:APIMethodRetry.TimeoutSeconds
    }

    # Add proxy settings if configured
    if ($Script:RMMAuth.ContainsKey('Proxy')) {

        $RequestParams.Proxy = $Script:RMMAuth.Proxy

    }

    if ($Script:RMMAuth.ContainsKey('ProxyCredential')) {

        $RequestParams.ProxyCredential = $Script:RMMAuth.ProxyCredential

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

            $Result = Invoke-APIRestMethod -Parameters $RequestParams

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

                # If we have original parameters, check which ones are missing from nextPageUrl - workaround for API not preserving all query params
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
                $RequestParams.Uri = $NextUrl
                $Result = Invoke-APIRestMethod -Parameters $RequestParams
                $Result.$PageElement

            }

        } else {
            
            Invoke-APIRestMethod -Parameters $RequestParams

        }

    } catch {

        throw $_

    }
}
