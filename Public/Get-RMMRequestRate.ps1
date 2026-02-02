<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
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
        TimeoutSec = $Script:APIMethodRetry.TimeoutSeconds
    }

    if ($Script:RMMAuth.ContainsKey('Proxy')) {

        $RequestParams.Proxy = $Script:RMMAuth.Proxy

    }

    if ($Script:RMMAuth.ContainsKey('ProxyCredential')) {

        $RequestParams.ProxyCredential = $Script:RMMAuth.ProxyCredential
        
    }

    Invoke-RestMethod @RequestParams
    
}
