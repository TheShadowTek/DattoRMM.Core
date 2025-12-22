function Get-RMMEsxiHostAudit {
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

        Write-Debug "Getting ESXi host audit for device UID: $DeviceUid"

        $APIMethod = @{
            Path = "audit/esxihost/$DeviceUid"
            Method = 'Get'
        }

        $Response = Invoke-APIMethod @APIMethod

        if ($Response) {

            $Audit = [DRMMEsxiHostAudit]::FromAPIMethod($Response)
            $Audit.DeviceUid = $DeviceUid
            
            return $Audit

        }
    }
}
