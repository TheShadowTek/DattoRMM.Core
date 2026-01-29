<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMDevice {
    <#
    .SYNOPSIS
        Retrieves device information from the Datto RMM API.

    .DESCRIPTION
        The Get-RMMDevice function retrieves managed device information at different scopes:
        global (account-level), site-level, or for specific devices. Devices can be filtered
        by hostname, device type, operating system, site name, or retrieved using specific
        identifiers (UID, ID, or MAC address).

        The function supports pipeline input from Get-RMMSite to easily retrieve all devices
        for specific sites.

        When using -IncludeLastLoggedInUser, the function will prompt for confirmation due to
        privacy implications unless -Force is specified.

    .PARAMETER Site
        A DRMMSite object to retrieve devices for. Accepts pipeline input from Get-RMMSite.

    .PARAMETER SiteUid
        The unique identifier (GUID) of a site to retrieve devices for.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of a specific device to retrieve.

    .PARAMETER DeviceId
        The numeric ID of a specific device to retrieve.

    .PARAMETER MacAddress
        The MAC address of a device to retrieve. Accepts formats: 001122334455, 00:11:22:33:44:55, or 00-11-22-33-44-55.

    .PARAMETER Hostname
        Filter devices by hostname (partial match supported).

    .PARAMETER FilterId
        Apply a device filter by its ID. Can be used at global or site scope.

    .PARAMETER DeviceType
        Filter devices by device type category (e.g., "Desktop", "Laptop", "Server").

    .PARAMETER OperatingSystem
        Filter devices by operating system (partial match supported).

    .PARAMETER SiteName
        Filter devices by site name (partial match supported).

    .PARAMETER IncludeLastLoggedInUser
        Include the last logged in user information. Requires confirmation unless -Force is specified.

    .PARAMETER Force
        Suppress the confirmation prompt when using -IncludeLastLoggedInUser.

    .PARAMETER NetSummary
        Retrieve network interface summary for devices at a site. Returns DRMMDeviceNetworkInterface objects.

    .EXAMPLE
        Get-RMMDevice

        Retrieves all devices in the account.

    .EXAMPLE
        Get-RMMDevice -Hostname "SERVER01"

        Retrieves devices with hostname containing "SERVER01".

    .EXAMPLE
        Get-RMMSite -Name "Main Office" | Get-RMMDevice

        Gets all devices for the "Main Office" site.

    .EXAMPLE
        Get-RMMDevice -DeviceUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

        Retrieves a specific device by its unique identifier.

    .EXAMPLE
        Get-RMMDevice -MacAddress "00:11:22:33:44:55"

        Retrieves a device by its MAC address.

    .EXAMPLE
        Get-RMMDevice -FilterId 12345

        Retrieves all devices matching the specified filter.

    .EXAMPLE
        Get-RMMDevice -DeviceType "Server" -OperatingSystem "Windows Server 2022"

        Retrieves all Windows Server 2022 devices.

    .EXAMPLE
        Get-RMMSite | Get-RMMDevice -NetSummary

        Gets network interface information for devices at all sites.

    .EXAMPLE
        Get-RMMDevice -DeviceUid $guid -IncludeLastLoggedInUser -Force

        Retrieves a device with last logged in user information without confirmation prompt.

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite.
        You can also pipe objects with DeviceUid, DeviceId, SiteUid, or MacAddress properties.

    .OUTPUTS
        DRMMDevice. Returns device objects with comprehensive information including:
        - Device identification (Uid, Id, Hostname)
        - Network information (IntIpAddress, ExtIpAddress)
        - Status (Online, Suspended, Deleted, RebootRequired)
        - Software information (OperatingSystem, CagVersion)
        - Dates (LastSeen, LastReboot, LastAuditDate)
        - UDFs, Antivirus, Patch Management information

        When -NetSummary is specified, returns DRMMDeviceNetworkInterface objects with network card details.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        The -IncludeLastLoggedInUser parameter requires explicit confirmation due to privacy
        implications. Use -Force to bypass the confirmation prompt.

    .LINK
        about_DRMMDevice

    .LINK
        about_DRMMFilter

    .LINK
        Get-RMMFilter

    .LINK
        Get-RMMSite
    #>
    [CmdletBinding(DefaultParameterSetName = 'GlobalAll', SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(
            ParameterSetName = 'SiteAll',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteNetSummary',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMSite]
        $Site,

        [Parameter(
            ParameterSetName = 'DeviceByUid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [guid]
        $DeviceUid,

        [Parameter(
            ParameterSetName = 'DeviceById',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Id')]
        [int]
        $DeviceId,

        [Parameter(
            ParameterSetName = 'SiteAllUid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteUidNetSummary',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [guid]
        $SiteUid,

        [Parameter(
            ParameterSetName = 'DeviceByMacAddress',
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

        [Parameter(ParameterSetName = 'GlobalAll')]
        [string]
        $Hostname,

        [Parameter(ParameterSetName = 'GlobalAll', ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = 'SiteAll', ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = 'SiteAllUid', ValueFromPipelineByPropertyName = $true)]
        [long]
        $FilterId,

        [Parameter(ParameterSetName = 'GlobalAll')]
        [string]
        $DeviceType,

        [Parameter(ParameterSetName = 'GlobalAll')]
        [string]
        $OperatingSystem,

        [Parameter(ParameterSetName = 'GlobalAll')]
        [string]
        $SiteName,

        [Parameter(ParameterSetName = 'GlobalAll')]
        [Parameter(ParameterSetName = 'SiteAll')]
        [Parameter(ParameterSetName = 'SiteAllUid')]
        [Parameter(ParameterSetName = 'DeviceByUid')]
        [Parameter(ParameterSetName = 'DeviceById')]
        [Parameter(ParameterSetName = 'DeviceByMacAddress')]
        [switch]
        $IncludeLastLoggedInUser,

        [Parameter(ParameterSetName = 'GlobalAll')]
        [Parameter(ParameterSetName = 'SiteAll')]
        [Parameter(ParameterSetName = 'SiteAllUid')]
        [Parameter(ParameterSetName = 'DeviceByUid')]
        [Parameter(ParameterSetName = 'DeviceById')]
        [Parameter(ParameterSetName = 'DeviceByMacAddress')]
        [switch]
        $Force,

        [Parameter(ParameterSetName = 'SiteNetSummary', Mandatory = $true)]
        [Parameter(ParameterSetName = 'SiteUidNetSummary', Mandatory = $true)]
        [switch]
        $NetSummary
    )

    begin {

        if ($IncludeLastLoggedInUser -and -not $Force -and -not $PSCmdlet.ShouldProcess("Device information", "Retrieve last logged in user data")) {

            return

        }
    }

    process {

        Write-Debug "Getting RMM device(s) using parameter set: $($PSCmdlet.ParameterSetName)"

        if ($PSCmdlet.ParameterSetName -eq 'DeviceByUid') {

            # Single device by UID
            $APIMethod = @{
                Path = "device/$DeviceUid"
                Method = 'Get'
            }

            Write-Debug "Getting device by UID: $DeviceUid"
            $Response = Invoke-APIMethod @APIMethod

            [DRMMDevice]::FromAPIMethod($Response, $IncludeLastLoggedInUser.IsPresent)

        } elseif ($PSCmdlet.ParameterSetName -eq 'DeviceById') {

            # Single device by ID
            $APIMethod = @{
                Path = "device/id/$DeviceId"
                Method = 'Get'
            }

            Write-Debug "Getting device by ID: $DeviceId"
            $Response = Invoke-APIMethod @APIMethod

            [DRMMDevice]::FromAPIMethod($Response, $IncludeLastLoggedInUser.IsPresent)

        } elseif ($PSCmdlet.ParameterSetName -eq 'DeviceByMacAddress') {

            # Single or multiple devices by MAC address
            # Normalize MAC address by removing separators
            $NormalizedMacAddress = $MacAddress -replace '[:\-\.]', ''
            
            $APIMethod = @{
                Path = "device/macAddress/$NormalizedMacAddress"
                Method = 'Get'
                Paginate = $true
                PageElement = 'devices'
            }

            Write-Debug "Getting device(s) by MAC address: $NormalizedMacAddress"
            Invoke-APIMethod @APIMethod | ForEach-Object {

                [DRMMDevice]::FromAPIMethod($_, $IncludeLastLoggedInUser.IsPresent)

            }

        } elseif ($PSCmdlet.ParameterSetName -in 'SiteNetSummary', 'SiteUidNetSummary') {

            if ($Site) {

                $SiteUid = $Site.Uid

            }

            $APIMethod = @{
                Path = "site/$SiteUid/devices/network-interface"
                Method = 'Get'
                Paginate = $true
                PageElement = 'devices'
            }

            Write-Debug "Getting all devices with network interfaces for site UID: $SiteUid"
            Invoke-APIMethod @APIMethod | ForEach-Object {

                [DRMMDeviceNetworkInterface]::FromAPIMethod($_)

            }

        } elseif ($PSCmdlet.ParameterSetName -match '^Site') {

            if ($Site) {

                $SiteUid = $Site.Uid

            }

            $APIMethod = @{
                Path = "site/$SiteUid/devices"
                Method = 'Get'
                Paginate = $true
                PageElement = 'devices'
            }

            if ($FilterId) {

                $APIMethod.Parameters = @{ filterId = $FilterId }

            }

            switch ($PSCmdlet.ParameterSetName) {

                {$_ -in 'SiteAll','SiteAllUid'} {

                        Write-Debug "Getting all devices for site UID: $SiteUid"
                        Invoke-APIMethod @APIMethod | ForEach-Object {

                            [DRMMDevice]::FromAPIMethod($_, $IncludeLastLoggedInUser.IsPresent)

                        }
                    }
                }

        } else {

            # Global scope
            $APIMethod = @{
                Path = 'account/devices'
                Method = 'Get'
                Paginate = $true
                PageElement = 'devices'
            }

            # Build filter parameters
            $Parameters = @{}

            switch ($PSBoundParameters.Keys) {

                'FilterId' {$Parameters.filterId = $FilterId}
                'Hostname' {$Parameters.hostname = $Hostname}
                'DeviceType' {$Parameters.deviceType = $DeviceType}
                'OperatingSystem' {$Parameters.operatingSystem = $OperatingSystem}
                'SiteName' {$Parameters.siteName = $SiteName}

            }

            if ($Parameters.Count -gt 0) {

                $APIMethod.Parameters = $Parameters

            }

            Write-Debug "Getting global devices"
            Invoke-APIMethod @APIMethod | ForEach-Object {

                [DRMMDevice]::FromAPIMethod($_, $IncludeLastLoggedInUser.IsPresent)

            }
        }
    }
}

