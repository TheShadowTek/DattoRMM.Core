function Get-RMMStatus {
    [CmdletBinding()]
    param ()

    process {

        Write-Debug "Getting RMM system status"

        $APIMethod = @{
            Path = 'system/status'
            Method = 'Get'
        }

        $Response = Invoke-APIMethod @APIMethod
        [DRMMStatus]::FromAPIMethod($Response)

    }
}
