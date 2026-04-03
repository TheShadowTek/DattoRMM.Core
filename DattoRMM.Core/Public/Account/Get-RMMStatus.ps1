<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMStatus {
    <#
    .SYNOPSIS
        Retrieves the current status of the Datto RMM system.

    .DESCRIPTION
        The Get-RMMStatus function retrieves the operational status of the Datto RMM platform,
        including service availability and any system-wide issues or maintenance notifications.

        This function is useful for monitoring the health of the Datto RMM service and can be
        used in automation scripts to check service availability before performing operations.

    .EXAMPLE
        Get-RMMStatus

        Retrieves the current Datto RMM system status.

    .EXAMPLE
        $Status = Get-RMMStatus
        PS > if ($Status.IsOperational) {
        >>     Write-Host "System is operational"
        >> }

        Checks if the system is operational before proceeding.

    .EXAMPLE
        Get-RMMStatus | Select-Object Status, Message

        Retrieves system status and displays the status and any messages.

    .INPUTS
        None. You cannot pipe objects to Get-RMMStatus.

    .OUTPUTS
        DRMMStatus. Returns a status object with the following properties:
        - Status: Current system status
        - IsOperational: Boolean indicating if system is fully operational
        - Message: Any status messages or maintenance notifications
        - LastUpdated: Timestamp of status update

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Consider checking system status before running bulk operations or automated tasks.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMStatus.md

    .LINK
        about_DRMMStatus

    #>
    [CmdletBinding()]
    param ()

    process {

        Write-Debug "Getting RMM system status"

        $APIMethod = @{
            Path = 'system/status'
            Method = 'Get'
        }

        $Response = Invoke-ApiMethod @APIMethod
        [DRMMStatus]::FromAPIMethod($Response)

    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC06eM7rPdfpvUx
# K5R3IGkuwJByhPnJl5YAzpSuIpfvGKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIH+jTHPzLURvrBlrGpeM9vv1MOcE
# TsxcFc7CUE/0cFx7MA0GCSqGSIb3DQEBAQUABIIBAFn1kb0EeqBFnznnX3i0Ml69
# KdoZY1hju2o03tzEA4wRWg1RuEI6viX/PWWaM20V5TEjMXvxngsvdzk0k7YstnDj
# +eUkokrZI9ko0n95icDjzbkTblMnv/uknsJAtUR3EqMs+GL2nCCHrqoAithQ/EVV
# DZJRwjiBuiKELAJqAE/PdIhMcB+0jNWjAbf0c1uXbr8YnVHnJWcnUga15erbCVLi
# XwoaeqrnGG7JzW8T0WimNHhRyjnCglKpIwseOUPb9vmpjLZCUF/rwURIYSjyBCAh
# AUdWv5xfzWmLKNpV2sPSxO+xuzdrBYrIYR/cRZ+pEodJrcWgUrabgvQvJFUp0WA=
# SIG # End signature block
