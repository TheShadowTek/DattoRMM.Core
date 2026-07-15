---
title: DattoRMM.Core
description: A PowerShell module for the Datto RMM API v2 with typed output classes, full pipeline support, adaptive throttling, and secure credential handling.
layout: default
nav_order: 1
---

# DattoRMM.Core

A PowerShell module for the Datto RMM API v2. Provides typed, object-oriented access to devices, sites, alerts, jobs, filters, variables, and account management with built-in adaptive throttling and secure credential handling.

> **⚠️ Legacy Rate-Limit Compatibility** — Some Datto RMM accounts use a legacy single-bucket rate-limit model. Use the `-LegacyThrottle` switch on `Connect-DattoRMM` to enable compatibility.

> **Requires PowerShell 7.4 or later** (Core edition only).

---

## Features

| Feature | Description |
|---|---|
| **Typed Object Model** | All API responses returned as strongly-typed PowerShell classes with properties, methods, and pipeline support |
| **Full Pipeline Integration** | Chain commands naturally: `Get-RMMSite \| Get-RMMDevice \| Get-RMMAlert` |
| **Adaptive Throttling** | Automatic rate-limit management with configurable profiles (Aggressive, Medium, Cautious) |
| **Secure by Default** | Credentials handled via `SecureString` and `PSCredential`; tokens held in memory only |
| **Persistent Configuration** | Platform region, throttle profile, page size, and retry settings saved across sessions |
| **Auto-Pagination** | Paginated API endpoints handled transparently, streaming results into the pipeline |
| **Opinionated CSV Export** | Export Sites, Devices, and Alerts to flattened CSV using named column transforms |
| **Comprehensive Coverage** | 43 commands across 12 domains |

---

## Installation

See [INSTALL.md](../INSTALL.md) for full instructions including execution policy, certificate trust, and Azure Automation.

```powershell
Install-Module DattoRMM.Core
```

---

## Quick Start

```powershell
# Connect with API key and secret
$Secret = Read-Host -Prompt "Enter API Secret" -AsSecureString
Connect-DattoRMM -Key "your-api-key" -Secret $Secret

# Retrieve all devices
Get-RMMDevice

# Get alerts for a specific site
Get-RMMSite -Name "Main Office" | Get-RMMAlert

# Export all sites to CSV
Get-RMMSite | Export-RMMObjectCsv -Path .\Sites.csv
```

---

## Commands

| Domain | Commands |
|---|---|
| **Account** | `Get-RMMAccount`, `Get-RMMNetMapping`, `Get-RMMRequestRate`, `Get-RMMStatus`, `Get-RMMThrottleStatus`, `Get-RMMUser`, `Invoke-RMMApiMethod` |
| **Activity Log** | `Get-RMMActivityLog` |
| **Alerts** | `Get-RMMAlert`, `Resolve-RMMAlert` |
| **Auth** | `Connect-DattoRMM`, `Disconnect-DattoRMM`, `Request-RMMToken`, `Reset-RMMApiKeys`, `Set-RMMTokenClipboard` |
| **Components** | `Get-RMMComponent` |
| **Config** | `Get-RMMConfig`, `Set-RMMConfig`, `Save-RMMConfig`, `Remove-RMMConfig` |
| **Devices** | `Get-RMMDevice`, `Get-RMMDeviceAudit`, `Get-RMMDeviceSoftware`, `Get-RMMEsxiHostAudit`, `Get-RMMPrinterAudit`, `Move-RMMDevice`, `Set-RMMDeviceUdf`, `Set-RMMDeviceWarranty` |
| **Export** | `Export-RMMObjectCsv` |
| **Filters** | `Get-RMMFilter` |
| **Jobs** | `Get-RMMJob`, `Get-RMMJobResult`, `New-RMMQuickJob` |
| **Sites** | `Get-RMMSite`, `Get-RMMSiteSettings`, `New-RMMSite`, `Set-RMMSite`, `Set-RMMSiteProxy`, `Remove-RMMSiteProxy` |
| **Variables** | `Get-RMMVariable`, `New-RMMVariable`, `Set-RMMVariable`, `Remove-RMMVariable` |

