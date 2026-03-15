<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMUser {
    <#
    .SYNOPSIS
        Retrieves user accounts from the Datto RMM API.

    .DESCRIPTION
        The Get-RMMUser function retrieves all user accounts in the Datto RMM system. This
        includes user information such as email addresses, phone numbers, roles, and access levels.

        PRIVACY NOTICE: This function retrieves personally identifiable information (PII)
        including user email addresses and phone numbers. By default, this function requires
        confirmation before executing. Use -Force to bypass the confirmation prompt.

    .PARAMETER Force
        Bypasses the confirmation prompt. Use this when automating scripts where interactive
        confirmation is not possible.

    .EXAMPLE
        Get-RMMUser

        Retrieves all users after confirmation.

    .EXAMPLE
        Get-RMMUser -Force

        Retrieves all users without confirmation prompt.

    .EXAMPLE
        Get-RMMUser -Force | Where-Object {$_.Role -eq 'Administrator'}

        Retrieves all administrator users.

    .EXAMPLE
        Get-RMMUser -Force | Select-Object Name, Email, Role

        Retrieves all users and displays selected properties.

    .EXAMPLE
        $Users = Get-RMMUser -Force
        PS > $Users | Group-Object Role | Select-Object Name, Count

        Retrieves users and groups them by role to show user counts per role.

    .INPUTS
        None. You cannot pipe objects to Get-RMMUser.

    .OUTPUTS
        DRMMUser. Returns user objects with the following properties:
        - Id: User numeric ID
        - Uid: User unique identifier
        - Name: User full name
        - Email: User email address
        - Phone: User phone number
        - Role: User role/permission level
        - Enabled: Whether the user account is active
        - LastLogin: Last login timestamp

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        This function retrieves PII and requires high-impact confirmation by default.
        Handle user data in compliance with your organisation's privacy policies.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMUser.md
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

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
        Invoke-ApiMethod @APIMethod | ForEach-Object {

            [DRMMUser]::FromAPIMethod($_)

        }
    }
}

