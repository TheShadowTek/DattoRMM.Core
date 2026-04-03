<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMSite {
    <#
    .SYNOPSIS
        Retrieves sites from the Datto RMM API.

    .DESCRIPTION
        The Get-RMMSite function retrieves site information from Datto RMM. Sites represent
        customer organisations or locations within your RMM account.

        By default, this function excludes the "Deleted Devices" system site which has an 
        invalid GUID. Use the -DeletedDevices parameter to retrieve only that specific site.

        The function supports multiple query modes:
        - Get all sites (excludes Deleted Devices)
        - Get a specific site by UID
        - Search for sites by name
        - Get only the Deleted Devices system site
        - Include extended properties (settings, variables, filters)

        Extended properties allow you to retrieve related data for sites in a single command.

    .PARAMETER SiteUid
        The unique identifier (GUID) of a specific site to retrieve.

    .PARAMETER All
        Retrieve all sites in the account. This is the default behaviour. Set to $false to
        disable when using other parameters.

    .PARAMETER SiteName
        Search for sites by name using partial matching (LIKE operator). Returns all sites
        where the name contains the specified value.

    .PARAMETER ExtendedProperties
        Additional properties to retrieve for each site. Valid values:
        - Settings: Include site settings
        - Variables: Include site variables
        - Filters: Include device filters

        Use this to populate the SiteSettings, Variables, and Filters properties of the
        returned site objects.

    .PARAMETER DeletedDevices
        Retrieve only the special "Deleted Devices" system site. This is a system Datto RMM
        site that has an invalid GUID. This switch uses a dedicated parameter set and cannot
        be combined with other filtering parameters.
        
        Returns a DRMMDeletedDevicesSite object with a string Uid property instead of guid.
        
        WARNING: Methods inherited from DRMMSite (such as GetDevices(), GetAlerts(), etc.)
        will throw errors when called on this object due to the malformed GUID. This site is
        included only for completeness and should not be used in normal operations.

    .EXAMPLE
        Get-RMMSite

        Retrieves all sites in the account (excludes the Deleted Devices system site).

    .EXAMPLE
        Get-RMMSite -SiteUid "12067610-8504-48e3-b5de-60e48416aaad"

        Retrieves a specific site by its unique identifier.

    .EXAMPLE
        Get-RMMSite -SiteName "Contoso"

        Searches for sites containing "Contoso" in the name (partial match).

    .EXAMPLE
        Get-RMMSite -SiteName "Production" | Get-RMMDevice

        Searches for sites with "Production" in the name and retrieves all devices from those sites.

    .EXAMPLE
        Get-RMMSite -ExtendedProperties Settings, Variables

        Retrieves all sites and includes their settings and variables.

    .EXAMPLE
        $Site = Get-RMMSite -SiteUid $SiteUid -ExtendedProperties Settings
        PS > $Site.SiteSettings.GeneralSettings

        Retrieves a site with its settings and accesses the general settings.

    .EXAMPLE
        Get-RMMSite -DeletedDevices

        Retrieves only the \"Deleted Devices\" system site (if it exists). Returns a
        DRMMDeletedDevicesSite object with string Uid property. Note that methods like
        GetDevices() will fail due to the invalid GUID.

    .EXAMPLE
        Get-RMMSite | Sort-Object Name | Select-Object Name, Uid

        Retrieves all sites, sorts by name, and displays name and UID.

    .EXAMPLE
        $Sites = Get-RMMSite -ExtendedProperties Filters
        PS > $Sites | ForEach-Object {
        >>     [PSCustomObject]@{
        >>         SiteName = $_.Name
        >>         FilterCount = $_.Filters.Count
        >>     }
        >> }

        Retrieves sites with filters and displays the filter count for each.

    .INPUTS
        None. You cannot pipe objects to Get-RMMSite.

    .OUTPUTS
        DRMMSite. Returns site objects with the following properties:
        - Uid: Site unique identifier (guid)
        - Id: Site numeric ID
        - Name: Site name
        - Description: Site description
        - OnDemand: Whether site is on-demand
        - SplashtopAutoInstall: Splashtop auto-install setting
        - ProxySettings: Proxy configuration
        - DevicesStatus: Device statistics for the site
        - SiteSettings: Site settings (if ExtendedProperties includes Settings)
        - Variables: Site variables (if ExtendedProperties includes Variables)
        
        DRMMDeletedDevicesSite. When using -DeletedDevices, returns a derived site object:
        - Uid: Site unique identifier (string, invalid GUID format)
        - All other properties same as DRMMSite
        - WARNING: Inherited methods will fail due to invalid GUID
        - Filters: Device filters (if ExtendedProperties includes Filters)

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Using ExtendedProperties can significantly increase response time and API calls.
        Only request extended properties when needed.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Sites/Get-RMMSite.md

    .LINK
        about_DRMMSite

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMFilter
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param (
        [Parameter(
            ParameterSetName = 'Single',
            Mandatory
        )]
        [guid]
        $SiteUid,

        [Parameter(
            ParameterSetName = 'Search',
            Mandatory = $false
        )]
        [string]
        $SiteName,

        [Parameter(
            ParameterSetName = 'All'
        )]
        [Parameter(
            ParameterSetName = 'Single'
        )]
        [Parameter(
            ParameterSetName = 'Search'
        )]
        [RMMSiteExtendedProperty[]]
        $ExtendedProperties,

        [Parameter(
            ParameterSetName = 'DeletedDevices',
            Mandatory
        )]
        [switch]
        $DeletedDevices
    )

    $APIMethod = @{
        Path = ''
        Method = 'Get'
    }

    switch ($PSCmdlet.ParameterSetName) {

        'Single' {

            $APIMethod.Path = "site/$SiteUid"
            $Response = Invoke-ApiMethod @APIMethod
            $Site = [DRMMSite]::FromAPIMethod($Response)

            if ($ExtendedProperties.Count -gt 0) {
                
                Add-SiteExtendedProperties -Site $Site -ExtendedProperties $ExtendedProperties

            }

            return $Site

        }

        'DeletedDevices' {
            
            $APIMethod.Path = 'account/sites'
            $APIMethod.Paginate = $true
            $APIMethod.PageElement = 'sites'
            
            # Return only sites with invalid GUIDs (e.g., "Deleted Devices" system site)
            Invoke-ApiMethod @APIMethod | Where-Object {try {[void][guid]$_.uid; $false} catch {$true}} | ForEach-Object {
                
                [DRMMDeletedDevicesSite]::FromAPIMethod($_)
                
            }
        }

        {$_ -in 'All', 'Search'} {

            $APIMethod.Path = 'account/sites'
            $APIMethod.Paginate = $true
            $APIMethod.PageElement = 'sites'

            if ($SiteName) {

                $APIMethod.Parameters = @{siteName = $SiteName}

            }

            # Process sites - filter out invalid GUIDs
            Invoke-ApiMethod @APIMethod | Where-Object {try {[void][guid]$_.uid; $true} catch {$false}} | ForEach-Object {

                Write-Verbose "Processing site: $($_.name)"
                $Site = [DRMMSite]::FromAPIMethod($_)
                
                if ($ExtendedProperties.Count -gt 0) {

                    Add-SiteExtendedProperties -Site $Site -ExtendedProperties $ExtendedProperties

                }

                return $Site

            }
        }
    }
}

