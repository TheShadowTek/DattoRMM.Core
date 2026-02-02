<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
# DattoRMM.Core.psm1
# Main module file for Datto RMM API v2 PowerShell module

# Load class definitions
using module '.\Private\Classes.psm1'

# Initialize script-scoped auth object
$Script:RMMAuth = $null

# Default configuration values (fallback if config file doesn't exist or fails to load)
$Script:ConfigPlatform = $null
$Script:ConfigPageSize = $null
$Script:ConfigThrottleProfile = $null
$Script:ConfigTokenExpireHours = $null
$Script:ConfigAPIMaxRetries = $null
$Script:ConfigAPIRetryIntervalSeconds = $null
$Script:ConfigAPITimeoutSeconds = $null
$Script:TokenExpireHours = 100
$Script:MaxPageSize = $null

# Throttle profile defaults
$Script:ThrottleProfileDefaults = @{
    'Cautious' = @{
        DelayMultiplier = 1250
        LowUtilCheckInterval = 25
        ThrottleUtilisationThreshold = 0.3
        ThrottleCutOffOverhead = 0.1
    }
    'Medium' = @{
        DelayMultiplier = 750
        LowUtilCheckInterval = 25
        ThrottleUtilisationThreshold = 0.5
        ThrottleCutOffOverhead = 0.05
    }
    'Aggressive' = @{
        DelayMultiplier = 500
        LowUtilCheckInterval = 50
        ThrottleUtilisationThreshold = 0.5
        ThrottleCutOffOverhead = 0.04
    }
    'DefaultProfile' = @{
        DelayMultiplier = 750
        LowUtilCheckInterval = 25
        ThrottleUtilisationThreshold = 0.5
        ThrottleCutOffOverhead = 0.05
    }
}

# Retry settings
$Script:APIMethodRetry = @{
    MaxRetries = 5
    RetryIntervalSeconds = 10
    TimeoutSeconds = 60
}

# Initialize throttle state variable, and set safe defaults
$Script:RMMThrottle = [ordered]@{
    Profile = 'DefaultProfile'          # Initialise default profile
    CheckInterval = 1                   # Force initialisation of throttle state
    CheckCount = 1                      # Number of checks since last update - force initial delay
    Utilisation = 0                     # Current rate limit utilisation (0 to 1) - force initial update
    LowUtilCheckInterval = 25           # Utilisation limit before delaying requests - throttling activation threshold
    DelayMultiplier = 750               # Multiplier for calculating delay when throttling
    DelayMS = 0                         # Current delay in milliseconds
    Pause = $false                      # Whether to pause requests entirely
    Throttle = $false                   # Whether to throttle requests
    ThrottleCutOffOverhead = 0.05       # Fraction of rate limit to reserve as safety margin (default 5%)
    ThrottleUtilisationThreshold = 0.5  # Utilisation threshold to start throttling
}

# Dot-source remaining .ps1 files in Private folder
Get-ChildItem -Path $PSScriptRoot\Private -Filter *.ps1 | Where-Object {$_.BaseName -ne 'howtothrottle'} | ForEach-Object {

    . $_.FullName

}

# Dot-source all .ps1 files in Public folder (if exists)
if (Test-Path $PSScriptRoot\Public) {

    Get-ChildItem -Path $PSScriptRoot\Public -Filter *.ps1 -Recurse | ForEach-Object {

        . $_.FullName

    }
}

# Load configuration from file if it exists
Write-Verbose "Attempting to load configuration file..."
$ConfigDir = Join-Path $HOME '.DattoRMM.Core'
$Script:ConfigPath = Join-Path $ConfigDir 'config.json'
$SavedConfig = Read-ConfigFile

