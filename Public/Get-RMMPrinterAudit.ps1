function Get-RMMPrinterAudit {
    <#
    .SYNOPSIS
        Retrieves printer audit data for a specific device.

    .DESCRIPTION
        The Get-RMMPrinterAudit function retrieves detailed printer information for a device,
        including printer hardware details, supply levels (toner/ink), and configuration.

        This audit data is collected by the Datto RMM agent from SNMP-enabled network printers
        or locally connected printers. It provides inventory and supply status information
        useful for proactive printer management.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of the device to retrieve printer audit data for.
        Accepts pipeline input from Get-RMMDevice.

    .EXAMPLE
        Get-RMMDevice -DeviceId 12345 | Get-RMMPrinterAudit

        Retrieves printer audit data for device 12345.

    .EXAMPLE
        Get-RMMPrinterAudit -DeviceUid "12345678-1234-1234-1234-123456789012"

        Retrieves printer audit data using a specific device UID.

    .EXAMPLE
        $Audit = Get-RMMDevice -Name "PRINTER01" | Get-RMMPrinterAudit
        PS > $Audit.Printers | Select-Object Name, Model, SupplyLevels

        Retrieves printer audit data and displays printer names, models, and supply levels.

    .EXAMPLE
        Get-RMMDevice -FilterId 200 | Get-RMMPrinterAudit | 
            ForEach-Object {$_.Printers} | 
            Where-Object {$_.SupplyLevels.Black -lt 20}

        Gets devices matching filter 200 and finds printers with low black toner (<20%).

    .EXAMPLE
        $PrinterAudit = Get-RMMPrinterAudit -DeviceUid $DeviceUid
        PS > $PrinterAudit.SnmpInfo

        Retrieves printer audit data and displays SNMP information.

    .INPUTS
        System.Guid. You can pipe DeviceUid from Get-RMMDevice.
        DRMMDevice. You can pipe device objects from Get-RMMDevice.

    .OUTPUTS
        DRMMPrinterAudit. Returns printer audit objects with the following properties:
        - DeviceUid: Device unique identifier
        - Printers: Array of printer objects with details and supply levels
        - SnmpInfo: SNMP configuration and status
        - SystemInfo: Device system information
        - MarkerSupplies: Detailed supply/consumable information

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Printer audit data is only available for devices with printers detected by the agent.
        SNMP must be enabled on network printers for complete data collection.
    #>
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

            [DRMMPrinterAudit]::FromAPIMethod($Response, $DeviceUid)

        }
    }
}
