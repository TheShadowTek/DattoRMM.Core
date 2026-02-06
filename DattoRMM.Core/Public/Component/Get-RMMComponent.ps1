<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMComponent {
    <#
    .SYNOPSIS
        Retrieves all components (scripts/jobs) from the Datto RMM account.

    .DESCRIPTION
        The Get-RMMComponent function retrieves all components available in the authenticated
        user's Datto RMM account. Components are reusable scripts or automation jobs that can
        be executed on managed devices.

        Each component includes information about its variables (inputs and outputs), category,
        and whether it requires credentials to run.

    .EXAMPLE
        Get-RMMComponent

        Retrieves all components in the account.

    .EXAMPLE
        Get-RMMComponent | Where-Object {$_.Name -like "*PowerShell*"}

        Retrieves all components with "PowerShell" in the name.

    .EXAMPLE
        Get-RMMComponent | Where-Object {$_.CredentialsRequired -eq $true}

        Retrieves all components that require credentials to execute.

    .EXAMPLE
        $Component = Get-RMMComponent | Where-Object {$_.Name -eq "Get System Info"}
        PS > $Component.GetInputVariables()

        Gets a specific component and displays its input variables.

    .EXAMPLE
        Get-RMMComponent | Select-Object Name, Description, CategoryCode | Format-Table

        Retrieves all components and displays their name, description, and category in a table.

    .INPUTS
        None. This function does not accept pipeline input.

    .OUTPUTS
        DRMMComponent. Returns component objects with the following notable properties:
        - Uid: Unique identifier for the component
        - Name: Display name of the component
        - Description: Description of what the component does
        - CategoryCode: Category the component belongs to
        - CredentialsRequired: Whether credentials are required
        - Variables: Array of input and output variables

        The component object also includes helper methods:
        - GetVariable(name): Get a specific variable by name
        - GetInputVariables(): Get all input variables
        - GetOutputVariables(): Get all output variables

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Component/Get-RMMComponent.md

    .LINK
        about_DRMMComponent

    .LINK
        New-RMMQuickJob

    .LINK
        Get-RMMJob
    #>
    [CmdletBinding()]
    param ()

    # Retrieve all components with pagination
    $Components = Invoke-APIMethod -Path 'account/components' -Method GET -Paginate -PageElement 'components'

    foreach ($Component in $Components) {

        [DRMMComponent]::FromAPIMethod($Component, $Script:SessionPlatform)

    }
}

