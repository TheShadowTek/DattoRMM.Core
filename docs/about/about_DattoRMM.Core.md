# about_DattoRMM.Core

## SHORT DESCRIPTION

A PowerShell module for the Datto RMM API v2 with typed output classes, full pipeline support, adaptive throttling, and secure credential handling.

## LONG DESCRIPTION

The DattoRMM.Core module provides an object-oriented interface to the Datto RMM API v2. All API responses are returned as strongly-typed PowerShell classes with properties, methods, and pipeline support.

### Requirements

- PowerShell 7.0 or later (Core edition only).
- A Datto RMM account with API access enabled.
- An API key and secret generated from the Datto RMM web portal.

### Key Capabilities

- **Typed Object Model** — API responses are returned as strongly-typed classes (`DRMMDevice`, `DRMMSite`, `DRMMAlert`, etc.) with helper methods and consistent property access.
- **Pipeline Integration** — Commands accept and produce typed objects for natural chaining: sites to devices, devices to alerts, devices to jobs.
- **Adaptive Throttling** — Automatic request pacing that adjusts in real time based on API utilisation, with configurable profiles for single and concurrent use.
- **Secure Credential Handling** — API secrets handled via `SecureString` and `PSCredential`; tokens stored in memory only; PII-sensitive operations require explicit confirmation.
- **Persistent Configuration** — Platform region, throttle profile, page size, and API resilience settings saved to a JSON config file.
- **Auto-Pagination** — Paginated API endpoints are handled transparently, streaming results into the pipeline.
- **Automatic Token Refresh** — Optional credential retention for long-running automation without manual re-authentication.
- **API Resilience** — Configurable retry logic with exponential backoff for transient failures.

### Module Architecture

The module follows a layered architecture:

1. **Classes** — Domain models, request/response types, and enums defined in a single structured module (`Private/Classes/Classes.psm1`), loaded first via `using module`.
2. **Private Helpers** — Integration logic, API invocation, throttling, and configuration management.
3. **Public API** — 40 exported commands organised by domain, orchestrating private helpers and returning typed objects.

Public functions are grouped by domain under `Public/<Domain>/` and are the only exported surface. Private functions handle all API communication and data transformation.

## COMMAND DOMAINS

### Account
Retrieve account information, platform status, network mappings, and user accounts.

- `Get-RMMAccount` — Account details, billing descriptor, and device counts.
- `Get-RMMStatus` — Platform operational status and health.
- `Get-RMMUser` — User accounts (PII-protected, requires confirmation or `-Force`).
- `Get-RMMNetMapping` — Datto Networking site mappings.
- `Get-RMMRequestRate` — Current API request rate.

### Authentication
Connect, disconnect, and manage API credentials and tokens.

- `Connect-DattoRMM` — Authenticate with key/secret, PSCredential, or pre-existing API token; supports proxy and auto-refresh.
- `Disconnect-DattoRMM` — Clear session token and credentials from memory.
- `Request-RMMToken` — Generate a token and return it as a `DRMMToken` object without storing it in module state.
- `Reset-RMMAPIKeys` — Regenerate API keys (invalidates current session).
- `Show-RMMToken` — Display current token details (security-sensitive).

### Configuration
Manage module settings for the current session or persistently.

- `Get-RMMConfig` — View current configuration.
- `Set-RMMConfig` — Set platform, page size, throttle profile, retry settings.
- `Save-RMMConfig` — Write current session config to disk.
- `Remove-RMMConfig` — Delete the persistent config file.

### Devices
Query, audit, and manage devices across sites.

- `Get-RMMDevice` — Retrieve devices globally, by site, by filter, by UID, hostname, or MAC address.
- `Get-RMMDeviceAudit` — Hardware and software inventory for a device.
- `Get-RMMDeviceSoftware` — Installed software for a device.
- `Get-RMMEsxiHostAudit` — VMware ESXi host audit data.
- `Get-RMMPrinterAudit` — Printer hardware, supply levels, and SNMP data.
- `Move-RMMDevice` — Move a device to a different site.
- `Set-RMMDeviceUDF` — Set user-defined fields (UDF1–UDF30).
- `Set-RMMDeviceWarranty` — Set or clear warranty expiration date.

### Sites
Create, retrieve, and manage sites and site settings.

