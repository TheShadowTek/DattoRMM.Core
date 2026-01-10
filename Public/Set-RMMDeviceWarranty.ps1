function Set-RMMDeviceWarranty {
    <#
    .SYNOPSIS
        Sets the warranty expiration date on a device in Datto RMM.

    .DESCRIPTION
        The Set-RMMDeviceWarranty function updates the warranty expiration date for a device
        in the Datto RMM system. The warranty date is used for asset management, tracking
        hardware support coverage, and planning device refresh cycles.

        The warranty date can be set to a specific date or cleared by passing $null.

    .PARAMETER Device
        A DRMMDevice object to update. Accepts pipeline input from Get-RMMDevice.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of the device to update.

    .PARAMETER WarrantyDate
        The warranty expiration date as a DateTime object. Set to $null to clear the warranty date.
        The date will be formatted as ISO 8601 (yyyy-MM-dd) when sent to the API.

    .PARAMETER Force
        Bypasses the confirmation prompt.

    .EXAMPLE
        Set-RMMDeviceWarranty -DeviceUid $DeviceUid -WarrantyDate (Get-Date "2027-12-31")

        Sets the warranty expiration date to December 31, 2027.

    .EXAMPLE
        Get-RMMDevice -Hostname "SERVER01" | Set-RMMDeviceWarranty -WarrantyDate (Get-Date).AddYears(3)

        Sets the warranty date to 3 years from today via pipeline.

    .EXAMPLE
        Set-RMMDeviceWarranty -DeviceUid $DeviceUid -WarrantyDate $null -Force

        Clears the warranty date without confirmation.

    .EXAMPLE
        Get-RMMDevice -FilterId 100 | Set-RMMDeviceWarranty -WarrantyDate (Get-Date "2026-06-30")

        Sets the warranty date for all devices in a filter.

    .EXAMPLE
        # Bulk update warranties from a CSV file
        $Warranties = Import-Csv -Path "device_warranties.csv"
        # CSV format: DeviceUid,WarrantyDate
        # Example row: a1b2c3d4-e5f6-7890-abcd-ef1234567890,2027-12-31

        foreach ($Item in $Warranties) {
            Set-RMMDeviceWarranty -DeviceUid $Item.DeviceUid -WarrantyDate ([datetime]$Item.WarrantyDate) -Force
        }

        Imports warranty dates from a CSV and updates devices in bulk.

    .EXAMPLE
        # Set warranty dates based on purchase date
        $Devices = Get-RMMDevice -FilterId 200
        $Devices | ForEach-Object {
            if ($_.PurchaseDate) {
                $WarrantyExpiry = $_.PurchaseDate.AddYears(3)
                $_ | Set-RMMDeviceWarranty -WarrantyDate $WarrantyExpiry
            }
        }

        Calculates 3-year warranty dates based on device purchase dates.

    .INPUTS
        DRMMDevice. You can pipe device objects from Get-RMMDevice.
        You can also pipe objects with DeviceUid or Uid properties.

    .OUTPUTS
        None. This function does not return any output.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Best practices for warranty management:
        - Update warranty dates when purchasing new devices
        - Use filters to identify devices with expired warranties
        - Track warranty dates to plan device refresh cycles
        - Set reminders to review warranties quarterly
        - Clear warranty dates for devices that are no longer under warranty
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByDeviceUid', SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(
            ParameterSetName = 'ByDeviceObject',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMDevice]
        $Device,

        [Parameter(
            ParameterSetName = 'ByDeviceUid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Uid')]
        [guid]
        $DeviceUid,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [Nullable[datetime]]
        $WarrantyDate,

        [Parameter()]
        [switch]
        $Force
    )

    process {

        if ($Device) {

            $DeviceUid = $Device.Uid
            $DeviceName = $Device.Hostname
        }
        else {

            $DeviceName = "device $DeviceUid"
        }

        $Target = "device '$DeviceName' (UID: $DeviceUid)"
        
        if ($null -eq $WarrantyDate) {

            $Action = "Clear warranty date"
        }
        else {

            $Action = "Set warranty date to $($WarrantyDate.ToString('yyyy-MM-dd'))"
        }

        if (-not $PSCmdlet.ShouldProcess($Target, $Action)) {

            return
        }

        Write-Debug "Setting warranty date for device $DeviceUid"

        # Build request body
        $Body = @{}

        if ($null -eq $WarrantyDate) {

            $Body.warrantyDate = $null
        }
        else {

            # Format as ISO 8601 date (yyyy-MM-dd)
            $Body.warrantyDate = $WarrantyDate.ToString('yyyy-MM-dd')
        }

        $APIMethod = @{
            Path = "device/$DeviceUid/warranty"
            Method = 'Post'
            Body = $Body
        }

        Invoke-APIMethod @APIMethod | Out-Null
    }
}
