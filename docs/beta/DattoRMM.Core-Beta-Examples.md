# DattoRMM.Core Beta — Worked Examples

Practical, real-world scripts that demonstrate the module's typed object model, pipeline support, and extensibility. Each example builds on concepts from the [Beta Guide](DattoRMM.Core-Beta-Guide.md) and the [Authentication](../about/about_DattoRMM.CoreAuthentication.md) reference.

---

## Table of Contents

- [Azure Automation — Alert Housekeeping with Key Vault](#azure-automation--alert-housekeeping-with-key-vault)
- [CSV Device Export — Flattened Site-Device Report](#csv-device-export--flattened-site-device-report)
- [Custom Type Extensions — Split Site Name by Convention](#custom-type-extensions--split-site-name-by-convention)
- [UDF Expansion — Parse Delimited Device Metadata](#udf-expansion--parse-delimited-device-metadata)
- [Activity Log — Job Output Collection](#activity-log--job-output-collection)

---

## Azure Automation — Alert Housekeeping with Key Vault

An Azure Automation Runbook that connects to Datto RMM using credentials stored in Azure Key Vault, retrieves all open alerts, and resolves stale alerts older than a configurable threshold.

This pattern is typical for MSPs that run scheduled maintenance against their Datto RMM account from Azure.

### Prerequisites

- An Azure Automation Account with the `Az.KeyVault` and `DattoRMM.Core` modules installed.
- A Managed Identity (system or user-assigned) with `Get` permission on Key Vault secrets.
- Two Key Vault secrets: one for the API key (plain text), one for the API secret (stored as a secret).

### Runbook Script

```powershell
<#
    .SYNOPSIS
        Resolves stale open alerts older than a configurable number of days.

    .DESCRIPTION
        Connects to Datto RMM using API credentials from Azure Key Vault,
        retrieves all open alerts, and resolves any that have been open
        longer than the specified threshold. Designed to run as a scheduled
        Azure Automation Runbook.

    .NOTES
        Module requirements: Az.Accounts, Az.KeyVault, DattoRMM.Core
        Authentication: System-assigned Managed Identity
#>

param (

    [int]$StaleDays = 30,
    [string]$VaultName = 'MyKeyVault',
    [string]$Platform = 'Merlot'

)

# --- Authenticate to Azure (Managed Identity) ---
Connect-AzAccount -Identity | Out-Null

# --- Retrieve API credentials from Key Vault ---
$ApiKey = Get-AzKeyVaultSecret -VaultName $VaultName -Name 'DattoRMM-API-Key' -AsPlainText
$ApiSecret = (Get-AzKeyVaultSecret -VaultName $VaultName -Name 'DattoRMM-API-Secret').SecretValue

# --- Connect to Datto RMM ---
Connect-DattoRMM -Key $ApiKey -Secret $ApiSecret -Platform $Platform
Write-Output "Connected to Datto RMM ($Platform)"

# --- Retrieve all open alerts ---
$Alerts = Get-RMMAlert -Status Open
Write-Output "Retrieved $($Alerts.Count) open alerts"

# --- Identify stale alerts ---
$Cutoff = (Get-Date).AddDays(-$StaleDays)

$StaleAlerts = $Alerts | Where-Object {$_.Timestamp -lt $Cutoff}
Write-Output "Found $($StaleAlerts.Count) alerts older than $StaleDays days"

if ($StaleAlerts.Count -eq 0) {

    Write-Output "No stale alerts to resolve. Exiting."
    Disconnect-DattoRMM
    return

}

# --- Resolve stale alerts ---
$StaleAlerts | Resolve-RMMAlert
Write-Output "Resolved $($StaleAlerts.Count) stale alerts"

# --- Optional: output summary for runbook logs ---
$StaleAlerts |
    Select-Object @{n='AlertUid';e={$_.AlertUid}},
                  @{n='DeviceHostname';e={$_.Hostname}},
                  @{n='SiteName';e={$_.SiteName}},
                  @{n='Priority';e={$_.Priority}},
                  @{n='AlertAge';e={(New-TimeSpan -Start $_.Timestamp -End (Get-Date)).Days}} |
    Format-Table -AutoSize |
    Out-String |
    Write-Output

Disconnect-DattoRMM
Write-Output "Alert housekeeping complete."
```

### Key Points

- **Managed Identity** avoids storing credentials in the Runbook or Automation Account variables.
- **Key Vault** centralises secret management and supports rotation without modifying the Runbook.
- The Runbook parameters (`$StaleDays`, `$VaultName`, `$Platform`) allow reuse across schedules and environments.
- `Disconnect-DattoRMM` clears the session token from memory at the end — good practice in shared automation contexts.

### Scheduling

In the Azure portal, attach a schedule to the Runbook and optionally override `StaleDays` or `Platform` per schedule. For example, run weekly with `StaleDays = 14` for aggressive housekeeping, or monthly with `StaleDays = 90` for a lighter touch.

---

## CSV Device Export — Flattened Site-Device Report

A script that exports all devices grouped by site to a single flat CSV, suitable for reporting, import into other tools, or Excel analysis. The challenge is that `DRMMDevice` objects contain nested properties (`Udfs`, `DeviceType`, `Antivirus`, `PatchManagement`) that need to be flattened for CSV.

### Script

```powershell
<#
    .SYNOPSIS
        Exports all devices across all sites to a flattened CSV file.

    .DESCRIPTION
        Retrieves every site and its devices, selects key properties,
        flattens nested objects into scalar columns, and exports the
        result to a single CSV. Suitable for reporting, auditing, or
        feeding into downstream tools.

    .NOTES
        For large environments, retrieving devices per-site (piping from
        Get-RMMSite) often performs better than a single Get-RMMDevice call.
#>

param (

    [string]$OutputPath = ".\DattoRMM-DeviceExport-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

)

# --- Retrieve all devices via site pipeline for efficiency ---
$Devices = Get-RMMSite | Get-RMMDevice

Write-Host "Retrieved $($Devices.Count) devices. Flattening for export..."

# --- Flatten nested properties into a clean export ---
$Export = $Devices | Select-Object `
    SiteName,
    Hostname,
    @{n='DeviceCategory';e={$_.DeviceType.Category}},
    @{n='DeviceTypeName';e={$_.DeviceType.Name}},
    OperatingSystem,
    @{n='Is64Bit';e={$_.A64Bit}},
    IntIpAddress,
    ExtIpAddress,
    Domain,
    Description,
    Online,
    LastSeen,
    LastReboot,
    LastAuditDate,
    CreationDate,
    CagVersion,
    RebootRequired,
    Suspended,
    Deleted,
    SnmpEnabled,
    @{n='AntivirusProduct';e={$_.Antivirus.ProductName}},
    @{n='AntivirusStatus';e={$_.Antivirus.Status}},
    @{n='PatchStatus';e={$_.PatchManagement.Status}},
    @{n='PatchLastScan';e={$_.PatchManagement.LastScan}},
    WarrantyDate,
    @{n='Udf1';e={$_.Udfs.Udf1}},
    @{n='Udf2';e={$_.Udfs.Udf2}},
    @{n='Udf3';e={$_.Udfs.Udf3}},
    @{n='Udf4';e={$_.Udfs.Udf4}},
    @{n='Udf5';e={$_.Udfs.Udf5}},
    @{n='Udf6';e={$_.Udfs.Udf6}}

$Export | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Exported $($Export.Count) devices to $OutputPath"
```

### Key Points

- **Site-first retrieval** (`Get-RMMSite | Get-RMMDevice`) is more efficient in large environments than a single `Get-RMMDevice` call — see the [Beta Guide](DattoRMM.Core-Beta-Guide.md#retrieving-data) for details.
- **Calculated properties** with `Select-Object` flatten nested typed objects (`DeviceType`, `Antivirus`, `PatchManagement`, `Udfs`) into scalar CSV columns.
- **UDF columns** — include as many or as few UDFs as needed. Adjust the `Udf1`–`Udf6` range to match your environment's UDF usage.
- The timestamp in the filename prevents accidental overwrites on repeated runs.

### Variations

**Export a single site:**

```powershell
Get-RMMSite -Name "Main Office" | Get-RMMDevice |
    Select-Object SiteName, Hostname, OperatingSystem, Online, LastSeen |
    Export-Csv -Path MainOffice-Devices.csv -NoTypeInformation
```

**Export with all 30 UDFs:**

```powershell
$UdfColumns = 1..30 | ForEach-Object {
    $Num = $_
    @{n="Udf$Num";e=[scriptblock]::Create("`$_.Udfs.Udf$Num")}
}

$BaseColumns = @('SiteName', 'Hostname', 'OperatingSystem', 'Online', 'LastSeen')

Get-RMMSite | Get-RMMDevice |
    Select-Object ($BaseColumns + $UdfColumns) |
    Export-Csv -Path AllDevices-WithUDFs.csv -NoTypeInformation
```

---

## Custom Type Extensions — Split Site Name by Convention

Many MSPs use a naming convention for sites, such as `CUST001 - Contoso Ltd` or `1234 - Acme Corp`. You can use PowerShell's `Update-TypeData` to add calculated `ScriptProperty` members to the `DRMMSite` type, giving every site object `CustomerName` and `CustomerId` properties derived from the name.

This does not modify the module — it extends the type system in your session using a custom `.ps1xml` file.

### Step 1: Create a Custom Types File

Save the following as `DattoRMM.Core.User.Types.ps1xml` in a location of your choice (e.g. `$HOME/.DattoRMM.Core/` alongside your config file, or with your scripts):

```xml
<?xml version="1.0" encoding="utf-8"?>
<Types>

  <!-- Extend DRMMSite: derive CustomerName and CustomerId from site Name -->
  <!-- Assumes naming convention: "CUSTID - Customer Name" or "ID - Name" -->

  <Type>
    <Name>DRMMSite</Name>
    <Members>

      <ScriptProperty>
        <Name>CustomerId</Name>
        <GetScriptBlock>
          if ($this.Name -match '^\s*(.+?)\s*-') {
            $Matches[1].Trim()
          } else {
            $null
          }
        </GetScriptBlock>
      </ScriptProperty>

      <ScriptProperty>
        <Name>CustomerName</Name>
        <GetScriptBlock>
          if ($this.Name -match '^\s*.+?\s*-\s*(.+)$') {
            $Matches[1].Trim()
          } else {
            $this.Name
          }
        </GetScriptBlock>
      </ScriptProperty>

    </Members>
  </Type>

</Types>
```

### Step 2: Load the Extension

Load the custom types file at the start of your script or in your PowerShell profile:

```powershell
# Load the module
Import-Module DattoRMM.Core

# Load custom type extensions
Update-TypeData -PrependPath "$HOME/.DattoRMM.Core/DattoRMM.Core.User.Types.ps1xml"
```

### Step 3: Use the New Properties

```powershell
# Sites now have CustomerName and CustomerId
Get-RMMSite | Select-Object CustomerId, CustomerName, Name, Description

# Output:
# CustomerId CustomerName     Name                   Description
# ---------- ------------     ----                   -----------
# CUST001    Contoso Ltd      CUST001 - Contoso Ltd  Primary site for Contoso
# CUST002    Fabrikam Inc     CUST002 - Fabrikam Inc East region office
# 1234       Acme Corp        1234 - Acme Corp       Acme headquarters
```

**Filter by derived property:**

```powershell
# Get all devices for a specific customer
Get-RMMSite | Where-Object {$_.CustomerId -eq 'CUST001'} | Get-RMMDevice
```

**Export with customer columns:**

```powershell
Get-RMMSite |
    Select-Object CustomerId, CustomerName, Id, Uid,
        @{n='TotalDevices';e={$_.DevicesStatus.NumberOfDevices}},
        @{n='OnlineDevices';e={$_.DevicesStatus.NumberOfOnlineDevices}} |
    Export-Csv -Path CustomerSites.csv -NoTypeInformation
```

### Key Points

- `Update-TypeData -PrependPath` loads the extensions before the module's built-in types, so your `ScriptProperty` definitions take precedence for new members.
- The regex pattern (`^\s*(.+?)\s*-`) handles common conventions. Adjust the regex to match your site naming standard.
- This approach is non-destructive — it adds properties without modifying the module's class definitions.
- For persistent use, add the `Update-TypeData` call to your `$PROFILE` or to a shared team script.

### Custom Format Extension

You can also create a custom Format file to control how sites display in the console. Save as `DattoRMM.Core.User.Format.ps1xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Configuration>
  <ViewDefinitions>

    <View>
      <Name>DRMMSite.CustomerView</Name>
      <ViewSelectedBy><TypeName>DRMMSite</TypeName></ViewSelectedBy>
      <TableControl>
        <TableHeaders>
          <TableColumnHeader><Label>CustomerId</Label><Width>12</Width></TableColumnHeader>
          <TableColumnHeader><Label>CustomerName</Label><Width>25</Width></TableColumnHeader>
          <TableColumnHeader><Label>SiteName</Label><Width>30</Width></TableColumnHeader>
          <TableColumnHeader><Label>Devices</Label><Width>8</Width></TableColumnHeader>
          <TableColumnHeader><Label>Online</Label><Width>8</Width></TableColumnHeader>
        </TableHeaders>
        <TableRowEntries>
          <TableRowEntry>
            <TableColumnItems>
              <TableColumnItem><ScriptBlock>if ($_.Name -match '^\s*(.+?)\s*-') {$Matches[1].Trim()} else {''}</ScriptBlock></TableColumnItem>
              <TableColumnItem><ScriptBlock>if ($_.Name -match '^\s*.+?\s*-\s*(.+)$') {$Matches[1].Trim()} else {$_.Name}</ScriptBlock></TableColumnItem>
              <TableColumnItem><PropertyName>Name</PropertyName></TableColumnItem>
              <TableColumnItem><ScriptBlock>if ($_.DevicesStatus) {$_.DevicesStatus.NumberOfDevices} else {0}</ScriptBlock></TableColumnItem>
              <TableColumnItem><ScriptBlock>if ($_.DevicesStatus) {$_.DevicesStatus.NumberOfOnlineDevices} else {0}</ScriptBlock></TableColumnItem>
            </TableColumnItems>
          </TableRowEntry>
        </TableRowEntries>
      </TableControl>
    </View>

  </ViewDefinitions>
</Configuration>
```

Load it alongside the types extension:

```powershell
Update-FormatData -PrependPath "$HOME/.DattoRMM.Core/DattoRMM.Core.User.Format.ps1xml"
```

> [!NOTE]
> When a custom format view shares the same `TypeName` as a built-in view, PowerShell uses the most recently loaded view for default display. Use `-PrependPath` to ensure your custom view takes priority, or use `Format-Table -View DRMMSite.CustomerView` to invoke it explicitly.

---

## UDF Expansion — Parse Delimited Device Metadata

Datto RMM UDFs are string fields limited to 255 characters. MSPs commonly pack structured data into a single UDF using a delimiter — for example, storing extended system information as a semicolon-separated string.

The `DRMMDevice` class provides a `GetUdfAsCsv()` method that parses a UDF value into a `PSCustomObject` with named headers, making structured UDF data easy to work with.

### Scenario

Your RMM component populates **UDF 10** on each device with extended system metadata, delimited by semicolons:

```
Primary;Finance;Server Room A;John Smith;2025-06-15
```

The fields represent: `Role`, `Department`, `Location`, `AssetOwner`, `DeploymentDate`.

### Expanding a Single Device

```powershell
$Device = Get-RMMDevice -Hostname "SRV-DC01"

# Parse UDF 10 as semicolon-delimited data with custom headers
$Metadata = $Device.GetUdfAsCsv(10, ';', @('Role', 'Department', 'Location', 'AssetOwner', 'DeploymentDate'))
$Metadata

# Output:
# Role       : Primary
# Department : Finance
# Location   : Server Room A
# AssetOwner : John Smith
# DeploymentDate : 2025-06-15
```

### Expanding UDFs Across All Devices

```powershell
$Headers = @('Role', 'Department', 'Location', 'AssetOwner', 'DeploymentDate')

Get-RMMSite | Get-RMMDevice | ForEach-Object {

    $Udf = $_.GetUdfAsCsv(10, ';', $Headers)

    if ($null -ne $Udf) {

        [pscustomobject]@{
            Hostname       = $_.Hostname
            SiteName       = $_.SiteName
            Role           = $Udf.Role
            Department     = $Udf.Department
            Location       = $Udf.Location
            AssetOwner     = $Udf.AssetOwner
            DeploymentDate = $Udf.DeploymentDate
        }

    }

} | Export-Csv -Path DeviceMetadata.csv -NoTypeInformation
```

### Method Signatures

The `GetUdfAsCsv` method has three overloads:

| Signature | Description |
|---|---|
| `GetUdfAsCsv([int]$UdfNumber, [string[]]$Headers)` | Parse the UDF using comma as delimiter |
| `GetUdfAsCsv([int]$UdfNumber, [string]$Delimiter, [string[]]$Headers)` | Parse with a custom delimiter |

- `$UdfNumber` — The UDF field number (1–30).
- `$Delimiter` — The character separating values (e.g. `;`, `|`, `,`).
- `$Headers` — An array of column names applied to the parsed values.

### Key Points

- UDF values are limited to 255 characters. The delimiter and headers approach gets the most out of this constraint.
- `GetUdfAsCsv` returns `$null` if the UDF is empty or whitespace, so always check before accessing properties.
- The returned `PSCustomObject` integrates naturally with `Select-Object`, `Where-Object`, `Export-Csv`, and other pipeline commands.
- Headers must match the number of delimited values in the UDF. Mismatched counts produce unexpected column mapping.
- This pattern works well for asset tagging, deployment metadata, licensing info, or any structured data that fits within the 255-character UDF limit.

### Combining UDF Expansion with Type Extensions

You can combine UDF expansion with the custom type extension pattern from the previous example. For instance, if UDF 5 contains a comma-separated pair of `Region,Tier`:

```powershell
# Get devices with expanded UDFs and customer site context
Get-RMMSite |
    Where-Object {$_.CustomerId -eq 'CUST001'} |
    Get-RMMDevice |
    ForEach-Object {

        $Tier = $_.GetUdfAsCsv(5, ',', @('Region', 'Tier'))

        [pscustomobject]@{
            CustomerName = $_.SiteName -replace '^\s*\S+\s*-\s*', ''
            Hostname     = $_.Hostname
            OS           = $_.OperatingSystem
            Region       = if ($Tier) {$Tier.Region} else {'Unknown'}
            ServiceTier  = if ($Tier) {$Tier.Tier} else {'Unassigned'}
        }

    } | Export-Csv -Path CustomerDeviceTiers.csv -NoTypeInformation
```

---

## Activity Log — Job Output Collection

Retrieves activity logs for a specific site over the last 24 hours, filters for deployment job runs matching a critical job name, pipes into `Get-RMMJobResult` to fetch execution results, and appends any standard output to a shared CSV file.

This pattern is useful for collecting script output from scheduled jobs — for example, a compliance check component that writes CSV results to stdout.

### Prerequisites

- The `-UseExperimentalDetailClasses` switch on `Get-RMMActivityLog` is **required** to get the strongly-typed `DRMMActivityLogDetailsDeviceJobDeployment` detail class, which `Get-RMMJobResult` expects when piping from activity logs.
- The job's component must produce CSV-formatted standard output (one header row followed by data rows).

### Script

```powershell
<#
    .SYNOPSIS
        Collects stdout from a named job's recent deployments and appends to a shared CSV.

    .DESCRIPTION
        Queries the last 24 hours of activity logs for a specific site,
        filters for deployment runs of a critical job, retrieves job results
        with output, parses CSV from stdout, and appends to a shared report.

    .NOTES
        Requires -UseExperimentalDetailClasses on Get-RMMActivityLog for
        typed detail classes that Get-RMMJobResult can consume via pipeline.
#>

param (

    [string]$SiteName = 'DC01 - Contoso Primary',
    [string]$JobNameFilter = 'Critical Compliance Check',
    [string]$OutputPath = '.\ComplianceResults.csv'

)

# --- Get the target site ---
$Site = Get-RMMSite -Name $SiteName

if (-not $Site) {

    Write-Error "Site '$SiteName' not found."
    return

}

Write-Host "Querying activity logs for '$($Site.Name)' (last 24 hours)..."

# --- Retrieve device job deployment logs for the last 24 hours ---
$Logs = $Site |
    Get-RMMActivityLog -Entity Device -Category Job -Action Deployment `
        -UseExperimentalDetailClasses -Force

Write-Host "Found $($Logs.Count) deployment activity log entries"

# --- Filter for the target job name ---
$TargetLogs = $Logs | Where-Object {$_.Details.JobName -eq $JobNameFilter}
Write-Host "Matched $($TargetLogs.Count) entries for job '$JobNameFilter'"

if ($TargetLogs.Count -eq 0) {

    Write-Host "No matching job deployments found. Exiting."
    return

}

# --- Retrieve job results with output, filter for stdout, parse CSV ---
$TargetLogs | Get-RMMJobResult -IncludeOutput | ForEach-Object {

    $Result = $_

    if ($Result.HasStdOut -and $Result.StdOut) {

        foreach ($StdOutEntry in $Result.StdOut) {

            # Parse CSV from the component's standard output
            $Parsed = $StdOutEntry.GetStdDataAsCsv()

            if ($Parsed) {

                # Add context columns and append to CSV
                $Parsed | Select-Object `
                    @{n='JobUid';e={$Result.JobUid}},
                    @{n='DeviceUid';e={$Result.DeviceUid}},
                    @{n='RanOn';e={$Result.RanOn}},
                    @{n='ComponentName';e={$StdOutEntry.ComponentName}},
                    * |
                    Export-Csv -Path $OutputPath -Append -NoTypeInformation

            }

        }

        Write-Host "Appended stdout from device $($Result.DeviceUid) to $OutputPath"

    } else {

        Write-Verbose "No stdout for device $($Result.DeviceUid) — skipping"

    }

}

Write-Host "Job output collection complete. Results in $OutputPath"
```

### Key Points

- **`-UseExperimentalDetailClasses`** is required to produce `DRMMActivityLogDetailsDeviceJobDeployment` objects. Without it, details use the generic class and `Get-RMMJobResult` will skip them with a warning.
- **`-Force`** on `Get-RMMActivityLog` bypasses the per-site confirmation prompt — useful in non-interactive scripts.
- **`Get-RMMJobResult -IncludeOutput`** makes additional API calls to fetch stdout/stderr. Without `-IncludeOutput`, `StdOut` and `StdErr` arrays are empty.
- **`GetStdDataAsCsv()`** on `DRMMJobStdData` parses the component's stdout as CSV (first row treated as headers by default). If the stdout is JSON instead, use `GetStdDataAsJson()`.
- **`Export-Csv -Append`** adds rows without rewriting the file, making this safe to run on a schedule — each run appends new results.
- The `Select-Object` step prepends context columns (`JobUid`, `DeviceUid`, `RanOn`, `ComponentName`) so every row in the shared CSV is traceable to its source.

### Variations

**All sites, last 7 days:**

```powershell
Get-RMMSite | Get-RMMActivityLog -Start (Get-Date).AddDays(-7) `
    -Entity Device -Category Job -Action Deployment `
    -UseExperimentalDetailClasses -Force |
    Where-Object {$_.Details.JobName -eq 'Critical Compliance Check'} |
    Get-RMMJobResult -IncludeOutput |
    Where-Object {$_.HasStdOut} |
    ForEach-Object {$_.StdOut | ForEach-Object {$_.GetStdDataAsCsv()}} |
    Export-Csv -Path AllSites-ComplianceResults.csv -NoTypeInformation
```

---

## SEE ALSO

- [Beta Guide](DattoRMM.Core-Beta-Guide.md) — Getting started and core beta guidance
- [Beta Overview](about_DattoRMM.CoreBeta.md) — Beta status, expectations, and roadmap
- [Authentication](../about/about_DattoRMM.CoreAuthentication.md) — All authentication methods including Azure Key Vault
- [Configuration](../about/about_DattoRMM.CoreConfiguration.md) — Platform, throttle, and persistence settings
- [Module Overview](../about/about_DattoRMM.Core.md) — Architecture and command reference
