<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
# DattoRMM.Core.psm1
# Main module file for Datto RMM API v2 PowerShell module

# Load class definitions
# Load class definitions - order is determined by cross-domain inheritance
using module '.\Private\Classes\Enums\Enums.psm1'
using module '.\Private\Classes\DRMMObject\DRMMObject.psm1'
using module '.\Private\Classes\DRMMToken\DRMMToken.psm1'
using module '.\Private\Classes\DRMMAPIKeySecret\DRMMAPIKeySecret.psm1'
using module '.\Private\Classes\DRMMAccount\DRMMAccount.psm1'
using module '.\Private\Classes\DRMMActivityLog\DRMMActivityLog.psm1'
using module '.\Private\Classes\DRMMAlert\DRMMAlert.psm1'
using module '.\Private\Classes\DRMMComponent\DRMMComponent.psm1'
using module '.\Private\Classes\DRMMNetworkInterface\DRMMNetworkInterface.psm1'
using module '.\Private\Classes\DRMMDeviceAudit\DRMMDeviceAudit.psm1'
using module '.\Private\Classes\DRMMEsxiHostAudit\DRMMEsxiHostAudit.psm1'
using module '.\Private\Classes\DRMMPrinterAudit\DRMMPrinterAudit.psm1'
using module '.\Private\Classes\DRMMJob\DRMMJob.psm1'
using module '.\Private\Classes\DRMMDevice\DRMMDevice.psm1'
using module '.\Private\Classes\DRMMVariable\DRMMVariable.psm1'
using module '.\Private\Classes\DRMMFilter\DRMMFilter.psm1'
using module '.\Private\Classes\DRMMSite\DRMMSite.psm1'
using module '.\Private\Classes\DRMMNetMapping\DRMMNetMapping.psm1'
using module '.\Private\Classes\DRMMStatus\DRMMStatus.psm1'
using module '.\Private\Classes\DRMMThrottleStatus\DRMMThrottleStatus.psm1'
using module '.\Private\Classes\DRMMUser\DRMMUser.psm1'

# Load throttle profile defaults from data file
$Script:ThrottleProfileDefaults = Import-PowerShellDataFile -Path "$PSScriptRoot\Private\Data\ThrottleProfiles.psd1"

# Load operation-to-rate-limit mapping for write operation classification
$Script:OperationMapping = Import-PowerShellDataFile -Path "$PSScriptRoot\Private\Data\OperationMapping.psd1"

# Load API method retry configuration from data file
$Script:ApiMethodRetry = Import-PowerShellDataFile -Path "$PSScriptRoot\Private\Data\RetryDefaults.psd1"

# Initialize script-scoped auth object
$Script:RMMAuth = $null

# Legacy single-bucket throttle mode flag (set by Connect-DattoRMM -LegacyThrottle)
$Script:LegacyThrottleMode = $false

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
$Script:ConfigApiMaxRetries = $null
$Script:ConfigApiRetryIntervalSeconds = $null
$Script:ConfigApiTimeoutSeconds = $null
$Script:ConfigTokenRefreshBufferMinutes = $null
$Script:TokenExpireHours = 100
$Script:TokenRefreshBufferMinutes = 10
$Script:MaxPageSize = $null

# Establish module-level config file path (used by Read-ConfigFile, Write-ConfigFile, and related functions)
$Script:ConfigPath = Join-Path (Join-Path $HOME '.DattoRMM.Core') 'config.json'

# Load and apply any saved configuration from disk
Initialize-SavedConfig

# Load built-in and user-defined export transforms
Initialize-ExportTransforms

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
    Remove-Variable -Name LegacyThrottleMode -Scope Script -ErrorAction SilentlyContinue
    Remove-Variable -Name RMMThrottle -Scope Script -ErrorAction SilentlyContinue
    Remove-Variable -Name ApiMethodRetry -Scope Script -ErrorAction SilentlyContinue
    Remove-Variable -Name ThrottleProfileDefaults -Scope Script -ErrorAction SilentlyContinue
    Remove-Variable -Name OperationMapping -Scope Script -ErrorAction SilentlyContinue
    Remove-Variable -Name ExportTransforms -Scope Script -ErrorAction SilentlyContinue
    
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAqZFC92vxNXWHn
# keYrsg7ixzmBiQ43JAYioEYXviF8NKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKstr+zYMoVfs7hAJl1BVn3J6Vbd
# TVC+TwUW4HPC7Q1pMA0GCSqGSIb3DQEBAQUABIIBABQVkeXejs7ERsz3XRi9Ixo9
# tfZvFWfW4H22GQEMl0bnducgYIoXsKlNVnR/ZT2kBgnNItr30IfiOiQsBKwT/nMD
# JNaw6VvnijeHepaq2KLjGOYMgl29AUlbe95osrml24K/1Ti6jKG1QhoVJyaPFK5Y
# GHJnYqpmiGpnxwqnXd2RUzvzSG1EnUiVuFGBjT0fhfCbM9opALyjUUlGVUjFmQYV
# aWmvEb6QKG8At3Rk+ytjsb01BqpLoyIzFK3PCzOZ0IYhS+hbnqwA5jRt9rbx0GCw
# PQcA8tEkRBMOrw2jU6HAPeJGeI6EzOyvu9VGwaBTBgNO21S6NgpSutEtG83v7eo=
# SIG # End signature block
