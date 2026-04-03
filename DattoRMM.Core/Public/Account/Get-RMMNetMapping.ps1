<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMNetMapping {
    <#
    .SYNOPSIS
        Retrieves Datto Networking site mappings.

    .DESCRIPTION
        The Get-RMMNetMapping function retrieves the mapping between Datto RMM sites and
        Datto Networking sites. This mapping is used to associate RMM-managed devices with
        their corresponding Datto Networking configurations.

        Datto Networking provides network management capabilities, and this function helps
        correlate RMM sites with their network infrastructure.

    .EXAMPLE
        Get-RMMNetMapping

        Retrieves all Datto Networking site mappings for the account.

    .EXAMPLE
        $Mappings = Get-RMMNetMapping
        PS > $Mappings | Select-Object SiteName, NetworkSiteName

        Retrieves all mappings and displays the site names from both systems.

    .EXAMPLE
        Get-RMMNetMapping | Where-Object {$_.SiteUid -eq $MySiteUid}

        Retrieves the Datto Networking mapping for a specific RMM site.

    .EXAMPLE
        Get-RMMNetMapping | Format-Table SiteName, NetworkSiteName, Status

        Retrieves all mappings and displays them in a formatted table.

    .INPUTS
        None. You cannot pipe objects to Get-RMMNetMapping.

    .OUTPUTS
        DRMMNetMapping. Returns mapping objects with the following properties:
        - Uid: Mapping unique identifier
        - SiteUid: Datto RMM site identifier
        - SiteName: Datto RMM site name
        - NetworkSiteUid: Datto Networking site identifier
        - NetworkSiteName: Datto Networking site name
        - Status: Mapping status

    .NOTES

        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        This function is only relevant if your account uses Datto Networking.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMNetMapping.md

    .LINK
        about_DRMMNetMapping
    #>
    [CmdletBinding()]
    param ()

    process {

        Write-Debug "Getting RMM Datto Networking site mappings"

        $APIMethod = @{
            Path = 'account/dnet-site-mappings'
            Method = 'Get'
            Paginate = $true
            PageElement = 'dnetSiteMappings'
        }

        Invoke-ApiMethod @APIMethod | Where-Object {try {[void][guid]$_.uid; $true} catch {$false}} | ForEach-Object {

            [DRMMNetMapping]::FromAPIMethod($_)

        }
    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD5p2hmrlZbMXYz
# fP+NuvN3/UTJQZvI8+n2Xkn+GKZjUqCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDYXlP3qBRuYjTwSG/l7sYtTC6nX
# KPx1bp8nSsbDjP9kMA0GCSqGSIb3DQEBAQUABIIBAFYFGRU+RMtv6hf9kCrkTjbz
# YGUIuXGkNC4LK0R+GoVumW92E1twOZbaQbsjlYW3oG8xMSSHUzYI0y1o6xxXlDhM
# 5iTZD5Sy77PitnZT8gGsa+xiCjMufJI/vON3gIUqM2D3j657zv1BiN7OoWp4yyZl
# qDSrGvyCt6B0yOUAQkB17gEKyrW3LVIvhCXMrGSNoTHdsYwJHvENtbKlaS5rfyu4
# 20a7HPRjl7JcN51L06FtGXZRn4JCV6ipMM3EL7Jj1OBSbSZBxnmkDtfPxd9Ai+qA
# 52lD/4b7Kpgem7JuZJyAMIus1QCUYsungcM4DjABQxH2g18RomZck7dZbqRxALE=
# SIG # End signature block
