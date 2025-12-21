function Get-RMMComponent {
    [CmdletBinding()]
    param ()

    # Retrieve all components with pagination
    $Components = Invoke-APIMethod -Path 'account/components' -Method GET -Paginate -PageElement 'components'

    foreach ($Component in $Components) {

        [DRMMComponent]::FromAPIMethod($Component)

    }
}
