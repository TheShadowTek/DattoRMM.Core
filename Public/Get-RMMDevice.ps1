function Get-RMMDevice {
    [CmdletBinding(DefaultParameterSetName = 'GlobalAll')]
    param (
        [Parameter(
            ParameterSetName = 'SiteAll',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteByUid',
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
            ParameterSetName = 'SiteUidByUid',
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
        [Parameter(
            ParameterSetName = 'GlobalByUid',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteByUid',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteUidByUid',
            Mandatory = $true
        )]
        [guid]
        $DeviceUid,

        [Parameter(
            ParameterSetName = 'GlobalByHostname',
            Mandatory = $true
        )]
        [string]
        $Hostname,

        [Parameter(ParameterSetName = 'GlobalAll')]
        [Parameter(ParameterSetName = 'GlobalByUid')]
        [Parameter(ParameterSetName = 'GlobalByHostname')]
        [Parameter(ParameterSetName = 'SiteAll')]
        [Parameter(ParameterSetName = 'SiteAllUid')]
        [long]
        $FilterId,

        [Parameter(ParameterSetName = 'GlobalAll')]
        [Parameter(ParameterSetName = 'GlobalByUid')]
        [Parameter(ParameterSetName = 'GlobalByHostname')]
        [string]
        $DeviceType,

        [Parameter(ParameterSetName = 'GlobalAll')]
        [Parameter(ParameterSetName = 'GlobalByUid')]
        [Parameter(ParameterSetName = 'GlobalByHostname')]
        [string]
        $OperatingSystem,

        [Parameter(ParameterSetName = 'GlobalAll')]
        [Parameter(ParameterSetName = 'GlobalByUid')]
        [Parameter(ParameterSetName = 'GlobalByHostname')]
        [string]
        $SiteName,

        [Parameter(ParameterSetName = 'GlobalAll')]
        [Parameter(ParameterSetName = 'GlobalByUid')]
        [Parameter(ParameterSetName = 'GlobalByHostname')]
        [Parameter(ParameterSetName = 'SiteAll')]
        [Parameter(ParameterSetName = 'SiteByUid')]
        [Parameter(ParameterSetName = 'SiteAllUid')]
        [Parameter(ParameterSetName = 'SiteUidByUid')]
        [Parameter(ParameterSetName = 'DeviceByUid')]
        [switch]
        $IncludeLastLoggedInUser,

        [Parameter(ParameterSetName = 'GlobalAll')]
        [Parameter(ParameterSetName = 'GlobalByUid')]
        [Parameter(ParameterSetName = 'GlobalByHostname')]
        [Parameter(ParameterSetName = 'SiteAll')]
        [Parameter(ParameterSetName = 'SiteByUid')]
        [Parameter(ParameterSetName = 'SiteAllUid')]
        [Parameter(ParameterSetName = 'SiteUidByUid')]
        [Parameter(ParameterSetName = 'DeviceByUid')]
        [switch]
        $Force
    )

    begin {

        if ($IncludeLastLoggedInUser -and -not $Force) {

            $ConfirmMessage = "Revealing last logged in user information. This may contain sensitive data. Continue?"
            $ConfirmCaption = "Confirm Reveal Last Logged In User"

            if (-not $PSCmdlet.ShouldContinue($ConfirmMessage, $ConfirmCaption)) {

                Write-Warning "Operation cancelled by user."
                return

            }
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

                {$_ -in 'SiteByUid','SiteUidByUid'} {

                    Write-Debug "Getting site device by UID: $DeviceUid for site UID: $SiteUid"
                    Invoke-APIMethod @APIMethod | Where-Object {$_.uid -eq $DeviceUid} | ForEach-Object {

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

            switch ($PSCmdlet.ParameterSetName) {

                'GlobalAll' {

                    Write-Debug "Getting all global devices"
                    Invoke-APIMethod @APIMethod | ForEach-Object {

                        [DRMMDevice]::FromAPIMethod($_, $IncludeLastLoggedInUser.IsPresent)

                    }
                }

                'GlobalByUid' {

                    Write-Debug "Getting global device by UID: $DeviceUid"
                    Invoke-APIMethod @APIMethod | Where-Object {$_.uid -eq $DeviceUid} | ForEach-Object {

                        [DRMMDevice]::FromAPIMethod($_, $IncludeLastLoggedInUser.IsPresent)

                    }
                }

                'GlobalByHostname' {

                    Write-Debug "Getting global device by Hostname: $Hostname"
                    Invoke-APIMethod @APIMethod | ForEach-Object {

                        [DRMMDevice]::FromAPIMethod($_, $IncludeLastLoggedInUser.IsPresent)

                    }
                }
            }
        }
    }
}
