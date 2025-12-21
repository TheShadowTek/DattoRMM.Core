function Get-RMMDevice {
    [CmdletBinding(DefaultParameterSetName = 'GlobalAll', SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(
            ParameterSetName = 'SiteAll',
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
            ParameterSetName = 'SiteAllUid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteUidNetSummary',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Uid')]
        [guid]
        $SiteUid,

        [Parameter(
            ParameterSetName = 'DeviceByUid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [guid]
        $DeviceUid,

        [Parameter(
            ParameterSetName = 'DeviceById',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Id')]
        [int]
        $DeviceId,

        [Parameter(
            ParameterSetName = 'DeviceByMacAddress',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
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

        [Parameter(ParameterSetName = 'GlobalAll')]
        [string]
        $Hostname,

        [Parameter(ParameterSetName = 'GlobalAll')]
        [Parameter(ParameterSetName = 'SiteAll')]
        [Parameter(ParameterSetName = 'SiteAllUid')]
        [long]
        $FilterId,

        [Parameter(ParameterSetName = 'GlobalAll')]
        [string]
        $DeviceType,

        [Parameter(ParameterSetName = 'GlobalAll')]
        [string]
        $OperatingSystem,

        [Parameter(ParameterSetName = 'GlobalAll')]
        [string]
        $SiteName,

        [Parameter(ParameterSetName = 'GlobalAll')]
        [Parameter(ParameterSetName = 'SiteAll')]
        [Parameter(ParameterSetName = 'SiteAllUid')]
        [Parameter(ParameterSetName = 'DeviceByUid')]
        [Parameter(ParameterSetName = 'DeviceById')]
        [Parameter(ParameterSetName = 'DeviceByMacAddress')]
        [switch]
        $IncludeLastLoggedInUser,

        [Parameter(ParameterSetName = 'GlobalAll')]
        [Parameter(ParameterSetName = 'SiteAll')]
        [Parameter(ParameterSetName = 'SiteAllUid')]
        [Parameter(ParameterSetName = 'DeviceByUid')]
        [Parameter(ParameterSetName = 'DeviceById')]
        [Parameter(ParameterSetName = 'DeviceByMacAddress')]
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

        Write-Debug "Getting RMM device(s) using parameter set: $($PSCmdlet.ParameterSetName)"

        if ($PSCmdlet.ParameterSetName -eq 'DeviceByUid') {

            # Single device by UID
            $APIMethod = @{
                Path = "device/$DeviceUid"
                Method = 'Get'
            }

            Write-Debug "Getting device by UID: $DeviceUid"
            $Response = Invoke-APIMethod @APIMethod

            [DRMMDevice]::FromAPIMethod($Response, $IncludeLastLoggedInUser.IsPresent)

        } elseif ($PSCmdlet.ParameterSetName -eq 'DeviceById') {

            # Single device by ID
            $APIMethod = @{
                Path = "device/id/$DeviceId"
                Method = 'Get'
            }

            Write-Debug "Getting device by ID: $DeviceId"
            $Response = Invoke-APIMethod @APIMethod

            [DRMMDevice]::FromAPIMethod($Response, $IncludeLastLoggedInUser.IsPresent)

        } elseif ($PSCmdlet.ParameterSetName -eq 'DeviceByMacAddress') {

            # Single or multiple devices by MAC address
            # Normalize MAC address by removing separators
            $NormalizedMacAddress = $MacAddress -replace '[:\-\.]', ''
            
            $APIMethod = @{
                Path = "device/macAddress/$NormalizedMacAddress"
                Method = 'Get'
                Paginate = $true
                PageElement = 'devices'
            }

            Write-Debug "Getting device(s) by MAC address: $NormalizedMacAddress"
            Invoke-APIMethod @APIMethod | ForEach-Object {

                [DRMMDevice]::FromAPIMethod($_, $IncludeLastLoggedInUser.IsPresent)

            }

        } elseif ($PSCmdlet.ParameterSetName -in 'SiteNetSummary', 'SiteUidNetSummary') {

            if ($Site) {

                $SiteUid = $Site.Uid

            }

            $APIMethod = @{
                Path = "site/$SiteUid/devices/network-interface"
                Method = 'Get'
                Paginate = $true
                PageElement = 'devices'
            }

            Write-Debug "Getting all devices with network interfaces for site UID: $SiteUid"
            Invoke-APIMethod @APIMethod | ForEach-Object {

                [DRMMDeviceNetworkInterface]::FromAPIMethod($_)

            }

        } elseif ($PSCmdlet.ParameterSetName -match '^Site') {

            if ($Site) {

                $SiteUid = $Site.Uid

            }

            $APIMethod = @{
                Path = "site/$SiteUid/devices"
                Method = 'Get'
                Paginate = $true
                PageElement = 'devices'
            }

            if ($FilterId) {

                $APIMethod.Parameters = @{ filterId = $FilterId }

            }

            switch ($PSCmdlet.ParameterSetName) {

                {$_ -in 'SiteAll','SiteAllUid'} {

                        Write-Debug "Getting all devices for site UID: $SiteUid"
                        Invoke-APIMethod @APIMethod | ForEach-Object {

                            [DRMMDevice]::FromAPIMethod($_, $IncludeLastLoggedInUser.IsPresent)

                        }
                    }
                }

        } else {

            # Global scope
            $APIMethod = @{
                Path = 'account/devices'
                Method = 'Get'
                Paginate = $true
                PageElement = 'devices'
            }

            # Build filter parameters
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

            Write-Debug "Getting global devices"
            Invoke-APIMethod @APIMethod | ForEach-Object {

                [DRMMDevice]::FromAPIMethod($_, $IncludeLastLoggedInUser.IsPresent)

            }
        }
    }
}