function Add-SiteExtendedProperties {
    param (
        [DRMMSite]
        $Site,

        [RMMSiteExtendedProperty[]]
        $ExtendedProperties
    )

    if ($ExtendedProperties -contains [RMMSiteExtendedProperty]::Settings) {

        $Site.SiteSettings = Get-RMMSiteSettings -SiteUid $Site.Uid

    }

    if ($ExtendedProperties -contains [RMMSiteExtendedProperty]::Variables) {

        $Site.Variables = Get-RMMVariable -SiteUid $Site.Uid

    }

    if ($ExtendedProperties -contains [RMMSiteExtendedProperty]::Filters) {

        $Site.Filters = Get-RMMFilter -Site $Site
        
    }
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCgCTMCM+8yvXxs
# bjk9m3ewMmMsg8X9YKZCZE8tVVa2cKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICyUfo35i/QKvpT8kgkLpXjIOwxJ
# tBkWrQson8A/3nDLMA0GCSqGSIb3DQEBAQUABIIBAH8FnbF0qOsiuJq4AJSm/M2a
# oBBziY0hjqIbbweC9nY/LUYE2p0xlI/SairDXxvP2IUXa74YeQq+eI6Zg5vp2ftJ
# Q9+BE+tWiZr6EutjDI1UTM41NcpTEAIUqJ7nmi21mDTJm4ZoKJRosWzhjO99Dxv6
# 4Xul8iSt2W+Rb0czM7Ts5VSiS6Cm1kLK/FjLtBjwE6S9NezFzjolFZYJf4LSUSEY
# H5ky7HVO3Tv9MfF9uLTxpnG6eZ5RbiX+hsuStPX4qv4HxVRoGm8zXvtlD9ymlAPf
# FRGwXxCkej8upmDjC6YMixyQeKXyQR93RyilnD+B1nsslneS5Gs346817y0uMDs=
# SIG # End signature block
