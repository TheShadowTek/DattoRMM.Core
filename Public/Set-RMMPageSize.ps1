<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Set-RMMPageSize {
    <#
    .SYNOPSIS
        Sets the default page size for Datto RMM API queries in the current session.

    .DESCRIPTION
        Sets the number of results returned per page for Datto RMM API queries in the
        current session. The maximum allowed is determined by your Datto RMM account
        (typically 250). If you specify a value above the maximum, it will be capped.
        The default page size is loaded from your configuration file if present and
        valid, otherwise the account maximum is used at connection time.

    .PARAMETER PageSize
        The number of results to return per page for API queries. Must be a positive
        integer. Values above your account's maximum (usually 250) will be capped.

    .EXAMPLE
        Set-RMMPageSize -PageSize 100

        Sets the page size to 100 for all subsequent API queries in the session (if
        allowed by your account).

    .NOTES
        The page size setting only affects the current session and is not persisted.
        The default and maximum page size is typically 250, but may vary by account.
        The value is set at connection time based on your config and account limits.

        For large pipelines, using a smaller page size (such as 100) can improve
        responsiveness and reduce memory usage, as each page is returned to the pipeline
        as soon as it is received.

    .LINK
        Get-RMMPageSize
    #>
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
        $Script:ConfigDefaultPageSize = $Script:MaxPageSize


    } else {

        $Script:PageSize = $PageSize
        $Script:ConfigDefaultPageSize = $PageSize

    }

    Write-Verbose "Page size set to $($Script:PageSize)."

}

