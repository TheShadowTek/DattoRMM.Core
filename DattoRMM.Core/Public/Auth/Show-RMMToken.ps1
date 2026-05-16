<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Show-RMMToken {
    <#
    .SYNOPSIS
        Displays the current Datto RMM API token and authentication details.

    .DESCRIPTION
        Shows the contents of $Script:RMMAuth, including the access token, expiry, and other details.
        WARNING: The access token is sensitive. Do not share or publish this information.

    .NOTES
        This command requires confirmation and has ConfirmImpact set to High.

    .EXAMPLE
        Show-RMMToken
        Displays the current API token and related details.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Show-RMMToken.md

    .LINK
        Connect-DattoRMM

    .LINK
        Disconnect-DattoRMM

    .LINK
        about_DattoRMM.CoreAuthentication
    #>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param()

    Write-Warning "The following token is sensitive. Do not share or publish!"

    if ($PSCmdlet.ShouldProcess("console", "Show API Token")) {

        if ($null -eq $Script:RMMAuth) {

            throw "No authentication token found. Please connect first."

        } else {

            Write-Host "`nCurrent Datto RMM API Authentication Token:"
            Write-Host "-----------------------------------------------"
            Write-host "Access Token : $($Script:RMMAuth.AccessToken)"
            Write-host "Token Type : $($Script:RMMAuth.TokenType)"
            if ($Script:RMMAuth.ExpiresAt -eq [datetime]::new([datetime]::MaxValue.Ticks, [System.DateTimeKind]::Utc)) {

                Write-Host "Expires At : No Expiry (API Token)"

            } else {

                Write-Host "Expires At : $($Script:RMMAuth.ExpiresAt.ToLocalTime()) (UTC: $($Script:RMMAuth.ExpiresAt.ToString('HH:mm:ss')))"

            }        
        
        }
    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAN8Q1StgWqjiDt
# lTCFReLwkvsynZK1ry4rjfR/Ss+QkKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICRIs/8jRVupBGNoIYoZvWumqaa8
# /TaxZpxBqapzLpRmMA0GCSqGSIb3DQEBAQUABIIBAHPSUEJx2zn7KdvxP+IAyIlC
# 6yh2NgIcNigcfRsrKfXxhI7ureN2W+y6jV9tpObWBZ2VcKxdAcqHANmL31IGSKAt
# ZbmZ3BC2QXAza3wVNioAjH0CzjXbOhdugE/3GrU1qSvR0DjDoAjB10xNjQ20OvHA
# TtHnle0EDAgqQK/IODAKNMtcJ9BwzLu16sRHAMhIycS4djGM4AfvVRsf0v3BTqua
# GH+RHJTNdOOgsSU+jPl/rfTxxVeF+NWGqncOsu17tzwuRvT9GwaBWpLrGSotvvch
# b8qIDBvypAISzphGUodZqaK8dMsQ8UUiMnjnjGlR4hjrD3jUIM+baJco2JKA7K0=
# SIG # End signature block
