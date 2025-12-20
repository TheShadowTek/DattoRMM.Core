function Get-RMMUser {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]

    param (
        [switch]
        $Force
    )

    begin {

        if (-not $Force -and -not $PSCmdlet.ShouldProcess("Account users", "Retrieve user information including email addresses and phone numbers")) {

            return

        }

    }

    process {

        Write-Debug "Getting RMM users"

        $APIMethod = @{
            Path = 'account/users'
            Method = 'Get'
            Paginate = $true
            PageElement = 'users'
        }

        Write-Debug "Getting all account users"
        Invoke-APIMethod @APIMethod | ForEach-Object {

            [DRMMUser]::FromAPIMethod($_)

        }

    }

}
