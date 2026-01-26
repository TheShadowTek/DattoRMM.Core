<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Set-RMMConfig {
    <#
    .SYNOPSIS
        Configures the current DattoRMM.Core session and optionally saves settings persistently.

    .DESCRIPTION
        Set-RMMConfig allows you to configure the current session's settings for the DattoRMM.Core module. You can update platform, page size, throttling, and token expiration for the current session. Use -Persist to save these settings to the configuration file for future sessions. Use -Default to reset all settings to module defaults (both in session and config).

        The TokenExpireHours setting controls how often the module will proactively refresh the API token before expiry. Changing this value does not invalidate the current token; it only updates the local refresh interval. Lower values mean the token is refreshed more frequently, reducing risk of accidental expiration during long sessions. Higher values mean the same token is reused longer, which may or may not offer a security benefit (less frequent token changes, but not invalidated on update). Note: The token is only refreshed locally; the previous token remains valid until it naturally expires or is revoked by the API provider.

    .PARAMETER Platform
        Sets the default Datto RMM platform region for connections in the current session. Valid values: Pinotage, Concord, Vidal, Merlot, Zinfandel, Syrah. Use -Persist to save as the default for future sessions.

    .PARAMETER PageSize
        Sets the default page size for API requests in the current session. Valid range: 1-250 (actual max depends on your Datto RMM account). Use -Persist to save as the default for future sessions.

    .PARAMETER ThrottleProfile
        Sets the throttling profile for API requests in the current session. Valid values: Cautious, Medium, Aggressive. Default is Medium. Use -Persist to save as the default for future sessions.

    .PARAMETER TokenExpireHours
        Sets the token refresh interval (in hours) for the current session. Valid range: 1-100. Default is 100. Use -Persist to save as the default for future sessions.

    .PARAMETER Persist
        If specified, saves the provided settings to the configuration file for future sessions. Without -Persist, changes apply only to the current session.

    .PARAMETER Default
        Resets all settings to module defaults in the current session. If used with -Persist, also deletes the persistent configuration file (full factory reset). Without -Persist, only the current session is affected and the saved config remains unchanged.

    .PARAMETER Force
        Skips confirmation prompts for impactful actions (such as resetting or saving configuration). Use with -Default or -Persist to bypass -Confirm and proceed immediately.

    .NOTES
        Confirmation logic is handled up front with early returns, ensuring efficient and predictable behavior.

    .EXAMPLE
        Set-RMMConfig -Platform Merlot

        Sets the default platform to Merlot for the current session only.

    .EXAMPLE
        Set-RMMConfig -Platform Pinotage -PageSize 100 -Persist

        Sets both the default platform and page size, and saves them for future sessions.

    .EXAMPLE
        Set-RMMConfig -ThrottleProfile Cautious -TokenExpireHours 50

        Configures advanced throttling and token refresh settings for the current session only.

    .EXAMPLE
        Set-RMMConfig -Default

        Resets all configuration to module defaults, both in session and in the config file.

    .INPUTS
        None. You cannot pipe objects to Set-RMMConfig.

    .OUTPUTS
        None. This function updates the session and/or persistent configuration file.

    .NOTES
        Configuration is stored at: $HOME/.DattoRMM.Core/config.json At least one parameter must be specified unless using -Default. Settings take effect immediately in the session. Use -Persist to save for future sessions.

    .LINK
        Connect-DattoRMM
        Save-RMMConfig
        Get-RMMConfig
        Reset-RMMConfig
        Set-RMMPageSize
        about_DattoRMM.CoreThrottling
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(
            ParameterSetName = 'Set',
            Mandatory = $false
        )]
        [RMMPlatform]
        $Platform,

        [Parameter(
            ParameterSetName = 'Set',
            Mandatory = $false
        )]
        [ValidateRange(1, 250)]
        [int]
        $PageSize,

        [Parameter(
            ParameterSetName = 'Set',
            Mandatory = $false
        )]
        [RMMThrottleProfile]
        $ThrottleProfile,

        [Parameter(
            ParameterSetName = 'Set',
            Mandatory = $false
        )]
        [ValidateRange(1, 100)]
        [int]
        $TokenExpireHours,

        [Parameter(
            ParameterSetName = 'Set',
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName = 'Default',
            Mandatory = $false
        )]
        [switch]
        $Persist,

        [Parameter(
            ParameterSetName = 'Default',
            Mandatory = $true
        )]
        [switch]
        $Default,

        [Parameter(
            Mandatory = $false
        )]
        [switch]
        $Force 
    )

    # Ensure at least one parameter is provided

    if (($PSBoundParameters.Keys | Where-Object {$_ -ne 'Persist'}).Count -lt 1) {

        throw "At least one configuration parameter must be specified."
        
    }

    if ($Default -and (-not $Force -and -not $PSCmdlet.ShouldProcess("DattoRMM.Core configuration", "Reset to default settings"))) {

        Write-Warning "No action taken. Use -Default to reset settings to defaults."
        return

    }

    if ($Persist -and (-not $Force -and -not $PSCmdlet.ShouldProcess("DattoRMM.Core configuration", "Update persistent configuration"))) {

        Write-Warning "No action taken. Use -Persist to save settings to persistent configuration."
        return

    } 

    if ($Default) {

        Write-Verbose "Resetting configuration to default settings."

        # Clear saved config
        $Config = @{}

        # Reset session variables to defaults
        $Script:TokenExpireHours = 100

        # Reset throttle to default profile (Medium)
        $Script:RMMThrottle.Profile = 'DefaultProfile'
        $Script:RMMThrottle.DelayMultiplier = $Script:ThrottleProfileDefaults.DefaultProfile.DelayMultiplier
        $Script:RMMThrottle.LowUtilCheckInterval = $Script:ThrottleProfileDefaults.DefaultProfile.LowUtilCheckInterval
        $Script:RMMThrottle.ThrottleCutOffOverhead = $Script:ThrottleProfileDefaults.DefaultProfile.ThrottleCutOffOverhead
        $Script:RMMThrottle.ThrottleUtilisationThreshold = $Script:ThrottleProfileDefaults.DefaultProfile.ThrottleUtilisationThreshold

        if ($Persist) {

            if (Test-Path -Path $Script:ConfigPath) {

                Remove-Item -Path $Script:ConfigPath -Force
                Write-Verbose "Deleted configuration file at: $Script:ConfigPath"

            }
        }

        return

    }

    # Read existing config if updating saved config
    if ($Persist) {

        $Config = Read-ConfigFile

        if ($null -eq $Config) {

            [hashtable]$Config = @{}

        }
    }

    switch ($PSBoundParameters.Keys) {

        'PageSize' {
            
            # If PageSize parameter greater than account max, ot will not be saved to config
            if ($null -eq $Script:MaxPageSize) {
                
                Write-Warning "MaxPageSize is unknown. Connect-DattoRMM must be run to determine account maximum page size before setting PageSize.$(if ($Persist) {"PageSize $PageSize will not be saved."})"
                $Script:SessionPageSize = $PageSize
                
            } elseif ($PageSize -gt $Script:MaxPageSize) {
                
                Write-Warning "Requested page size ($PageSize) exceeds account maximum ($($Script:MaxPageSize)). Setting to maximum.$(if ($Persist) {"PageSize $PageSize will not be saved."})"
                $Script:PageSize = $Script:MaxPageSize
                $Script:SessionPageSize = $Script:MaxPageSize
                
            } else {
                
                Write-Verbose "Set PageSize to: $PageSize"
                $Script:PageSize = $PageSize
                $Script:SessionPageSize = $PageSize

                if ($Persist) {

                    $Config['PageSize'] = $PageSize
                
                }
            }
        }
        
        'Platform' {

            Write-Verbose "Set Platform to: $Platform"
            $Script:SessionPlatform = $Platform.ToString()

            if ($Persist) {

                $Config['Platform'] = $Platform.ToString()

            }
        }

        'ThrottleProfile' {

            # Set throttle profile parameter
            Write-Verbose "Set ThrottleProfile to: $ThrottleProfile"
            $Script:RMMThrottle.Profile = [RMMThrottleProfile]::GetName($ThrottleProfile)
            $Script:RMMThrottle.DelayMultiplier = $Script:ThrottleProfileDefaults.$([RMMThrottleProfile]::GetName($ThrottleProfile)).DelayMultiplier
            $Script:RMMThrottle.LowUtilCheckInterval = $Script:ThrottleProfileDefaults.$([RMMThrottleProfile]::GetName($ThrottleProfile)).LowUtilCheckInterval
            $Script:RMMThrottle.ThrottleCutOffOverhead = $Script:ThrottleProfileDefaults.$([RMMThrottleProfile]::GetName($ThrottleProfile)).ThrottleCutOffOverhead
            $Script:RMMThrottle.ThrottleUtilisationThreshold = $Script:ThrottleProfileDefaults.$([RMMThrottleProfile]::GetName($ThrottleProfile)).ThrottleUtilisationThreshold

            if ($Persist) {

                $Config['ThrottleProfile'] = [RMMThrottleProfile]::GetName($ThrottleProfile)

            }
        }

        'TokenExpireHours' {

            Write-Verbose "Set TokenExpireHours to: $TokenExpireHours"
            $Script:TokenExpireHours = $TokenExpireHours

            if ($Persist) {

                $Config['TokenExpireHours'] = $TokenExpireHours

            }
        }
    }

    if ($Persist) {

        # Write config file
        $Success = Write-ConfigFile -Config $Config

        if ($Success) {

            switch ($PSBoundParameters.Keys) {

                'PageSize' {
                    $Script:ConfigPageSize = $Script:PageSize
                }

                'Platform' {
                    $Script:ConfigPlatform = $Script:SessionPlatform
                }

                'ThrottleProfile' {
                    $Script:ConfigThrottleProfile = $Script:RMMThrottle.Profile
                }

                'TokenExpireHours' {
                    $Script:ConfigTokenExpireHours = $Script:TokenExpireHours
                }
            }

            Write-Host "Configuration saved successfully." -ForegroundColor Green

        } else {

            throw "Failed to save configuration."

        }
    }
}

