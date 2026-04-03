<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
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

        This function is called automatically by Get-RMMDeviceAudit when a piped DRMMDevice
        object has a DeviceClass of 'printer'. It can also be called directly with a Device
        object or DeviceUid.

    .PARAMETER Device
        A DRMMDevice object to retrieve printer audit data for. Accepts pipeline input from
        Get-RMMDevice.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of the device to retrieve printer audit data for.

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

        When piping a DRMMDevice object to Get-RMMDeviceAudit, devices with DeviceClass
        'printer' are automatically routed to this function.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Get-RMMPrinterAudit.md

    .LINK
        about_DRMMDevice

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMDeviceAudit
    #>
    [CmdletBinding(DefaultParameterSetName = 'DeviceUid')]
    param (
        [Parameter(
            ParameterSetName = 'Device',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMDevice]
        $Device,

        [Parameter(
            ParameterSetName = 'DeviceUid',
            Mandatory = $true
        )]
        [guid]
        $DeviceUid
    )

    process {

        Write-Verbose "Getting printer audit with parameter set: $($PSCmdlet.ParameterSetName)"

        switch ($PSCmdlet.ParameterSetName) {

            'Device' {

                if ($Device.DeviceClass -ne 'printer') {

                    Write-Warning "Device '$($Device.Hostname)' has device class '$($Device.DeviceClass)', not 'printer'. Use Get-RMMDeviceAudit to route to the correct audit endpoint."
                    return

                }

                $DeviceUid = $Device.Uid

            }
        }

        Write-Debug "Getting printer audit for DeviceUid: $DeviceUid"

        $APIMethod = @{
            Path = "audit/printer/$DeviceUid"
            Method = 'Get'
        }

        $Response = Invoke-ApiMethod @APIMethod

        if ($Response) {

            [DRMMPrinterAudit]::FromAPIMethod($Response, $DeviceUid)

        }
    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCyJVz4CWz5EfmM
# sERS9xc4lrU0A72iH7bdyYpjnPzDS6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHVK24JqbZwKC3NxJ1o/rKPjKFtt
# Zi/YIeNMLtPFyZLcMA0GCSqGSIb3DQEBAQUABIIBAIpveHMHXzRGYNKKiPdxXeSe
# omKpnGcFB3ArShNpZ5w+gShK3FXKVjSvR9gMrbYBSlA8xpY6ZaQKD2B3FWsmyKTh
# NeyowAmX6zDbqI3BYowbV0gxlSU73Vyr6cVbyF/0DzIYZYMrxpklccJMZkgtqrtg
# AtvoVwhN/zqO4Q0kQe5cVN3R8gYuh/RdXEf/NnCKvfQ+ZZdERiXXSYcqsmsNAUZ4
# kkOL8p3IAJYReUv3uE1mO/A/CKz8ksZRLfYAdcxpNE5EQftjIdRVHy3+lia977FE
# S9++h8+PSOFtx7/h9Q1EAgWEbPwhTKxGZzx21h/PYGdQaM65BOD4q2OzAg+KDqc=
# SIG # End signature block
