<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Loads persisted configuration from disk and applies it to session-scoped variables.
.DESCRIPTION
    Reads the saved configuration file via Read-ConfigFile and populates all Script-scoped
    configuration variables used throughout the session. This includes platform, page size,
    token expiry, API retry settings, and the active throttle profile.

    If no configuration file is found, the throttle profile defaults to 'DefaultProfile'
    and all other session variables remain at their module-initialisation defaults.

    If a configuration file is present but an error occurs during application, a non-terminating
    error is written and the session may be partially configured.

    Called once during module load, after all Private and Public functions have been dot-sourced.
#>
function Initialize-SavedConfig {
    [CmdletBinding()]
    param ()

    Write-Verbose "Attempting to load configuration file..."

    $SavedConfig = Read-ConfigFile

    if ($null -ne $SavedConfig) {

        try {

            switch ($SavedConfig.Keys) {

                'Platform' {
                    $Script:ConfigPlatform = $SavedConfig.Platform
                    $Script:SessionPlatform = $SavedConfig.Platform
                    Write-Verbose "Platform: $($Script:ConfigPlatform)"
                }

                'PageSize' {
                    $Script:ConfigPageSize = $SavedConfig.PageSize
                    $Script:SessionPageSize = $SavedConfig.PageSize
                    Write-Verbose "PageSize: $($Script:ConfigPageSize)"
                }

                'TokenExpireHours' {
                    $Script:TokenExpireHours = $SavedConfig.TokenExpireHours
                    $Script:ConfigTokenExpireHours = $SavedConfig.TokenExpireHours
                    Write-Verbose "TokenExpireHours: $($Script:TokenExpireHours)"
                }

                'APIMaxRetries' {
                    $Script:APIMethodRetry.MaxRetries = $SavedConfig.APIMaxRetries
                    $Script:ConfigAPIMaxRetries = $SavedConfig.APIMaxRetries
                    Write-Verbose "APIMaxRetries: $($Script:APIMethodRetry.MaxRetries)"
                }

                'APIRetryIntervalSeconds' {
                    $Script:APIMethodRetry.RetryIntervalSeconds = $SavedConfig.APIRetryIntervalSeconds
                    $Script:ConfigAPIRetryIntervalSeconds = $SavedConfig.APIRetryIntervalSeconds
                    Write-Verbose "APIRetryIntervalSeconds: $($Script:APIMethodRetry.RetryIntervalSeconds)"
                }

                'APITimeoutSeconds' {
                    $Script:APIMethodRetry.TimeoutSeconds = $SavedConfig.APITimeoutSeconds
                    $Script:ConfigAPITimeoutSeconds = $SavedConfig.APITimeoutSeconds
                    Write-Verbose "APITimeoutSeconds: $($Script:APIMethodRetry.TimeoutSeconds)"
                }

                'ThrottleProfile' {

                    Import-ThrottleProfile -Config $SavedConfig

                }
            }

        } catch {

            Write-Error "Error loading saved config $($Script:ConfigPath). Session settings may be incomplete: $($_.Exception.Message)"

        }

    } else {

        $Script:RMMThrottle.Profile = 'DefaultProfile'
        Write-Verbose "No configuration file found; using default settings."

    }

}
