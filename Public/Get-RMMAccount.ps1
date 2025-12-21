function Get-RMMAccount {
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
