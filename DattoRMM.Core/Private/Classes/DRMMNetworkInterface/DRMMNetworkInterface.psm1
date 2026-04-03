using module '..\DRMMObject\DRMMObject.psm1'

<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
#region DRMMNetworkInterface class
class DRMMNetworkInterface : DRMMObject {
    # region DRMMNetworkInterface class
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