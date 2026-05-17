# PII-Safe Output Pack

Reference implementation of PII masking via the DattoRMM.Core type/format extension system.

---

## What Is This?

> **This is a reference example, not a ready-to-deploy configuration.** Before installing, review every file and adapt it for your environment. The UDF number (`Udf5`), visible character counts, and the choice of which fields to mask are all organisation-specific decisions that only you can make. Deploy only what your organisation actually requires.

The DattoRMM.Core module returns raw API data without filtering or masking. If your organisation needs PII protection at the console output layer, this pack demonstrates how to implement it using the built-in type and format extension points — without modifying the module.

Two full examples are provided:

| Example | Fields masked |
|---|---|
| **DRMMUser** | `Username`, `FirstName`, `LastName`, `Email`, `Telephone` |
| **DRMMDevice** | `LastLoggedInUser`, and a specific UDF that contains PII (UDF5 by default) |

Masking is **additive**: the raw properties are unchanged and always accessible. The masked properties (`MaskedEmail`, `MaskedLastLoggedInUser`, etc.) are layered on top. The format files redirect the default console views to show masked values instead of raw ones.

---

## Files

| File | Purpose |
|---|---|
| `DattoRMM.Core.PII-Safe.Types.ps1xml` | Adds `ScriptProperty` members to `DRMMUser` and `DRMMDevice` |
| `DattoRMM.Core.PII-Safe.Format.ps1xml` | Overrides default List and Table views to display masked properties |
| `ExportTransforms.psd1` | Overrides the `Default` export transform for `DRMMUser` and `DRMMDevice`; masked fields in CSV output |
| `README.md` | This file |

---

## Installation

### Option A — Profile folder (recommended, persistent)

Copy all three extension files to the DattoRMM.Core profile folder:

```powershell
$ProfileFolder = Join-Path $HOME '.DattoRMM.Core'
New-Item -ItemType Directory -Path $ProfileFolder -Force | Out-Null

Copy-Item .\DattoRMM.Core.PII-Safe.Types.ps1xml   $ProfileFolder
Copy-Item .\DattoRMM.Core.PII-Safe.Format.ps1xml  $ProfileFolder
Copy-Item .\ExportTransforms.psd1                 $ProfileFolder
```

The module discovers and loads `*.Types.ps1xml`, `*.Format.ps1xml`, and `ExportTransforms.psd1` from this folder automatically during `Import-Module`. The format file is loaded with `-PrependPath` so its views take precedence over the module defaults. The export transforms are merged with the built-in transforms; entries with the same class/transform name override the built-in version.

> If you already have a custom `ExportTransforms.psd1` in the profile folder, merge the `DRMMUser` and `DRMMDevice` entries from this file into your existing file rather than replacing it.

### Option B — In-session only

Load manually after importing the module:

```powershell
Import-Module DattoRMM.Core

Update-TypeData   -PrependPath .\DattoRMM.Core.PII-Safe.Types.ps1xml
Update-FormatData -PrependPath .\DattoRMM.Core.PII-Safe.Format.ps1xml
```

Order matters: load the types file before the format file.

To activate the export transform in-session, reimport the module after copying `ExportTransforms.psd1` to the profile folder, or merge its contents into your existing `$HOME\.DattoRMM.Core\ExportTransforms.psd1` and reimport.

---

## How It Works

### Types extension (`*.Types.ps1xml`)

PowerShell's type extension system lets you add computed properties (`ScriptProperty`) to any .NET type. Each masked property calls the `[DRMMObject]::MaskString()` static utility, which the module provides for exactly this purpose.

```powershell
# Reading a masked property — no masking in the class, no module change required
(Get-RMMUser)[0].MaskedEmail          # "ja********************"
(Get-RMMUser)[0].Email                # "jane.smith@contoso.com"  ← raw value unchanged
```

`MaskString` signature:

```
[DRMMObject]::MaskString([string]$Value, [int]$VisibleChars, [string]$MaskChar)
```

| Parameter | Effect |
|---|---|
| `$Value` | The string to mask |
| `$VisibleChars` | Number of leading characters to leave visible |
| `$MaskChar` | Replacement character (default `*`) |

Notes:
- If `$Value` is null or empty, returns `***`.
- If `$Value` is shorter than or equal to `$VisibleChars`, the **entire** string is masked for safety.

### Format extension (`*.Format.ps1xml`)

PowerShell selects the first matching format view for a type. Loading the format file with `-PrependPath` (Option B) or via the profile folder (Option A) ensures the PII-Safe views are found first, replacing the default console output for `DRMMUser` and `DRMMDevice` objects.

