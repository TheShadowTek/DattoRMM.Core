# DattoRMM.Core Beta Guide


## Introduction

Welcome to the DattoRMM.Core PowerShell module beta! This guide will help you get started, understand key features, and provide feedback. Your input is vital for improving the module before v1.

For beta status, expectations, and the roadmap to v1, see [Beta Overview](about_DattoRMM.CoreBeta.md).  
For detailed worked examples (Azure Automation, CSV exports, type extensions, UDF expansion), see [Beta Examples](DattoRMM.Core-Beta-Examples.md).

---
## Requirements

- **PowerShell 7.4 or later** (Core edition only).
- **Recommended:** Use the latest Long-Term Support (LTS) version of PowerShell for best stability and compatibility.

### Platform Testing

| Platform | Status |
|---|---|
| **Windows** | Primary development and testing platform. Fully supported. |
| **Azure Automation** | Runbook deployment validated. Managed Identity and Key Vault credential patterns confirmed. |
| **Linux** | Limited testing on Ubuntu 24.04.1 LTS only. Expected to work on other distributions, but not yet verified. |
| **macOS** | No testing performed. Expected to work under PowerShell 7.4+, but not verified. |

If you are running on Linux or macOS, **OS-specific feedback is especially valuable** — please report any issues, unexpected behaviour, or platform-specific quirks via GitHub Issues.

---

## Getting Started

### Installation

Install from the PowerShell Gallery:

```powershell
Install-Module DattoRMM.Core -AllowPrerelease
```

Or import directly from a local path:

```powershell
Import-Module ./DattoRMM.Core.psd1
```

> [!NOTE]
> Windows users with `AllSigned` or `RemoteSigned` execution policy must trust the module's signing certificate before import. See [INSTALL.md](../../INSTALL.md) for full setup instructions including certificate trust and Azure Automation deployment.

### Connecting

Authenticate using your API key and secret:

```powershell
$Secret = Read-Host -Prompt "Enter API Secret" -AsSecureString
Connect-DattoRMM -Key "your-api-key" -Secret $Secret
```

Or with a PSCredential:

```powershell
$Cred = Get-Credential -Message "Enter API key and secret"
Connect-DattoRMM -Credential $Cred
```

> [!TIP]
> You can also use PowerShell SecretStore for secure, persistent credentials:

```powershell
Connect-DattoRMM -Credential (Get-Secret -Name 'DattoRMM-APIKeys')
```

> [!NOTE]
> Some Datto RMM accounts use a legacy single-bucket rate-limit model. If you encounter throttling errors earlier than expected, add `-LegacyThrottle` when connecting:
>
> ```powershell
> Connect-DattoRMM -Key "your-api-key" -Secret $Secret -LegacyThrottle
> ```

---

## Basic Usage

### Retrieving Data


Get all devices (simple method):

```powershell
Get-RMMDevice
```

> [!TIP]
> In large environments, retrieving devices by first getting sites and then piping to `Get-RMMDevice` can improve performance. While this may increase the total number of API requests and pages (since some pages may not be full), it often results in better server-side processing and faster overall response times, especially when working with many devices across multiple sites.

Get all devices (efficient for large environments):

```powershell
Get-RMMSite | Get-RMMDevice
```

Export sites, devices, and alerts to separate CSV files:

```powershell
Get-RMMSite | Export-Csv Sites.csv
Get-RMMDevice | Export-Csv Devices.csv
Get-RMMAlert -Status All | Export-Csv Alerts.csv
```

> [!TIP]
> For flattened CSV export that handles nested properties automatically, use `Export-RMMObjectCsv` instead. Built-in transforms cover Sites, Devices, and Alerts; user-defined transforms extend the system to any custom column layout.
>
> ```powershell
> Get-RMMSite | Export-RMMObjectCsv -Path .\Sites.csv
> Get-RMMDevice | Export-RMMObjectCsv -Path .\Devices.csv
> Get-RMMAlert -Status All | Export-RMMObjectCsv -Path .\Alerts.csv
> ```
>
> See [about_DattoRMM.CoreExport](../about/about_DattoRMM.CoreExport.md) for the full transform system reference.

### Example: Filter and Resolve Alerts

```powershell
$Filter = Get-RMMSite -Name "Main Office" | Get-RMMFilter -Name "Critical Servers"
$Devices = Get-RMMDevice -FilterId $Filter.Id
$Devices | Get-RMMAlert -Status Low | Resolve-RMMAlert
```
### Advanced Workflow
If you are piping large amounts of data into downstream batch operations (e.g., writing to Azure Table Storage, which has a batch size limit of 100), consider setting the API page size to match your batch size. For example, setting the API page size to 100 can improve pipeline throughput, even though it increases the number of requests and pages. This approach can optimize end-to-end performance in real-world automation scenarios.

```powershell
Set-RMMConfig -PageSize 100
Get-RMMSite | Get-RMMDevice | <AzureTableBatchFunction>
```


---

## Working with Typed Objects

All DattoRMM.Core commands return strongly-typed PowerShell classes rather than `PSCustomObject` or raw hashtables. Every object has documented properties, typed nested members, and helper methods you can call directly.

### Discovering Properties and Methods

Use `Get-Member` to see everything available on any object:

```powershell
# All properties and methods on a device
Get-RMMDevice | Select-Object -First 1 | Get-Member

# Methods only
Get-RMMDevice | Select-Object -First 1 | Get-Member -MemberType Method
```

