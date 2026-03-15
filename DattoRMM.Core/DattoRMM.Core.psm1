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

# Dot-source remaining .ps1 files in Private folder
Get-ChildItem -Path $PSScriptRoot\Private -Filter *.ps1 -Recurse | Where-Object {$_.BaseName -ne 'howtothrottle'} | ForEach-Object {

    . $_.FullName

}

# Dot-source all .ps1 files in Public folder (if exists)
if (Test-Path $PSScriptRoot\Public) {

    Get-ChildItem -Path $PSScriptRoot\Public -Filter *.ps1 -Recurse | ForEach-Object {

        . $_.FullName

    }
}

# Initialise throttle state with safe static defaults.
# Profile settings are overridden by Import-ThrottleProfile during config loading.
# Discovered limits are replaced by Initialize-ThrottleState on Connect-DattoRMM.
Set-ThrottleDefaults

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

# Establish module-level config file path (used by Read-ConfigFile, Write-ConfigFile, and related functions)
$Script:ConfigPath = Join-Path (Join-Path $HOME '.DattoRMM.Core') 'config.json'

# Load and apply any saved configuration from disk
Initialize-SavedConfig

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
