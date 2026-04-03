using module '..\DRMMObject\DRMMObject.psm1'

<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Represents a network mapping in the DRMM system, including properties such as name, unique identifier, description, associated network IDs, and portal URL.
.DESCRIPTION
    The DRMMNetMapping class models a network mapping within the DRMM platform. It includes properties such as Id, Uid, AccountUid, Name, Description, DatatoNetworkingNetworkIds, and PortalUrl. The class provides a constructor and a static method to create an instance from API response data. Additionally, it includes a method to open the portal URL associated with the network mapping in the default web browser. The class serves as a representation of network mappings within the DRMM system, allowing for easy access and management of network mapping information.
#>
class DRMMNetMapping : DRMMObject {

    # The identifier of the network mapping.
    [long]$Id
    # The unique identifier (UID) of the network mapping.
    [guid]$Uid
    # The unique identifier (UID) of the account.
    [string]$AccountUid
    # The name of the network mapping.
    [string]$Name
    # The description of the network mapping.
    [string]$Description
    # The network IDs associated with Datto Networking.
    [long[]]$DatatoNetworkingNetworkIds
    # The URL of the portal.
    [string]$PortalUrl

    DRMMNetMapping() : base() {

        $this.DatatoNetworkingNetworkIds = @()

    }

    static [DRMMNetMapping] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $NetMapping = [DRMMNetMapping]::new()
        $NetMapping.Id = $Response.id
        $NetMapping.Uid = $Response.uid
        $NetMapping.AccountUid = $Response.accountUid
        $NetMapping.Name = $Response.name
        $NetMapping.Description = $Response.description
        $NetMapping.PortalUrl = $Response.portalUrl
        
        if ($Response.dattoNetworkingNetworkIds) {

            $NetMapping.DatatoNetworkingNetworkIds = $Response.dattoNetworkingNetworkIds

        }

        return $NetMapping

    }

    <#
    .SYNOPSIS
        Opens the portal URL associated with the network mapping in the default web browser.
    .DESCRIPTION
        The OpenPortal method checks if the PortalUrl property is set for the network mapping. If it is available, it launches the URL in the default web browser using the Start-Process cmdlet. If the PortalUrl is not set, it issues a warning indicating that the portal URL is not available for the network mapping.
    .OUTPUTS
        This method does not return a value. It performs an action to open the portal URL in the default web browser.
    #>
    [void] OpenPortal() {

        if ($this.PortalUrl) {

            Start-Process $this.PortalUrl

        } else {

            Write-Warning "Portal URL is not available for network mapping $($this.Name)"

        }
    }
}