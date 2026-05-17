<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMUser {
    <#
    .SYNOPSIS
        Retrieves user accounts from the Datto RMM API.

    .DESCRIPTION
        The Get-RMMUser function retrieves all user accounts in the Datto RMM system. This
        includes user information such as email addresses, phone numbers, roles, and access levels.

    .EXAMPLE
        Get-RMMUser

        Retrieves all users after confirmation.

    .EXAMPLE
        Get-RMMUser | Where-Object {$_.Role -eq 'Administrator'}

        Retrieves all administrator users.

    .EXAMPLE
        Get-RMMUser | Select-Object Name, Email, Role

        Retrieves all users and displays selected properties.

    .EXAMPLE
        $Users = Get-RMMUser
        PS > $Users | Group-Object Role | Select-Object Name, Count | Format-Table -AutoSize

        Retrieves users and groups them by role to show user counts per role.

    .INPUTS
        None. You cannot pipe objects to Get-RMMUser.

    .OUTPUTS
        DRMMUser. Returns user objects with the following properties:
        - Id: User numeric ID
        - Uid: User unique identifier
        - Name: User full name
        - Email: User email address
        - Phone: User phone number
        - Role: User role/permission level
        - Enabled: Whether the user account is active
        - LastLogin: Last login timestamp

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMUser.md

    .LINK
        Connect-DattoRMM
    #>
    [CmdletBinding()]

    param ()

    Write-Debug "Getting RMM users"

    $APIMethod = @{
        Path = 'account/users'
        Method = 'Get'
        Paginate = $true
        PageElement = 'users'
    }

    Write-Debug "Getting all account users"

    Invoke-ApiMethod @APIMethod | ForEach-Object {

        [DRMMUser]::FromAPIMethod($_)

    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBCyVoeMDPgruQV
# 2euZGvgRnqJ0CunrqeYucsW0QOPBQqCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHGVpguBLpMdamVtHzpt0jTBRhpZ
# z5451W6M/nfNmrKiMA0GCSqGSIb3DQEBAQUABIIBAEsqrZE5FkXIm/1WzfLGTi2c
# 5hg94bzqyDvk1vHr+hFxi2zmMB8ItSHotnSAUACcD0rY9bWUqLr0K2cGGqCPQibM
# O5niDSITjkMefEWtboxPfUO6rOWzECcv2QzDlXnLpoNcb/Y1sqq5kl2hnZYqqeFe
# EoZYcGKxgE1Jv1tjwOFmqBvUAT2ueYmkcYwUJzB+k0W2+eDj+vigwgK2FLwoWnO9
# 8/pOHbz0gMLgo6KRd5AkQGwNKqB4TcXLPjTZtrrd6LlWVcKQUPF3UagdPwYrkmh/
# z9CHrL2Q3LqZ9kaV7nHKDvPwr8zDTMOkxT4Lg4OJe4fOrfobSOUumI8PeVaAdvk=
# SIG # End signature block
