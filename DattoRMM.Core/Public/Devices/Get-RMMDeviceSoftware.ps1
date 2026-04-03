<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMDeviceSoftware {
    <#
    .SYNOPSIS
        Retrieves installed software for a specific device.

    .DESCRIPTION
        The Get-RMMDeviceSoftware function retrieves a list of all installed software applications
        on a specific device. This includes installed programs, Windows updates, and other software
        components detected by the Datto RMM agent.

        This function requires a DeviceUid and is typically used after retrieving devices with
        Get-RMMDevice or Get-RMMDeviceAudit.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of the device to retrieve software for. Accepts pipeline
        input from Get-RMMDevice.

    .EXAMPLE
        Get-RMMDevice -DeviceId 12345 | Get-RMMDeviceSoftware

        Retrieves all installed software for device 12345.

    .EXAMPLE
        $Device = Get-RMMDevice -Name "SERVER01"
        PS > Get-RMMDeviceSoftware -DeviceUid $Device.Uid

        Retrieves a device by name and then gets its installed software.

    .EXAMPLE
        Get-RMMDevice -FilterId 100 | Get-RMMDeviceSoftware | Where-Object {$_.Name -like "*Microsoft*"}

        Gets all devices matching filter 100 and retrieves their installed Microsoft software.

    .EXAMPLE
        $Software = Get-RMMDevice -DeviceId 12345 | Get-RMMDeviceSoftware
        PS > $Software | Select-Object Name, Version, Publisher | Format-Table

        Retrieves software and displays it in a formatted table.

    .EXAMPLE
        Get-RMMDevice -DeviceId 12345 | Get-RMMDeviceSoftware | 
            Group-Object Publisher | Select-Object Name, Count | Sort-Object Count -Descending

        Retrieves software and groups by publisher to see which vendors have the most applications installed.

    .INPUTS
        System.Guid. You can pipe DeviceUid from Get-RMMDevice.
        DRMMDevice. You can pipe device objects from Get-RMMDevice.

    .OUTPUTS
        DRMMDeviceAuditSoftware. Returns software objects with the following properties:
        - Name: Application name
        - Version: Application version
        - Publisher: Software publisher/vendor
        - InstallDate: Date installed (if available)
        - InstallLocation: Installation path
        - UninstallString: Uninstall command
        - Size: Installed size in bytes

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        The software inventory is collected by the Datto RMM agent during regular audit cycles.
        Results may not be real-time if the device is offline or hasn't reported recently.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Get-RMMDeviceSoftware.md

    .LINK
        about_DRMMDevice

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMDeviceAudit
    #>
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

        Invoke-ApiMethod @APIMethod | ForEach-Object {

            [DRMMDeviceAuditSoftware]::FromAPIMethod($_)

        }
    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAhWuEIvDoxjPSL
# gKkn4JU3N8+K6E+cIbBRPbe3Q6B1gaCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEPToFgglQB19e27IusAsZmwCtWP
# GwY25miPygY44vf5MA0GCSqGSIb3DQEBAQUABIIBAJEAuCxvurBZfvUa/oizvac9
# b8Ub/zA4g7DrtZC1iHFcHa+tRnGIniXirGxZqLLrLtCUeLeU4eAh4pKnWg/YxHjq
# 8M2Y+XvDwHrabYXMfR9qu/zXmLt27Q+3SagBVDoOhgaa3rWF7vg1Zkakafc6Trpl
# whS5nXoZUeZWU5YaekJ2PJGjenxQQQiW2kwLY1B7P8rYsmXsRTjXWk2Hv4CO/Jln
# fIsqosd/fGHYPt+GHAe859/0ccmDAWYj6X3RzOEwVI2wZbVUi2uS0gNH3A4nzYCb
# napGYglurmV6+gEXrP1xw15WTzpajOB/oPWKEcwhS4jntzQGMcCcfNbKfCDnU7Y=
# SIG # End signature block
