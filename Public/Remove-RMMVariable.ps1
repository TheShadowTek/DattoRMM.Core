<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Remove-RMMVariable {
    <#
    .SYNOPSIS
        Deletes a variable from the Datto RMM account or site.

    .DESCRIPTION
        The Remove-RMMVariable function permanently deletes a variable from either the
        account (global) level or from a specific site.

        This is a destructive operation that cannot be undone. Use the -Confirm parameter
        to prompt for confirmation before deleting each variable.

    .PARAMETER Variable
        A DRMMVariable object to delete. Accepts pipeline input from Get-RMMVariable.

    .PARAMETER VariableId
        The unique identifier of the variable to delete.

    .PARAMETER SiteUid
        The unique identifier (GUID) of the site containing the variable. Required when
        deleting site-level variables by VariableId.

    .EXAMPLE
        Get-RMMVariable -Name "OldVariable" | Remove-RMMVariable

        Deletes an account-level variable via pipeline.

    .EXAMPLE
        Remove-RMMVariable -VariableId 12345 -Confirm:$false

        Deletes an account-level variable by ID without prompting for confirmation.

    .EXAMPLE
        Get-RMMSite -Name "Closed Office" | Get-RMMVariable | Remove-RMMVariable -Confirm

        Deletes all variables from a site with confirmation prompts.

    .EXAMPLE
        Remove-RMMVariable -SiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -VariableId 67890

        Deletes a site-level variable by specifying site UID and variable ID.

    .INPUTS
        DRMMVariable. You can pipe variable objects from Get-RMMVariable.
        You can also pipe objects with VariableId and SiteUid properties.

    .OUTPUTS
        None. This function does not return any output.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        This operation is permanent and cannot be undone. Variables are immediately
        deleted from the Datto RMM system.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByVariableObject', SupportsShouldProcess, ConfirmImpact = 'High')]
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
        $SiteUid
    )

    process {

        # Determine scope and set working values
        if ($Variable) {

            $VariableId = $Variable.Id
            $Scope = $Variable.Scope
            $VariableName = $Variable.Name
            
            if ($Scope -eq 'Site') {

                $SiteUid = $Variable.SiteUid

            }

        } else {

            # When using VariableId parameter, determine scope by presence of SiteUid
            if ($PSBoundParameters.ContainsKey('SiteUid')) {

                $Scope = 'Site'

            } else {

                $Scope = 'Global'

            }

            $VariableName = "{$VariableId}"

        }

        if ($Scope -eq 'Site') {

            $Target = "site variable '$VariableName' (ID: $VariableId) from site $SiteUid"

        } else {

            $Target = "account variable '$VariableName' (ID: $VariableId)"

        }

        if (-not $PSCmdlet.ShouldProcess($Target, "Delete variable permanently")) {

            return

        }

        Write-Debug "Deleting RMM variable $VariableId at $Scope scope"

        # Determine API path based on scope
        if ($Scope -eq 'Site') {

            $Path = "site/$SiteUid/variable/$VariableId"

        } else {

            $Path = "account/variable/$VariableId"

        }

        $APIMethod = @{
            Path = $Path
            Method = 'Delete'
        }

        Invoke-APIMethod @APIMethod | Out-Null

    }
}

