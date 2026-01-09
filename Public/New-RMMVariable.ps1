function New-RMMVariable {
    <#
    .SYNOPSIS
        Creates a new variable in the Datto RMM account or site.

    .DESCRIPTION
        The New-RMMVariable function creates a new variable at either the account (global) level
        or at a specific site level. Variables can store configuration data that can be referenced
        in scripts and automation.

        Variables can optionally be masked to hide sensitive values in the Datto RMM UI.

    .PARAMETER Site
        A DRMMSite object to create the variable in. Accepts pipeline input from Get-RMMSite.

    .PARAMETER SiteUid
        The unique identifier (GUID) of a site to create the variable in.

    .PARAMETER Name
        The name of the variable to create.

    .PARAMETER Value
        The value to assign to the variable.

    .PARAMETER Masked
        Whether the variable value should be masked (hidden) in the Datto RMM UI. Use this for
        sensitive values like passwords or API keys.

    .EXAMPLE
        New-RMMVariable -Name "CompanyName" -Value "Contoso Ltd"

        Creates an account-level variable named "CompanyName".

    .EXAMPLE
        New-RMMVariable -Name "APIKey" -Value "secret123" -Masked

        Creates a masked account-level variable for sensitive data.

    .EXAMPLE
        Get-RMMSite -Name "Main Office" | New-RMMVariable -Name "SiteCode" -Value "MO001"

        Creates a site-level variable via pipeline.

    .EXAMPLE
        New-RMMVariable -SiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -Name "BackupPath" -Value "\\server\backup"

        Creates a site-level variable by specifying the site UID.

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite.
        You can also pipe objects with SiteUid or Uid properties.

    .OUTPUTS
        DRMMVariable. Returns the newly created variable object.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Variable names must be unique within their scope (account or site).
        The Masked property can only be set during creation and cannot be changed later.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Global', SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        [Parameter(
            ParameterSetName = 'BySiteObject',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMSite]
        $Site,

        [Parameter(
            ParameterSetName = 'BySiteUid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Uid')]
        [guid]
        $SiteUid,

        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Value,

        [Parameter()]
        [switch]
        $Masked
    )

    process {

        if ($Site) {
            $SiteUid = $Site.Uid
        }

        $Scope = if ($PSCmdlet.ParameterSetName -match 'Site') { 'Site' } else { 'Global' }
        $Target = if ($Scope -eq 'Site') { "site $SiteUid" } else { "account" }

        if (-not $PSCmdlet.ShouldProcess("Create variable '$Name' in $Target", "Create variable", "Creating variable")) {
            return
        }

        Write-Debug "Creating new RMM variable '$Name' at $Scope scope"

        # Build request body
        $Body = @{}

        if ($PSBoundParameters.ContainsKey('Name')) {
            $Body.name = $Name
        }

        if ($PSBoundParameters.ContainsKey('Value')) {
            $Body.value = $Value
        }

        if ($Masked.IsPresent) {
            $Body.masked = $true
        }

        # Determine API path based on scope
        $Path = if ($Scope -eq 'Site') {
            "site/$SiteUid/variable"
        } else {
            'account/variable'
        }

        $APIMethod = @{
            Path = $Path
            Method = 'Put'
            Body = $Body
        }

        $Response = Invoke-APIMethod @APIMethod

        [DRMMVariable]::FromAPIMethod($Response, $Scope, $SiteUid)
    }
}
