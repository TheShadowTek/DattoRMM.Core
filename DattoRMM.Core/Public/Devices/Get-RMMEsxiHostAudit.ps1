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

        $Response = Invoke-APIMethod @APIMethod

        if ($Response) {

            [DRMMEsxiHostAudit]::FromAPIMethod($Response, $DeviceUid)

        }
    }
}