### Accessing Nested Typed Objects

Most objects carry typed nested members. Dot-notation works naturally in the pipeline:

```powershell
$Device = Get-RMMDevice -Hostname 'SRV-DC01'
$Device.DeviceType.Category       # e.g., "Server"
$Device.Antivirus.ProductName     # e.g., "Windows Defender"
$Device.PatchManagement.Status    # e.g., "Approved"
$Device.Udfs.Udf1                 # UDF string value
```

Alert contexts are also polymorphic typed objects:

```powershell
$Alert = Get-RMMAlert -Status Open | Select-Object -First 1
$Alert.AlertContext.GetType().Name    # e.g., "DRMMAlertContextDiskUsage"
$Alert.AlertSourceInfo.SiteName
```

### Calling Class Methods

```powershell
# Parse a UDF value as delimited data
$Device.GetUdfAsCsv(10, ';', @('Role', 'Department', 'Location'))

# Parse job component stdout as CSV
$JobResult.StdOut | ForEach-Object {$_.GetStdDataAsCsv()}
```

### Class Reference

Class reference documentation for all types is in `docs/about/classes/`. Each domain folder contains a page per class with full property and method listings.

---

## Throttling & Long-Running Operations

The module includes adaptive throttling to respect Datto RMM API rate limits. For more details, see [about_DattoRMM.CoreThrottling](../about/about_DattoRMM.CoreThrottling.md). Throttling profiles:



- **Aggressive**: Fastest, riskier
- **Medium**: Balanced (default)
- **Cautious**: Safest, slowest

Set the profile for your session:

```powershell
Set-RMMConfig -ThrottleProfile Cautious
```

For concurrent/long-running tests, open multiple PowerShell windows and run test commands:

```powershell
# Stress test — run in several windows simultaneously
# Ctrl+C to cancel at any time; adjust the iteration count for comfort
$DebugPreference = 'Continue'

# Read heavy testing
1..100 | ForEach-Object {Write-Host "Stress read test: $_"; Get-RMMSite | Get-RMMDevice | Get-RMMAudit | Out-Null}

# Write test
1..100 | ForEach-Object {Write-Host "Stress write test: $_"; Set-RMMDeviceUdf -DeviceUid '628d9f36-694e-4d65-8433-e7de99f5e192' -UdfNumber 300 -UdfValue (Get-Date)}
```

To monitor throttle utilisation in real time, open a separate shell and run alongside the stress test:

```powershell
# Live throttle monitor — refreshes every 5 seconds
while ($true) {
    Get-RMMThrottleStatus |
        Select-Object -ExpandProperty Buckets |
        Sort-Object Utilisation -Descending |
        Format-Table
    Start-Sleep -Seconds 5
}
```

---

## Alert Contexts

Some alert contexts generated by default monitors in the new UI are undocumented in the Datto RMM API specification. The module includes typed classes for all documented contexts and falls back to `DRMMAlertContextGeneric` for unrecognised ones — no data is lost.

For identification scripts, a list of known unrecognised types, and submission guidance, see [about_DattoRMM.CoreAlertContextDiscovery](../about/about_DattoRMM.CoreAlertContextDiscovery.md).

---

## Activity Log Details

Activity log `Details` objects are fully polymorphic and entirely undocumented. Unlike alert contexts, all details are returned as `DRMMActivityLogDetailsGeneric` by default — typed dispatch requires `-UseExperimentalDetailClasses`. The dispatch hierarchy is three levels deep: Entity → Category → Action.

Currently mapped combinations are limited (Device/job/deployment and Device/job/create). Coverage depends entirely on real-world data from beta testers and may never be complete without a published API schema.

For schema collection scripts, an explanation of the hierarchy, and submission guidance, see [about_DattoRMM.CoreActivityLogDiscovery](../about/about_DattoRMM.CoreActivityLogDiscovery.md).

---

## Troubleshooting & Debugging

- Use `$DebugPreference = "Continue"` for verbose output.
- All secrets are handled securely; tokens are never written to disk.
- For issues, see the [Known Issues](#known-issues) section below.

---

## Known Issues

- Sorting `AlertContext` in `Out-GridView` may cause a crash if mixed types are present.
- Some alert contexts are undocumented—please help identify these.

---

## Feedback

Please report issues, undocumented alert contexts, or suggestions via [GitHub Issues](https://github.com/TheShadowTek/DattoRMM.Core/issues).

---

## Further Reading

- [Project README](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/README.md)
- [Beta Overview](about_DattoRMM.CoreBeta.md) — Beta status, expectations, and roadmap to v1
- [Beta Examples](DattoRMM.Core-Beta-Examples.md) — Detailed worked examples (Azure Automation, CSV exports, type extensions, UDF expansion)
- [Authentication](../about/about_DattoRMM.CoreAuthentication.md) — All credential methods including Key Vault and SecretStore
- [Configuration](../about/about_DattoRMM.CoreConfiguration.md) — Platform, throttle, and persistence settings
- [Alert Context Discovery](../about/about_DattoRMM.CoreAlertContextDiscovery.md) — Identify and report unrecognised alert context types
- [Activity Log Discovery](../about/about_DattoRMM.CoreActivityLogDiscovery.md) — Identify and report undocumented activity log detail combinations
- In-module help: `Get-Help <Command>`
- About topics: `Get-Help about_DattoRMM.Core`, `Get-Help about_DattoRMM.CoreThrottling`

---
