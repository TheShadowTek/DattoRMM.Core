# DattoRMM.Core PowerShell Module

## Overview

This PowerShell module provides a comprehensive, object-oriented interface for managing and automating tasks with the Datto RMM API v2. It enables secure authentication, robust device and job management, and advanced automation scenarios for Datto RMM environments.

## Features

- **Secure API Authentication**: Supports both API key/secret and PSCredential authentication, with secure handling of secrets and tokens.
- **Comprehensive Device Management**: Query, filter, and manage devices with rich object models and class-based methods.
- **Job and Automation Control**: Create, monitor, and retrieve results from jobs and quick jobs, with detailed status and output access.
- **Account and Site Management**: Retrieve and manage account, site, and variable information with simple, scriptable commands.
- **Advanced Filtering and Querying**: Flexible parameter sets for targeting devices, jobs, and sites by multiple criteria.
- **Rate Limiting and Throttling**: Built-in safeguards to respect Datto RMM API rate limits and prevent accidental lockouts or service disruption.
- **Extensible and Scriptable**: Designed for automation, reporting, and integration into larger PowerShell workflows.

## Security

- All authentication secrets are handled securely using PowerShell's `SecureString` and credential objects.
- Access tokens are stored only in memory for the session and are never written to disk.
- Sensitive operations that may expose personally identifiable information (PII)—such as retrieving the last logged-in user—are PII-hardened and use PowerShell's ConfirmImpact system, requiring explicit confirmation or the use of `-Force`. These operations fully support `-Confirm` and `-WhatIf` for safe automation.
- Configurable token refresh: The module automatically refreshes API tokens before expiry (default 100 hours, configurable), supporting long-running workloads and automation without manual re-authentication.

## Rate Limiting & Throttling

The module automatically detects and respects Datto RMM API rate limits, using built-in throttling logic to prevent exceeding allowed request rates. Throttling is adaptive and configurable, with three preset aggressiveness levels:

- **Cautious**: Maximum safety, checks rate limits frequently, slowest.
- **Medium**: Balanced for most workloads (default).
- **Aggressive**: Fastest, checks less often, higher risk of hitting limits.

You can adjust throttling for the current session or persistently:

```powershell
# Set throttling to Cautious for this session
Set-RMMThrottle -ThrottleProfile Cautious

# Set throttling to Aggressive and persist for future sessions
Set-RMMThrottle -ThrottleProfile Aggressive -Persist
```

All default values are managed centrally and can be tuned in one place. For advanced options, custom settings, and Datto's official API guidance, see:

- [docs/about/about_DattoRMM.CoreThrottling.md](docs/about/about_DattoRMM.CoreThrottling.md)

With this built-in throttling, it is safe to run large parallel workloads (such as data extraction or bulk operations) without risking API lockouts or service disruption.


## Platform Support

Datto RMM operates multiple platform regions. The module supports connecting to any supported region using the `-Platform` parameter or by configuring a persistent default.

**Supported Platforms:**

- Pinotage (default)
- Concord
- Vidal
- Merlot
- Zinfandel
- Syrah

You can specify the platform region at connection time:

```powershell
$Secret = Read-Host -Prompt "Enter API Secret" -AsSecureString
Connect-DattoRMM -Key "your-api-key" -Secret $Secret -Platform Merlot
```

Or persist your preferred default platform for all sessions:

```powershell
Set-RMMConfig -Platform Merlot -Persist
```

If you do not specify a platform, the module will use your configured default (if set), or fall back to Pinotage.


### Installation

Copy the module files to your PowerShell module path, or import directly from your working directory:

```powershell
Import-Module ./DattoRMM.Core.psd1
```



### Authentication


Connect using an API key and secret (shell):

```powershell
$Secret = Read-Host -Prompt "Enter API Secret" -AsSecureString
Connect-DattoRMM -Key "your-api-key" -Secret $Secret
```

Or with a PSCredential (shell):

```powershell
$Cred = Get-Credential -Message "Enter API key and secret"
Connect-DattoRMM -Credential $Cred
```

Or with PowerShell SecretStore - securley presist between sessions (shell - interactive):

```powershell
# Requires Microsoft.PowerShell.SecretManagement and Microsoft.PowerShell.SecretStore modules
Import-Module Microsoft.PowerShell.SecretManagement

# Store credential object in default vault
$Cred = Get-Credential
Set-Secret -Name "DattoRMM-API" -Secret $Cred

# Retrieve a PSCredential from SecretStore (including future sessions)
Connect-DattoRMM -Credential (Get-Secret -Name "DattoRMM-API")
```
> [!NOTE]
> If used in a script with a password protected vault, use a SecureString parameter to provide access to the vault 

#### Using in Azure Automation Runbooks

This module can be used in Azure Automation Runbooks for secure, unattended automation. You can retrieve credentials from the Automation Account credential store or from Azure Key Vault.



