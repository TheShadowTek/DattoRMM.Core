<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMNetMapping {
    <#
    .SYNOPSIS
        Retrieves Datto Networking site mappings.

    .DESCRIPTION
        The Get-RMMNetMapping function retrieves the mapping between Datto RMM sites and
        Datto Networking sites. This mapping is used to associate RMM-managed devices with
        their corresponding Datto Networking configurations.

        Datto Networking provides network management capabilities, and this function helps
        correlate RMM sites with their network infrastructure.

    .EXAMPLE
        Get-RMMNetMapping

        Retrieves all Datto Networking site mappings for the account.

    .EXAMPLE
        $Mappings = Get-RMMNetMapping
        PS > $Mappings | Select-Object SiteName, NetworkSiteName

        Retrieves all mappings and displays the site names from both systems.

    .EXAMPLE
        Get-RMMNetMapping | Where-Object {$_.SiteUid -eq $MySiteUid}

        Retrieves the Datto Networking mapping for a specific RMM site.

    .EXAMPLE
        Get-RMMNetMapping | Format-Table SiteName, NetworkSiteName, Status

        Retrieves all mappings and displays them in a formatted table.

    .INPUTS
        None. You cannot pipe objects to Get-RMMNetMapping.

    .OUTPUTS
        DRMMNetMapping. Returns mapping objects with the following properties:
        - Uid: Mapping unique identifier
        - SiteUid: Datto RMM site identifier
        - SiteName: Datto RMM site name
        - NetworkSiteUid: Datto Networking site identifier
        - NetworkSiteName: Datto Networking site name
        - Status: Mapping status

    .NOTES

        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        This function is only relevant if your account uses Datto Networking.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMNetMapping.md

    .LINK
        about_DRMMNetMapping
    #>
    [CmdletBinding()]
    param ()

    process {

        Write-Debug "Getting RMM Datto Networking site mappings"

        $APIMethod = @{
            Path = 'account/dnet-site-mappings'
            Method = 'Get'
            Paginate = $true
            PageElement = 'dnetSiteMappings'
        }

        Invoke-APIMethod @APIMethod | Where-Object {try {[void][guid]$_.uid; $true} catch {$false}} | ForEach-Object {

            [DRMMNetMapping]::FromAPIMethod($_)

        }
    }
}

