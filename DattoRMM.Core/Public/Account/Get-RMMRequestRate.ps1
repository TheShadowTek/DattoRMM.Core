<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMRequestRate {
    <#
    .SYNOPSIS
        Retrieves the current API request rate information for the Datto RMM account.

    .DESCRIPTION
        Get-RMMRequestRate connects to the Datto RMM API and retrieves information about the current request rate limits for the account. This includes details such as the maximum allowed requests per minute, the number of requests currently used, and the time until the request count resets.

        This information is useful for monitoring API usage and ensuring that your applications stay within the allowed limits to avoid throttling.

    .EXAMPLE
        Get-RMMRequestRate

        Retrieves the current API request rate information for the connected Datto RMM account.

    .NOTES
        This function requires an active connection to the Datto RMM API. Use Connect-DattoRMM to authenticate before calling this function.

        The request rate information is returned as a custom object with properties such as MaxRequestsPerMinute, RequestsUsed, and TimeUntilReset.

        For more details on the API request rate limits, refer to the Datto RMM API documentation.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMRequestRate.md
    #>
    [CmdletBinding()]
    
    param ()

    if (-not $Script:RMMAuth) {

        throw "Not connected. Use Connect-DattoRMM first."

    }

    Write-Debug "Getting request rate information from Datto RMM API."
    $Headers = @{Authorization = "Bearer $($script:RMMAuth.AccessToken)"}
    $RequestParams = @{
        Uri = "$API/system/request_rate"
        Method = 'Get'
        Headers = $Headers
        TimeoutSec = $Script:ApiMethodRetry.TimeoutSeconds
    }

    if ($Script:RMMAuth.ContainsKey('Proxy')) {

        $RequestParams.Proxy = $Script:RMMAuth.Proxy

    }

    if ($Script:RMMAuth.ContainsKey('ProxyCredential')) {

        $RequestParams.ProxyCredential = $Script:RMMAuth.ProxyCredential
        
    }

    Invoke-RestMethod @RequestParams
    
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAxHotvCXYwc80p
# NWEAoChu4rKeDNQdneiOiBRRgN2pOKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHGQNX2apViOxsAVzlV5M9T+rS7G
# PiSDpWnUIKJWeteWMA0GCSqGSIb3DQEBAQUABIIBABIKBcQiFfvVYWkIrqd4+MjF
# u8/BwO4c0GIgjAgxAC4bgfe2BucxCxODizh2XCgOxaj+7Uydi1dIXXLoe5nPwsrN
# pkHP/u7P/GNjNStczPAJbxqwvVjXjRQGqFNxwRbQDLAZ7RE9e30tpZRegxGM4K1f
# FDT+69WSEitqsI+JE0rsdxs5MetYLLjCOMxlqvOmaJ+yOFiG81x48OURL7/SKffk
# Sol47BraHutufsomcGldERDBEHZulQJiqUjrDe6QFfiWf5IFMAtIzCNbae/eJqX4
# uBUoPX0JRLoMOs97D0p/i4QHxHhpcP/Wxb7U2BXh4NhnaM2Q+i+7PFEFHPjCIvY=
# SIG # End signature block
