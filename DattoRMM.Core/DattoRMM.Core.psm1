<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
# DattoRMM.Core.psm1
# Main module file for Datto RMM API v2 PowerShell module

# Load class definitions
using module '.\Private\Classes\Classes.psm1'

# Load throttle profile defaults from data file
$Script:ThrottleProfileDefaults = Import-PowerShellDataFile -Path "$PSScriptRoot\Private\Data\ThrottleProfiles.psd1"

# Load operation-to-rate-limit mapping for write operation classification
$Script:OperationMapping = Import-PowerShellDataFile -Path "$PSScriptRoot\Private\Data\OperationMapping.psd1"

# Load API method retry configuration from data file
$Script:APIMethodRetry = Import-PowerShellDataFile -Path "$PSScriptRoot\Private\Data\RetryDefaults.psd1"

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

# Initialize throttle state variable with safe defaults for multi-bucket model
# Profile settings are overridden by Import-ThrottleProfile during config loading.
# Discovered limits are populated by Initialize-ThrottleState on Connect-DattoRMM.
$Script:RMMThrottle = [ordered]@{
    Profile = 'DefaultProfile'                                                      # Active throttle profile name
    DelayMultiplier = 750                                                           # Delay multiplier for global account bucket throttling
    ThrottleCutOffOverhead = 0.05                                                   # Safety margin below accountCutOffRatio for pause trigger
    ThrottleUtilisationThreshold = 0.3                                              # Utilisation ratio at which throttling activates
    CalibrationBaseSeconds = 8                                                      # Ceiling interval at high confidence and zero drift
    CalibrationMinSeconds = 0.5                                                     # Absolute floor to prevent excessive API calibration calls
    CalibrationConfidenceCount = 50                                                 # Local samples needed before interval reaches full base
    DriftThresholdPercent = 0.02                                                    # Drift gap at which accelerated calibration begins (2%)
    DriftScalingFactor = 2                                                          # How aggressively interval shrinks as drift exceeds threshold
    WriteDelayMultiplier = 1000                                                     # Delay multiplier for write bucket throttling
    UnknownOperationSafetyFactor = 0.3                                              # Fractional delay for unmapped write operations
    WindowSizeSeconds = 60                                                          # Rolling window size (discovered from API)
    AccountLimit = 600                                                              # Global account rate limit (discovered from API)
    AccountCutOffRatio = 0.9                                                        # Account cut-off ratio (discovered from API)
    WriteLimit = 600                                                                # Global write rate limit (discovered from API)
    AccountLocalTimestamps = [System.Collections.Generic.List[datetime]]::new()     # Local timestamps for global account bucket
    WriteLocalTimestamps = [System.Collections.Generic.List[datetime]]::new()       # Local timestamps for global write bucket
    OperationBuckets = @{}                                                          # Per-operation write buckets (discovered from API)
    LastCalibrationUtc = [datetime]::MinValue                                       # Force initial calibration
    SamplesAtLastCalibration = 0                                                    # Local account sample count at last calibration (for request gate)
    AccountUtilisation = 0.0                                                        # Computed global account utilisation
    WriteUtilisation = 0.0                                                          # Computed global write utilisation
    DelayMS = 0                                                                     # Current computed delay in milliseconds
    Pause = $false                                                                  # Hard pause flag
    Throttle = $false                                                               # Soft throttle flag
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
    
    # Remove throttle state and module defaults
    Remove-Variable -Name RMMThrottle -Scope Script -ErrorAction SilentlyContinue
    Remove-Variable -Name APIMethodRetry -Scope Script -ErrorAction SilentlyContinue
    Remove-Variable -Name ThrottleProfileDefaults -Scope Script -ErrorAction SilentlyContinue
    Remove-Variable -Name OperationMapping -Scope Script -ErrorAction SilentlyContinue
    
}
