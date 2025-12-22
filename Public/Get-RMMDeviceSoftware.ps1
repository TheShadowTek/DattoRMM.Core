function Get-RMMDeviceSoftware {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [guid]
        $DeviceUid
    )

    process {

        Write-Debug "Getting RMM device software for DeviceUid: $DeviceUid"

        $APIMethod = @{
            Path = "audit/device/$DeviceUid/software"
            Method = 'Get'
            Paginate = $true
            PageElement = 'software'
        }

        Invoke-APIMethod @APIMethod | ForEach-Object {

            [DRMMDeviceAuditSoftware]::FromAPIMethod($_)

        }
    }
}
