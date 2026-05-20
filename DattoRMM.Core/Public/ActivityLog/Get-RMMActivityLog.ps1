<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMActivityLog {
    <#
    .SYNOPSIS
        Retrieves activity logs from the Datto RMM API.

    .DESCRIPTION
        Retrieves activity logs for one or more sites, with optional filtering by date range, entity type,
        categories, actions, and users. Supports global (all sites) or site-specific queries. Site IDs are
        batched for large environments to avoid API limits.

        You can specify sites by:
        - Piping DRMMSite objects (from Get-RMMSite)
        - Passing SiteId(s) directly
        - Omitting both for global (all sites) scope

    .PARAMETER Site
        A DRMMSite object to retrieve activity logs for. Accepts pipeline input from Get-RMMSite.

    .PARAMETER SiteId
        The numeric ID of a site to retrieve activity logs for.

    .PARAMETER Start
        Start date/time for fetching data. Accepts local or UTC; local times are automatically converted
        to UTC for the API. Format: yyyy-MM-ddTHH:mm:ssZ. Required.
        Defaults to 24 hours ago.

    .PARAMETER End
        End date/time for fetching data. Accepts local or UTC; local times are automatically converted
        to UTC for the API. Format: yyyy-MM-ddTHH:mm:ssZ. Required.
        Defaults to the current time.
        
    .PARAMETER Entity
        Filters activity logs by entity type. Valid values: 'Device', 'User'.

    .PARAMETER Category
        Filters activity logs by category (e.g., 'job', 'device').

    .PARAMETER Action
        Filters activity logs by action (e.g., 'deployment', 'note').

    .PARAMETER UserId
        Filters activity logs by user ID (integer).

    .PARAMETER Order
        Specifies the order in which records are returned by creation date. Valid values: 'asc', 'desc'.
        Default is 'desc'.

    .PARAMETER SearchQuery
        Filters activity logs using an advanced Lucene-style search expression, identical to the
        Activity Log UI search bar. Accepts field searches, wildcards, boolean operators, fuzzy
        matching, and grouped expressions. Passed through verbatim — no client-side parsing or
        validation is applied.

    .PARAMETER UseExperimentalDetailClasses
        Enables experimental entity/category-specific detail classes for activity logs. When specified,
        details are parsed into strongly-typed classes based on entity, category, and action combinations
        (e.g., DRMMActivityLogDetailsDeviceJob for DEVICE/job activities). When not specified (default),
        all details use the generic DRMMActivityLogDetailsGeneric class with dynamic properties.

    .EXAMPLE
        Get-RMMActivityLog -Start "2024-01-01T00:00:00Z" -End "2024-01-02T00:00:00Z"

        Retrieves activity logs for all sites for January 1st, 2024.

    .EXAMPLE
        $Start = Get-Date '2024-01-01T00:00:00Z'
        PS > $End = Get-Date '2024-01-02T00:00:00Z'
        PS > Get-RMMSite -SiteName "Main Office" | Get-RMMActivityLog -Start $Start -End $End

        Retrieves activity logs for the "Main Office" site.

    .EXAMPLE
        Get-RMMActivityLog -SiteId 1234,5678 -Start (Get-Date '2024-01-01') -End (Get-Date '2024-01-02')

        Retrieves activity logs for sites with IDs 1234 and 5678.

    .EXAMPLE
        Get-RMMSite | Get-RMMActivityLog

        Retrieves activity logs for last 24 hours for all sites.

    .EXAMPLE
        Get-RMMActivityLog -Start (Get-Date).AddDays(-7) -End (Get-Date) -SearchQuery 'data.filter_id : "filterId" AND device.hostname : "hostname"'

        Retrieves activity logs for the past 7 days matching a specific filter ID and hostname using
        a Lucene-style search expression.

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite (uses the Id property).

    .OUTPUTS
        DRMMActivityLog. Returns activity log objects with details about the activity.

    .NOTES
        - Requires an active connection to the Datto RMM API (use Connect-DattoRMM first).
        - The API uses integer IDs (not UIDs) for sites and users in this endpoint.
        - Results are paginated automatically.
        - UserId accepts up to 750 values. This safely stays within URL length limits
          (750 × 7 chars ≈ 5,250 chars, well within the 6KB safe threshold).

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/ActivityLog/Get-RMMActivityLog.md

    .LINK
        Connect-DattoRMM

    .LINK
        Get-RMMSite

    .LINK
        about_DRMMActivityLog

    #>

    [CmdletBinding(DefaultParameterSetName = 'Global')]

    param(
        [Parameter(
            ParameterSetName = 'Site',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMSite]
        $Site,

        [Parameter(
            ParameterSetName = 'SiteId',
            Mandatory = $true
        )]
        [long]
        $SiteId,

        [Parameter(
            Mandatory = $false
        )]
        [datetime]
        $Start = (Get-Date).AddHours(-24),

        [Parameter(
            Mandatory = $false
        )]
        [datetime]
        $End = (Get-Date),

        [Parameter(
            Mandatory = $false
        )]
        [ValidateSet(
            'Device', 
            'User'
        )]
        [string[]]
        $Entity,

        [Parameter(
            Mandatory = $false
        )]
        [string[]]
        $Category,

        [Parameter(
            Mandatory = $false
        )]
        [string[]]
        $Action,

        [Parameter(
            Mandatory = $false
        )]
        [ValidateCount(1, 750)]
        [long[]]
        $UserId,

        [Parameter(
            Mandatory = $false
        )]
        [ValidateSet(
            'asc', 
            'desc'
        )]
        [string]
        $Order = 'desc',

        [Parameter(
            Mandatory = $false
        )]
        [string]
        $SearchQuery,

        [Parameter(
            Mandatory = $false
        )]
        [switch]
        $UseExperimentalDetailClasses
    )

    begin {

        Write-Verbose "Getting activity logs with parameter set: $($PSCmdlet.ParameterSetName)"

        # Build query parameters with required date range
        $Parameters = @{
            from = $Start.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
            until = $End.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        }

        # Add optional filter parameters
        switch ($PSBoundParameters.Keys) {

            'Entity' {$Parameters['entities'] = ($Entity | ForEach-Object { $_.ToLower() }) -join ','}
            'Category' {$Parameters['categories'] = ($Category | ForEach-Object { $_.ToLower() }) -join ','}
            'Action' {$Parameters['actions'] = ($Action | ForEach-Object { $_.ToLower() }) -join ','}
            'UserId' {$Parameters['userIds'] = $UserId -join ','}
            'Order' {$Parameters['order'] = $Order}
            'SearchQuery' {$Parameters['searchQuery'] = $SearchQuery}

        }
    }

    process {

        # Set siteIds parameter based on scope
        switch ($PSCmdlet.ParameterSetName) {

            'Site' {$Parameters['siteIds'] = $Site.Id}
            'SiteId' {$Parameters['siteIds'] = $SiteId}

        }

        $InvokeParams = @{
            Method = 'GET'
            Path = 'activity-logs'
            Parameters = $Parameters
            Paginate = $true
            PageElement = 'activities'
        }

        Invoke-ApiMethod @InvokeParams | ForEach-Object {

            [DRMMActivityLog]::FromAPIMethod($_, $UseExperimentalDetailClasses.IsPresent)

        }
    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAfFk/hT5FOnxhr
# GtPHILf/bUNFHyUfujW4Jf2NkuZcdKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINQf9fw5fJL8I/8avuTYX/VOH3/R
# //1L0Mdpj4xksc5nMA0GCSqGSIb3DQEBAQUABIIBAHI9zdOrmlbNNzoUXF+DV7bS
# 8QehRwlN6+EfjbVWJ4E9awmMv3MTnFsam9g4PgFs639NKGVhhGvB3ySnsWde87Bh
# h+WqZiX5QWIreyra3bwMq38puMlhzkzExUzFTUiiZA+l5O6Hox0N9S75YSVXbDQH
# Wg/ZUaw8gM4Cjmg6RPDM81nFiwnNMjLEua69a4LEZoXw8RoLXVmBiMswWTv1Inat
# 8/EIu/jr5Jd9zksYLD1B7yIcj6QWcMYnrlDdtbaYksmArmSZ2AbI4OpecgpWju6y
# E7POO/A7zWWDoFUX16ZX2y9shVoivhOxK5VcFbKhqQaV3X0Os6ObdIE+02WvH/Y=
# SIG # End signature block
