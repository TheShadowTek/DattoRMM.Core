<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '.\DRMMObject.psm1'
class DRMMNetworkInterface : DRMMObject {
    [string]$Instance
    [string]$Ipv4
    [string]$Ipv6
    [string]$MacAddress
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

