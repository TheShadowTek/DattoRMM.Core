function Get-RMMStatus {
    <#
    .SYNOPSIS
        Retrieves the current status of the Datto RMM system.

    .DESCRIPTION
        The Get-RMMStatus function retrieves the operational status of the Datto RMM platform,
        including service availability and any system-wide issues or maintenance notifications.

        This function is useful for monitoring the health of the Datto RMM service and can be
        used in automation scripts to check service availability before performing operations.

    .EXAMPLE
        Get-RMMStatus

        Retrieves the current Datto RMM system status.

    .EXAMPLE
        $Status = Get-RMMStatus
        PS > if ($Status.IsOperational) {
        >>     Write-Host "System is operational"
        >> }

        Checks if the system is operational before proceeding.

    .EXAMPLE
        Get-RMMStatus | Select-Object Status, Message

        Retrieves system status and displays the status and any messages.

    .INPUTS
        None. You cannot pipe objects to Get-RMMStatus.

    .OUTPUTS
        DRMMStatus. Returns a status object with the following properties:
        - Status: Current system status
        - IsOperational: Boolean indicating if system is fully operational
        - Message: Any status messages or maintenance notifications
        - LastUpdated: Timestamp of status update

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Consider checking system status before running bulk operations or automated tasks.

    .LINK
        about_DRMMStatus

    #>
    [CmdletBinding()]
    param ()

    process {

        Write-Debug "Getting RMM system status"

        $APIMethod = @{
            Path = 'system/status'
            Method = 'Get'
        }

        $Response = Invoke-APIMethod @APIMethod
        [DRMMStatus]::FromAPIMethod($Response)

    }
}
