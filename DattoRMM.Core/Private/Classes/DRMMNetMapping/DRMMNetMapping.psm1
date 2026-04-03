<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '..\DRMMObject\DRMMObject.psm1'
<#
.SYNOPSIS
    Represents a network mapping in the DRMM system, including properties such as name, unique identifier, description, associated network IDs, and portal URL.
.DESCRIPTION
    The DRMMNetMapping class models a network mapping within the DRMM platform. It includes properties such as Id, Uid, AccountUid, Name, Description, DatatoNetworkingNetworkIds, and PortalUrl. The class provides a constructor and a static method to create an instance from API response data. Additionally, it includes a method to open the portal URL associated with the network mapping in the default web browser. The class serves as a representation of network mappings within the DRMM system, allowing for easy access and management of network mapping information.
#>
class DRMMNetMapping : DRMMObject {

    # The identifier of the network mapping.
    [long]$Id
    # The unique identifier (UID) of the network mapping.
    [guid]$Uid
    # The unique identifier (UID) of the account.
    [string]$AccountUid
    # The name of the network mapping.
    [string]$Name
    # The description of the network mapping.
    [string]$Description
    # The network IDs associated with Datto Networking.
    [long[]]$DatatoNetworkingNetworkIds
    # The URL of the portal.
    [string]$PortalUrl

    DRMMNetMapping() : base() {

        $this.DatatoNetworkingNetworkIds = @()

    }

    static [DRMMNetMapping] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $NetMapping = [DRMMNetMapping]::new()
        $NetMapping.Id = $Response.id
        $NetMapping.Uid = $Response.uid
        $NetMapping.AccountUid = $Response.accountUid
        $NetMapping.Name = $Response.name
        $NetMapping.Description = $Response.description
        $NetMapping.PortalUrl = $Response.portalUrl
        
        if ($Response.dattoNetworkingNetworkIds) {

            $NetMapping.DatatoNetworkingNetworkIds = $Response.dattoNetworkingNetworkIds

        }

        return $NetMapping

    }

    <#
    .SYNOPSIS
        Opens the portal URL associated with the network mapping in the default web browser.
    .DESCRIPTION
        The OpenPortal method checks if the PortalUrl property is set for the network mapping. If it is available, it launches the URL in the default web browser using the Start-Process cmdlet. If the PortalUrl is not set, it issues a warning indicating that the portal URL is not available for the network mapping.
    .OUTPUTS
        This method does not return a value. It performs an action to open the portal URL in the default web browser.
    #>
    [void] OpenPortal() {

        if ($this.PortalUrl) {

            Start-Process $this.PortalUrl

        } else {

            Write-Warning "Portal URL is not available for network mapping $($this.Name)"

        }
    }
}
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDcP8ewKV0Q9JiG
# JgFfynEtjnNYKhuhCi63PL/3WGJGt6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGMO8Tj2JAeHIEPTVF39Y/Vem8QS
# +jUCXns7923dnz7XMA0GCSqGSIb3DQEBAQUABIIBAIxfOJoKHhdPWXMt35gOUBFl
# BStAiK5FLo9NBZ9VdjBHbQGmwotfi9sL14ySRwihCvDJ6Ov1qEeEiFMCdabRhVrH
# Gwz3jg0my4Wo+gFVqpqIiPdgDBzbf2dO+NE1WPH5/LKjvZp+Y+4pQsYTbW7r62wM
# b91DEpaflLK+GUqypG52jOiVw43jtM6Y7+cWY2W6KiF+iTckUdAzkAKC9PJ22xDb
# wIWt2c5m9bCLwgQx2+TS+e0d8rWZOC73HF4Ghp+gONizGveQu5uBzvARZ82ulwRv
# NqM1jWvEoMP98UsPQpgJCg9DqRRkT4w3txllxIvmw2LWpbRPVhf90WNjfenfIpA=
# SIG # End signature block
