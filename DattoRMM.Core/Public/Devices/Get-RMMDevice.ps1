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
        global (account-level), site-level, filter-based, or for specific devices. Devices can
        be filtered by hostname, device type, operating system, or site name at the global scope.

        The function supports pipeline input from Get-RMMSite, Get-RMMDevice, and Get-RMMFilter,
        making it easy to retrieve devices for filtered sets of sites or filter definitions.

        When specifying a Filter, site-scoped filters automatically route to the appropriate site
        endpoint. Global-scoped filters route to the account endpoint.

    .PARAMETER Site
        A DRMMSite object to retrieve devices for. Accepts pipeline input from Get-RMMSite.

    .PARAMETER SiteUid
        The unique identifier (GUID) of a site to retrieve devices for.

    .PARAMETER Device
        A DRMMDevice object to re-retrieve from the API. Accepts pipeline input from Get-RMMDevice.
        Useful for refreshing stale device data.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of a specific device to retrieve.

    .PARAMETER DeviceId
        The numeric ID of a specific device to retrieve.

    .PARAMETER MacAddress
        The MAC address of a device to retrieve. Accepts formats: 001122334455, 00:11:22:33:44:55,
        or 00-11-22-33-44-55.

    .PARAMETER Filter
        A DRMMFilter object to retrieve matching devices for. Accepts pipeline input from Get-RMMFilter.
        Site-scoped filters automatically route to the appropriate site endpoint.

    .PARAMETER FilterId
        Apply a device filter by its numeric ID. When used alone, queries at the global (account) scope.
        When combined with Site or SiteUid, queries at the site scope.

    .PARAMETER Hostname
        Filter devices by hostname (partial match supported). Only available at global scope.

    .PARAMETER DeviceType
        Filter devices by device type category (e.g., "Desktop", "Laptop", "Server").
        Only available at global scope.

    .PARAMETER OperatingSystem
        Filter devices by operating system (partial match supported). Only available at global scope.

    .PARAMETER SiteName
        Filter devices by site name (partial match supported). Only available at global scope.

    .PARAMETER NetSummary
        Retrieve network interface summary for devices at a site. Returns DRMMDeviceNetworkInterface objects.

    .EXAMPLE
        Get-RMMDevice

        Retrieves all devices in the account.

    .EXAMPLE
        Get-RMMDevice -Hostname "SERVER01"

        Retrieves devices with hostname containing "SERVER01".

    .EXAMPLE
        Get-RMMSite -SiteName "Main Office" | Get-RMMDevice

        Gets all devices for the "Main Office" site.

    .EXAMPLE
        Get-RMMFilter -Name "Production Servers" | Get-RMMDevice

        Gets all devices matching the "Production Servers" filter. Site-scoped filters automatically
        route to the correct site endpoint.

    .EXAMPLE
        Get-RMMDevice -DeviceUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

        Retrieves a specific device by its unique identifier.

    .EXAMPLE
        Get-RMMDevice -MacAddress "00:11:22:33:44:55"

        Retrieves a device by its MAC address.

    .EXAMPLE
        Get-RMMDevice -FilterId 12345

        Retrieves all devices matching filter 12345 at the account level.

    .EXAMPLE
        Get-RMMSite -SiteName "Main Office" | Get-RMMDevice -FilterId 12345

        Retrieves devices matching filter 12345 scoped to the "Main Office" site.

    .EXAMPLE
        Get-RMMDevice -DeviceType "Server" -OperatingSystem "Windows Server 2022"

        Retrieves all Windows Server 2022 devices.

    .EXAMPLE
        Get-RMMSite | Get-RMMDevice -NetSummary

        Gets network interface information for devices at all sites.

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite.
        DRMMDevice. You can pipe device objects from Get-RMMDevice.
        DRMMFilter. You can pipe filter objects from Get-RMMFilter.

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

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Get-RMMDevice.md

    .LINK
        about_DRMMDevice

    .LINK
        about_DRMMFilter

    .LINK
        Get-RMMFilter

    .LINK
        Get-RMMSite

    .LINK
        Get-RMMDeviceAudit
    #>

    [CmdletBinding(DefaultParameterSetName = 'Global', SupportsShouldProcess)]
    param (
        [Parameter(
            ParameterSetName = 'Site',
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
            ParameterSetName = 'SiteUid',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteUidNetSummary',
            Mandatory = $true
        )]
        [guid]
        $SiteUid,

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

        [Parameter(
            ParameterSetName = 'DeviceId',
            Mandatory = $true
        )]
        [int]
        $DeviceId,

        [Parameter(
            ParameterSetName = 'DeviceMac',
            Mandatory = $true
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

        [Parameter(
            ParameterSetName = 'Filter',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMFilter]
        $Filter,

        [Parameter(ParameterSetName = 'Global')]
        [Parameter(ParameterSetName = 'Site')]
        [Parameter(ParameterSetName = 'SiteUid')]
        [long]
        $FilterId,

        [Parameter(ParameterSetName = 'Global')]
        [string]
        $Hostname,

        [Parameter(ParameterSetName = 'Global')]
        [string]
        $DeviceType,

        [Parameter(ParameterSetName = 'Global')]
        [string]
        $OperatingSystem,

        [Parameter(ParameterSetName = 'Global')]
        [string]
        $SiteName,

        [Parameter(ParameterSetName = 'SiteNetSummary', Mandatory = $true)]
        [Parameter(ParameterSetName = 'SiteUidNetSummary', Mandatory = $true)]
        [switch]
        $NetSummary
    )

    process {

        Write-Verbose "Getting devices with parameter set: $($PSCmdlet.ParameterSetName)"

        # Set API method configuration based on parameter set
        switch -Regex ($PSCmdlet.ParameterSetName) {

            '^Device' {

                if ($Device) {

                    $DeviceUid = $Device.Uid

                }

                switch ($PSCmdlet.ParameterSetName) {

                    'DeviceId' {

                        $APIMethod = @{
                            Path = "device/id/$DeviceId"
                            Method = 'Get'
                        }
                    }

                    'DeviceMac' {

                        $NormalizedMac = $MacAddress -replace '[:\-\.]', ''

                        $APIMethod = @{
                            Path = "device/macAddress/$NormalizedMac"
                            Method = 'Get'
                            Paginate = $true
                            PageElement = 'devices'
                        }
                    }

                    default {

                        $APIMethod = @{
                            Path = "device/$DeviceUid"
                            Method = 'Get'
                        }
                    }
                }
            }

            '^Global' {

                $APIMethod = @{
                    Path = 'account/devices'
                    Method = 'Get'
                    Paginate = $true
                    PageElement = 'devices'
                }

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
            }

            '^Site' {

                if ($Site) {

                    $SiteUid = $Site.Uid

                }

                if ($PSCmdlet.ParameterSetName -match 'NetSummary') {

                    $APIMethod = @{
                        Path = "site/$SiteUid/devices/network-interface"
                        Method = 'Get'
                        Paginate = $true
                        PageElement = 'devices'
                    }

                } else {

                    $APIMethod = @{
                        Path = "site/$SiteUid/devices"
                        Method = 'Get'
                        Paginate = $true
                        PageElement = 'devices'
                    }

                    if ($FilterId) {

                        $APIMethod.Parameters = @{filterId = $FilterId}

                    }
                }
            }

            '^Filter' {

                if ($Filter.Scope -eq 'Site' -and $Filter.Site) {

                    $MethodPath = "site/$($Filter.Site.Uid)/devices"

                } else {

                    $MethodPath = "account/devices"

                }

                $APIMethod = @{
                    Path = $MethodPath
                    Method = 'Get'
                    Paginate = $true
                    PageElement = 'devices'
                    Parameters = @{filterId = $Filter.Id}
                }
            }
        }

        # Invoke API and return typed objects
        if ($PSCmdlet.ParameterSetName -match 'NetSummary') {

            Invoke-ApiMethod @APIMethod | ForEach-Object {

                [DRMMDeviceNetworkInterface]::FromAPIMethod($_)

            }

        } elseif ($APIMethod.Paginate) {

            Invoke-ApiMethod @APIMethod | ForEach-Object {

                [DRMMDevice]::FromAPIMethod($_)

            }

        } else {

            $Response = Invoke-ApiMethod @APIMethod

            [DRMMDevice]::FromAPIMethod($Response)

        }
    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCd+j9mOJHXg/V0
# wP0XSOer9Slj6/HJk+bbQm1oXlJ9OKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBUkgJPLVS0IoCP27tYRzleAA3AP
# kobA/JPtRtbivu2CMA0GCSqGSIb3DQEBAQUABIIBAEZ9XNhvLkFwdXyTLpTiNMG4
# /LKuHSXHbduQVQDgmdpnOgARC6uGVD/3YcGC7TL3xoneN6HHhVCDB3mw3OHEO+Dx
# rrgmCqNJz3j7/bOc9z6okcJ69k+5uglmkAng2uwv0mdarEhfR/3mRGC6CD2nFZQp
# 9Q1vxCTroVzGZ1kHDyt5ZtDqleHZJrSJ6EitEoYqN3DbT9Qq3YPditieq4DXFOVC
# rI5WXEgEB/aM8wR/plSWucwo3ygqx433Y7o98hXhcfAoeahOCRGABpMH8hLkNkTD
# pmW/d9icMqz4OdTBbjezFeuFtYF4JHaoxaYrWRx7s+JBNaqLvFEJt31Ed/F7y+U=
# SIG # End signature block
