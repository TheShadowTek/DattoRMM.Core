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
        This command requires confirmation and has ConfirmImpact set to Low.

    .EXAMPLE
        Show-RMMToken
        Displays the current API token and related details.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Show-RMMToken.md
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
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD8a6G6foDhDuDs
# B04Nb+aSKeKdCADXjaOuZWqlB355OqCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIObBdpgHRxWAdKO+GHP/2uiwhh5m
# s9d8E5hUoh8WHyTiMA0GCSqGSIb3DQEBAQUABIIBACwUpG4WDMRrBamevK4g+rTT
# R2GQwfj+4/OEw/vuP5zSVM4j6ucGM84ZnYDlrEdMaCe9Zf1iCqFWSteX1Pe3w4Kv
# IVl5qj/WMgv2tM9mZnGGpoITffcMJevudYNsKekPMxiMu+yaBpGRbT/9gZ44UL0K
# g06Ld3p2fNhydbt82Q5W+xA4Q7wSbwjrr3RlHE4e2N8+H3ERDO1V4Ph1AK4fD+/q
# WGp3PHZzGgW1OKbNJAejbSiyfCsEg4zJBY7m0l/r3PSV13SVAJNkGL1TSoqXhl4i
# VuwIGSeukITRACNc9G61HllMwMRCJSnFSMOevCNuu+2RdLSqpLp4jjsgcfmFF2A=
# SIG # End signature block