if ($null -ne $SavedConfig) {

    try {

        switch ($SavedConfig.Keys) {

            'Platform' {
                $Script:ConfigPlatform = $SavedConfig.Platform
                $Script:SessionPlatform = $SavedConfig.Platform
                Write-Verbose "`tPlatform: $($Script:ConfigPlatform)"
            }

            'PageSize' {
                $Script:ConfigPageSize = $SavedConfig.PageSize
                $Script:SessionPageSize = $SavedConfig.PageSize
                Write-Verbose "`tPageSize: $($Script:ConfigPageSize)"
            }

            'TokenExpireHours' {
                $Script:TokenExpireHours = $SavedConfig.TokenExpireHours
                $Script:ConfigTokenExpireHours = $SavedConfig.TokenExpireHours

                Write-Verbose "`tTokenExpireHours: $($Script:TokenExpireHours)"
            }

            'APIMaxRetries' {
                $Script:APIMethodRetry.MaxRetries = $SavedConfig.APIMaxRetries
                $Script:ConfigAPIMaxRetries = $SavedConfig.APIMaxRetries
                Write-Verbose "`tAPIMaxRetries: $($Script:APIMethodRetry.MaxRetries)"
            }

            'APIRetryIntervalSeconds' {
                $Script:APIMethodRetry.RetryIntervalSeconds = $SavedConfig.APIRetryIntervalSeconds
                $Script:ConfigAPIRetryIntervalSeconds = $SavedConfig.APIRetryIntervalSeconds
                Write-Verbose "`tAPIRetryIntervalSeconds: $($Script:APIMethodRetry.RetryIntervalSeconds)"
            }

            'APITimeoutSeconds' {
                $Script:APIMethodRetry.TimeoutSeconds = $SavedConfig.APITimeoutSeconds
                $Script:ConfigAPITimeoutSeconds = $SavedConfig.APITimeoutSeconds
                Write-Verbose "`tAPITimeoutSeconds: $($Script:APIMethodRetry.TimeoutSeconds)"
            }
            'ThrottleProfile' {

                if ($SavedConfig.ThrottleProfile -ne 'Custom') {

                    Set-RMMConfig -ThrottleProfile $SavedConfig.ThrottleProfile
                    $Script:RMMThrottle.Profile = $SavedConfig.ThrottleProfile
                    $Script:ConfigThrottleProfile = $SavedConfig.ThrottleProfile
                    $Script:SessionThrottleProfile = $SavedConfig.ThrottleProfile
                    Write-Verbose "`tThrottleProfile: $($SavedConfig.ThrottleProfile)"

                } else {

                    # Load defaults for any incomplete or missing settings
                    Write-Warning "Loading custom configuration settings from $($Script:ConfigPath) - session behaviour may be unpredictable..."
                    $Script:ConfigThrottleProfile = 'Custom'
                    $Script:RMMThrottle.Profile = 'Custom'
                    $Script:RMMThrottle.DelayMultiplier =  $Script:ThrottleProfileDefaults.DefaultProfile.DelayMultiplier
                    $Script:RMMThrottle.LowUtilCheckInterval = $Script:ThrottleProfileDefaults.DefaultProfile.LowUtilCheckInterval
                    $Script:RMMThrottle.ThrottleCutOffOverhead = $Script:ThrottleProfileDefaults.DefaultProfile.ThrottleCutOffOverhead
                    $Script:RMMThrottle.ThrottleUtilisationThreshold = $Script:ThrottleProfileDefaults.DefaultProfile.ThrottleUtilisationThreshold

                    # Load custom defaults
                    switch ($SavedConfig.Keys) {

                        'DelayMultiplier' {
                            $Script:RMMThrottle.DelayMultiplier = $SavedConfig.DelayMultiplier
                            Write-Warning "`tCUSTOM DelayMultiplier: $($Script:RMMThrottle.DelayMultiplier)"
                        }
                        'LowUtilCheckInterval' {
                            $Script:RMMThrottle.LowUtilCheckInterval = $SavedConfig.LowUtilCheckInterval
                            Write-Warning "`tCUSTOM LowUtilCheckInterval: $($Script:RMMThrottle.LowUtilCheckInterval)"
                        }

                        'ThrottleCutOffOverhead' {
                            $Script:RMMThrottle.ThrottleCutOffOverhead = $SavedConfig.ThrottleCutOffOverhead
                            Write-Warning "`tCUSTOM ThrottleCutOffOverhead: $($Script:RMMThrottle.ThrottleCutOffOverhead)"
                        }

                        'ThrottleUtilisationThreshold' {
                            $Script:RMMThrottle.ThrottleUtilisationThreshold = $SavedConfig.ThrottleUtilisationThreshold
                            Write-Warning "`tCUSTOM ThrottleUtilisationThreshold: $($Script:RMMThrottle.ThrottleUtilisationThreshold)"
                        }
                    }
                }
            }
        }

    } catch {

        Write-Error "Error loading saved config $($Script:ConfigPath). Session settings may be incomplete: $($_.Exception.Message)"

    }

} else {

    $Script:RMMThrottle.Profile = 'DefaultProfile'
    Write-Verbose "No configuration file found; using default settings."

}

# Module removal handler - cleanup module variables
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {

    # Remove authentication variable and clear proxy settings
    if ($Script:RMMAuth) {

        if ($Script:RMMAuth.ContainsKey('ProxyCredential')) {

            $Script:RMMAuth.ProxyCredential = $null
            
        }

        Remove-Variable -Name RMMAuth -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name SessionPlatform -Scope Script -ErrorAction SilentlyContinue

    }
    
    # Remove throttle state variable
    if ($Script:RMMThrottle) {

        Remove-Variable -Name RMMThrottle -Scope Script -ErrorAction SilentlyContinue

    }
}
