<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '..\DRMMObject\DRMMObject.psm1'
<#
.SYNOPSIS
    Represents an OAuth access token response from the Datto RMM API.
.DESCRIPTION
    The DRMMToken class encapsulates the OAuth token information returned by the Datto RMM authentication endpoint. It includes the access token (stored as a secure string), token type, expiration date, scope, and JWT identifier. This class provides a static method to create an instance from the API response object, ensuring the access token is securely stored and the expires_in value is converted to a DateTime for easier time-based operations.
#>
class DRMMToken : DRMMObject {

    # The OAuth access token, stored as a secure string to protect sensitive credential data.
    [securestring]$AccessToken
    # The type of the access token (e.g., Bearer).
    [string]$TokenType
    # The expiration date and time of the access token, calculated from the token lifetime at the point of creation.
    [datetime]$Expires
    # The OAuth scope granted by the access token.
    [string]$Scope
    # The unique JWT identifier for the access token.
    [string]$Jti

    DRMMToken() : base() {

    }

    static [DRMMToken] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Token = [DRMMToken]::new()
        $Token.AccessToken = ConvertTo-SecureString -String $Response.access_token -AsPlainText -Force
        $Response.access_token = $null # Clear plain text token from memory
        $Token.TokenType = $Response.token_type
        $Token.Expires = [datetime]::UtcNow.AddSeconds($Response.expires_in)
        $Token.Scope = $Response.scope
        $Token.Jti = $Response.jti

        return $Token

    }
}
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA/Fl9Q1iYbDxrI
# /cxN8t5tlebQeOKQH9Kcak9kIuhLy6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPmxG3KOXPCxgLci8Ag8OxmwbPEb
# L0CRSPvvavZCPa1zMA0GCSqGSIb3DQEBAQUABIIBAJqo64loI2h7KzHTAcrHTucD
# 4ed3DuE5TrYztHptCnp9CjDv7qAw2MJE1uST0cuJ7eZalrSiBNHV5tPZSF+D2P3m
# hsWZcdPRONqhDbHohcYXv1l8lLtbcKVXrJj3JIi4wB8xsbxLTSXEqv8zvoACXhLL
# h0+DzQ5dk+UNJwRzd1F4IwN+JGH6yxqPeC7UhBC9Dc7TfrkTVfzTIHOU7R+r/4Ka
# IAxjDvnuJwIdnlyPQrjpXzqAiz/k1fg33uH4176s5um2mpLcTcs2aC25jG/sZSTY
# dPFka/dN5/Kn1BVM4MDNnIaLUNjn+VZLDh+KeoEGin3344kSSOmVpRrFfSorroE=
# SIG # End signature block
