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

        When using -IncludeLastLoggedInUser, the function will prompt for confirmation due to
        privacy implications unless -Force is specified.

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
        Get-RMMSite -Name "Main Office" | Get-RMMDevice -FilterId 12345

        Retrieves devices matching filter 12345 scoped to the "Main Office" site.

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

        The -IncludeLastLoggedInUser parameter requires explicit confirmation due to privacy
        implications. Use -Force to bypass the confirmation prompt.

        When piping sites or filters, the IncludeLastLoggedInUser parameter applies to all
        objects in the pipeline.

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
    #>

    [CmdletBinding(DefaultParameterSetName = 'Global', SupportsShouldProcess, ConfirmImpact = 'High')]
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

        [Parameter(ParameterSetName = 'Global')]
        [Parameter(ParameterSetName = 'Site')]
        [Parameter(ParameterSetName = 'SiteUid')]
        [Parameter(ParameterSetName = 'Device')]
        [Parameter(ParameterSetName = 'DeviceUid')]
        [Parameter(ParameterSetName = 'DeviceId')]
        [Parameter(ParameterSetName = 'DeviceMac')]
        [Parameter(ParameterSetName = 'Filter')]
        [switch]
        $IncludeLastLoggedInUser,

        [Parameter(ParameterSetName = 'Global')]
        [Parameter(ParameterSetName = 'Site')]
        [Parameter(ParameterSetName = 'SiteUid')]
        [Parameter(ParameterSetName = 'Device')]
        [Parameter(ParameterSetName = 'DeviceUid')]
        [Parameter(ParameterSetName = 'DeviceId')]
        [Parameter(ParameterSetName = 'DeviceMac')]
        [Parameter(ParameterSetName = 'Filter')]
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

                [DRMMDevice]::FromAPIMethod($_, $IncludeLastLoggedInUser.IsPresent)

            }

        } else {

            $Response = Invoke-ApiMethod @APIMethod

            [DRMMDevice]::FromAPIMethod($Response, $IncludeLastLoggedInUser.IsPresent)

        }
    }
}