**Example: Using Automation Account Credential**

```powershell
# Import the module (ensure it is uploaded to the Automation Account)
Import-Module DattoRMM.Core

# Retrieve credential asset by name
$Cred = Get-AutomationPSCredential -Name "DattoRMM-API"

# Connect using the credential
Connect-DattoRMM -Credential $Cred
```

> [!NOTE]
> The credential asset must be created in the Automation Account before use.


**Example: Using Azure Key Vault**

For Azure-based automation, you can retrieve credentials directly from Azure Key Vault using the Azure PowerShell modules:

```powershell
# Authenticate to Azure (Managed Identity or Service Principal recommended in Automation)
Connect-AzAccount

# Retrieve API key and secret from Azure Key Vault
$ApiKey = Get-AzKeyVaultSecret -VaultName "MyKeyVault" -Name "DattoRMM-API-Key" -AsPlainText
$Secret = Get-AzKeyVaultSecret -VaultName "MyKeyVault" -Name "DattoRMM-API-Secret"

# Connect using the retrieved key and secret
Connect-DattoRMM -Key $ApiKey -Secret $Secret
```

> [!NOTE]
> The Key Vault and secrets must be created and accessible to the automation context.


> [!NOTE]
> PowerShell SecretManagement vaults (such as SecretStore, KeePass, etc.) are primarily for local shell use. In Azure Automation, credential retrieval methods such as Automation Account Credential and Azure Key Vault are commonly used and recommended. Other methods or third-party PAM modules may work, but compatibility is not guaranteed or verified.



### Example Usage

Get a device filter by name for a site, then get devices in that filter, and resolve all low alerts:
```powershell
$Filter = Get-RMMSite -Name "Main Office" | Get-RMMFilter -Name "Critical Servers"
$Devices = Get-RMMDevice -FilterId $Filter.Id
$Devices | Get-RMMAlert -Status Low | Resolve-RMMAlert
```

Move all devices in a site filter to another site:
```powershell
$TargetSite = Get-RMMSite -Name "New Office"
$SourceFilter = Get-RMMSite -Name "Main Office" | Get-RMMFilter -Name "Production Servers"
$SourceFilter | Get-RMMDevice | Move-RMMDevice -Site $TargetSite
```

Start a patch job on all devices in the global 'Web Servers' filter:
```powershell
$Filter = Get-RMMFilter -Name "Web Servers" | Where-Object {$_.IsGlobal()}
$Component = Get-RMMComponent | Where-Object Name -eq "Patch WebServer - URGENT"
Get-RMMDevice -FilterId $Filter.Id | New-RMMQuickJob -JobName "Patch WebServer - URGENT" -Component $Component -Force
```

### More Examples

See the `docs/` folder and in-module help for detailed usage and advanced scenarios.

## SecureString Handling and Cross-Platform Security

- On **Windows**, SecureString values are decrypted using secure .NET APIs and memory is immediately zeroed after use.
- On **Linux/macOS**, SecureString is converted using `PSCredential.GetNetworkCredential().Password`. Due to .NET Core limitations, plaintext may persist in managed memory until garbage collection runs.
- All sensitive variables are cleared from memory as soon as possible.
- For high-security scenarios on Linux/macOS, you may call `[GC]::Collect()` after sensitive operations to force memory cleanup.

**Example:**
```powershell
$secret = Read-Host -AsSecureString
Connect-DattoRMM -Key "your-api-key" -Secret $secret
[System.GC]::Collect() # Optional: for extra security on Linux/macOS
```

### Commands Requiring [GC]::Collect() for Maximum Security (Linux/macOS)

If you are operating in a high-security environment on Linux or macOS, consider running `[System.GC]::Collect()` after using any of the following commands with SecureString input:

- `Connect-DattoRMM` (when using the `-Secret` or `-Credential` parameter)
- `New-RMMVariable` (when using a SecureString for the `-Value` parameter)
- `Set-RMMVariable` (when using a SecureString for the `-Value` parameter)

This ensures that any sensitive plaintext temporarily created in memory is more quickly cleaned up by the .NET garbage collector.

## Known Issues

- **Out-GridView crash when sorting AlertContext**: When piping `DRMMAlert` objects to `Out-GridView` and the `AlertContext` property contains mixed types, attempting to sort the `AlertContext` column will cause `Out-GridView` to crash. This is under review for a fix (potentially via custom `Types ToString()` or a Format Table View).

## Disclaimer

This module is provided "as is" without warranty of any kind. Use at your own risk. This project is not affiliated with or endorsed by Datto, Inc. or its subsidiaries.

## License

This project is licensed under the Mozilla Public License 2.0 (MPL-2.0).

All source files include an SPDX license identifier for clarity and automated compliance:

    SPDX-License-Identifier: MPL-2.0

You can find the full license text in the [LICENSE](./LICENSE) file.

