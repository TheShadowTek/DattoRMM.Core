function Set-RMMPageSize {
    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $PageSize
    )

    if (-not $Script:RMMAuth) {

        throw "Not connected. Use Connect-DattoRMM first."

    }

    if (-not $Script:MaxPageSize) {

        throw "Account maximum page size not yet determined. Please reconnect using Connect-DattoRMM."

    }

    if ($PageSize -gt $Script:MaxPageSize) {

        Write-Warning "Requested page size ($PageSize) exceeds account maximum ($($Script:MaxPageSize)). Setting to maximum."
        $Script:PageSize = $Script:MaxPageSize

    } else {

        $Script:PageSize = $PageSize

    }

    Write-Verbose "Page size set to $($Script:PageSize)."

}
