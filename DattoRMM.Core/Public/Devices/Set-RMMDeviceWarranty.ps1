<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
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
        $Site = Get-RMMSite -Name "Chicago Office"
        PS > $Filter = $Site | Get-RMMFilter | Where-Object {$_.Name -eq "Dell Latitude 7490"}
        PS > Get-RMMDevice -FilterId $Filter.FilterId | Set-RMMDeviceWarranty -WarrantyDate (Get-Date "2026-06-30")

        Sets the warranty date for all Dell Latitude 7490 laptops at the Chicago Office site.

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
        # Set warranty dates from CSV using serial number matching
        $Warranties = Import-Csv -Path "warranty_imports.csv"
        # CSV format: SerialNumber,WarrantyDate
        # Example row: ABC123456,2028-03-15

        $Site = Get-RMMSite -Name "Boston Office"
        $Devices = Get-RMMDevice -SiteUid $Site.Uid

        foreach ($Item in $Warranties) {
            $Device = $Devices | Where-Object {$_.SerialNumber -eq $Item.SerialNumber}
            if ($Device) {
                $Device | Set-RMMDeviceWarranty -WarrantyDate ([datetime]$Item.WarrantyDate) -Force
                Write-Host "Updated warranty for $($Device.Hostname) (SN: $($Item.SerialNumber))"
            }
        }

        Imports warranties from a CSV and matches devices by serial number at a specific site.

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

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Set-RMMDeviceWarranty.md

    .LINK
        about_DRMMDevice

    .LINK
        Get-RMMDevice
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
            Mandatory = $true
        )]
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

        } else {

            $DeviceName = "device $DeviceUid"
        }

        $Target = "device '$DeviceName' (UID: $DeviceUid)"
        
        if ($null -eq $WarrantyDate) {

            $Action = "Clear warranty date"

        } else {

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

        } else {

            # Format as ISO 8601 date (yyyy-MM-dd)
            $Body.warrantyDate = $WarrantyDate.ToString('yyyy-MM-dd')

        }

        $APIMethod = @{
            Path = "device/$DeviceUid/warranty"
            Method = 'Post'
            Body = $Body
        }

        Invoke-ApiMethod @APIMethod | Out-Null
        
    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBq0Y8vGcqrvkBU
# iEqgGZ+6u6T6jn/CD8y1yty4hK/5YaCCA04wggNKMIICMqADAgECAhB464iXHfI6
# gksEkDDTyrNsMA0GCSqGSIb3DQEBCwUAMD0xFjAUBgNVBAoMDVJvYmVydCBGYWRk
# ZXMxIzAhBgNVBAMMGkRhdHRvUk1NLkNvcmUgQ29kZSBTaWduaW5nMB4XDTI2MDMz
# MTAwMTMzMFoXDTI4MDMzMTAwMjMzMFowPTEWMBQGA1UECgwNUm9iZXJ0IEZhZGRl
# czEjMCEGA1UEAwwaRGF0dG9STU0uQ29yZSBDb2RlIFNpZ25pbmcwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQChn1EpMYQgl1RgWzQj2+wp2mvdfb3UsaBS
# nxEVGoQ0gj96tJ2MHAF7zsITdUjwaflKS1vE6wAlOg5EI1V79tJCMxzM0bFpOdR1
# L5F2HE/ovIAKNkHxFUF5qWU8vVeAsOViFQ4yhHpzLen0WLF6vhmc9eH23dLQy5fy
# tELZQEc2WbQFa4HMAitP/P9kHAu6CUx5s4woLIOyyR06jkr3l9vk0sxcbCxx7+dF
# RrsSLyPYPH+bUAB8+a0hs+6qCeteBuUfLvGzpMhpzKAsY82WZ3Rd9X38i32dYj+y
# dYx+nx+UEMDLjDJrZgnVa8as4RojqVLcEns5yb/XTjLxDc58VatdAgMBAAGjRjBE
# MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU
# H+B0vf97dYXqdUX1YMcWhFsY6fcwDQYJKoZIhvcNAQELBQADggEBAJmD4EEGNmcD
# 1JtFoRGxuLJaTHxDwBsjqcRQRE1VPZNGaiwIm8oSQdHVjQg0oIyK7SEb02cs6n6Y
# NZbwf7B7WZJ4aKYbcoLug1k1x9SoqwBmfElECeJTKXf6dkRRNmrAodpGCixR4wMH
# KXqwqP5F+5j7bdnQPiIVXuMesxc4tktz362ysph1bqKjDQSCBpwi0glEIH7bv5Ms
# Ey9Gl3fe+vYC5W06d2LYVebEfm9+7766hsOgpdDVgdtnN+e6uwIJjG/6PTG6TMDP
# y+pr5K6LyUVYJYcWWUTZRBqqwBHiLGekPbxrjEVfxUY32Pq4QfLzUH5hhUCAk4HN
# XpF9pOzFLMUxggIDMIIB/wIBATBRMD0xFjAUBgNVBAoMDVJvYmVydCBGYWRkZXMx
# IzAhBgNVBAMMGkRhdHRvUk1NLkNvcmUgQ29kZSBTaWduaW5nAhB464iXHfI6gksE
# kDDTyrNsMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKEC
# gAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwG
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHufb+KmpaBTWuPxAQr/8c+3oEpD
# 31gps0rwhYA+NGbdMA0GCSqGSIb3DQEBAQUABIIBACtpdTwG8cuErje0SThXLfGw
# 4EQRy4la7NNb9399IE/kqKo/eGnqJyWYpvj1p2ub9tZNWvBUnq1PE2QcCFRUoj0e
# dv/yGV2TwVekHtmBmxQ/BJhGP8tClq5DvTWRXCpWW69fdUD0146Ikv4azfV9D5Dq
# 7cr5ThKUo3FrZo8FRIL3f5t0UmCfxNiGn/fTIN5TeuDN38CrtN0AgRt7w30JhqHQ
# P0JL3j/r/+cRR20icNyMaOQ15ALQNmtsFY2yJNR4qiY2EDyDxqxn9ovuKtw+/iGd
# WFMyG+wabUQJP+XLRpDT/aD9b56ue1yxPwbNHhGaieU4tjvJ9wKcnOTkaw2hjHE=
# SIG # End signature block