- `Get-RMMSite` — Retrieve sites with optional extended properties (settings, variables, filters).
- `Get-RMMSiteSettings` — Site-level configuration (timezone, locale, proxy, mail).
- `New-RMMSite` — Create a new site.
- `Set-RMMSite` — Update site properties.
- `Set-RMMSiteProxy` — Configure site-level proxy settings.
- `Remove-RMMSiteProxy` — Remove site-level proxy settings.

### Alerts
Retrieve and resolve alerts at global, site, or device scope.

- `Get-RMMAlert` — Retrieve alerts with status filtering (Open, Resolved, All).
- `Resolve-RMMAlert` — Mark an alert as resolved.

### Jobs
Create and inspect automation jobs.

- `Get-RMMJob` — Retrieve job details, results, stdout, stderr, or components.
- `Get-RMMJobResult` — Retrieve detailed results for a specific job execution.
- `New-RMMQuickJob` — Execute an ad-hoc job on a device using a component.

### Filters
Retrieve device filters at global or site scope.

- `Get-RMMFilter` — Retrieve filters by name, ID, type, or site.

### Components
Retrieve reusable automation components.

- `Get-RMMComponent` — List all components with variables and metadata.

### Activity Log
Retrieve activity logs with date, entity, and category filtering.

- `Get-RMMActivityLog` — Activity logs globally or per site (PII-protected).

### Variables
Manage account-level and site-level variables.

- `Get-RMMVariable` — Retrieve variables at global or site scope.
- `New-RMMVariable` — Create a variable (supports masked values and SecureString).
- `Set-RMMVariable` — Update a variable's name or value.
- `Remove-RMMVariable` — Permanently delete a variable.

## PIPELINE PATTERNS

The module is designed around pipeline chaining. Common patterns:

```powershell
# Site → Alerts
Get-RMMSite -Name "Main Office" | Get-RMMAlert

# Filter → Device → Alert
Get-RMMFilter -Name "Domain Controllers" | Get-RMMDevice | Get-RMMAlert

# Site → Filter → Devices → Job
$Filter = Get-RMMSite -Name "DC" | Get-RMMFilter -Name "Web Servers"
Get-RMMDevice -FilterId $Filter.Id | New-RMMQuickJob -JobName "Patch" -Component $Component -Force

# Device → Audit
Get-RMMDevice -Hostname "SRV-*" | Get-RMMDeviceAudit

# Site → Variables
Get-RMMSite -Name "Branch Office" | Get-RMMVariable

# Bulk export
Get-RMMSite | Export-Csv Sites.csv
Get-RMMDevice | Export-Csv Devices.csv
Get-RMMAlert -Status All | Export-Csv Alerts.csv
```

## EXAMPLES

### Example 1: Connect and list devices

```powershell
$Secret = Read-Host -Prompt "Enter API Secret" -AsSecureString
Connect-DattoRMM -Key "your-api-key" -Secret $Secret
Get-RMMDevice
```

### Example 2: Resolve low-severity alerts for a site filter

```powershell
$Filter = Get-RMMSite -Name "Main Office" | Get-RMMFilter -Name "Critical Servers"
Get-RMMDevice -FilterId $Filter.Id | Get-RMMAlert -Status Low | Resolve-RMMAlert
```

### Example 3: Move devices between sites

```powershell
$Target = Get-RMMSite -Name "New Office"
Get-RMMSite -Name "Old Office" | Get-RMMDevice | Move-RMMDevice -Site $Target
```

### Example 4: Run an ad-hoc job

```powershell
$Component = Get-RMMComponent | Where-Object Name -eq "Patch WebServer"
Get-RMMDevice -FilterId 12345 | New-RMMQuickJob -JobName "Emergency Patch" -Component $Component -Force
```

### Example 5: Configure and persist settings

```powershell
Set-RMMConfig -Platform Merlot -PageSize 100 -ThrottleProfile Medium -Persist
```

## SEE ALSO

- [about_DattoRMM.CoreAuthentication](about_DattoRMM.CoreAuthentication.md)
- [about_DattoRMM.CoreConfiguration](about_DattoRMM.CoreConfiguration.md)
- [about_DattoRMM.CoreThrottling](about_DattoRMM.CoreThrottling.md)
- [about_DattoRMM.CoreSecurity](about_DattoRMM.CoreSecurity.md)
- [Beta Overview](../beta/about_DattoRMM.CoreBeta.md)
- [Beta Guide](../beta/DattoRMM.Core-Beta-Guide.md)
- [Beta Examples](../beta/DattoRMM.Core-Beta-Examples.md)
- [Command Reference](../commands/)
- [Class Reference](classes/about_ClassIndex.md)
