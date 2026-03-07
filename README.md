# DattoRMM.Core

A PowerShell module for the Datto RMM API v2. Provides typed, object-oriented access to devices, sites, alerts, jobs, filters, variables, and account management with built-in adaptive throttling and secure credential handling.

> **Requires PowerShell 7.4 or later** (Core edition only).

## Features

- **Typed Object Model** — All API responses are returned as strongly-typed PowerShell classes with properties, methods, and pipeline support.
- **Full Pipeline Integration** — Chain commands naturally: `Get-RMMSite | Get-RMMDevice | Get-RMMAlert`.
- **Adaptive Throttling** — Automatic rate-limit management with configurable profiles (Aggressive, Medium, Cautious) for safe single or concurrent use.
- **Secure by Default** — Credentials handled via `SecureString` and `PSCredential`; tokens held in memory only; PII-sensitive operations require explicit confirmation.
- **Persistent Configuration** — Platform region, throttle profile, page size, and retry settings saved to a JSON config file for consistent behaviour across sessions.
- **Comprehensive Coverage** — 41 commands across 11 domains: Account, Activity Log, Alerts, Auth, Components, Config, Devices, Filters, Jobs, Sites, and Variables.

## Installation

Copy the module folder to a path in `$env:PSModulePath`, or import directly:

```powershell
Import-Module ./DattoRMM.Core.psd1
```

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
Get-RMMSite | Export-Csv Sites.csv
```

For credential storage options (SecretStore, Azure Automation, Key Vault), see [Authentication](docs/about/about_DattoRMM.CoreAuthentication.md).

## Examples

Resolve all critical-severity alerts for devices in a site filter:

```powershell
$Filter = Get-RMMSite -Name "Main Office" | Get-RMMFilter -Name "Critical Servers"
$Filter | Get-RMMDevice | Get-RMMAlert | Where-Object {$_.Priority -eq "Critical"} | Resolve-RMMAlert
```

Move devices from one site to another:

```powershell
$Target = Get-RMMSite -Name "New Office"
Get-RMMSite -Name "Old Office" | Get-RMMDevice | Move-RMMDevice -Site $Target
```

Run an ad-hoc job on filtered devices:

```powershell
$Component = Get-RMMComponent | Where-Object Name -eq "Patch WebServer"
Get-RMMDevice -FilterId 12345 | New-RMMQuickJob -JobName "Emergency Patch" -Component $Component -Force
```

## Commands

| Domain | Commands |
|---|---|
| **Account** | `Get-RMMAccount`, `Get-RMMNetMapping`, `Get-RMMRequestRate`, `Get-RMMStatus`, `Get-RMMUser`, `Invoke-RMMApiMethod` |
| **Activity Log** | `Get-RMMActivityLog` |
| **Alerts** | `Get-RMMAlert`, `Resolve-RMMAlert` |
| **Auth** | `Connect-DattoRMM`, `Disconnect-DattoRMM`, `Request-RMMToken`, `Reset-RMMAPIKeys`, `Show-RMMToken` |
| **Components** | `Get-RMMComponent` |
| **Config** | `Get-RMMConfig`, `Set-RMMConfig`, `Save-RMMConfig`, `Remove-RMMConfig` |
| **Devices** | `Get-RMMDevice`, `Get-RMMDeviceAudit`, `Get-RMMDeviceSoftware`, `Get-RMMEsxiHostAudit`, `Get-RMMPrinterAudit`, `Move-RMMDevice`, `Set-RMMDeviceUDF`, `Set-RMMDeviceWarranty` |
| **Filters** | `Get-RMMFilter` |
| **Jobs** | `Get-RMMJob`, `Get-RMMJobResult`, `New-RMMQuickJob` |
| **Sites** | `Get-RMMSite`, `Get-RMMSiteSettings`, `New-RMMSite`, `Set-RMMSite`, `Set-RMMSiteProxy`, `Remove-RMMSiteProxy` |
| **Variables** | `Get-RMMVariable`, `New-RMMVariable`, `Set-RMMVariable`, `Remove-RMMVariable` |

Run `Get-Help <CommandName>` for detailed parameter and usage information, or see the [command reference](docs/commands/).

## Documentation

| Topic | Description |
|---|---|
| [Module Overview](docs/about/about_DattoRMM.Core.md) | Architecture, design principles, and feature summary |
| [Authentication](docs/about/about_DattoRMM.CoreAuthentication.md) | All authentication methods, credential storage, and automation scenarios |
| [Configuration](docs/about/about_DattoRMM.CoreConfiguration.md) | Platform regions, page size, retry settings, and persistent configuration |
| [Throttling](docs/about/about_DattoRMM.CoreThrottling.md) | Adaptive throttling, profiles, concurrent use, and API rate limit details |
| [Security](docs/about/about_DattoRMM.CoreSecurity.md) | PII handling, credential lifecycle, SecureString cross-platform behaviour |
| [Alert Context Discovery (Beta)](docs/about/about_DattoRMM.CoreAlertContextDiscovery.md) | Guidance for collecting unrecognised alert context schema data during beta |
| [Command Reference](docs/commands/) | Per-command documentation with examples |
| [Class Reference](docs/about/classes/) | Typed output classes and enums |

About topics are also available in-module:

```powershell
Get-Help about_DattoRMM.Core
Get-Help about_DattoRMM.CoreThrottling
```

## Disclaimer

This module is provided "as is" without warranty of any kind. Use at your own risk. This project is not affiliated with or endorsed by Datto, Inc. or its subsidiaries.

## License

This project is licensed under the Mozilla Public License 2.0 (MPL-2.0).

All source files include an SPDX license identifier for clarity and automated compliance:

    SPDX-License-Identifier: MPL-2.0

You can find the full license text in the [LICENSE](./LICENSE) file.

