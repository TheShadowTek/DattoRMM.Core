function Set-RMMVariable {
    <#
    .SYNOPSIS
        Updates an existing variable in the Datto RMM account or site.

    .DESCRIPTION
        The Set-RMMVariable function updates the name and/or value of an existing variable at
        either the account (global) level or at a specific site level.

        NOTE: The Masked property can only be set during variable creation and cannot be
        changed after the variable has been created. Use New-RMMVariable with -Masked to
        create a masked variable.

    .PARAMETER Variable
        A DRMMVariable object to update. Accepts pipeline input from Get-RMMVariable.

    .PARAMETER VariableId
        The unique identifier of the variable to update.

    .PARAMETER SiteUid
        The unique identifier (GUID) of the site containing the variable. Required when
        updating site-level variables by VariableId.

    .PARAMETER Name
        The new name for the variable. If not specified when piping a variable object,
        the existing name is preserved.

    .PARAMETER Value
        The new value for the variable.

    .PARAMETER Force
        Bypasses the confirmation prompt.

    .EXAMPLE
        Get-RMMVariable -Name "CompanyName" | Set-RMMVariable -Value "Contoso Corporation"

        Updates the value of an account-level variable via pipeline.

    .EXAMPLE
        Set-RMMVariable -VariableId 12345 -Name "CompanyName" -Value "New Company Ltd"

        Updates both name and value of an account-level variable by ID.

    .EXAMPLE
        Get-RMMSite -Name "Main Office" | Get-RMMVariable -Name "SiteCode" | Set-RMMVariable -Value "MO002"

        Updates a site-level variable via pipeline.

    .EXAMPLE
        Set-RMMVariable -SiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -VariableId 67890 -Value "\\newserver\backup"

        Updates a site-level variable by specifying site UID and variable ID.

    .INPUTS
        DRMMVariable. You can pipe variable objects from Get-RMMVariable.
        You can also pipe objects with VariableId and SiteUid properties.

    .OUTPUTS
        DRMMVariable. Returns the updated variable object.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        The Masked property cannot be changed after a variable is created. If you need
        to change a variable to be masked (or unmasked), you must delete and recreate it.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByVariableObject', SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(
            ParameterSetName = 'ByVariableObject',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMVariable]
        $Variable,

        [Parameter(
            ParameterSetName = 'ByVariableId',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [long]
        $VariableId,

        [Parameter(
            ParameterSetName = 'ByVariableId',
            ValueFromPipelineByPropertyName = $true
        )]
        [guid]
        $SiteUid,

        [Parameter(
            ParameterSetName = 'ByVariableId',
            Mandatory = $true
        )]
        [Parameter(ParameterSetName = 'ByVariableObject')]
        [string]
        $Name,

        [Parameter(
            ParameterSetName = 'ByVariableId',
            Mandatory = $true
        )]
        [Parameter(ParameterSetName = 'ByVariableObject')]
        [string]
        $Value,

        [Parameter()]
        [switch]
        $Force
    )

    process {

        # Determine scope and set working values
        if ($Variable) {

            $VariableId = $Variable.Id
            $Scope = $Variable.Scope
            
            if ($Scope -eq 'Site') {

                $SiteUid = $Variable.SiteUid

            }

            # Default Name and Value to existing values if not specified
            if (-not $PSBoundParameters.ContainsKey('Name')) {

                $Name = $Variable.Name

            }

            if (-not $PSBoundParameters.ContainsKey('Value')) {

                $Value = $Variable.Value

            }

        } else {

            # When using VariableId parameter, determine scope by presence of SiteUid
            if ($PSBoundParameters.ContainsKey('SiteUid')) {

                $Scope = 'Site'

            } else {

                $Scope = 'Global'

            }
        }

        if ($Scope -eq 'Site') {

            $Target = "site variable $VariableId in site $SiteUid"

        } else {

            $Target = "account variable $VariableId"

        }

        if (-not $PSCmdlet.ShouldProcess($Target, "Update variable '$Name'")) {

            return

        }

        Write-Debug "Updating RMM variable $VariableId at $Scope scope"

        # Build request body
        $Body = @{
            name = $Name
            value = $Value
        }

        # Determine API path based on scope
        if ($Scope -eq 'Site') {

            $Path = "site/$SiteUid/variable/$VariableId"

        } else {

            $Path = "account/variable/$VariableId"
        }

        $APIMethod = @{
            Path = $Path
            Method = 'Post'
            Body = $Body
        }

        $Response = Invoke-APIMethod @APIMethod

        # Fetch the updated variable since API doesn't return it
        $GetParams = @{
            Id = $VariableId
        }

        if ($Scope -eq 'Site') {

            $GetParams.SiteUid = $SiteUid

        }

        Get-RMMVariable @GetParams

    }
}
