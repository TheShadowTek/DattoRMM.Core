# about_DattoRMM.CoreExport

## SHORT DESCRIPTION

Opinionated CSV export for DattoRMM.Core typed objects using named column transforms, with support for user-defined transforms loaded from the module profile folder.

## LONG DESCRIPTION

`Export-RMMObjectCsv` provides a structured, low-friction way to export `DRMMSite`, `DRMMDevice`, and `DRMMAlert` objects to CSV without requiring users to manually flatten nested properties using `Select-Object`. The command detects the object type from the pipeline, applies a named transform, and streams each row directly to disk.

### Why a dedicated export command

DattoRMM.Core objects are typed classes with rich nested structures. A `DRMMDevice` carries its site details, antivirus status, patch management state, and UDFs as nested objects. A `DRMMAlert` wraps source device and site information inside `AlertSourceInfo`. Passing these directly to `Export-Csv` produces columns containing class names rather than values.

`Export-RMMObjectCsv` resolves this by applying a transform — a named, ordered list of column definitions — that flattens the object into a predictable, human-readable CSV shape.

### The transform system

A transform is a named array of column definitions stored in a `.psd1` file. Each transform belongs to a class name key, and each class can have multiple named transforms.

**Column definition formats:**

A simple string includes a direct property by name:

```powershell
'Hostname'
'Online'
'OperatingSystem'
```

A hashtable with `Name` and `Path` creates a calculated column using dot-notation for nested access. This also resolves ETS ScriptProperties added via `Types.ps1xml`:

```powershell
@{Name = 'DeviceCategory'; Path = 'DeviceType.Category'}
@{Name = 'AntivirusStatus'; Path = 'Antivirus.AntivirusStatus'}
@{Name = 'TotalDevices'; Path = 'DevicesStatus.NumberOfDevices'}
```

Paths are validated at runtime against `^[a-zA-Z_][a-zA-Z0-9_.]*$` before being converted to scriptblocks.

A hashtable with `Name` and `Method` calls a parameterless method on the object. This resolves class methods and ETS ScriptMethods added via `Types.ps1xml`:

```powershell
@{Name = 'AlertSummary'; Method = 'GetSummary'}
@{Name = 'DeviceAge'; Method = 'GetDeviceAge'}
```

Method names are validated against `^[a-zA-Z_][a-zA-Z0-9_]*$`.

A hashtable with `Name` and `Expression` evaluates a string expression as a scriptblock. This supports member access on `$_`, string operations, conditionals, and comparison operators:

```powershell
@{Name = 'Status'; Expression = 'if ($_.Online) {"Online"} else {"Offline"}'}
@{Name = 'CustomerId'; Expression = '$_.Name.Split(" - ")[0]'}
@{Name = 'DisplayName'; Expression = '$_.Hostname.ToUpper()'}
```

Because `.psd1` data files cannot contain scriptblock literals (`{...}`), expressions are written as strings and converted to scriptblocks at runtime after passing layered security validation.

**Expression security model:**

Expressions are validated by `Test-ExportExpression` through four layers before conversion:

| Layer | Check | Purpose |
|---|---|---|
| 1 | Length cap (500 characters) | Prevents abuse via excessively long expressions |
| 2 | ASCII character whitelist | Fast rejection of unexpected character classes |
| 3 | PowerShell AST parsing | Whitelists safe node types only; blocks cmdlet calls, .NET type access, assignments, redirections, and scriptblock literals |
| 4 | Variable restriction | Only `$_`, `$null`, `$true`, and `$false` are permitted |

**What is allowed in expressions:**

- Property access on `$_` — `$_.Hostname`, `$_.Antivirus.AntivirusStatus`
- Method calls on `$_` and its members — `$_.Hostname.ToUpper()`, `$_.Name.Split("-")[0]`
- Comparisons — `$_.Value -gt 10`, `$_.Online -eq $true`
- Conditionals — `if ($_.Online) {"Up"} else {"Down"}`
- String interpolation — `"$($_.SiteName) - $($_.Hostname)"`
- Ternary expressions — `$_.Online ? "Up" : "Down"`

**What is blocked:**

- Cmdlet or function calls (`Get-Date`, `Write-Host`, `Invoke-Expression`)
- .NET type access (`[System.IO.File]::ReadAllText()`, `[DateTime]::Now`)
- Arbitrary variables (`$env:COMPUTERNAME`, `$Host`, `$Error`, `$PSVersionTable`)
- Assignment statements (`$x = 5`)
- Redirections, pipeline commands, and nested scriptblock literals

> If an expression requires cmdlets or .NET types, define a ScriptProperty or ScriptMethod in `Types.ps1xml` and reference it via `Path` or `Method` instead. For more complex transformations, write a custom export script outside the module.

> Each hashtable entry must contain exactly one of `Path`, `Method`, or `Expression`. Entries with more than one are skipped with a warning.

### Built-in transforms

