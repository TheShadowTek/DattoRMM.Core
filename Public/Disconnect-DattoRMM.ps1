function Disconnect-DattoRMM {
    <#
    .SYNOPSIS
        Disconnects from the Datto RMM API and clears authentication information.

    .DESCRIPTION
        The Disconnect-DattoRMM function clears the stored authentication token and credentials
        from the module's script scope, effectively ending the current API session.

        This function should be called when you are finished working with the Datto RMM API
        to ensure credentials are removed from memory.

    .EXAMPLE
        Disconnect-DattoRMM

        Disconnects from the Datto RMM API and clears stored authentication.

    .EXAMPLE
        Connect-DattoRMM -Key "your-api-key" -Secret $Secret
        PS > Get-RMMDevice
        PS > Disconnect-DattoRMM

        Connects to the API, performs operations, then disconnects and clears credentials.

    .INPUTS
        None. You cannot pipe objects to Disconnect-DattoRMM.

    .OUTPUTS
        None. This function does not generate output but clears authentication information from module scope.

    .NOTES
        After disconnecting, you will need to run Connect-DattoRMM again to re-authenticate
        before making additional API calls.

        The module also automatically clears authentication information when the module is removed
        from the session.

    .LINK
        Connect-DattoRMM
    #>

    $Script:RMMAuth = $null
    Write-Verbose "Disconnected from Datto RMM API."

}