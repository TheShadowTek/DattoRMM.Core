<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMAccount {
    <#
    .SYNOPSIS
        Retrieves information about the authenticated Datto RMM account.

    .DESCRIPTION
        The Get-RMMAccount function retrieves detailed information about the currently authenticated
        Datto RMM account, including account details, device statistics, and configuration settings.

        The returned object includes:
        - Account ID and name
        - Currency settings
        - Account descriptor (billing email, device limit, timezone)
        - Device status statistics (total, online, offline, on-demand, managed)

    .EXAMPLE
        Get-RMMAccount

        Retrieves information about the authenticated account.

    .EXAMPLE
        $Account = Get-RMMAccount
        PS > $Account.Name
        PS > $Account.DevicesStatus

        Retrieves account information and displays specific properties.

    .EXAMPLE
        $Account = Get-RMMAccount
        PS > $Account.GetSummary()

        Retrieves account information and displays a summary using the built-in method.

    .EXAMPLE
        Get-RMMAccount | Select-Object Name, Currency, @{N='OnlineDevices';E={$_.DevicesStatus.NumberOfOnlineDevices}}

        Retrieves account information and displays selected properties including online device count.

    .INPUTS
        None. You cannot pipe objects to Get-RMMAccount.

    .OUTPUTS
        DRMMAccount. Returns an account object with the following properties:
        - Id (int): Account ID
        - Uid (string): Account unique identifier
        - Name (string): Account name
        - Currency (string): Currency code
        - Descriptor (DRMMAccountDescriptor): Billing email, device limit, timezone
        - DevicesStatus (DRMMAccountDevicesStatus): Device count statistics

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        The DevicesStatus property includes a GetSummary() method that returns a formatted
        string showing online/total devices and percentage.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMAccount.md

    .LINK
        Connect-DattoRMM

    .LINK
        Get-RMMDevice

    .LINK
        about_DRMMAccount
    #>

    [CmdletBinding()]
    param ()

    begin {

        # Validate connection
        if (-not $Script:RMMAuth) {

            throw 'Not authenticated. Please use Connect-DattoRMM first.'

        }
    }

    process {

        # Retrieve account information
        $Response = Invoke-ApiMethod -Path 'account' -Method GET

        [DRMMAccount]::FromAPIMethod($Response)

    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCPNm57y8/naNAP
# 1FTyHYgy1BGlPfMqYH0pVaprSEB8oaCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOZBGskUeqpKB2cNsRX3SwXndib5
# xLSj28luQRRotBTgMA0GCSqGSIb3DQEBAQUABIIBAF40h34XW0YmHdZcKjiCFVP5
# cY9T2Vp0WLCIoPij80J8qUW+1Q9oRV/H81LpzICK3viWkzDxZb36k6yWbdRHjNuq
# gc6TlDiFaPOtYo7VLm/YMXwC5F81yaMqXnzbHrb698R3gZNt7mjqQZPupmIO5K1c
# 7RY74hu4b973u8YbcMScw+1kg8wkkzuiJxpA68QLEoQi32FhbkZ60Dbb/HTG/aU5
# RknP1CeyLmc4joAexOO1+0D8e0SEzb0tI4UFRVMp8lOmqubnDMohdqcqb/q+wdKb
# 5lBVeX9NvbgoyN1enhltn1jk1vy0l2liqVaw74nlz70NzqtNWgZg8B5Ry+EuPGQ=
# SIG # End signature block