| Type | Transform | Description |
|---|---|---|
| `DRMMSite` | `Default` | Id, Uid, Name, Description, OnDemand, device counts, AutotaskCompanyName, AutotaskCompanyId, PortalUrl |
| `DRMMSite` | `Summary` | Id, Name, Description, device counts |
| `DRMMDevice` | `Default` | Id, Uid, site details, hostname, device type, IP addresses, OS, user, domain, online status, timestamps, warranty, antivirus, patch status, PortalUrl |
| `DRMMDevice` | `Summary` | Id, Hostname, SiteName, OperatingSystem, Online, LastSeen, IntIpAddress |
| `DRMMAlert` | `Default` | AlertUid, Priority, Diagnostics, resolution details, context class, monitor config, source device and site, AutoresolveMins, PortalUrl |
| `DRMMAlert` | `Summary` | AlertUid, Priority, Resolved, Timestamp, DeviceName, SiteName, Diagnostics |

### Selecting a transform

The `-TransformName` parameter is tab-completable. Its `ValidateSet` is built dynamically from all loaded transforms — built-in and user-defined — when the function is invoked. It defaults to `'Default'` if not specified.

```powershell
Get-RMMDevice | Export-RMMObjectCsv -Path .\Devices.csv -TransformName Summary
```

### Memory efficiency

Objects are written to disk one at a time in the `process` block. The file is created (or cleared) in `begin` before the pipeline starts. This streaming approach keeps memory usage flat regardless of how large the pipeline is, and is safe for Azure Automation runbooks and other memory-constrained environments.

### The -Append parameter

`-Append` writes new rows into an existing file without truncating it. File creation and overwrite decisions are made in `begin` — before any pipeline objects arrive — so a long-running export will not fail midway through on a file access conflict.

When using `-Append`, the caller is responsible for ensuring the schema matches. Mixing a `Default` export with a `Summary` append will produce a malformed CSV.

---

## UDF HANDLING

User-defined fields are excluded from the default transform to keep the output clean. Two parameters control UDF inclusion for `DRMMDevice` exports.

### -IncludeUdf

Includes all 30 UDF columns (Udf1–Udf30) in every row, regardless of whether they contain values. This produces a consistent, fixed-width schema across all rows, which is important when using `-Append` to combine exports from multiple runs:

```powershell
Get-RMMDevice | Export-RMMObjectCsv -Path .\Devices.csv -IncludeUdf
```

### -Udf

Includes only the named UDFs. Useful when only a subset of fields are relevant and the schema is known:

```powershell
Get-RMMDevice | Export-RMMObjectCsv -Path .\Devices.csv -Udf 'Udf1', 'Udf5', 'Udf10'
```

Both parameters are ignored for all but `DRMMDevice` exports, other types produce a warning if specified.

> When Datto RMM expands the UDF count in a future platform update, `-IncludeUdf` will include all new fields automatically once the class is updated.

---

## DEFINING CUSTOM TRANSFORMS

Custom transforms are loaded from `$HOME/.DattoRMM.Core/ExportTransforms.psd1` at module import. They are merged with the built-in transforms. An entry with the same class and transform name as a built-in entry overrides the built-in version.

The file uses the same format as the built-in `ExportTransforms.psd1`:

```powershell
@{

    'DRMMSite' = @{

        'Billing' = @(
            'Name'
            'AutotaskCompanyName'
            'AutotaskCompanyId'
            @{Name = 'TotalDevices'; Path = 'DevicesStatus.NumberOfDevices'}
        )
    }

    'DRMMDevice' = @{

        'Compliance' = @(
            'Hostname'
            'SiteName'
            'OperatingSystem'
            'RebootRequired'
            @{Name = 'PatchStatus'; Path = 'PatchManagement.PatchStatus'}
            @{Name = 'AntivirusStatus'; Path = 'Antivirus.AntivirusStatus'}
            'WarrantyDate'
        )
    }
}
```

After creating or editing the file, reimport the module to pick up the changes:

```powershell
Remove-Module DattoRMM.Core
Import-Module .\DattoRMM.Core\DattoRMM.Core.psd1
```

### Transforms for any class

The transform system is not limited to Site, Device, and Alert. You can define transforms for any DattoRMM.Core class that is returned from the API, including `DRMMActivityLog`, `DRMMComponent`, `DRMMFilter`, or `DRMMVariable`. The class name key must exactly match the PowerShell class name:

```powershell
@{

    'DRMMActivityLog' = @{

        'Default' = @(
            'Id'
            'Created'
            'Username'
            'Type'
            'Description'
        )
    }
}
```

Pipe the objects to `Export-RMMObjectCsv` as normal — the command detects the type and resolves the transform:

```powershell
Get-RMMActivityLog | Export-RMMObjectCsv -Path .\ActivityLog.csv
```

If no transform is defined for the detected type, a non-terminating error is raised on the first object and the export stops.

### Using with type extensions

