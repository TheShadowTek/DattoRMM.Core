<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
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
        The value to assign to the variable. Accepts both string and SecureString.
        
        When a SecureString is provided:
        - The value is securely converted for the API call
        - Plaintext is cleared from memory immediately after use
        - The variable is NOT automatically masked (use -Masked if desired)

    .PARAMETER Masked
        Whether the variable value should be masked (hidden) in the Datto RMM UI. Use this for
        sensitive values like passwords or API keys.
        
        This must be explicitly specified and is independent of whether you use SecureString.

    .PARAMETER Force
        Bypasses the confirmation prompt.

    .EXAMPLE
        New-RMMVariable -Name "CompanyName" -Value "Contoso Ltd"

        Creates an account-level variable named "CompanyName".

    .EXAMPLE
        New-RMMVariable -Name "APIKey" -Value "secret123" -Masked

        Creates a masked account-level variable for sensitive data.

    .EXAMPLE
        $Secret = Read-Host -AsSecureString -Prompt "Enter API Key"
        PS > New-RMMVariable -Name "APIKey" -Value $Secret -Masked

        Creates a masked variable using SecureString for secure input and transport.

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
        DRMMVariable. Returns the newly created variable object (fetched via Get-RMMVariable).

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Variable names must be unique within their scope (account or site).
        The Masked property can only be set during creation and cannot be changed later.

        API Behavior: The Datto API does not return the created variable object, so this
        function fetches it using Get-RMMVariable by name.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Variables/New-RMMVariable.md
    #>
    [CmdletBinding(DefaultParameterSetName = 'Global', SupportsShouldProcess, ConfirmImpact = 'High')]
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

        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter()]
        [object]
        $Value,

        [Parameter()]
        [switch]
        $Masked,

        [Parameter()]
        [switch]
        $Force
    )

    process {

        if ($Site) {

            $SiteUid = $Site.Uid

        }

        $Scope = if ($PSCmdlet.ParameterSetName -match 'Site') {'Site'} else {'Global'}
        $Target = if ($Scope -eq 'Site') {"site $SiteUid"} else {"account"}

        if (-not $PSCmdlet.ShouldProcess($Target, "Create variable '$Name'") -and -not $Force) {

            return

        }

        Write-Debug "Creating new RMM variable '$Name' at $Scope scope"

        # Handle SecureString value conversion
        $PlainValue = $null

        if ($PSBoundParameters.ContainsKey('Value')) {

            if ($Value -is [SecureString]) {

                $PlainValue = ConvertFrom-SecureStringToPlaintext -SecureString $Value
                Write-Verbose "SecureString detected - converting securely for API call"

            } else {

                $PlainValue = $Value

            }
        }

        # Build request body
        $Body = @{}

        switch ($PSBoundParameters.Keys) {

            'Name' { $Body.name = $Name }
            'Value' { $Body.value = $PlainValue }
            'Masked' { $Body.masked = $true }

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

        # Invoke-ApiMethod does not throw on 400 errors by default, so use try/catch, throw on warnings
        try {

            Invoke-ApiMethod @APIMethod -WarningAction Stop | Out-Null

            
        } catch {

            Write-Warning "Failed to create variable '$Name' at $Scope scope.$(if ($Scope -eq 'Site') {" Site UID: $SiteUid."})"
            return

        }

        # API doesn't return the created variable, so fetch it by name
        $GetParams = @{
            Name = $Name
        }
        
        if ($Scope -eq 'Site') {

            $GetParams.SiteUid = $SiteUid

        }

        Get-RMMVariable @GetParams

    }

    end {

        # Clear plaintext value from memory
        $PlainValue = $null

    }
}

