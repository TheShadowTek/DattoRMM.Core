<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMComponent {
    <#
    .SYNOPSIS
        Retrieves all components (scripts/jobs) from the Datto RMM account.

    .DESCRIPTION
        The Get-RMMComponent function retrieves all components available in the authenticated
        user's Datto RMM account. Components are reusable scripts or automation jobs that can
        be executed on managed devices.

        Each component includes information about its variables (inputs and outputs), category,
        and whether it requires credentials to run.

    .EXAMPLE
        Get-RMMComponent

        Retrieves all components in the account.

    .EXAMPLE
        Get-RMMComponent | Where-Object {$_.Name -like "*PowerShell*"}

        Retrieves all components with "PowerShell" in the name.

    .EXAMPLE
        Get-RMMComponent | Where-Object {$_.CredentialsRequired -eq $true}

        Retrieves all components that require credentials to execute.

    .EXAMPLE
        $Component = Get-RMMComponent | Where-Object {$_.Name -eq "Get System Info"}
        PS > $Component.GetInputVariables()

        Gets a specific component and displays its input variables.

    .EXAMPLE
        Get-RMMComponent | Select-Object Name, Description, CategoryCode | Format-Table

        Retrieves all components and displays their name, description, and category in a table.

    .INPUTS
        None. This function does not accept pipeline input.

    .OUTPUTS
        DRMMComponent. Returns component objects with the following notable properties:
        - Uid: Unique identifier for the component
        - Name: Display name of the component
        - Description: Description of what the component does
        - CategoryCode: Category the component belongs to
        - CredentialsRequired: Whether credentials are required
        - Variables: Array of input and output variables

        The component object also includes helper methods:
        - GetVariable(name): Get a specific variable by name
        - GetInputVariables(): Get all input variables
        - GetOutputVariables(): Get all output variables

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Component/Get-RMMComponent.md

    .LINK
        about_DRMMComponent

    .LINK
        New-RMMQuickJob

    .LINK
        Get-RMMJob
    #>
    [CmdletBinding()]
    param ()

    # Retrieve all components with pagination
    $Components = Invoke-ApiMethod -Path 'account/components' -Method GET -Paginate -PageElement 'components'

    foreach ($Component in $Components) {

        [DRMMComponent]::FromAPIMethod($Component, $Script:SessionPlatform)

    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC06/tV0kPj50gr
# BQbE50/p0gKcQD4JMvVeL8ydj2yCHKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIK7dV/WhAAh4+gC2cOHwOlgACXds
# TRwvU+GYijo9UbXMMA0GCSqGSIb3DQEBAQUABIIBAIXJKk6Jccvc6A/K0lJJu86z
# 8BPueGI4i2s/EzH0N+HKZY3Hs4tftGmwx7VTDQhQxe8tbtUQmqgzomufcTehTctY
# r6NheGpBddxvYe8h/Jqwkqhh1cL5WNtEPojp0Msi2/tgyAZ9gDP9/WkHx70TqzGj
# aRsmln+1mPg0xEcpGxMZxde2Q1LHpvBvs6roSc0VwctzscYCsTcq/Znwu7LdGp8r
# NpOqZwAhJMcvikY9ykIyDhUR5kU7/ztFoz7QpTHEWRKp4XfWc9s9LHaG/w3rCjD0
# Pw7ENa0n2K9XMge009e8Hdd1BT0e0tNnEJ5idJ88Cx+uEmiyrRoM/+kwagHy0PY=
# SIG # End signature block