Full per-command documentation with examples is available in the [Command Reference](commands/about_CommandIndex.md).

---

## Pipeline Examples

```powershell
# Resolve all critical alerts for devices in a site filter
$Filter = Get-RMMSite -Name "Main Office" | Get-RMMFilter -Name "Critical Servers"
$Filter | Get-RMMDevice | Get-RMMAlert | Where-Object {$_.Priority -eq "Critical"} | Resolve-RMMAlert

# Move devices from one site to another
$Target = Get-RMMSite -Name "New Office"
Get-RMMSite -Name "Old Office" | Get-RMMDevice | Move-RMMDevice -Site $Target

# Run an ad-hoc job on filtered devices
$Component = Get-RMMComponent | Where-Object Name -eq "Patch WebServer"
Get-RMMDevice -FilterId 12345 | New-RMMQuickJob -JobName "Emergency Patch" -Component $Component -Force

# Bulk export
Get-RMMSite   | Export-RMMObjectCsv -Path .\Sites.csv
Get-RMMDevice | Export-RMMObjectCsv -Path .\Devices.csv
Get-RMMAlert -Status All | Export-RMMObjectCsv -Path .\Alerts.csv -IncludeTimestamp
```

---

## Documentation

### Guides

| Topic | Description |
|---|---|
| [Module Overview](about/about_DattoRMM.Core.md) | Architecture, design principles, and feature summary |
| [Authentication](about/about_DattoRMM.CoreAuthentication.md) | All authentication methods, credential storage, and automation scenarios |
| [Configuration](about/about_DattoRMM.CoreConfiguration.md) | Platform regions, page size, retry settings, and persistent configuration |
| [Throttling](about/about_DattoRMM.CoreThrottling.md) | Adaptive throttling, profiles, concurrent use, and API rate limit details |
| [Security](about/about_DattoRMM.CoreSecurity.md) | Credential lifecycle, PII handling philosophy, SecureString cross-platform behaviour |
| [Export](about/about_DattoRMM.CoreExport.md) | CSV export, built-in transforms, custom transform authoring, UDF handling |
| [Format Extensions](about/about_DattoRMM.CoreFormatExtensions.md) | Loading user-supplied Format.ps1xml files to customise console output |
| [Type Extensions](about/about_DattoRMM.CoreTypeExtensions.md) | Loading user-supplied Types.ps1xml files to extend typed objects |
| [Alert Context Discovery](about/about_DattoRMM.CoreAlertContextDiscovery.md) | Guidance for collecting unrecognised alert context schema data during beta |

### Reference

| Topic | Description |
|---|---|
| [Command Reference](commands/about_CommandIndex.md) | Per-command documentation with parameters and examples |
| [Class Reference](about/classes/about_ClassIndex.md) | Typed output classes and enums |

### Beta

| Topic | Description |
|---|---|
| [Beta Overview](beta/about_DattoRMM.CoreBeta.md) | Beta status, expectations, and roadmap to v1 |
| [Beta Guide](beta/DattoRMM.Core-Beta-Guide.md) | Getting started with the beta, usage tips, and feedback |
| [Beta Examples](beta/DattoRMM.Core-Beta-Examples.md) | Worked examples: Azure Automation, CSV exports, type extensions, UDF expansion |

### Repository

| Topic | Description |
|---|---|
| [Installation](../INSTALL.md) | PowerShell Gallery install, code signing, certificate trust, and Azure Automation |
| [Changelog](../CHANGELOG.md) | Version history and release notes |
| [Contributing](../CONTRIBUTING.md) | Architecture overview, naming conventions, and contribution guide |
| [Security Policy](../SECURITY.md) | Vulnerability reporting and credential security design |

---

About topics are also available in-module via `Get-Help`:

```powershell
Get-Help about_DattoRMM.Core
Get-Help about_DattoRMM.CoreThrottling
Get-Help about_DattoRMM.CoreAuthentication
```

---

## Disclaimer

This module is provided "as is" without warranty of any kind. Use at your own risk. This project is not affiliated with or endorsed by Datto, Inc. or its subsidiaries.

## License

Licensed under the [Mozilla Public License 2.0](../LICENSE) (MPL-2.0). All source files include an SPDX license identifier.
