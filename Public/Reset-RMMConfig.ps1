function Reset-RMMConfig {
    <#
    .SYNOPSIS
        Resets Datto-RMM module configuration to defaults.

    .DESCRIPTION
        The Reset-RMMConfig function clears the persistent configuration file, resetting all
        settings to their default values. This affects future PowerShell sessions but does not
        modify the current session's runtime values.
        
        To reset configuration in the current session, reload the module after running this function.

    .PARAMETER Force
        Bypasses the confirmation prompt and immediately deletes the configuration file.

    .EXAMPLE
        Reset-RMMConfig

        Prompts for confirmation before resetting the configuration.

    .EXAMPLE
        Reset-RMMConfig -Force

        Resets the configuration without prompting for confirmation.

    .INPUTS
        None. You cannot pipe objects to Reset-RMMConfig.

    .OUTPUTS
        None. Displays a message indicating success or failure.

    .NOTES
        Configuration file location: $HOME/.datto-rmm/config.json
        
        This function only deletes the configuration file. Current session values remain unchanged
        until the module is reloaded.
        
        Default values after reset:
        - DefaultPlatform: Pinotage
        - DefaultPageSize: Account Maximum
        - LowUtilCheckInterval: 50
        - TokenExpireHours: 100

    .LINK
        Set-RMMConfig
        Get-RMMConfig
        Set-RMMPageSize
        Get-RMMPageSize
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [switch]
        $Force
    )

    $ConfigPath = Get-ConfigFilePath

    if (-not (Test-Path $ConfigPath)) {

        Write-Host "No configuration file exists. Nothing to reset." -ForegroundColor Yellow
        return

    }

    if ($Force -or $PSCmdlet.ShouldProcess("Datto-RMM configuration", "Reset to defaults")) {
        
        try {
            
            Remove-Item -Path $ConfigPath -Force -ErrorAction Stop
            Write-Host "Configuration reset successfully. Defaults will be used in future sessions." -ForegroundColor Green
            Write-Verbose "Deleted configuration file: $ConfigPath"
            
            # Clear current session config variables (but keep runtime values)
            Write-Warning "Current session configuration variables remain active. Reload the module to apply defaults."
            
        } catch {

            Write-Error "Failed to reset configuration: $_"
            
        }
    }
}
