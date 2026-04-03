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

        The function prompts for confirmation before retrieving logs for each site, including in global
        mode. Supports Yes/No/Yes to All/No to All responses for safe handling of PII.

    .PARAMETER Site
        One or more DRMMSite objects (from Get-RMMSite) to retrieve activity logs for. Accepts pipeline
        input.

    .PARAMETER SiteId
        One or more site IDs (integer) to retrieve activity logs for.

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

    .PARAMETER UseExperimentalDetailClasses
        Enables experimental entity/category-specific detail classes for activity logs. When specified,
        details are parsed into strongly-typed classes based on entity, category, and action combinations
        (e.g., DRMMActivityLogDetailsDeviceJob for DEVICE/job activities). When not specified (default),
        all details use the generic DRMMActivityLogDetailsGeneric class with dynamic properties.

    .EXAMPLE
        Get-RMMActivityLog -Start "2024-01-01T00:00:00Z" -End "2024-01-02T00:00:00Z"

        Retrieves activity logs for all sites for January 1st, 2024. Prompts for each site.

    .EXAMPLE
        $Start = Get-Date '2024-01-01T00:00:00Z'
        PS > $End = Get-Date '2024-01-02T00:00:00Z'
        PS > Get-RMMSite -SiteName "Main Office" | Get-RMMActivityLog -Start $Start -End $End

        Retrieves activity logs for the "Main Office" site. Prompts for confirmation.

    .EXAMPLE
        Get-RMMActivityLog -SiteId 1234,5678 -Start (Get-Date '2024-01-01') -End (Get-Date '2024-01-02')

        Retrieves activity logs for sites with IDs 1234 and 5678. Prompts for each site.

    .EXAMPLE
        Get-RMMSite | Get-RMMActivityLog

        Retrieves activity logs for last 24 hours for all sites. Prompts for each site, or select Yes to All to proceed without further prompts.

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite (uses the Id property).

    .OUTPUTS
        DRMMActivityLog. Returns activity log objects with details about the activity.

    .NOTES
        - Requires an active connection to the Datto RMM API (use Connect-DattoRMM first).
        - Site IDs are batched in groups of 100 to avoid API/query length limits.
        - Confirmation prompt appears for each site (Yes/No/Yes to All/No to All supported).
        - The API uses integer IDs (not UIDs) for sites and users in this endpoint.
        - Results are paginated automatically.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/ActivityLog/Get-RMMActivityLog.md

    .LINK
        about_DRMMActivityLog
    #>

    [CmdletBinding(DefaultParameterSetName='Global', SupportsShouldProcess = $true, ConfirmImpact='High')]

    param(
        [Parameter(
            ParameterSetName = 'Site',
            ValueFromPipeline = $true
        )]
        [DRMMSite[]]
        $Site,

        [Parameter(ParameterSetName = 'SiteId')]
        [long[]]$SiteId,

        [Parameter(
            Mandatory = $false
        )]
        [datetime]$Start = (Get-Date).AddHours(-24),

        [Parameter(
            Mandatory = $false
        )]
        [datetime]$End = (Get-Date),

        [Parameter()]
        [ValidateSet('Device', 'User')]
        [string[]]$Entity,

        [Parameter()]
        [string[]]$Category,

        [Parameter()]
        [string[]]$Action,

        [Parameter()]
        [long[]]$UserId,

        [Parameter()]
        [ValidateSet('asc', 'desc')]
        [string]$Order = 'desc',

        [Parameter()]
        [switch]$UseExperimentalDetailClasses
    )

    begin {

        # Build query parameters (excluding siteIds), initializing with required date range parameters
        $Parameters = @{
            from = $Start.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
            until = $End.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        }

        switch ($PSBoundParameters.Keys) {

            'Entity' {$Parameters['entities'] = ($Entity | ForEach-Object { $_.ToLower() }) -join ','}
            'Category' {$Parameters['categories'] = ($Category | ForEach-Object { $_.ToLower() }) -join ','}
            'Action' {$Parameters['actions'] = ($Action | ForEach-Object { $_.ToLower() }) -join ','}
            'UserId' {$Parameters['userIds'] = $UserId -join ','}
            'Order' {$Parameters['order'] = $Order}
        
        }
        
        # Remove duplicate site IDs to limit unnecessary API calls
        if ($SiteId) {

            $SiteID = $SiteId | Sort-Object -Unique

        }

        [array]$AllSites = @()

    }

    process {

        # Collect sites based on parameter set
        switch ($PSCmdlet.ParameterSetName) {

            'Site' {[array]$AllSites += $Site}
            'SiteId' {[array]$AllSites = Get-RMMSite | Where-Object {$_.Id -in $SiteId}}
            'Global' {[array]$AllSites = Get-RMMSite}

        }
    }

    end {

        # Remove duplicate sites (if any) and confirm processing for each site
        [array]$AllSites = $AllSites | Sort-Object -Property Id -Unique
        $ProcessSites = @()

        foreach ($SiteObject in $AllSites) {

            if ($PSCmdlet.ShouldProcess("Activity logs for site: $($SiteObject.Name) may contain PII or sensitive information. Do you want to continue?", "Confirm Activity Log Retrieval for $($SiteObject.Name)")) {

                $ProcessSites += $SiteObject

            } else {
                
                Write-Warning "Skipping activity log retrieval for site: $($SiteObject.Name)"

            }
        }

        # Batch sites (default 100 per batch)
        $BatchSize = 100

        for ($BatchIndex = 0; $BatchIndex -lt $ProcessSites.Count; $BatchIndex += $BatchSize) {

            $BatchSites = $ProcessSites[$BatchIndex..([Math]::Min($BatchIndex+$BatchSize-1, $ProcessSites.Count-1))]
            $Parameters['siteIds'] = ($BatchSites | ForEach-Object {$_.Id}) -join ','
            $Path = 'activity-logs'

            Invoke-ApiMethod -Method 'GET' -Path $Path -Parameters $Parameters -Paginate -PageElement 'activities' | ForEach-Object {

                [DRMMActivityLog]::FromAPIMethod($_, $UseExperimentalDetailClasses.IsPresent)

            }
        }
    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCgr8kBdJHNa8zY
# zU0piYeE1BvSRSoIdN/YrXqU9L7Nb6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHJqVE6xBXI6r7D19kPR2oTgd351
# KziiMZjyluiwY3h+MA0GCSqGSIb3DQEBAQUABIIBAD0eWTEvY8UMa+VWDsscGrMo
# DGxqppnds8niHMw3Z1K3DFAZzTH9DthoBCyoxVgYNCfe+QF/c2oQEFmFdamgfWT/
# 7UZAG6xhu6KXpImonkdVSo1YvRaBiwjN72ZnRv4Sm/x2IRZR082I/OABnvwGhLUd
# DvUXi/YhDrx3xQ6j1kW06M71OJ6XnFvWDlu0w3W1nbNjZomUzJY8DoYHJOd4x6yD
# DuKGtCEjpHEJV9Tm0E/EQCvejVf08Gp/LnybxuucjonL7YCwcx4bYJ8tSTguCaB+
# yq7w9A5ybR4LFtqs+MJTKtnWTGpeN4HXi4DJwK1hVLot4+aDJZ9AaJIv2iE2eG4=
# SIG # End signature block
