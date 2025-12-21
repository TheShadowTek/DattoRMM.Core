function Get-RMMComponent {

    <#

    .SYNOPSIS
    Fetches component records from the authenticated user's account.

    .DESCRIPTION
    Retrieves all components from Datto RMM. Components are scripts or procedures that can be executed on devices through jobs.

    .EXAMPLE
    Get-RMMComponent

    Retrieves all components available in the account.

    .EXAMPLE
    Get-RMMComponent | Where-Object { $_.CategoryCode -eq 'monitoring' }

    Retrieves all components and filters for monitoring category.

    .EXAMPLE
    Get-RMMComponent | ForEach-Object { $_.GetSummary() }

    Retrieves all components and displays a summary of each.

    .EXAMPLE
    $component = Get-RMMComponent | Where-Object { $_.Name -eq 'My Component' }
    $component.GetInputVariables()

    Retrieves all components, filters for a specific one, and displays its input variables.

    .OUTPUTS
    DRMMComponent

    .NOTES
    Components contain variables that define their input and output parameters.
    Use the GetInputVariables() and GetOutputVariables() methods to filter variables by direction.

    .LINK
    https://help.aem.autotask.net/en/Content/2SETUP/APIv2.htm

    #>

    [CmdletBinding()]
    param ()

    # Retrieve all components with pagination
    $Components = Invoke-APIMethod -Path 'account/components' -Method GET -Paginate -PageElement 'components'

    foreach ($Component in $Components) {

        [DRMMComponent]::FromAPIMethod($Component)

    }
}
