<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '..\DRMMObject\DRMMObject.psm1'
#region DRMMNetworkInterface class
<#
.SYNOPSIS
    Represents a network interface attached to a device in the Datto RMM platform.
.DESCRIPTION
    The DRMMNetworkInterface class models network interface information returned as part of a device audit in the Datto RMM platform. It captures the instance identifier, IPv4 and IPv6 addresses, MAC address, and interface type. Instances are created from API responses via the static FromAPIMethod factory method and are typically used as elements within device audit network interface collections on DRMMDevice and DRMMDeviceAudit objects.
#>
class DRMMNetworkInterface : DRMMObject {
    [string]$Instance
    # The IPv4 address of the network interface.
    [string]$Ipv4
    # The IPv6 address of the network interface.
    [string]$Ipv6
    # The MAC address of the network interface.
    [string]$MacAddress
    # The type of the network interface.
    [string]$Type

    DRMMNetworkInterface() : base() {}

    static [DRMMNetworkInterface] FromAPIMethod([pscustomobject]$Response) {
        if ($null -eq $Response) { return $null }
        $Nic = [DRMMNetworkInterface]::new()
        $Nic.Instance = $Response.instance
        $Nic.Ipv4 = $Response.ipv4
        $Nic.Ipv6 = $Response.ipv6
        $Nic.MacAddress = $Response.macAddress
        $Nic.Type = $Response.type
        return $Nic
    }
}
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCHsvLx56Q98Lwk
# mQ2huhInWqseCJwAPIubGdLYvodUo6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKl263GGqUdwi9isoB/YJ52BE/r2
# d4eG7uvwap9at84pMA0GCSqGSIb3DQEBAQUABIIBAFBsbiwuiVMpfjS4tG1fdBWz
# molHWV91z+ijm1ALWLHSrDlnX1k5HkeiJXc0m0f2BLkydG+PLvqDV6Y3MCF2Qvlo
# qDTQCr2Zge4X6qE2kawGXwGwEe63knk0gkLtm5B9ONvcTRRZheBRzxE8leidLtLp
# apxfdsVgkjFEwCRKjpxrKBbZmwF2F19plR1UwKnoW6QQoT52tC9UEIs2LtvVsmDc
# yKCVU/fUIdpGt9lhiaYLYQ20BFPGUpenOD5hElw0Jc0f3cL3bvYcoDTix1p4Ny1+
# zY9cfGwqXUmgS27xoWC/TJ4AXYh/tgZElKd4RUfIYRrs82Z7DUlzL43JBNtDAEM=
# SIG # End signature block
