function Get-RMMAccount {
    <#
    .SYNOPSIS
        Retrieves information about the authenticated Datto RMM account.

    .DESCRIPTION
        The Get-RMMAccount function retrieves detailed information about the currently authenticated
        Datto RMM account, including account details, device statistics, and configuration settings.

        The returned object includes:
        - Account ID and name
        - Currency settings
        - Account descriptor (billing email, device limit, timezone)
        - Device status statistics (total, online, offline, on-demand, managed)

    .EXAMPLE
        Get-RMMAccount

        Retrieves information about the authenticated account.

    .EXAMPLE
        $Account = Get-RMMAccount
        PS > $Account.Name
        PS > $Account.DevicesStatus

        Retrieves account information and displays specific properties.

    .EXAMPLE
        $Account = Get-RMMAccount
        PS > $Account.GetSummary()

        Retrieves account information and displays a summary using the built-in method.

    .EXAMPLE
        Get-RMMAccount | Select-Object Name, Currency, @{N='OnlineDevices';E={$_.DevicesStatus.NumberOfOnlineDevices}}

        Retrieves account information and displays selected properties including online device count.

    .INPUTS
        None. You cannot pipe objects to Get-RMMAccount.

    .OUTPUTS
        DRMMAccount. Returns an account object with the following properties:
        - Id (int): Account ID
        - Uid (string): Account unique identifier
        - Name (string): Account name
        - Currency (string): Currency code
        - Descriptor (DRMMAccountDescriptor): Billing email, device limit, timezone
        - DevicesStatus (DRMMAccountDevicesStatus): Device count statistics

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        The DevicesStatus property includes a GetSummary() method that returns a formatted
        string showing online/total devices and percentage.

    .LINK
        Connect-DattoRMM

    .LINK
        Get-RMMDevice

    .LINK
        about_DRMMAccount
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
