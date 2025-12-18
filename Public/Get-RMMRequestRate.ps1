function Get-RMMRequestRate {

    if (-not $script:RMMAuth) {

        throw "Not connected. Use Connect-DattoRMM first."

    }

    $InvokeRMMApi = @{
        Uri = "$API/system/request_rate"
        Method = 'Get'
    }

    Invoke-RMMApi @InvokeRMMApi # pipe to create class when class has been created

}