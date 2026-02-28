<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMDeviceAudit {
    <#
    .SYNOPSIS
        Retrieves detailed audit information for a device.

    .DESCRIPTION
        The Get-RMMDeviceAudit function retrieves comprehensive hardware and software inventory
        information for a managed device. This includes system information, BIOS details, network
        interfaces, processors, memory, disks, displays, and optionally installed software.

        When a DRMMDevice object is piped in, the function inspects the DeviceClass property and
        automatically routes to the correct audit endpoint. ESXi hosts are routed to
        Get-RMMEsxiHostAudit, printers are routed to Get-RMMPrinterAudit, and all other device
        classes (device, rmmnetworkdevice, unknown) use the standard device audit endpoint.

    .PARAMETER Device
        A DRMMDevice object to retrieve audit data for. Accepts pipeline input from Get-RMMDevice.
        The DeviceClass property determines which audit endpoint is used.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of the device to audit.

    .PARAMETER Software
        Include installed software inventory in the audit results. When not specified, the Software
        property will be null. Only applies to standard device audits. Use Get-RMMDeviceSoftware
        for software-only queries.

    .EXAMPLE
        Get-RMMDevice -Hostname "SERVER01" | Get-RMMDeviceAudit

        Retrieves audit information for SERVER01. Routes to the correct audit endpoint based on
        the device's DeviceClass.

    .EXAMPLE
        Get-RMMDeviceAudit -DeviceUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

        Retrieves device audit information for a specific device by UID.

    .EXAMPLE
        Get-RMMDeviceAudit -DeviceUid $device.Uid -Software

        Retrieves complete audit information including all installed software.

    .EXAMPLE
        Get-RMMDevice -FilterId 12345 | Get-RMMDeviceAudit | Where-Object {$_.SystemInfo.TotalPhysicalMemory -lt 8GB}

        Gets audit data for filtered devices and finds those with less than 8GB RAM. ESXi hosts
        and printers in the results are automatically routed to their respective audit endpoints.

    .EXAMPLE
        $Audit = Get-RMMDeviceAudit -DeviceUid $guid -Software
        $Audit.Software | Where-Object {$_.Name -like "*Office*"}

        Retrieves audit with software and filters for Microsoft Office installations.

    .INPUTS
        DRMMDevice. You can pipe device objects from Get-RMMDevice.

    .OUTPUTS
        DRMMDeviceAudit. Returns a device audit object when DeviceClass is device, rmmnetworkdevice,
        or unknown.

        DRMMEsxiHostAudit. Returns an ESXi host audit object when DeviceClass is esxihost.

        DRMMPrinterAudit. Returns a printer audit object when DeviceClass is printer.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        When piping DRMMDevice objects, the DeviceClass property determines routing:
        - esxihost: Routes to Get-RMMEsxiHostAudit
        - printer: Routes to Get-RMMPrinterAudit
        - device, rmmnetworkdevice, unknown: Uses the standard device audit endpoint

        The -Software switch can significantly increase response time and data size for devices
        with many installed applications. Use Get-RMMDeviceSoftware if you only need software inventory.

        The -Software switch is only applicable to standard device audits. When the Device parameter
        routes to an ESXi or printer audit endpoint, the -Software switch is ignored.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Get-RMMDeviceAudit.md

    .LINK
        about_DRMMDevice

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMDeviceSoftware

    .LINK
        Get-RMMEsxiHostAudit

    .LINK
        Get-RMMPrinterAudit
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
        $DeviceUid,

        [Parameter(ParameterSetName = 'Device')]
        [Parameter(ParameterSetName = 'DeviceUid')]
        [switch]
        $Software
    )

    process {

        Write-Verbose "Getting device audit with parameter set: $($PSCmdlet.ParameterSetName)"

        # Route based on parameter set
        switch ($PSCmdlet.ParameterSetName) {

            'Device' {

                $DeviceUid = $Device.Uid

                # Route to the correct audit function based on device class
                switch ($Device.DeviceClass) {

                    'esxihost' {

                        Write-Verbose "Device '$($Device.Hostname)' is an ESXi host — routing to Get-RMMEsxiHostAudit"

                        if ($Software) {

                            Write-Warning "The -Software switch is not applicable to ESXi host audits and will be ignored."

                        }

                        Get-RMMEsxiHostAudit -DeviceUid $DeviceUid
                        return

                    }

                    'printer' {

                        Write-Verbose "Device '$($Device.Hostname)' is a printer — routing to Get-RMMPrinterAudit"

                        if ($Software) {

                            Write-Warning "The -Software switch is not applicable to printer audits and will be ignored."

                        }

                        Get-RMMPrinterAudit -DeviceUid $DeviceUid
                        return

                    }

                    default {

                        Write-Verbose "Device '$($Device.Hostname)' has device class '$($Device.DeviceClass)' — using standard device audit"

                    }
                }
            }

        }

        # Standard device audit path (Device default or DeviceUid)
        $APIMethod = @{
            Path = "audit/device/$DeviceUid"
            Method = 'Get'
        }

        Write-Debug "Getting device audit for DeviceUid: $DeviceUid"
        $Response = Invoke-APIMethod @APIMethod

        $Audit = [DRMMDeviceAudit]::FromAPIMethod($Response)
        $Audit.DeviceUid = $DeviceUid

        # Retrieve software data if requested
        if ($Software) {

            Write-Debug "Getting software data for DeviceUid: $DeviceUid"
            $SoftwareData = Get-RMMDeviceSoftware -DeviceUid $DeviceUid
            $Audit.Software = $SoftwareData

        }

        return $Audit

    }
}

