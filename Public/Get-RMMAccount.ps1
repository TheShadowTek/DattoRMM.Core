function Get-RMMAccount {

    <#

    .SYNOPSIS
    Fetches the authenticated user's account data.

    .DESCRIPTION
    Retrieves account information including name, currency, device limits, and device status for the authenticated user's Datto RMM account.

    .EXAMPLE
    Get-RMMAccount

    Retrieves the account information.

    .EXAMPLE
    $account = Get-RMMAccount
    $account.GetSummary()

    Retrieves account information and displays a summary.

    .EXAMPLE
    $account = Get-RMMAccount
    $account.DevicesStatus.GetOnlinePercentage()

    Retrieves account information and displays the percentage of devices that are online.

    .OUTPUTS
    DRMMAccount

    .NOTES
    This function returns account-level information including billing details and device statistics.

    .LINK
    https://help.aem.autotask.net/en/Content/2SETUP/APIv2.htm

    #>

    [CmdletBinding()]
    param ()

    begin {

        # Validate connection
        if (-not $Script:RMMAuth) {

            throw 'Not authenticated. Please use Connect-DattoRMM first.'

        }

    }

    process {

        # Retrieve account information
        $Response = Invoke-APIMethod -Path 'account' -Method GET

        [DRMMAccount]::FromAPIMethod($Response)

    }

}
