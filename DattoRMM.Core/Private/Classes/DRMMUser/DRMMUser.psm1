<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '..\DRMMObject\DRMMObject.psm1'
<#
.SYNOPSIS
    Represents a user in the DRMM system, including properties such as first name, last name, username, email, telephone, status, creation date, last access date, and disabled status.
.DESCRIPTION
    The DRMMUser class models a user within the DRMM platform, encapsulating properties such as FirstName, LastName, Username, Email, Telephone, Status, Created, LastAccess, and Disabled. The class provides a constructor and a static method to create an instance from API response data. The FromAPIMethod static method takes a response object, extracts the relevant information, and populates the properties of the DRMMUser instance accordingly. The class also includes methods to generate a full name for the user and to provide a summary of the user's information, including their username and disabled status. The DRMMUser class serves as a representation of users within the DRMM system, allowing for easy access to user information and status details.
#>
class DRMMUser : DRMMObject {

    # The first name of the user.
    [string]$FirstName
    # The last name of the user.
    [string]$LastName
    # The username of the user.
    [string]$Username
    # The email address of the user.
    [string]$Email
    # The telephone number of the user.
    [string]$Telephone
    # The current status of the user.
    [string]$Status
    # The creation date of the user.
    [Nullable[datetime]]$Created
    # The last access date of the user.
    [Nullable[datetime]]$LastAccess
    # Indicates whether the user is disabled.
    [bool]$Disabled

    DRMMUser() : base() {

    }

    static [DRMMUser] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $User = [DRMMUser]::new()
        $User.FirstName = $Response.firstName
        $User.LastName = $Response.lastName
        $User.Username = $Response.username
        $User.Email = $Response.email
        $User.Telephone = $Response.telephone
        $User.Status = $Response.status
        $User.Disabled = $Response.disabled

        $User.Created = [DRMMObject]::ParseApiDateTime($Response.created)
        $User.LastAccess = [DRMMObject]::ParseApiDateTime($Response.lastAccess)

        return $User

    }

    <#
    .SYNOPSIS
        Generates the full name of the user by combining the first name and last name.
    .DESCRIPTION
        The GetFullName method returns a string that combines the FirstName and LastName properties of the user to create a full name. The method trims any extra whitespace to ensure a clean output, even if one of the name components is missing.
    .OUTPUTS
        The full name of the user, which is a combination of the first name and last name.
    #>
    [string] GetFullName() {

        return "$($this.FirstName) $($this.LastName)".Trim()

    }

    <#
    .SYNOPSIS
        Generates a summary string for the user, including their full name, username, and disabled status.
    .DESCRIPTION
        The GetSummary method returns a string summarising the user's information, including their full name (constructed from the first and last name), username, and an indication of whether the user is disabled. If the user is disabled, the summary will include "(Disabled)" next to the username for clarity.
    .OUTPUTS
        A summary string that includes the full name, username, and disabled status of the user.
    #>
    [string] GetSummary() {

        $FullName = $this.GetFullName()
        $StatusText = if ($this.Disabled) {" (Disabled)"} else {""}

        return "$FullName ($($this.Username))$StatusText"

    }
}
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB9KcvbWHiyTgfd
# mK/rW6S4mlOrlPGj58uCb8yIuOoJzaCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICnonUuKZUlTui/2HNSNdB2McSss
# hGfPlW7atRXh3REzMA0GCSqGSIb3DQEBAQUABIIBAEwhYVQ8qXYS1ebvf2mr2Oru
# Hpa/deoqRED6ftecfES7rgI1PFeP2enf0ALmp8LEhhMg13bp4zL8Pl54uEOY1YuL
# iyo78QrNAgj4jqDUe9uvXyix4PwEo42Ax3vODOVvFgYqgsaf9sObLD3iY0vIEuIP
# 6CFJ9k97mnv6zmbw5p7iO3X/c/UjO1QyhDFAhv8m6EB64hslR9ig0DIni+tdDmcE
# BaAJHOkJWAXebhnYDEceZR5jl4NAm0IEYT0kOSpdY6wXCdUYHARGIhXbslq+0P07
# lZAz8N2QL6L/m6Gsa5ApZlfwQJq2C6pFKCHCZN1K7eD91aVo2i5ukLlDIrwB4QY=
# SIG # End signature block
