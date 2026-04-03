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