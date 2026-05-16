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

    .PARAMETER ApiMaxRetries
        Sets the maximum number of retry attempts for failed API requests. Valid range: 1-10. Default is 5. Use -Persist to save as the default for future sessions.

    .PARAMETER ApiRetryIntervalSeconds
        Sets the wait time in seconds between retry attempts. Valid range: 1-300. Default is 10. Use -Persist to save as the default for future sessions.

    .PARAMETER ApiTimeoutSeconds
        Sets the timeout in seconds for API requests. Valid range: 10-300. Default is 60. Use -Persist to save as the default for future sessions.

    .PARAMETER TokenRefreshBufferMinutes
        Sets the number of minutes before token expiry at which the module will proactively refresh the token. Valid range: 1-60. Default is 10. This prevents long-running paginated operations from failing due to mid-request token expiry. Use -Persist to save as the default for future sessions.

    .PARAMETER Persist
        If specified, saves the provided settings to the configuration file for future sessions. Without -Persist, changes apply only to the current session.

    .PARAMETER Default
        Resets all settings to module defaults in the current session. If used with -Persist, also deletes the persistent configuration file (full factory reset). Without -Persist, only the current session is affected and the saved config remains unchanged.

    .PARAMETER Force
        Skips confirmation prompts for impactful actions (such as resetting or saving configuration). Use with -Default or -Persist to bypass -Confirm and proceed immediately.

    .NOTES
        Confirmation logic is handled up front with early returns, ensuring efficient and predictable behaviour.
        Configuration is stored at: $HOME/.DattoRMM.Core/config.json
        At least one parameter must be specified unless using -Default. Settings take effect immediately in the session. Use -Persist to save for future sessions.

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

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Config/Set-RMMConfig.md

    .LINK
        Connect-DattoRMM

    .LINK
        Save-RMMConfig

    .LINK
        Get-RMMConfig

    .LINK
        Remove-RMMConfig

    .LINK
        about_DattoRMM.CoreThrottling

    .LINK
        about_DattoRMM.CoreConfiguration
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
        [ValidateRange(1, 10)]
        [int]
        $ApiMaxRetries,

        [Parameter(
            ParameterSetName = 'Set',
            Mandatory = $false
        )]
        [ValidateRange(1, 300)]
        [int]
        $ApiRetryIntervalSeconds,

        [Parameter(
            ParameterSetName = 'Set',
            Mandatory = $false
        )]
        [ValidateRange(10, 300)]
        [int]
        $ApiTimeoutSeconds,

        [Parameter(
            ParameterSetName = 'Set',
            Mandatory = $false
        )]
        [ValidateRange(1, 60)]
        [int]
        $TokenRefreshBufferMinutes,

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

    if (($PSBoundParameters.Keys | Where-Object {$_ -notin 'Persist', 'Default', 'Force'}).Count -lt 1) {

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

        # Reset session variables to defaults
        $Script:TokenExpireHours = 100
        $Script:TokenRefreshBufferMinutes = 10
        $Script:SessionPlatform = $null
        $Script:SessionPageSize = $null
        $Script:PageSize = $null

        # Reset throttle to default profile (Medium)
        $Script:RMMThrottle.Profile = 'DefaultProfile'

        foreach ($Key in $Script:ThrottleProfileDefaults['DefaultProfile'].Keys) {

            $Script:RMMThrottle[$Key] = $Script:ThrottleProfileDefaults['DefaultProfile'][$Key]

        }

        if ($Persist) {

            if (Test-Path -Path $Script:ConfigPath) {

                Remove-Item -Path $Script:ConfigPath -Force
                Write-Verbose "Deleted configuration file at: $Script:ConfigPath"

            }

            # Clear Config* tracking variables to reflect the now-empty persistent state
            $Script:ConfigPlatform = $null
            $Script:ConfigPageSize = $null
            $Script:ConfigThrottleProfile = $null
            $Script:ConfigTokenExpireHours = $null
            $Script:ConfigApiMaxRetries = $null
            $Script:ConfigApiRetryIntervalSeconds = $null
            $Script:ConfigApiTimeoutSeconds = $null
            $Script:ConfigTokenRefreshBufferMinutes = $null

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

            # Set throttle profile — iterate profile keys generically to stay in sync with ThrottleProfiles.psd1
            $ProfileName = [RMMThrottleProfile]::GetName($ThrottleProfile)
            Write-Verbose "Set ThrottleProfile to: $ProfileName"
            $Script:RMMThrottle.Profile = $ProfileName

            foreach ($Key in $Script:ThrottleProfileDefaults[$ProfileName].Keys) {

                $Script:RMMThrottle[$Key] = $Script:ThrottleProfileDefaults[$ProfileName][$Key]

            }

            if ($Persist) {

                $Config['ThrottleProfile'] = $ProfileName

            }
        }

        'TokenExpireHours' {

            Write-Verbose "Set TokenExpireHours to: $TokenExpireHours"
            $Script:TokenExpireHours = $TokenExpireHours

            if ($Persist) {

                $Config['TokenExpireHours'] = $TokenExpireHours

            }
        }

        'ApiMaxRetries' {

            Write-Verbose "Set ApiMaxRetries to: $ApiMaxRetries"
            $Script:ApiMethodRetry.MaxRetries = $ApiMaxRetries

            if ($Persist) {

                $Config['ApiMaxRetries'] = $ApiMaxRetries

            }
        }

        'ApiRetryIntervalSeconds' {

            Write-Verbose "Set ApiRetryIntervalSeconds to: $ApiRetryIntervalSeconds"
            $Script:ApiMethodRetry.RetryIntervalSeconds = $ApiRetryIntervalSeconds

            if ($Persist) {

                $Config['ApiRetryIntervalSeconds'] = $ApiRetryIntervalSeconds

            }
        }

        'ApiTimeoutSeconds' {

            Write-Verbose "Set ApiTimeoutSeconds to: $ApiTimeoutSeconds"
            $Script:ApiMethodRetry.TimeoutSeconds = $ApiTimeoutSeconds

            if ($Persist) {

                $Config['ApiTimeoutSeconds'] = $ApiTimeoutSeconds

            }
        }

        'TokenRefreshBufferMinutes' {

            Write-Verbose "Set TokenRefreshBufferMinutes to: $TokenRefreshBufferMinutes"
            $Script:TokenRefreshBufferMinutes = $TokenRefreshBufferMinutes

            if ($Persist) {

                $Config['TokenRefreshBufferMinutes'] = $TokenRefreshBufferMinutes

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

                'ApiMaxRetries' {
                    $Script:ConfigApiMaxRetries = $Script:ApiMethodRetry.MaxRetries
                }

                'ApiRetryIntervalSeconds' {
                    $Script:ConfigApiRetryIntervalSeconds = $Script:ApiMethodRetry.RetryIntervalSeconds
                }

                'ApiTimeoutSeconds' {
                    $Script:ConfigApiTimeoutSeconds = $Script:ApiMethodRetry.TimeoutSeconds
                }

                'TokenRefreshBufferMinutes' {
                    $Script:ConfigTokenRefreshBufferMinutes = $Script:TokenRefreshBufferMinutes
                }
            }

            Write-Host "Configuration saved successfully." -ForegroundColor Green

        } else {

            throw "Failed to save configuration."

        }
    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDBYUSqq9Yh8rOl
# eM0pOEhwjDrA8y4MxMMjhL48zps0S6CCA04wggNKMIICMqADAgECAhB464iXHfI6
# gksEkDDTyrNsMA0GCSqGSIb3DQEBCwUAMD0xFjAUBgNVBAoMDVJvYmVydCBGYWRk
# ZXMxIzAhBgNVBAMMGkRhdHRvUk1NLkNvcmUgQ29kZSBTaWduaW5nMB4XDTI2MDMz
# MTAwMTMzMFoXDTI4MDMzMTAwMjMzMFowPTEWMBQGA1UECgwNUm9iZXJ0IEZhZGRl
# czEjMCEGA1UEAwwaRGF0dG9STU0uQ29yZSBDb2RlIFNpZ25pbmcwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQChn1EpMYQgl1RgWzQj2+wp2mvdfb3UsaBS
# nxEVGoQ0gj96tJ2MHAF7zsITdUjwaflKS1vE6wAlOg5EI1V79tJCMxzM0bFpOdR1
# L5F2HE/ovIAKNkHxFUF5qWU8vVeAsOViFQ4yhHpzLen0WLF6vhmc9eH23dLQy5fy
# tELZQEc2WbQFa4HMAitP/P9kHAu6CUx5s4woLIOyyR06jkr3l9vk0sxcbCxx7+dF
# RrsSLyPYPH+bUAB8+a0hs+6qCeteBuUfLvGzpMhpzKAsY82WZ3Rd9X38i32dYj+y
# dYx+nx+UEMDLjDJrZgnVa8as4RojqVLcEns5yb/XTjLxDc58VatdAgMBAAGjRjBE
# MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU
# H+B0vf97dYXqdUX1YMcWhFsY6fcwDQYJKoZIhvcNAQELBQADggEBAJmD4EEGNmcD
# 1JtFoRGxuLJaTHxDwBsjqcRQRE1VPZNGaiwIm8oSQdHVjQg0oIyK7SEb02cs6n6Y
# NZbwf7B7WZJ4aKYbcoLug1k1x9SoqwBmfElECeJTKXf6dkRRNmrAodpGCixR4wMH
# KXqwqP5F+5j7bdnQPiIVXuMesxc4tktz362ysph1bqKjDQSCBpwi0glEIH7bv5Ms
# Ey9Gl3fe+vYC5W06d2LYVebEfm9+7766hsOgpdDVgdtnN+e6uwIJjG/6PTG6TMDP
# y+pr5K6LyUVYJYcWWUTZRBqqwBHiLGekPbxrjEVfxUY32Pq4QfLzUH5hhUCAk4HN
# XpF9pOzFLMUxggIDMIIB/wIBATBRMD0xFjAUBgNVBAoMDVJvYmVydCBGYWRkZXMx
# IzAhBgNVBAMMGkRhdHRvUk1NLkNvcmUgQ29kZSBTaWduaW5nAhB464iXHfI6gksE
# kDDTyrNsMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKEC
# gAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwG
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICR3pjT6gaDcHq6n1U7OHdJDnqcg
# sie8cRAHBLpdoU7lMA0GCSqGSIb3DQEBAQUABIIBACVSKVy+S+OHQCvntCRBfSm2
# 16yTZeiLWSh7vJVDp7jOs8WIsWunvVFGXEiyt0+j810vDe1XMEfDrVBnTreb+lBt
# kYiLdQBdBRYPfFids2ZoFVoZgp0UB6qkhw/5kJjKW2dJVGQKIaONUjk/DIwenhFG
# hJltAuIVcyM5wKouT/D3eYIevPxE/2z8FgpTQdr6aHms9AD30Bqn+10y2xFjopoQ
# sRV4nB1BayDXkrNJ3GrNcnXbXKh7ucacHJe8x9VxuhW+n/8gFbEBOzLl1D5HBwSq
# vQrwcgrxemsPTK/WyhdMUSYRO7VoOhIo83sBVONAelsV2Qz4kUAorYSSyIiDPgM=
# SIG # End signature block
