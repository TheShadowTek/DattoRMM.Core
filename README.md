# Datto-RMM PowerShell Module

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
Set-RMMThrottle -ThrottleAggressiveness Cautious

# Set throttling to Aggressive and persist for future sessions
Set-RMMThrottle -ThrottleAggressiveness Aggressive -Persist
```

All default values are managed centrally and can be tuned in one place. For advanced options, custom settings, and Datto's official API guidance, see:

- [docs/about_DattoRMMThrottling.md](docs/about_DattoRMMThrottling.md)

> With this built-in throttling, it is safe to run large parallel workloads (such as data extraction or bulk operations) without risking API lockouts or service disruption.

## Getting Started

### Installation

Copy the module files to your PowerShell module path, or import directly from your working directory:

```powershell
Import-Module ./Datto-RMM.psd1
```



### Authentication


Connect using an API key and secret (shell):

```powershell
$Secret = Read-Host -Prompt "Enter API Secret" -AsSecureString
Connect-DattoRMM -Key "your-api-key" -Secret $Secret
```

Or with a PSCredential (shell):

```powershell
$Cred = Get-Credential
Connect-DattoRMM -Credential $Cred
```

Or with PowerShell SecretStore (shell):

```powershell
# Requires Microsoft.PowerShell.SecretManagement and Microsoft.PowerShell.SecretStore modules
Import-Module Microsoft.PowerShell.SecretManagement

# Retrieve a PSCredential from SecretStore
$Cred = Get-Secret -Name "DattoRMM-API" -AsCredential

Connect-DattoRMM -Credential $Cred
```

#### Using in Azure Automation Runbooks

This module can be used in Azure Automation Runbooks for secure, unattended automation. You can retrieve credentials from the Automation Account credential store or from Azure Key Vault.



**Example: Using Automation Account Credential**

```powershell
# Import the module (ensure it is uploaded to the Automation Account)
Import-Module Datto-RMM

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

# Retrieve secret from Azure Key Vault
$SecretValue = Get-AzKeyVaultSecret -VaultName "MyKeyVault" -Name "DattoRMM-API-Secret"
$Secret = ConvertTo-SecureString $SecretValue.SecretValueText -AsPlainText -Force


# Connect using the secret (with your API key)
Connect-DattoRMM -Key "your-api-key" -Secret $Secret
```

> [!NOTE]
> The Key Vault and secret must be created and accessible to the automation context.


> [!NOTE]
> PowerShell SecretManagement vaults (such as SecretStore, KeePass, etc.) are primarily for local shell use. In Azure Automation, credential retrieval methods such as Automation Account Credential and Azure Key Vault are commonly used and recommended. Other methods or third-party PAM modules may work, but compatibility is not guaranteed or verified.



### Example Usage

Get a device filter by name for a site, then get devices in that filter, and resolve all low alerts:
```powershell
$Filter = Get-RMMSite -Name "Main Office" | Get-RMMDeviceFilter -Name "Critical Servers"
$Devices = Get-RMMDevice -FilterId $Filter.Id
$Devices | Get-RMMAlert -Status Low | Resolve-RMMAlert
```

Move all devices in a site filter to another site:
```powershell
$TargetSite = Get-RMMSite -Name "New Office"
$SourceFilter = Get-RMMSite -Name "Main Office" | Get-RMMDeviceFilter -Name "Production Servers"
$SourceFilter | Get-RMMDevice | Move-RMMDevice -Site $TargetSite
```

Start a patch job on all devices in the global 'Web Servers' filter:
```powershell
$Filter = Get-RMMDeviceFilter -Name "Web Servers" | Where-Object {$_.IsGlobal()}
$Component = Get-RMMComponent | Where-Object Name -eq "Patch WebServer - URGENT"
Get-RMMDevice -FilterId $Filter.Id | New-RMMQuickJob -JobName "Patch WebServer - URGENT" -Component $Component -Force
```

### More Examples

See the `docs/` folder and in-module help for detailed usage and advanced scenarios.

## Known Issues

- **Out-GridView crash when sorting AlertContext**: When piping `DRMMAlert` objects to `Out-GridView` and the `AlertContext` property contains mixed types, attempting to sort the `AlertContext` column will cause `Out-GridView` to crash. This is under review for a fix (potentially via custom `Types ToString()` or a Format Table View).

## Disclaimer

This module is provided "as is" without warranty of any kind. Use at your own risk. This project is not affiliated with or endorsed by Datto, Inc. or its subsidiaries.

## License

A license will be added in a future release.
