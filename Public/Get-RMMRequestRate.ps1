function Get-RMMRequestRate {
    [CmdletBinding()]
    
    param ()

    if (-not $Script:RMMAuth) {

        throw "Not connected. Use Connect-DattoRMM first."

    }

    $APIMethod = @{
        Path = "system/request_rate"
        Method = 'Get'
    }

    Write-Debug "Getting request rate information from Datto RMM API."
    $Headers = @{ Authorization = "Bearer $($script:RMMAuth.AccessToken)" }
    Invoke-RestMethod -Uri "$API/system/request_rate" -Method Get -Headers $Headers
    
}