Custom properties and methods added via `Types.ps1xml` are fully supported by the transform system.

**ScriptProperty via Path** — A ScriptProperty defined in `Types.ps1xml` is accessed like any other property and can be referenced using `Path`:

```xml
<!-- Types.ps1xml -->
<ScriptProperty>
    <Name>DeviceAge</Name>
    <GetScriptBlock>((Get-Date) - $this.LastSeen).Days</GetScriptBlock>
</ScriptProperty>
```

```powershell
# ExportTransforms.psd1
@{Name = 'DeviceAge'; Path = 'DeviceAge'}
```

**ScriptMethod via Method** — A ScriptMethod defined in `Types.ps1xml` can be called using the `Method` key:

```xml
<!-- Types.ps1xml -->
<ScriptMethod>
    <Name>GetStatusLabel</Name>
    <Script>if ($this.Online) {'Online'} else {'Offline'}</Script>
</ScriptMethod>
```

```powershell
# ExportTransforms.psd1
@{Name = 'Status'; Method = 'GetStatusLabel'}
```

**Expression for inline logic** — When a ScriptProperty or ScriptMethod is not available (or not worth creating), use `Expression` for ad-hoc logic directly in the transform. Expressions are restricted to member access on `$_`, comparisons, string operations, and conditionals — cmdlet calls and .NET type access are blocked:

```powershell
# ExportTransforms.psd1
@{Name = 'DisplayName';  Expression = '"$($_.SiteName) - $($_.Hostname)"'}
@{Name = 'StatusLabel';   Expression = 'if ($_.Online) {"Up"} else {"Down"}'}
@{Name = 'CustomerId'; Expression = '$_.Name.Split(" - ")[0]'}
```

> For expressions that require cmdlets (e.g., `Get-Date`) or .NET type access, define a ScriptProperty in `Types.ps1xml` instead and reference it via `Path`.

> A future update will support dynamic loading of `Types.ps1xml` and `Format.ps1xml` files from the module profile folder alongside the custom transforms file.

---

## EXAMPLES

### Example 1: Export all sites

```powershell
Get-RMMSite | Export-RMMObjectCsv -Path .\Sites.csv
```

### Example 2: Export devices with a compact column set

```powershell
Get-RMMDevice | Export-RMMObjectCsv -Path .\Devices.csv -TransformName Summary
```

### Example 3: Export all alerts with a UTC timestamp per row

```powershell
Get-RMMAlert -Status All | Export-RMMObjectCsv -Path .\Alerts.csv -IncludeTimestamp
```

### Example 4: Export devices with full UDF columns for consistent schema

```powershell
Get-RMMDevice | Export-RMMObjectCsv -Path .\Devices.csv -IncludeUdf
```

### Example 5: Append new device data to an existing file

```powershell
# Initial export
Get-RMMSite -Name "Site A" | Get-RMMDevice | Export-RMMObjectCsv -Path .\AllDevices.csv

# Append results from a second site with matching schema
Get-RMMSite -Name "Site B" | Get-RMMDevice | Export-RMMObjectCsv -Path .\AllDevices.csv -Append
```

### Example 6: Export using a custom user-defined transform

Assuming `$HOME/.DattoRMM.Core/ExportTransforms.psd1` defines a `'Compliance'` transform for `DRMMDevice`:

```powershell
Get-RMMDevice | Export-RMMObjectCsv -Path .\Compliance.csv -TransformName Compliance
```

### Example 7: Transform using a Method entry

Assuming `DRMMAlert` has a `GetSummary()` method (class method or ETS ScriptMethod):

```powershell
# In ExportTransforms.psd1
'DRMMAlert' = @{
    'WithSummary' = @(
        'AlertUid'
        'Priority'
        @{Name = 'AlertSummary'; Method = 'GetSummary'}
        'Timestamp'
    )
}
```

```powershell
Get-RMMAlert | Export-RMMObjectCsv -Path .\Alerts.csv -TransformName WithSummary
```

### Example 8: Transform using an Expression entry

```powershell
# In ExportTransforms.psd1
'DRMMDevice' = @{
    'StatusReport' = @(
        'Hostname'
        'SiteName'
        @{Name = 'Status'; Expression = 'if ($_.Online) {"Online"} else {"Offline"}'}
        @{Name = 'FQDN'; Expression = '"$($_.Hostname).$($_.Domain)"'}
        'OperatingSystem'
    )
}
```

```powershell
Get-RMMDevice | Export-RMMObjectCsv -Path .\StatusReport.csv -TransformName StatusReport
```

---

## SEE ALSO

- [Export-RMMObjectCsv](../commands/Export/Export-RMMObjectCsv.md)
- [about_DattoRMM.Core](about_DattoRMM.Core.md)
- [about_DattoRMM.CoreConfiguration](about_DattoRMM.CoreConfiguration.md)
- [about_ClassIndex](./classes/about_ClassIndex.md)