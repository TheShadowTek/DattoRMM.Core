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

        The audit data can be retrieved by device UID or MAC address. When querying by MAC address,
        if multiple devices share the same MAC address, the function will use the MAC address
        endpoint to retrieve all matching devices.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of the device to audit. Accepts pipeline input from Get-RMMDevice.

    .PARAMETER MacAddress
        The MAC address of the device to audit. Accepts formats: 001122334455, 00:11:22:33:44:55, or 00-11-22-33-44-55.

    .PARAMETER Software
        Include installed software inventory in the audit results. When specified without -Software,
        the Software property will be null. Use Get-RMMDeviceSoftware for software-only queries.

    .EXAMPLE
        Get-RMMDevice -Hostname "SERVER01" | Get-RMMDeviceAudit

        Retrieves audit information for SERVER01.

    .EXAMPLE
        Get-RMMDeviceAudit -DeviceUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

        Retrieves audit information for a specific device by UID.

    .EXAMPLE
        Get-RMMDeviceAudit -DeviceUid $device.Uid -Software

        Retrieves complete audit information including all installed software.

    .EXAMPLE
        Get-RMMDeviceAudit -MacAddress "00:11:22:33:44:55"

        Retrieves audit information using the device's MAC address.

    .EXAMPLE
        Get-RMMDevice -FilterId 12345 | Get-RMMDeviceAudit | Where-Object {$_.SystemInfo.TotalPhysicalMemory -lt 8GB}

        Gets audit data for filtered devices and finds those with less than 8GB RAM.

    .EXAMPLE
        $Audit = Get-RMMDeviceAudit -DeviceUid $guid -Software
        $Audit.Software | Where-Object {$_.Name -like "*Office*"}

        Retrieves audit with software and filters for Microsoft Office installations.

    .INPUTS
        You can pipe objects with DeviceUid or MacAddress properties to this function.

    .OUTPUTS
        DRMMDeviceAudit. Returns a device audit object containing:
        - DeviceUid: The device's unique identifier
        - PortalUrl: Link to device in the Datto RMM portal
        - SystemInfo: Manufacturer, model, memory, CPU cores
        - Bios: BIOS information
        - BaseBoard: Motherboard information
        - Nics: Network interface details
        - Processors: CPU information
        - PhysicalMemory: RAM module details
        - LogicalDisks: Disk partition information
        - Displays: Monitor information
        - VideoBoards: Graphics card details
        - AttachedDevices: Connected peripherals
        - SnmpInfo: SNMP details (for network devices)
        - MobileInfo: Cellular information (for mobile devices)
        - Software: Installed applications (only if -Software specified)

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        The -Software switch can significantly increase response time and data size for devices
        with many installed applications. Use Get-RMMDeviceSoftware if you only need software inventory.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Get-RMMDeviceAudit.md
        
    .LINK
        about_DRMMDevice

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMDeviceSoftware
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByDeviceUid')]
    param (
        [Parameter(
            ParameterSetName = 'ByDeviceUid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [guid]
        $DeviceUid,

        [Parameter(
            ParameterSetName = 'ByMacAddress',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateScript({
            $Normalized = $_ -replace '[:\-\.]', ''
            
            if ($Normalized -match '^[0-9A-Fa-f]{12}$') {

                $true

            } else {

                throw "Invalid MAC address format. Expected 12 hexadecimal characters (e.g., 001122334455, 00:11:22:33:44:55, or 00-11-22-33-44-55)"

            }
        })]
        [string]
        $MacAddress,

        [Parameter(ParameterSetName = 'ByDeviceUid')]
        [Parameter(ParameterSetName = 'ByMacAddress')]
        [switch]
        $Software
    )

    process {

        Write-Debug "Getting RMM device audit using parameter set: $($PSCmdlet.ParameterSetName)"

        # If MacAddress is provided, check if we need to resolve to DeviceUid
        if ($PSCmdlet.ParameterSetName -eq 'ByMacAddress') {

            Write-Debug "Looking up device by MAC address: $MacAddress"
            $Device = Get-RMMDevice -MacAddress $MacAddress

            if (-not $Device) {

                Write-Error "No device found with MAC address: $MacAddress"
                return

            }

            # Handle multiple devices with same MAC address
            if ($Device -is [array] -and $Device.Count -gt 1) {

                Write-Warning "Multiple devices found with MAC address $MacAddress. Using MAC address API endpoint."
                $UseMacAddressApi = $true

            } else {

                $DeviceUid = $Device.Uid
                $UseMacAddressApi = $false

            }

        }

        # Get the device audit data
        if ($UseMacAddressApi) {

            # Normalize MAC address by removing separators
            $NormalizedMacAddress = $MacAddress -replace '[:\-\.]', ''
            
            $APIMethod = @{
                Path = "audit/device/macAddress/$NormalizedMacAddress"
                Method = 'Get'
            }

            Write-Debug "Getting device audit for MAC address: $NormalizedMacAddress"
            $Response = Invoke-APIMethod @APIMethod

            $Audit = [DRMMDeviceAudit]::FromAPIMethod($Response)
            # DeviceUid remains null when using MAC address API

        } else {

            $APIMethod = @{
                Path = "audit/device/$DeviceUid"
                Method = 'Get'
            }

            Write-Debug "Getting device audit for DeviceUid: $DeviceUid"
            $Response = Invoke-APIMethod @APIMethod

            $Audit = [DRMMDeviceAudit]::FromAPIMethod($Response)
            $Audit.DeviceUid = $DeviceUid

        }

        # If Software switch is present, get software data
        if ($Software) {

            if ($UseMacAddressApi) {

                Write-Warning "Cannot retrieve software data when multiple devices share the same MAC address. DeviceUid is required."

            } else {

                Write-Debug "Getting software data for DeviceUid: $DeviceUid"
                $SoftwareData = Get-RMMDeviceSoftware -DeviceUid $DeviceUid
                $Audit.Software = $SoftwareData

            }

        }

        return $Audit

    }
}

