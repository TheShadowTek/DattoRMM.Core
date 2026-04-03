<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMEsxiHostAudit {
    <#
    .SYNOPSIS
        Retrieves ESXi host audit data for a specific device.

    .DESCRIPTION
        The Get-RMMEsxiHostAudit function retrieves detailed VMware ESXi host information,
        including host configuration, virtual machines, storage, and hardware details.

        This audit data is collected by the Datto RMM agent from ESXi hosts and provides
        comprehensive information about the virtualization environment, including:
        - Host system information and configuration
        - Virtual machines and their status
        - Processor and memory details
        - Network adapters and configuration
        - Datastore information and capacity

        This function is called automatically by Get-RMMDeviceAudit when a piped DRMMDevice
        object has a DeviceClass of 'esxihost'. It can also be called directly with a Device
        object or DeviceUid.

    .PARAMETER Device
        A DRMMDevice object to retrieve ESXi audit data for. Accepts pipeline input from
        Get-RMMDevice.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of the ESXi host device to retrieve audit data for.

    .EXAMPLE
        Get-RMMDevice -Name "ESXI-HOST-01" | Get-RMMEsxiHostAudit

        Retrieves ESXi audit data for an ESXi host by name.

    .EXAMPLE
        Get-RMMEsxiHostAudit -DeviceUid "12067610-8504-48e3-b5de-60e48416aaad"

        Retrieves ESXi audit data using a specific device UID.

    .EXAMPLE
        $Audit = Get-RMMDevice -DeviceId 12345 | Get-RMMEsxiHostAudit
        PS > $Audit.Guests | Select-Object Name, PowerState, GuestOS

        Retrieves ESXi audit data and displays virtual machine information.

    .EXAMPLE
        $EsxiAudit = Get-RMMEsxiHostAudit -DeviceUid $DeviceUid
        PS > $EsxiAudit.Datastores | Where-Object {$_.FreeSpaceGB -lt 100}

        Retrieves ESXi audit data and finds datastores with less than 100GB free.

    .EXAMPLE
        Get-RMMDevice -FilterId 300 | Get-RMMEsxiHostAudit | 
            ForEach-Object {
                [PSCustomObject]@{
                    HostName = $_.SystemInfo.Hostname
                    TotalVMs = $_.Guests.Count
                    RunningVMs = ($_.Guests | Where-Object PowerState -eq 'poweredOn').Count
                }
            }

        Gets ESXi hosts and creates a summary showing host names and VM counts.

    .INPUTS
        DRMMDevice. You can pipe device objects from Get-RMMDevice.

    .OUTPUTS
        DRMMEsxiHostAudit. Returns ESXi audit objects with the following properties:
        - DeviceUid: Device unique identifier
        - SystemInfo: ESXi host system information (version, build, hostname)
        - Guests: Array of virtual machine objects with status and configuration
        - Processors: Processor information and specifications
        - Nics: Network adapter configuration
        - PhysicalMemory: Memory modules and capacity
        - Datastores: Storage datastore information and capacity

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        ESXi audit data is only available for devices identified as VMware ESXi hosts.
        The Datto RMM agent must have appropriate permissions to query the ESXi host.

        When piping a DRMMDevice object to Get-RMMDeviceAudit, devices with DeviceClass
        'esxihost' are automatically routed to this function.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Get-RMMEsxiHostAudit.md

    .LINK
        about_DRMMDevice

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMDeviceAudit
    #>
    [CmdletBinding(DefaultParameterSetName = 'DeviceUid')]
    param (
        [Parameter(
            ParameterSetName = 'Device',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMDevice]
        $Device,

        [Parameter(
            ParameterSetName = 'DeviceUid',
            Mandatory = $true
        )]
        [guid]
        $DeviceUid
    )

    process {

        Write-Verbose "Getting ESXi host audit with parameter set: $($PSCmdlet.ParameterSetName)"

        switch ($PSCmdlet.ParameterSetName) {

            'Device' {

                if ($Device.DeviceClass -ne 'esxihost') {

                    Write-Warning "Device '$($Device.Hostname)' has device class '$($Device.DeviceClass)', not 'esxihost'. Use Get-RMMDeviceAudit to route to the correct audit endpoint."
                    return

                }

                $DeviceUid = $Device.Uid

            }
        }

        Write-Debug "Getting ESXi host audit for DeviceUid: $DeviceUid"

        $APIMethod = @{
            Path = "audit/esxihost/$DeviceUid"
            Method = 'Get'
        }

        $Response = Invoke-ApiMethod @APIMethod

        if ($Response) {

            [DRMMEsxiHostAudit]::FromAPIMethod($Response, $DeviceUid)

        }
    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDLzzLiDO5GsYWS
# GgVymT8kTabNjuHIAqtS6Qnve1EzwaCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDBKeGMsq9L8zt5aRrHj7UGK40TU
# Ds9cFdvdsx7RdllAMA0GCSqGSIb3DQEBAQUABIIBAD5/iWQOKmc/u2TM26ENDfyx
# ClEAfBt7gVQPuyU3TKrBVvid75qUi0GcieKZa2DwxeU/8i32DgOq4A/AP8VXRZrP
# yUUI6hGGj2kUoi0vnSNEtd3/GzReAke9wuJm4ef/vNOb2GvEAZ0dQkckYbeCgVXg
# 7wGHpG1If9KWkEmo2pJGCE/ZoNrb3LhanzGu7qQsrLuNwMNYYAVYkAtCEh0Q/nsW
# 7Yhh3kQxLCudb3KASvl7iBXhlXemVY2DQOemg0AL9TzAbuHuKMwxjHp+e50SeTL9
# eIUDVq/S2+eYk/y0Rodnqq17zV5HbvD0GVqowySPORNjbf7eX0FbVMhS1AR4Ciw=
# SIG # End signature block
