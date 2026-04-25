<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
@{

# Script module or binary module file associated with this manifest.
RootModule = 'DattoRMM.Core.psm1'

# Version number of this module. 
ModuleVersion = '0.5.53'

# Supported PSEditions
CompatiblePSEditions = @('Core')

# ID used to uniquely identify this module
GUID = '7dc3bd88-a8ca-4498-94bb-bf4d72416b6b'

# Author of this module
Author = 'Robert Faddes'

# Company or vendor of this module
CompanyName = 'Robert Faddes'

# Copyright statement for this module
Copyright = '(c) 2025-2026 Robert Faddes. All rights reserved.'

# Description of the functionality provided by this module
Description = 'PowerShell module for interfacing with Datto RMM API v2'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '7.4'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = @(
    'Private\\Classes\\DRMMAccount\\DRMMAccount.Types.ps1xml'
    'Private\\Classes\\DRMMActivityLog\\DRMMActivityLog.Types.ps1xml'
    'Private\\Classes\\DRMMAlert\\DRMMAlert.Types.ps1xml'
    'Private\\Classes\\DRMMComponent\\DRMMComponent.Types.ps1xml'
    'Private\\Classes\\DRMMNetworkInterface\\DRMMNetworkInterface.Types.ps1xml'
    'Private\\Classes\\DRMMDeviceAudit\\DRMMDeviceAudit.Types.ps1xml'
    'Private\\Classes\\DRMMEsxiHostAudit\\DRMMEsxiHostAudit.Types.ps1xml'
    'Private\\Classes\\DRMMPrinterAudit\\DRMMPrinterAudit.Types.ps1xml'
    'Private\\Classes\\DRMMJob\\DRMMJob.Types.ps1xml'
    'Private\\Classes\\DRMMDevice\\DRMMDevice.Types.ps1xml'
    'Private\\Classes\\DRMMVariable\\DRMMVariable.Types.ps1xml'
    'Private\\Classes\\DRMMFilter\\DRMMFilter.Types.ps1xml'
    'Private\\Classes\\DRMMSite\\DRMMSite.Types.ps1xml'
    'Private\\Classes\\DRMMNetMapping\\DRMMNetMapping.Types.ps1xml'
    'Private\\Classes\\DRMMStatus\\DRMMStatus.Types.ps1xml'
    'Private\\Classes\\DRMMUser\\DRMMUser.Types.ps1xml'
)

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @(
    'Private\\Classes\\DRMMAccount\\DRMMAccount.Format.ps1xml'
    'Private\\Classes\\DRMMActivityLog\\DRMMActivityLog.Format.ps1xml'
    'Private\\Classes\\DRMMAlert\\DRMMAlert.Format.ps1xml'
    'Private\\Classes\\DRMMComponent\\DRMMComponent.Format.ps1xml'
    'Private\\Classes\\DRMMNetworkInterface\\DRMMNetworkInterface.Format.ps1xml'
    'Private\\Classes\\DRMMDeviceAudit\\DRMMDeviceAudit.Format.ps1xml'
    'Private\\Classes\\DRMMEsxiHostAudit\\DRMMEsxiHostAudit.Format.ps1xml'
    'Private\\Classes\\DRMMPrinterAudit\\DRMMPrinterAudit.Format.ps1xml'
    'Private\\Classes\\DRMMJob\\DRMMJob.Format.ps1xml'
    'Private\\Classes\\DRMMDevice\\DRMMDevice.Format.ps1xml'
    'Private\\Classes\\DRMMVariable\\DRMMVariable.Format.ps1xml'
    'Private\\Classes\\DRMMFilter\\DRMMFilter.Format.ps1xml'
    'Private\\Classes\\DRMMSite\\DRMMSite.Format.ps1xml'
    'Private\\Classes\\DRMMNetMapping\\DRMMNetMapping.Format.ps1xml'
    'Private\\Classes\\DRMMStatus\\DRMMStatus.Format.ps1xml'
    'Private\\Classes\\DRMMUser\\DRMMUser.Format.ps1xml'
)

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
#NestedModules = @('Private\Classes\DRMMObject.psm1')

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    'Connect-DattoRMM',
    'Disconnect-DattoRMM',
    'Export-RMMObjectCsv',
    'Get-RMMAccount',
    'Get-RMMActivityLog',
    'Get-RMMAlert',
    'Get-RMMComponent',
    'Get-RMMConfig',
    'Get-RMMDevice',
    'Get-RMMDeviceAudit',
    'Get-RMMDeviceSoftware',
    'Get-RMMEsxiHostAudit',
    'Get-RMMFilter',
    'Get-RMMJob',
    'Get-RMMJobResult',
    'Get-RMMNetMapping',
    'Get-RMMPrinterAudit',
    'Get-RMMRequestRate',
    'Get-RMMSite',
    'Get-RMMSiteSettings',
    'Get-RMMStatus',
    'Get-RMMThrottleStatus',
    'Get-RMMUser',
    'Get-RMMVariable',
    'Invoke-RMMApiMethod',
    'Move-RMMDevice',
    'New-RMMQuickJob',
    'New-RMMSite',
    'New-RMMVariable',
    'Remove-RMMConfig',
    'Remove-RMMSiteProxy',
    'Remove-RMMVariable',
    'Request-RMMToken',
    'Reset-RMMApiKeys',
    'Resolve-RMMAlert',
    'Save-RMMConfig',
    'Set-RMMConfig',
    'Set-RMMDeviceUDF',
    'Set-RMMDeviceWarranty',
    'Set-RMMSite',
    'Set-RMMSiteProxy',
    'Set-RMMVariable',
    'Show-RMMToken'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('Datto', 'RMM', 'API', 'PowerShell')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/TheShadowTek/DattoRMM.Core/blob/main/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/TheShadowTek/DattoRMM.Core'

        # Base URL for the documentation
        DocsBaseUrl = 'https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'See CHANGELOG.md at https://github.com/TheShadowTek/DattoRMM.Core/blob/main/CHANGELOG.md'

        # Prerelease string of this module
        Prerelease = 'beta'

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''


}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCChi8R4z1hxT+zJ
# nDa6dW9GHbMeHG8dSxzTv3GVhs+cbaCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICbWOD2EjaXtlZxxySsdMV2frfPf
# qH7H1HhOVsF3L1r2MA0GCSqGSIb3DQEBAQUABIIBAJbIwOoCsT7r9/MhbVM0kc+m
# YnT2hDIgHMHkbR6HHNU7Q/qY90b5AvyvyvujM1N1xWGbRg4lI4oSTn/tcIKR+Qh5
# a2kvw99/0atAysEAcIn7GT6guP9MYiZlXpjrri6h3in4ue/uZQSkU6X/jH3n/Cf/
# 2t88RgLWxBF21gV/XS09K94Np//9E8Nrjr7Y9RxneBtqn3dzvASiDqnxejpFg/+q
# OxE6sjL7ABBI+7NhBI/UsMJFGyr1huH37FNbnbMN3jGvDa5MhD1GSUmGQvbGwwWy
# M+Ck/MG04uo/WRXGs3dU2VfG0fXRHx/+SBICS7J80265EHz+378/YbNzI8VldOg=
# SIG # End signature block
