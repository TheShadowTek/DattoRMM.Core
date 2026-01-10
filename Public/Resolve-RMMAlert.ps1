function Resolve-RMMAlert {
    <#
    .SYNOPSIS
        Resolves a Datto RMM alert.

    .DESCRIPTION
        The Resolve-RMMAlert function marks an alert as resolved in Datto RMM.
        The alert is identified by its unique alert UID (GUID).

    .PARAMETER AlertUid
        The unique identifier (GUID) of the alert to resolve.
        This can be obtained from Get-RMMAlert or from the AlertUid property of an alert object.

    .PARAMETER Force
        Bypasses the confirmation prompt and immediately resolves the alert.

    .EXAMPLE
        Resolve-RMMAlert -AlertUid '12345678-1234-1234-1234-123456789012'

        Resolves the alert with the specified UID.

    .EXAMPLE
        Get-RMMAlert -Scope Global | Where-Object Priority -eq 'Critical' | Resolve-RMMAlert

        Resolves all critical global alerts with confirmation prompts.

    .EXAMPLE
        Get-RMMAlert -Scope Global | Where-Object Priority -eq 'Critical' | Resolve-RMMAlert -Force

        Resolves all critical global alerts without confirmation prompts.

    .EXAMPLE
        $Alert.Resolve()

        If $Alert is a DRMMAlert object, you can use its Resolve() method directly.

    .INPUTS
        System.Guid. You can pipe alert UIDs or alert objects (AlertUid property is extracted automatically) to this function.

    .OUTPUTS
        None. This function does not return any output on success.

    .NOTES
        Requires an active connection to the Datto RMM API (Connect-DattoRMM).
        
        The function will throw an error if:
        - Not connected to the API
        - Alert UID is invalid
        - User doesn't have permission to resolve the alert
        - Alert doesn't exist

    .LINK
        about_DRMMAlert

    .LINK
        Get-RMMAlert
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [guid]
        $AlertUid,

        [switch]
        $Force
    )

    process {
        $Target = "Alert: $AlertUid"

        if ($Force -or $PSCmdlet.ShouldProcess($Target, "Resolve alert")) {
            
            try {

                $APIMethod = @{
                    Path = "alert/$AlertUid/resolve"
                    Method = 'Post'
                }

                $null = Invoke-APIMethod @APIMethod
                Write-Verbose "Successfully resolved alert: $AlertUid"

            } catch {

                Write-Error "Failed to resolve alert ${AlertUid}: $_"

            }
        }
    }
}
