<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMFilter {
    <#
    .SYNOPSIS
        Retrieves filters from the Datto RMM API.

    .DESCRIPTION
        The Get-RMMFilter function retrieves filters at different scopes: global (account-level) or site-level. Filters can be retrieved by ID, name, or all filters at a given scope.

        Filters in Datto RMM are used to group devices based on criteria and can be applied when retrieving devices with Get-RMMDevice.

        Filters are categorized as either "Default" (built-in system filters) or "Custom" (user-created filters).

    .PARAMETER Site
        A DRMMSite object to retrieve filters for. Accepts pipeline input from Get-RMMSite.

    .PARAMETER Id
        Retrieve a specific filter by its numeric ID.

    .PARAMETER Name
        Retrieve a filter by its name (exact match).

    .PARAMETER FilterType
        Filter the results by type. Valid values: 'All', 'Default', 'Custom'. Default is 'All'.
        Only applicable for global scope queries.

    .EXAMPLE
        Get-RMMFilter

        Retrieves all filters at the account level.

    .EXAMPLE
        Get-RMMFilter -FilterType Custom

        Retrieves only custom (user-created) filters.

    .EXAMPLE
        Get-RMMFilter -Id 12345

        Retrieves a specific filter by its ID.

    .EXAMPLE
        Get-RMMFilter -Name "Windows Servers"

        Retrieves a filter by exact name match.

    .EXAMPLE
        Get-RMMSite -Name "Main Office" | Get-RMMFilter

        Gets all filters for the "Main Office" site.

    .EXAMPLE
        Get-RMMFilter -Name "Production Servers" | Get-RMMDevice

        Retrieves a filter by name and pipes it to Get-RMMDevice to retrieve matching devices.
        Site-scoped filters automatically route to the correct site endpoint.

    .EXAMPLE
        Get-RMMFilter -Id 12345 | Get-RMMDevice

        Retrieves a filter by ID and pipes it to Get-RMMDevice.

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite.

    .OUTPUTS
        DRMMFilter. Returns filter objects with the following properties:
        - Id: Numeric identifier
        - Name: Filter name
        - Description: Filter description
        - Type: 'rmm_default' or 'custom'
        - Scope: 'Global' or 'Site'
        - SiteUid: Site identifier (for site-scoped filters)
        - DateCreate: Creation date
        - LastUpdated: Last modification date

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Filter objects can be piped directly to Get-RMMDevice to retrieve matching devices.
        Site-scoped filters automatically route to the correct site endpoint.
        Alternatively, use Get-RMMDevice -FilterId to retrieve devices by numeric filter ID.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Filter/Get-RMMFilter.md

    .LINK
        about_DRMMFilter

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMSite
    #>
    [CmdletBinding(DefaultParameterSetName = 'GlobalAll')]
    param (
        [Parameter(
            ParameterSetName = 'SiteAll',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteById',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteByName',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMSite]
        $Site,

        [Parameter(
            ParameterSetName = 'GlobalById',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteById',
            Mandatory = $true
        )]
        [int]
        $Id,

        [Parameter(
            ParameterSetName = 'GlobalByName',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteByName',
            Mandatory = $true
        )]
        [string]
        $Name,

        [Parameter(
            ParameterSetName = 'GlobalAll'
        )]
        [Parameter(
            ParameterSetName = 'GlobalById'
        )]
        [Parameter(
            ParameterSetName = 'GlobalByName'
        )]
        [ValidateSet('All', 'Default', 'Custom')]
        [string]
        $FilterType = 'All'
    )

    process {

        Write-Debug "Getting RMM filter(s) using parameter set: $($PSCmdlet.ParameterSetName)"

        if ($PSCmdlet.ParameterSetName -match '^Site') {

            $APIMethod = @{
                Path = "site/$($Site.Uid)/filters"
                Method = 'Get'
                Paginate = $true
                PageElement = 'filters'
            }

            switch ($PSCmdlet.ParameterSetName) {

                'SiteAll' {

                    Write-Debug "Getting all filters for site: $($Site.Name) (UID: $($Site.Uid))"
                    Invoke-ApiMethod @APIMethod | ForEach-Object {

                        [DRMMSiteFilter]::FromAPIMethod($_, $Site, $Script:SessionPlatform)

                    }
                }

                'SiteById' {

                    Write-Debug "Getting site filter by ID: $Id for site: $($Site.Name) (UID: $($Site.Uid))"
                    Invoke-ApiMethod @APIMethod | Where-Object {$_.id -eq $Id} | ForEach-Object {

                        [DRMMSiteFilter]::FromAPIMethod($_, $Site, $Script:SessionPlatform)

                    }
                }

                'SiteByName' {

                    Write-Debug "Getting site filter by Name: $Name for site: $($Site.Name) (UID: $($Site.Uid))"
                    Invoke-ApiMethod @APIMethod | Where-Object {$_.name -eq $Name} | ForEach-Object {

                        [DRMMSiteFilter]::FromAPIMethod($_, $Site, $Script:SessionPlatform)

                    }
                }
            }

        } else {

            # Global scope - handle Default, Custom, or All
            $Methods = @()

            switch ($FilterType) {

                'Default' {

                    $Methods += @{
                        Path = 'filter/default-filters'
                        Scope = 'Global'
                    }
                }

                'Custom' {

                    $Methods += @{
                        Path = 'filter/custom-filters'
                        Scope = 'Global'
                    }
                }

                'All' {

                    $Methods += @{
                        Path = 'filter/default-filters'
                        Scope = 'Global'
                    }
                    $Methods += @{
                        Path = 'filter/custom-filters'
                        Scope = 'Global'
                    }
                }
            }

            foreach ($Method in $Methods) {

                $APIMethod = @{
                    Path = $Method.Path
                    Method = 'Get'
                    Paginate = $true
                    PageElement = 'filters'
                }

                switch ($PSCmdlet.ParameterSetName) {

                    'GlobalAll' {

                        Write-Debug "Getting global filters from $($Method.Path)"
                        Invoke-ApiMethod @APIMethod | ForEach-Object {

                            [DRMMFilter]::FromAPIMethod($_, $Method.Scope, $Script:SessionPlatform)

                        }
                    }

                    'GlobalById' {

                        Write-Debug "Getting global filter by ID: $Id from $($Method.Path)"
                        Invoke-ApiMethod @APIMethod | Where-Object {$_.id -eq $Id} | ForEach-Object {

                            [DRMMFilter]::FromAPIMethod($_, $Method.Scope, $Script:SessionPlatform)

                        }
                    }

                    'GlobalByName' {

                        Write-Debug "Getting global filter by Name: $Name from $($Method.Path)"
                        Invoke-ApiMethod @APIMethod | Where-Object {$_.name -eq $Name} | ForEach-Object {

                            [DRMMFilter]::FromAPIMethod($_, $Method.Scope, $Script:SessionPlatform)

                        }
                    }
                }
            }
        }
    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDXaBf0Gtt0vCm2
# MWnJtswWkMZ0r2h2fkh64tN5YSsAa6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIK0dQBL2IDvMBWcekhihyr0E7VXz
# ixc9x4w8UGcmsik9MA0GCSqGSIb3DQEBAQUABIIBAAkFn9A4XEq+hDYmqAKsa4vx
# ijTGXD9p1ZrAODqMtUrnOWbKH9eFAHQNKgo1l202hFblgls5zrB8U9hBJZ8Z0dVe
# QAm1v9ShjvK3KUzy7C9vu9CZ1+Kc3rmWFgF+cADxsXEF8ahv+EgnGKVd6RjPwl9u
# OKDxZjXbNVaYJo0Zq7eOt2C8TpqJdHDUV5q37fYcAhAnfQ2JOzndin5ax6MxbvX8
# Sg9ZWqeiJcYhQ7tn56PDb503+w+SeOH/VTANcdicjvFxkDZ2PNwRFkbXAwAX4m0N
# fXVCBwEwVVQrUee1VAItMuIehSe6bzJUNot3Z3zSCV70RDK4AQvuE5BDjGh8uo4=
# SIG # End signature block
