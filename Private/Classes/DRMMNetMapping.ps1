<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '.\DRMMObject.psm1'

class DRMMNetMapping : DRMMObject {

    [long]$Id
    [guid]$Uid
    [string]$AccountUid
    [string]$Name
    [string]$Description
    [long[]]$DatatoNetworkingNetworkIds
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

    [void] OpenPortal() {

        if ($this.PortalUrl) {

            Start-Process $this.PortalUrl

        } else {

            Write-Warning "Portal URL is not available for site $($this.Name)"

        }
    }
}


