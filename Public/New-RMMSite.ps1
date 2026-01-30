<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function New-RMMSite {
    <#
    .SYNOPSIS
        Creates a new site in the Datto RMM account.

    .DESCRIPTION
        The New-RMMSite creates a new site in the authenticated user's account.
        A site represents a customer location or organisational unit within Datto RMM.

        Supports creating sites with proxy settings in a single operation,
        or proxy settings can be configured later using Set-RMMSiteProxy.

    .PARAMETER Name
        The name of the site to create. This parameter is required.

    .PARAMETER Description
        A description of the site.

    .PARAMETER Notes
        Additional notes about the site.

    .PARAMETER OnDemand
        Whether the site should be configured as an on-demand site.

    .PARAMETER SplashtopAutoInstall
        Whether Splashtop should be automatically installed on devices at this site.

    .PARAMETER ProxyHost
        The hostname or IP address of the proxy server.

    .PARAMETER ProxyPort
        The port number of the proxy server.

    .PARAMETER ProxyType
        The type of proxy server. Valid values: 'http', 'socks4', 'socks5'.

    .PARAMETER ProxyUsername
        The username for proxy authentication.

    .PARAMETER ProxyPassword
        The password for proxy authentication (as a SecureString).

    .EXAMPLE
        New-RMMSite -Name "Contoso Main Office"

        Creates a new site with the specified name.

    .EXAMPLE
        New-RMMSite -Name "Branch Office" -Description "West Coast Branch" -OnDemand

        Creates an on-demand site with a description.

    .EXAMPLE
        $ProxyPass = Read-Host -Prompt "Enter proxy password" -AsSecureString
        New-RMMSite -Name "Remote Site" -ProxyHost "proxy.contoso.com" -ProxyPort 8080 -ProxyType http -ProxyUsername "proxyuser" -ProxyPassword $ProxyPass

        Creates a site with HTTP proxy settings configured.

    .EXAMPLE
        New-RMMSite -Name "Test Site" -SplashtopAutoInstall -Notes "Testing environment"

        Creates a site with Splashtop auto-install enabled and notes.

    .INPUTS
        None. You cannot pipe objects to New-RMMSite.

    .OUTPUTS
        DRMMSite. Returns the newly created site object.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Proxy settings can be configured during site creation or added later using Set-RMMSiteProxy.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Description,

        [Parameter()]
        [string]
        $Notes,

        [Parameter()]
        [switch]
        $OnDemand,

        [Parameter()]
        [switch]
        $SplashtopAutoInstall,

        [Parameter()]
        [string]
        $ProxyHost,

        [Parameter()]
        [ValidateRange(1, 65535)]
        [int]
        $ProxyPort,

        [Parameter()]
        [ValidateSet('http', 'socks4', 'socks5')]
        [string]
        $ProxyType,

        [Parameter()]
        [string]
        $ProxyUsername,

        [Parameter()]
        [SecureString]
        $ProxyPassword
    )

    process {

        if (-not $PSCmdlet.ShouldProcess("Create new site '$Name'", "Create site", "Creating site")) {

            return

        }

        Write-Debug "Creating new RMM site: $Name"

        # Build request body
        $Body = @{
            name = $Name
        }

        switch ($PSBoundParameters.Keys) {

            'Description' {$Body.description = $Description}
            'Notes' {$Body.notes = $Notes}
            'OnDemand' {$Body.onDemand = $true}
            'SplashtopAutoInstall' {$Body.splashtopAutoInstall = $true}
        
        }

        # Build proxy settings if any proxy parameters are specified
        $ProxyParams = @('ProxyHost', 'ProxyPort', 'ProxyType', 'ProxyUsername', 'ProxyPassword')
        $HasProxySettings = $ProxyParams | Where-Object { $PSBoundParameters.ContainsKey($_) }

        if ($HasProxySettings) {

            # Validate required proxy parameters
            $RequiredProxyParams = @('ProxyHost', 'ProxyPort', 'ProxyType')
            $MissingParams = $RequiredProxyParams | Where-Object { -not $PSBoundParameters.ContainsKey($_) }

            if ($MissingParams) {

                throw "When configuring proxy settings, ProxyHost, ProxyPort, and ProxyType are required. Missing: $($MissingParams -join ', ')"

            }

            $ProxySettings = @{}

            switch ($PSBoundParameters.Keys) {

                'ProxyHost' {$ProxySettings.host = $ProxyHost}
                'ProxyPort' {$ProxySettings.port = $ProxyPort}
                'ProxyType' {$ProxySettings.type = $ProxyType}
                'ProxyUsername' {$ProxySettings.username = $ProxyUsername}
                'ProxyPassword' {

                    # Convert SecureString to plain text for API
                    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ProxyPassword)
                    $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
                    $ProxySettings.password = $PlainPassword
                    
                }
            }

            $Body.proxySettings = $ProxySettings

        }

        $APIMethod = @{
            Path = 'site'
            Method = 'Put'
            Body = $Body
        }

        $Response = Invoke-APIMethod @APIMethod

        [DRMMSite]::FromAPIMethod($Response)

    }
}

