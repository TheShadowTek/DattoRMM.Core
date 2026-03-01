<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Show-RMMToken {
    <#
    .SYNOPSIS
        Displays the current Datto RMM API token and authentication details.

    .DESCRIPTION
        Shows the contents of $Script:RMMAuth, including the access token, expiry, and other details.
        WARNING: The access token is sensitive. Do not share or publish this information.

    .NOTES
        This command requires confirmation and has ConfirmImpact set to Low.

    .EXAMPLE
        Show-RMMToken
        Displays the current API token and related details.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Show-RMMToken.md
    #>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param()

    Write-Warning "The following token is sensitive. Do not share or publish!"

    if ($PSCmdlet.ShouldProcess("console", "Show API Token")) {

        if ($null -eq $Script:RMMAuth) {

            throw "No authentication token found. Please connect first."

        } else {

            Write-Host "`nCurrent Datto RMM API Authentication Token:"
            Write-Host "-----------------------------------------------"
            Write-host "Access Token : $($Script:RMMAuth.AccessToken)"
            Write-host "Token Type : $($Script:RMMAuth.TokenType)"
            if ($Script:RMMAuth.ExpiresAt -eq [datetime]::new([datetime]::MaxValue.Ticks, [System.DateTimeKind]::Utc)) {

                Write-Host "Expires At : No Expiry (API Token)"

            } else {

                Write-Host "Expires At : $($Script:RMMAuth.ExpiresAt.ToLocalTime()) (UTC: $($Script:RMMAuth.ExpiresAt.ToString('HH:mm:ss')))"

            }        
        
        }
    }
}

