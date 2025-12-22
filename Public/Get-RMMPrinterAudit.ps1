function Get-RMMPrinterAudit {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Uid')]
        [guid]
        $DeviceUid
    )

    process {

        Write-Debug "Getting printer audit for device UID: $DeviceUid"

        $APIMethod = @{
            Path = "audit/printer/$DeviceUid"
            Method = 'Get'
        }

        $Response = Invoke-APIMethod @APIMethod

        if ($Response) {

            $Audit = [DRMMPrinterAudit]::FromAPIMethod($Response)
            $Audit.DeviceUid = $DeviceUid
            
            return $Audit

        }
    }
}
