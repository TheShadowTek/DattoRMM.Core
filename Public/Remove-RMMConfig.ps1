<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Remove-RMMConfig {
    <#
    .SYNOPSIS
        Deletes the persistent DattoRMM.Core configuration file (factory reset for future sessions).

    .DESCRIPTION
        Remove-RMMConfig deletes the configuration file at $HOME/.DattoRMM.Core/config.json, removing all saved settings.
        This does not affect the current session or in-memory configuration.
        To apply defaults in the current session, use Set-RMMConfig -Default or reload the module.

    .PARAMETER Force
        Bypasses the confirmation prompt and immediately deletes the configuration file.

    .EXAMPLE
        Remove-RMMConfig

        Prompts for confirmation before deleting the configuration file.

    .EXAMPLE
        Remove-RMMConfig -Force

        Deletes the configuration file without prompting for confirmation.

    .INPUTS
        None. You cannot pipe objects to Remove-RMMConfig.

    .OUTPUTS
        None. Displays a message indicating success or failure.

    .NOTES
        Configuration file location: $HOME/.DattoRMM.Core/config.json
        This function only deletes the configuration file. Current session values remain unchanged until the module is reloaded.

    .LINK
        Save-RMMConfig
        Get-RMMConfig
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [switch]
        $Force
    )

    $ConfigPath = $Script:ConfigPath

    if (-not (Test-Path $ConfigPath)) {

        Write-Warning "No configuration file exists. Nothing to delete."
        return

    }

    if ($Force -or $PSCmdlet.ShouldProcess("DattoRMM.Core configuration $ConfigPath", "Delete config file")) {

        try {

            Remove-Item -Path $ConfigPath -Force -ErrorAction Stop
            Write-Host "Configuration file deleted. Defaults will be used in future sessions." -ForegroundColor Green
            Write-Warning "Current session configuration remains active. Reload the module to apply defaults."

        } catch {

            Write-Error "Failed to delete configuration file: $_"

        }
    }
}
