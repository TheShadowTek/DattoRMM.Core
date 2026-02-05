<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMDeviceSoftware {
    <#
    .SYNOPSIS
        Retrieves installed software for a specific device.

    .DESCRIPTION
        The Get-RMMDeviceSoftware function retrieves a list of all installed software applications
        on a specific device. This includes installed programs, Windows updates, and other software
        components detected by the Datto RMM agent.

        This function requires a DeviceUid and is typically used after retrieving devices with
        Get-RMMDevice or Get-RMMDeviceAudit.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of the device to retrieve software for. Accepts pipeline
        input from Get-RMMDevice.

    .EXAMPLE
        Get-RMMDevice -DeviceId 12345 | Get-RMMDeviceSoftware

        Retrieves all installed software for device 12345.

    .EXAMPLE
        $Device = Get-RMMDevice -Name "SERVER01"
        PS > Get-RMMDeviceSoftware -DeviceUid $Device.Uid

        Retrieves a device by name and then gets its installed software.

    .EXAMPLE
        Get-RMMDevice -FilterId 100 | Get-RMMDeviceSoftware | Where-Object {$_.Name -like "*Microsoft*"}

        Gets all devices matching filter 100 and retrieves their installed Microsoft software.

    .EXAMPLE
        $Software = Get-RMMDevice -DeviceId 12345 | Get-RMMDeviceSoftware
        PS > $Software | Select-Object Name, Version, Publisher | Format-Table

        Retrieves software and displays it in a formatted table.

    .EXAMPLE
        Get-RMMDevice -DeviceId 12345 | Get-RMMDeviceSoftware | 
            Group-Object Publisher | Select-Object Name, Count | Sort-Object Count -Descending

        Retrieves software and groups by publisher to see which vendors have the most applications installed.

    .INPUTS
        System.Guid. You can pipe DeviceUid from Get-RMMDevice.
        DRMMDevice. You can pipe device objects from Get-RMMDevice.

    .OUTPUTS
        DRMMDeviceAuditSoftware. Returns software objects with the following properties:
        - Name: Application name
        - Version: Application version
        - Publisher: Software publisher/vendor
        - InstallDate: Date installed (if available)
        - InstallLocation: Installation path
        - UninstallString: Uninstall command
        - Size: Installed size in bytes

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        The software inventory is collected by the Datto RMM agent during regular audit cycles.
        Results may not be real-time if the device is offline or hasn't reported recently.

    .LINK
        about_DRMMDevice

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMDeviceAudit
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [guid]
        $DeviceUid
    )

    process {

        Write-Debug "Getting RMM device software for DeviceUid: $DeviceUid"

        $APIMethod = @{
            Path = "audit/device/$DeviceUid/software"
            Method = 'Get'
            Paginate = $true
            PageElement = 'software'
        }

        Invoke-APIMethod @APIMethod | ForEach-Object {

            [DRMMDeviceAuditSoftware]::FromAPIMethod($_)

        }
    }
}