Only console views are affected. Pipeline data, `Select-Object`, and JSON serialisation all use the raw properties directly and are not affected by format files. CSV export via `Export-RMMObjectCsv` is handled separately — see [Export Transforms](#export-transforms) below.

---

## Fields Masked

### DRMMUser

| Masked property | Source property | VisibleChars | Example output |
|---|---|---|---|
| `MaskedUsername` | `Username` | 2 | `js****` |
| `MaskedFirstName` | `FirstName` | 1 | `J***` |
| `MaskedLastName` | `LastName` | 1 | `S****` |
| `MaskedEmail` | `Email` | 2 | `ja********************` |
| `MaskedTelephone` | `Telephone` | 3 | `+44************` |

### DRMMDevice

| Masked property | Source property | VisibleChars | Example output |
|---|---|---|---|
| `MaskedLastLoggedInUser` | `LastLoggedInUser` | 2 | `CO************` |
| `MaskedUdf5` | `Udfs.Udf5` | 2 | `jo***************` |

`LastLoggedInUser` is only populated when `Get-RMMDevice` is called with `-IncludeLastLoggedInUser`. `MaskedLastLoggedInUser` is safe to access at all times; it returns `***` when the raw field is empty.

`MaskedUdf5` returns an empty string when `Udfs` is null (i.e., the device was retrieved without UDF data) and returns `***` when `Udf5` is set to an empty string.

---

## Customisation

### Changing the visible character count

Edit the `VisibleChars` argument in the `<GetScriptBlock>` of the Types file:

```xml
<!-- Show first 4 characters of email instead of 2 -->
<GetScriptBlock>[DRMMObject]::MaskString($this.Email, 4, '*')</GetScriptBlock>
```

### Masking a different UDF

The pack uses `Udf5` as a placeholder. To mask the UDF that contains PII in your environment:

1. Open `DattoRMM.Core.PII-Safe.Types.ps1xml`.
2. Find the `MaskedUdf5` block.
3. Change both the `<Name>` and the `$this.Udfs.Udf5` reference to your target UDF number:

```xml
<!-- Change Udf5 to your target UDF number, e.g. Udf12 -->
<ScriptProperty>
  <Name>MaskedUdf12</Name>
  <GetScriptBlock>
    if ($null -eq $this.Udfs) {return [string]::Empty}
    [DRMMObject]::MaskString($this.Udfs.Udf12, 2, '*')
  </GetScriptBlock>
</ScriptProperty>
```

4. Update the corresponding column in `DattoRMM.Core.PII-Safe.Format.ps1xml` to reference `MaskedUdf12`.
5. Update the corresponding entry in `ExportTransforms.psd1`: `@{Name = 'Udf12'; Path = 'MaskedUdf12'}`.

To mask multiple UDFs, duplicate the block for each one and update both the format file and the export transforms accordingly.

UDF numbers run from `Udf1` to `Udf300`.

### Masking with a different character

Replace the mask character argument:

```xml
[DRMMObject]::MaskString($this.Email, 2, '#')
```

---

## Enable / Disable

**To disable:** Remove the files from `$HOME\.DattoRMM.Core\` and restart the PowerShell session (or reimport the module). The module will revert to its default views, default export transforms, and no masked properties will be added.

**To re-enable:** Copy the files back and reimport the module.

---

## Export Transforms

The `ExportTransforms.psd1` file overrides the built-in `Default` export transform for `DRMMUser` and `DRMMDevice`. When installed, `Export-RMMObjectCsv` will write masked values to CSV for the PII fields defined in the pack.

```powershell
# With pack installed — CSV contains masked values
Get-RMMUser | Export-RMMObjectCsv -Path .\Users.csv

# Same command, raw output — temporarily bypass by naming a different transform
Get-RMMUser | Export-RMMObjectCsv -Path .\Users.csv -TransformName Default
# Note: if you have overridden Default, there is no built-in fallback via -TransformName.
# Remove the ExportTransforms.psd1 and reimport the module to restore raw defaults.
```

### How masked columns appear in the CSV

The column headers in the CSV are identical to the built-in defaults (`Username`, `Email`, `LastLoggedInUser`, `Udf5`, etc.). Only the values differ — downstream consumers do not need to be aware that masking is applied.

### UDF masking in exports

The built-in `-IncludeUdf` and `-Udf` parameters on `Export-RMMObjectCsv` always write raw UDF values and bypass the transform entirely. To get masked UDF values in CSV output, include the UDF in the transform via the `MaskedUdf<N>` ScriptProperty:

```powershell
# In ExportTransforms.psd1 — masked UDF5 in the CSV
@{Name = 'Udf5'; Path = 'MaskedUdf5'}

# Equivalent raw entry for comparison (does NOT use MaskString):
@{Name = 'Udf5'; Path = 'Udfs.Udf5'}
```

The `MaskedUdf5` path resolves the ScriptProperty added by `DattoRMM.Core.PII-Safe.Types.ps1xml`. That file must be installed for this reference to work. The `Udfs.Udf5` path resolves the raw nested property directly and does not depend on the types extension.

> `Expression` entries in export transforms cannot call `[DRMMObject]::MaskString()` — the expression validator blocks static .NET method calls. Use the `Path`-to-`ScriptProperty` pattern shown above instead.

---

## Limitations

- **Format overrides are console-only.** `Format-Table`, `Format-List`, and pipeline-to-console display are affected. `Select-Object`, `ConvertTo-Json`, and `Export-Csv` (when used directly) use raw properties and are not affected by format files.
- **Export masking requires ExportTransforms.psd1.** Installing only the Types and Format files leaves CSV output unmasked. All three files must be installed for complete coverage.
- **Export transforms cannot call MaskString inline.** The expression security model blocks `.NET` type access in `Expression` entries. Define masked ScriptProperties in Types.ps1xml and reference them via `Path`.
- **Not a security control.** This pack makes PII less visible in interactive sessions and CSV exports. It is not a substitute for access control, logging policy, or data governance.
- **Masking is not reversible.** The masked properties show only leading characters; the full value is not derivable from the masked output. Access the raw property directly when the full value is required.
- **MaskString behaviour on short strings.** If a value is shorter than or equal to `VisibleChars`, the entire string is masked (not partially revealed). This is intentional.

---

## See Also

- [about_DattoRMM.CoreTypeExtensions](../../about/about_DattoRMM.CoreTypeExtensions.md)
- [about_DattoRMM.CoreFormatExtensions](../../about/about_DattoRMM.CoreFormatExtensions.md)
- [about_DattoRMM.CoreExport](../../about/about_DattoRMM.CoreExport.md)
- [about_DattoRMM.CoreSecurity](../../about/about_DattoRMM.CoreSecurity.md)