# SIG # Begin signature block
# MIIcXwYJKoZIhvcNAQcCoIIcUDCCHEwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD/JLQjlIw0OSos
# aMa/M23hOWwgr3w19Y5nPxBC1aybJKCCFogwggNKMIICMqADAgECAhB464iXHfI6
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
# XpF9pOzFLMUwggWNMIIEdaADAgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3
# DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAX
# BgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3Vy
# ZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBH
# NDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIw
# aTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLK
# EdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4Tm
# dDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembu
# d8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnD
# eMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1
# XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVld
# QnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTS
# YW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSm
# M9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzT
# QRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6Kx
# fgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/
# MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv
# 9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBr
# MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUH
# MAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYG
# BFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72a
# rKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFID
# yE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/o
# Wajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv
# 76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30
# fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQwgga0MIIE
# nKADAgECAhANx6xXBf8hmS5AQyIMOkmGMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNV
# BAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdp
# Y2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0y
# NTA1MDcwMDAwMDBaFw0zODAxMTQyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYD
# VQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBH
# NCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEwggIiMA0GCSqG
# SIb3DQEBAQUAA4ICDwAwggIKAoICAQC0eDHTCphBcr48RsAcrHXbo0ZodLRRF51N
# rY0NlLWZloMsVO1DahGPNRcybEKq+RuwOnPhof6pvF4uGjwjqNjfEvUi6wuim5ba
# p+0lgloM2zX4kftn5B1IpYzTqpyFQ/4Bt0mAxAHeHYNnQxqXmRinvuNgxVBdJkf7
# 7S2uPoCj7GH8BLuxBG5AvftBdsOECS1UkxBvMgEdgkFiDNYiOTx4OtiFcMSkqTtF
# 2hfQz3zQSku2Ws3IfDReb6e3mmdglTcaarps0wjUjsZvkgFkriK9tUKJm/s80Fio
# cSk1VYLZlDwFt+cVFBURJg6zMUjZa/zbCclF83bRVFLeGkuAhHiGPMvSGmhgaTzV
# yhYn4p0+8y9oHRaQT/aofEnS5xLrfxnGpTXiUOeSLsJygoLPp66bkDX1ZlAeSpQl
# 92QOMeRxykvq6gbylsXQskBBBnGy3tW/AMOMCZIVNSaz7BX8VtYGqLt9MmeOreGP
# RdtBx3yGOP+rx3rKWDEJlIqLXvJWnY0v5ydPpOjL6s36czwzsucuoKs7Yk/ehb//
# Wx+5kMqIMRvUBDx6z1ev+7psNOdgJMoiwOrUG2ZdSoQbU2rMkpLiQ6bGRinZbI4O
# Lu9BMIFm1UUl9VnePs6BaaeEWvjJSjNm2qA+sdFUeEY0qVjPKOWug/G6X5uAiynM
# 7Bu2ayBjUwIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4E
# FgQU729TSunkBnx6yuKQVvYv1Ensy04wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5n
# P+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcG
# CCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQu
# Y29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGln
# aUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNV
# HSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIB
# ABfO+xaAHP4HPRF2cTC9vgvItTSmf83Qh8WIGjB/T8ObXAZz8OjuhUxjaaFdleMM
# 0lBryPTQM2qEJPe36zwbSI/mS83afsl3YTj+IQhQE7jU/kXjjytJgnn0hvrV6hqW
# Gd3rLAUt6vJy9lMDPjTLxLgXf9r5nWMQwr8Myb9rEVKChHyfpzee5kH0F8HABBgr
# 0UdqirZ7bowe9Vj2AIMD8liyrukZ2iA/wdG2th9y1IsA0QF8dTXqvcnTmpfeQh35
# k5zOCPmSNq1UH410ANVko43+Cdmu4y81hjajV/gxdEkMx1NKU4uHQcKfZxAvBAKq
# MVuqte69M9J6A47OvgRaPs+2ykgcGV00TYr2Lr3ty9qIijanrUR3anzEwlvzZiiy
# fTPjLbnFRsjsYg39OlV8cipDoq7+qNNjqFzeGxcytL5TTLL4ZaoBdqbhOhZ3ZRDU
# phPvSRmMThi0vw9vODRzW6AxnJll38F0cuJG7uEBYTptMSbhdhGQDpOXgpIUsWTj
# d6xpR6oaQf/DJbg3s6KCLPAlZ66RzIg9sC+NJpud/v4+7RWsWCiKi9EOLLHfMR2Z
# yJ/+xhCx9yHbxtl5TPau1j/1MIDpMPx0LckTetiSuEtQvLsNz3Qbp7wGWqbIiOWC
# nb5WqxL3/BAPvIXKUjPSxyZsq8WhbaM2tszWkPZPubdcMIIG7TCCBNWgAwIBAgIQ
# CoDvGEuN8QWC0cR2p5V0aDANBgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0
# ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMB4XDTI1
# MDYwNDAwMDAwMFoXDTM2MDkwMzIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNV
# BAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBTSEEyNTYgUlNB
# NDA5NiBUaW1lc3RhbXAgUmVzcG9uZGVyIDIwMjUgMTCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBANBGrC0Sxp7Q6q5gVrMrV7pvUf+GcAoB38o3zBlCMGMy
# qJnfFNZx+wvA69HFTBdwbHwBSOeLpvPnZ8ZN+vo8dE2/pPvOx/Vj8TchTySA2R4Q
# KpVD7dvNZh6wW2R6kSu9RJt/4QhguSssp3qome7MrxVyfQO9sMx6ZAWjFDYOzDi8
# SOhPUWlLnh00Cll8pjrUcCV3K3E0zz09ldQ//nBZZREr4h/GI6Dxb2UoyrN0ijtU
# DVHRXdmncOOMA3CoB/iUSROUINDT98oksouTMYFOnHoRh6+86Ltc5zjPKHW5KqCv
# pSduSwhwUmotuQhcg9tw2YD3w6ySSSu+3qU8DD+nigNJFmt6LAHvH3KSuNLoZLc1
# Hf2JNMVL4Q1OpbybpMe46YceNA0LfNsnqcnpJeItK/DhKbPxTTuGoX7wJNdoRORV
# bPR1VVnDuSeHVZlc4seAO+6d2sC26/PQPdP51ho1zBp+xUIZkpSFA8vWdoUoHLWn
# qWU3dCCyFG1roSrgHjSHlq8xymLnjCbSLZ49kPmk8iyyizNDIXj//cOgrY7rlRyT
# laCCfw7aSUROwnu7zER6EaJ+AliL7ojTdS5PWPsWeupWs7NpChUk555K096V1hE0
# yZIXe+giAwW00aHzrDchIc2bQhpp0IoKRR7YufAkprxMiXAJQ1XCmnCfgPf8+3mn
# AgMBAAGjggGVMIIBkTAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBTkO/zyMe39/dfz
# kXFjGVBDz2GM6DAfBgNVHSMEGDAWgBTvb1NK6eQGfHrK4pBW9i/USezLTjAOBgNV
# HQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwgZUGCCsGAQUFBwEB
# BIGIMIGFMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXQYI
# KwYBBQUHMAKGUWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRy
# dXN0ZWRHNFRpbWVTdGFtcGluZ1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNydDBfBgNV
# HR8EWDBWMFSgUqBQhk5odHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRU
# cnVzdGVkRzRUaW1lU3RhbXBpbmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcmwwIAYD
# VR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4IC
# AQBlKq3xHCcEua5gQezRCESeY0ByIfjk9iJP2zWLpQq1b4URGnwWBdEZD9gBq9fN
# aNmFj6Eh8/YmRDfxT7C0k8FUFqNh+tshgb4O6Lgjg8K8elC4+oWCqnU/ML9lFfim
# 8/9yJmZSe2F8AQ/UdKFOtj7YMTmqPO9mzskgiC3QYIUP2S3HQvHG1FDu+WUqW4da
# IqToXFE/JQ/EABgfZXLWU0ziTN6R3ygQBHMUBaB5bdrPbF6MRYs03h4obEMnxYOX
# 8VBRKe1uNnzQVTeLni2nHkX/QqvXnNb+YkDFkxUGtMTaiLR9wjxUxu2hECZpqyU1
# d0IbX6Wq8/gVutDojBIFeRlqAcuEVT0cKsb+zJNEsuEB7O7/cuvTQasnM9AWcIQf
# VjnzrvwiCZ85EE8LUkqRhoS3Y50OHgaY7T/lwd6UArb+BOVAkg2oOvol/DJgddJ3
# 5XTxfUlQ+8Hggt8l2Yv7roancJIFcbojBcxlRcGG0LIhp6GvReQGgMgYxQbV1S3C
# rWqZzBt1R9xJgKf47CdxVRd/ndUlQ05oxYy2zRWVFjF7mcr4C34Mj3ocCVccAvlK
# V9jEnstrniLvUxxVZE/rptb7IRE2lskKPIJgbaP5t2nGj/ULLi49xTcBZU8atufk
# +EMF/cWuiC7POGT75qaL6vdCvHlshtjdNXOCIUjsarfNZzGCBS0wggUpAgEBMFEw
# PTEWMBQGA1UECgwNUm9iZXJ0IEZhZGRlczEjMCEGA1UEAwwaRGF0dG9STU0uQ29y
# ZSBDb2RlIFNpZ25pbmcCEHjriJcd8jqCSwSQMNPKs2wwDQYJYIZIAWUDBAIBBQCg
# gYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0B
# CQQxIgQgkcPcg9N/u1f+xxJUKAm3/bcB94jQHeuyCEumM2Hvj54wDQYJKoZIhvcN
# AQEBBQAEggEAbWsUdfKUpVVktV/spzb6tJMQayEdJXAGCOUUgiHANCCKMXeZuiPS
# VhGX7pSOmqlIhW2Q4bxSpcx8V/ad0zebTyI4M9W46Ll39F4OQNIj/W82OszKjJ1q
# CFT5vwklJtrXxVMZvzl3klMNLUJLnmeaWJTUlXUvPggLXtqSNS6lo4nm2pfVussv
# pJ0xZsY80ixjjUJmsNPQcoRgj/Uyjh5gmGHkngI+9IOl9CZR6vkFnlXZQYt14CO2
# 4goPH/WnGk2qjSBveOl5Xth6LfBak5IFKc54DS66MGsFpV0exkz2lXRseZIHSgFz
# occnntauAVPkznR6f0MUSx08FzUSiUSmpKGCAyYwggMiBgkqhkiG9w0BCQYxggMT
# MIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5j
# LjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNB
# NDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUD
# BAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0yNjAzMzEwMDMwMzRaMC8GCSqGSIb3DQEJBDEiBCBLFVVA1uZbcuG2SSX8ToxM
# qGLQnKuLJ9+t5u/PmYLMFzANBgkqhkiG9w0BAQEFAASCAgBGdjiJZ12Ud2mPvm9f
# rx6fzhiWJXB3NXLk1V5jGOeBM3mfs8n2uIouUY9faT3NOlenTT0FZxgM9+VL+D4a
# uHfHI6vWpIxq27nK4aVRVHoRBl4521XRE6Ipu85iqYCzk2uIMXUjwFYCiE7km5vH
# uDwDMWIq3peRvx8uvlL7kZ2JuRNVJ+sq93/R8mijlfCmWlTia+jguQXYva4DzvF1
# OJTQDAN4stRpP+KRgkY+0qilcmffV3fAZ3olsKbl0Yb6wYFO9lTQmN9qTqiFG54P
# vvQOnLWDN8iU8JOF68fpORcAdR15DC4dGkPIxZpKN9mKNzoyMnU1YiT5itVr0E2g
# 7mLh6g+CSZjoWm8P4YzBgo6Fuqrwdv1AQczjtv+w/zbOc7r9+xiXOyYfWjhVxlK8
# 9uP3+2QoXN3hxi2z6ZhezDIRADqKdLiALYOoSQStdUUrySQ3xqt/toO1F7UWY/1K
# rXNItqHipyNU6URAUFSIl4FKmrUVQcRF0PCtKXGN2t6kf4PQED9iGMACsfMCpvfw
# uVroRQRb9/GAIAr4pabG0pICKcFF/vglXlzaC1rTsVCJpmc0yS+CenHgqxOnOCqx
# lFx/Fu/bgtpz6fFB0axqHQRYeCa6GmyXMUc1jRVEuHd2ZcDGOztnHYDTklcCj3as
# 6dR5Wb/cGjg7TzWC5CnK/Mx1mg==
# SIG # End signature block
