<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Initialize-PageSize {
    <#
    .SYNOPSIS
        Retrieves the account's maximum page size and configures the module's page size settings.

    .DESCRIPTION
        This internal function queries the Datto RMM API to determine the account's maximum allowed
        page size for paginated requests. It then sets the module's page size based on a priority order:
        
        1. Existing session page size (if within account limits)
        2. Configured default page size (if within account limits)
        3. Previously set page size (if within account limits)
        4. Account maximum page size
        
        This function also serves as a connection test, as it requires a valid authentication token
        to successfully query the API.

    .EXAMPLE
        Initialize-RMMPageSize
        
        Queries the API and configures page size settings.

    .NOTES
        This is an internal function used by Connect-DattoRMM and potentially other functions
        that need to validate or refresh page size configuration.
        
        Sets the following script-scope variables:
        - $Script:MaxPageSize: Account's maximum allowed page size
        - $Script:PageSize: Currently active page size for API requests
        - $Script:SessionPageSize: Session's configured page size
        
        Requires an active authentication token in $Script:RMMAuth.
    #>

    [CmdletBinding()]
    param()

    Write-Debug "Testing connection to Datto RMM API & setting maxpage size."
    
    $PageSizeMethod = @{
        Path = "system/pagination"
        Method = 'Get'
    }

    $AccountMaxPageSize = (Invoke-ApiMethod @PageSizeMethod).max
    $Script:MaxPageSize = $AccountMaxPageSize

    # Check if there's a configured default page size
    If ($null -ne $Script:SessionPageSize -and $Script:SessionPageSize -le $AccountMaxPageSize) {

        $Script:PageSize = $Script:SessionPageSize
        Write-Verbose "Set page size to existing session value: $($Script:PageSize)."

    } elseif ($null -ne $Script:ConfigPageSize -and $Script:ConfigPageSize -le $AccountMaxPageSize) {

        $Script:PageSize = $Script:ConfigPageSize
        Write-Verbose "Set page size to configured default: $($Script:PageSize)."

    } elseif ($null -ne $Script:PageSize -and $Script:PageSize -le $AccountMaxPageSize) {

        # If PageSize was previously set in this session and is within limits, keep it
        Write-Verbose "Retaining previously set page size: $($Script:PageSize)."

    } else {

        $Script:PageSize = $AccountMaxPageSize
        Write-Verbose "Set page size to account maximum: $($Script:PageSize)."

    }

    $Script:SessionPageSize = $Script:PageSize
    Write-Verbose "Using page size: $($Script:PageSize)."
}
