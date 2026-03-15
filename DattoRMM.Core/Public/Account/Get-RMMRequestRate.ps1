<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Retrieves the current API request rate information for the Datto RMM account.

.DESCRIPTION
    Get-RMMRequestRate connects to the Datto RMM API and retrieves information about the current request rate limits for the account. This includes details such as the maximum allowed requests per minute, the number of requests currently used, and the time until the request count resets.

    This information is useful for monitoring API usage and ensuring that your applications stay within the allowed limits to avoid throttling.

.EXAMPLE
    Get-RMMRequestRate

    Retrieves the current API request rate information for the connected Datto RMM account.

.NOTES
    This function requires an active connection to the Datto RMM API. Use Connect-DattoRMM to authenticate before calling this function.

    The request rate information is returned as a custom object with properties such as MaxRequestsPerMinute, RequestsUsed, and TimeUntilReset.

    For more details on the API request rate limits, refer to the Datto RMM API documentation.

.LINK
    https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMRequestRate.md
#>
function Get-RMMRequestRate {
    [CmdletBinding()]
    
    param ()

    if (-not $Script:RMMAuth) {

        throw "Not connected. Use Connect-DattoRMM first."

    }

    Write-Debug "Getting request rate information from Datto RMM API."
    $Headers = @{Authorization = "Bearer $($script:RMMAuth.AccessToken)"}
    $RequestParams = @{
        Uri = "$API/system/request_rate"
        Method = 'Get'
        Headers = $Headers
        TimeoutSec = $Script:ApiMethodRetry.TimeoutSeconds
    }

    if ($Script:RMMAuth.ContainsKey('Proxy')) {

        $RequestParams.Proxy = $Script:RMMAuth.Proxy

    }

    if ($Script:RMMAuth.ContainsKey('ProxyCredential')) {

        $RequestParams.ProxyCredential = $Script:RMMAuth.ProxyCredential
        
    }

    Invoke-RestMethod @RequestParams
    
}
