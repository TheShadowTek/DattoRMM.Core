function Get-RMMAlert {
    <#
    .SYNOPSIS
        Retrieves alerts from the Datto RMM API.

    .DESCRIPTION
        The Get-RMMAlert function retrieves alerts at different scopes: global (account-level),
        site-level, or device-level. Alerts can be filtered by status (Open, Resolved, or All)
        and can be retrieved for specific objects by UID.

        The function supports pipeline input from Get-RMMSite and Get-RMMDevice, making it easy
        to retrieve alerts for filtered sets of sites or devices.

    .PARAMETER Site
        A DRMMSite object to retrieve alerts for. Accepts pipeline input from Get-RMMSite.

    .PARAMETER SiteUid
        The unique identifier (GUID) of a site to retrieve alerts for.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of a device to retrieve alerts for. Accepts pipeline input
        from Get-RMMDevice.

    .PARAMETER AlertUid
        The unique identifier of a specific alert to retrieve.

    .PARAMETER Status
        Filter alerts by status. Valid values: 'All', 'Open', 'Resolved'. Default is 'All'.

    .EXAMPLE
        Get-RMMAlert

        Retrieves all alerts (both open and resolved) at the account level.

    .EXAMPLE
        Get-RMMAlert -Status Open

        Retrieves only open alerts at the account level.

    .EXAMPLE
        Get-RMMDevice -FilterId 12345 | Get-RMMAlert -Status Open

        Gets all devices matching filter 12345 and retrieves their open alerts.

    .EXAMPLE
        Get-RMMDevice -Name 'Servers' | Get-RMMDevice | Get-RMMAlert -Status Open

        Gets all devices matching filter 'Servers' and retrieves their open alerts.

    .EXAMPLE
        Get-RMMSite -Name "Contoso" | Get-RMMAlert -Status Resolved

        Gets the site named "Contoso" and retrieves all resolved alerts for that site.

    .EXAMPLE
        Get-RMMSite | Where-Object {$_.Name -like "Branch*"} | Get-RMMAlert

        Gets all sites with names starting with "Branch" and retrieves all alerts (open and resolved).

    .EXAMPLE
        Get-RMMDevice -Hostname "SERVER01" | Get-RMMAlert -Status All

        Gets the device named "SERVER01" and retrieves all its alerts.

    .EXAMPLE
        Get-RMMAlert -AlertUid "0e6cf376-e60a-4dc2-95b3-daa122e74de9"

        Retrieves a specific alert by its unique identifier.

    .EXAMPLE
        $Site = Get-RMMSite -Name "Main Office"
        PS > Get-RMMAlert -SiteUid $Site.Uid -Status Open

        Retrieves open alerts for a specific site using its UID.

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite.
        You can also pipe objects with DeviceUid or SiteUid properties.

    .OUTPUTS
        DRMMAlert. Returns alert objects with details about the alert status, priority, source, and more.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        When piping devices or sites, the Status parameter applies to all objects in the pipeline.

        The function retrieves alerts in batches and automatically handles pagination.

    .LINK
        about_DRMMAlert

    .LINK
        Connect-DattoRMM

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMSite

    .LINK
        Resolve-RMMAlert
    #>

    [CmdletBinding(DefaultParameterSetName = 'GlobalAll')]
    param (
        [Parameter(
            ParameterSetName = 'SiteAll',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMSite]
        $Site,

        [Parameter(
            ParameterSetName = 'DeviceAll',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [guid]
        $DeviceUid,

        [Parameter(
            ParameterSetName = 'SiteAllUid',
            Mandatory = $true
        )]
        [guid]
        $SiteUid,

        [Parameter(
            ParameterSetName = 'GlobalByUid',
            Mandatory = $true
        )]
        [guid]
        $AlertUid,

        [Parameter(
            ParameterSetName = 'GlobalAll'
        )]
        [Parameter(
            ParameterSetName = 'GlobalByUid'
        )]
        [Parameter(
            ParameterSetName = 'SiteAll'
        )]
        [Parameter(
            ParameterSetName = 'SiteAllUid'
        )]
        [Parameter(
            ParameterSetName = 'DeviceAll'
        )]
        [ValidateSet('All', 'Open', 'Resolved')]
        [string]
        $Status = 'All'
    )

    process {

        Write-Debug "Getting RMM alert(s) using parameter set: $($PSCmdlet.ParameterSetName)"

        if ($PSCmdlet.ParameterSetName -match '^Device') {

            # Device scope - handle Open, Resolved, or All
            $Methods = @()

            switch ($Status) {

                'Open' {

                    $Methods += @{
                        Path = "device/$DeviceUid/alerts/open"
                        Scope = 'Device'
                    }
                }

                'Resolved' {

                    $Methods += @{
                        Path = "device/$DeviceUid/alerts/resolved"
                        Scope = 'Device'
                    }
                }

                'All' {

                    $Methods += @{
                        Path = "device/$DeviceUid/alerts/open"
                        Scope = 'Device'
                    }
                    $Methods += @{
                        Path = "device/$DeviceUid/alerts/resolved"
                        Scope = 'Device'
                    }
                }
            }

            foreach ($Method in $Methods) {

                $APIMethod = @{
                    Path = $Method.Path
                    Method = 'Get'
                    Paginate = $true
                    PageElement = 'alerts'
                }

                Write-Debug "Getting device alerts from $($Method.Path)"
                Invoke-APIMethod @APIMethod | ForEach-Object {

                    [DRMMAlert]::FromAPIMethod($_, $null)

                }
            }

        } elseif ($PSCmdlet.ParameterSetName -match '^Site') {

            if ($Site) {

                $SiteUid = $Site.Uid

            }

            # Site scope - handle Open, Resolved, or All
            $Methods = @()

            switch ($Status) {

                'Open' {

                    $Methods += @{
                        Path = "site/$SiteUid/alerts/open"
                        Scope = 'Site'
                    }
                }

                'Resolved' {

                    $Methods += @{
                        Path = "site/$SiteUid/alerts/resolved"
                        Scope = 'Site'
                    }
                }

                'All' {

                    $Methods += @{
                        Path = "site/$SiteUid/alerts/open"
                        Scope = 'Site'
                    }
                    $Methods += @{
                        Path = "site/$SiteUid/alerts/resolved"
                        Scope = 'Site'
                    }
                }
            }

            foreach ($Method in $Methods) {

                $APIMethod = @{
                    Path = $Method.Path
                    Method = 'Get'
                    Paginate = $true
                    PageElement = 'alerts'
                }

                Write-Debug "Getting site alerts from $($Method.Path)"
                Invoke-APIMethod @APIMethod | ForEach-Object {

                    [DRMMAlert]::FromAPIMethod($_, $SiteUid)

                }
            }

        } else {

            # Global scope - handle Open, Resolved, or All
            $Methods = @()

            switch ($Status) {

                'Open' {

                    $Methods += @{
                        Path = 'account/alerts/open'
                        Scope = 'Global'
                    }
                }

                'Resolved' {

                    $Methods += @{
                        Path = 'account/alerts/resolved'
                        Scope = 'Global'
                    }
                }

                'All' {

                    $Methods += @{
                        Path = 'account/alerts/open'
                        Scope = 'Global'
                    }
                    $Methods += @{
                        Path = 'account/alerts/resolved'
                        Scope = 'Global'
                    }
                }
            }

            foreach ($Method in $Methods) {

                $APIMethod = @{
                    Path = $Method.Path
                    Method = 'Get'
                    Paginate = $true
                    PageElement = 'alerts'
                }

                switch ($PSCmdlet.ParameterSetName) {

                    'GlobalAll' {

                        Write-Debug "Getting global alerts from $($Method.Path)"
                        Invoke-APIMethod @APIMethod | ForEach-Object {

                            [DRMMAlert]::FromAPIMethod($_, $null)

                        }
                    }

                    'GlobalByUid' {

                        Write-Debug "Getting global alert by UID: $AlertUid from $($Method.Path)"
                        Invoke-APIMethod @APIMethod | Where-Object {$_.alertUid -eq $AlertUid} | ForEach-Object {

                            [DRMMAlert]::FromAPIMethod($_, $null)

                        }
                    }
                }
            }
        }
    }
}
