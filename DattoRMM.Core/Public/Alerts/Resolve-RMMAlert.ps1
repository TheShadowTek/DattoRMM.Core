<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Resolve-RMMAlert {
    <#
    .SYNOPSIS
        Resolves a Datto RMM alert.

    .DESCRIPTION
        The Resolve-RMMAlert function marks an alert as resolved in Datto RMM.
        The alert is identified by its unique alert UID (GUID).

    .PARAMETER AlertUid
        The unique identifier (GUID) of the alert to resolve.
        This can be obtained from Get-RMMAlert or from the AlertUid property of an alert object.

    .PARAMETER Force
        Bypasses the confirmation prompt and immediately resolves the alert.

    .EXAMPLE
        Resolve-RMMAlert -AlertUid '12345678-1234-1234-1234-123456789012'

        Resolves the alert with the specified UID.

    .EXAMPLE
        Get-RMMAlert -Scope Global | Where-Object Priority -eq 'Critical' | Resolve-RMMAlert

        Resolves all critical global alerts with confirmation prompts.

    .EXAMPLE
        Get-RMMAlert -Scope Global | Where-Object Priority -eq 'Critical' | Resolve-RMMAlert -Force

        Resolves all critical global alerts without confirmation prompts.

    .EXAMPLE
        $Alert.Resolve()

        If $Alert is a DRMMAlert object, you can use its Resolve() method directly.

    .INPUTS
        System.Guid. You can pipe alert UIDs or alert objects (AlertUid property is extracted automatically) to this function.

    .OUTPUTS
        None. This function does not return any output on success.

    .NOTES
        Requires an active connection to the Datto RMM API (Connect-DattoRMM).
        
        The function will throw an error if:
        - Not connected to the API
        - Alert UID is invalid
        - User doesn't have permission to resolve the alert
        - Alert doesn't exist

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Alerts/Resolve-RMMAlert.md

    .LINK
        Get-RMMAlert

    .LINK
        about_DRMMAlert
    #>

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium',
        DefaultParameterSetName = 'Alert'
    )]

    param(
        [Parameter(
            ParameterSetName = 'Alert',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMAlert]
        $Alert,

        [Parameter(
            ParameterSetName = 'AlertUid',
            Mandatory = $true
        )]
        [guid]
        $AlertUid,

        [switch]
        $Force
    )

    process {

        if ($PSCmdlet.ParameterSetName -eq 'Alert') {

            $AlertUid = $Alert.AlertUid
            
        }

        $Target = "Alert: $AlertUid"

        if ($Force -or $PSCmdlet.ShouldProcess($Target, "Resolve alert")) {
            
            try {

                $APIMethod = @{
                    Path = "alert/$AlertUid/resolve"
                    Method = 'Post'
                }

                $null = Invoke-ApiMethod @APIMethod
                Write-Verbose "Successfully resolved alert: $AlertUid"

            } catch {

                Write-Error "Failed to resolve alert ${AlertUid}: $_"

            }
        }
    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAdjzcaD6tNaOFF
# w/psnU1cJv2xg3LiVRpAifGwG8uKKKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICTV9eg9uH/JO14oxIkrDnOSVCua
# Jh4u9QshgfPDN1YQMA0GCSqGSIb3DQEBAQUABIIBAFFJSn4L7z4zOzqEpOW2wuWP
# +14TfMb27XS2HJNbW7q2yF/k/7Z8ZSVo/x3AoiwCoDZeVKWcI9tSxole4PbcHsTZ
# MRHoFlwaae2HSjmiy4jFGG3rPLpxk0p0OtMACff/IXWgnabGZOwBXOhUk8ApeVjV
# melrpQ566uvzaBOug46lop8clnUd0bvPdSytcXPfQ3sa5V/USpg9wCeGlVYOPP4T
# hnmK6zpb32KiBssI6WSr86a56PSh9jgOXUrVVtE5uxA2LyFZTkjYhJ2HvkZh6obA
# UPOyRFq4JoBM66j4KvzFQvUFHG1+mArBgejjdqP/IKNCwx19IArjSjWkHsl9oqw=
# SIG # End signature block
