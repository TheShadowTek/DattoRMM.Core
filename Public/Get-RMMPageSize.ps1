function Get-RMMPageSize {

    [CmdletBinding()]

    param ()

    if (-not $Script:RMMAuth) {

        throw "Not connected. Use Connect-DattoRMM first."

    }

    [PSCustomObject]@{
        CurrentPageSize = $Script:PageSize
        MaximumPageSize = $Script:MaxPageSize
    }
}
