# Migrate-ClassStructure.ps1 — Design & Approach

## Overview

`Migrate-ClassStructure.ps1` is a one-shot migration script that refactors the DattoRMM.Core module from a monolithic class/format/type architecture into a domain-segmented architecture while simultaneously merging external documentation (PSD1) into inline class comments.

**What it does in one operation:**
1. Splits `Classes.psm1` (239.8 KB, 118 types) into 21 domain-specific `.psm1` files
2. Splits `DattoRMM.Core.Format.ps1xml` (113.3 KB) into 16 domain format files
3. Splits `DattoRMM.Core.Types.ps1xml` (39.5 KB) into 16 domain type files
4. Merges `ClassDocContent.psd1` content into class `.SYNOPSIS`/`.DESCRIPTION`/`.NOTES`/`.LINK` blocks
5. Injects property `#` comments and method `<# .SYNOPSIS .OUTPUTS #>` blocks from PSD1 data
6. Rewrites `DattoRMM.Core.psm1` with ordered `using module` statements for dependency resolution
7. Updates `DattoRMM.Core.psd1` manifest with all new Format/Types files
8. Archives originals to `Private\Classes\_Archive\<timestamp>-<filename>`

---

## Architecture

### File Structure After Migration

```
DattoRMM.Core/
├── Private/Classes/
│   ├── _Archive/
│   │   └── 20260403-103120-Classes.psm1
│   │   └── 20260403-103120-DattoRMM.Core.Format.ps1xml
│   │   └── 20260403-103120-DattoRMM.Core.Types.ps1xml
│   ├── Enums/
│   │   └── Enums.psm1
│   ├── DRMMObject/
│   │   ├── DRMMObject.psm1
│   │   └── [no Format/Types for base class]
│   ├── DRMMAccount/
│   │   ├── DRMMAccount.psm1
│   │   ├── DRMMAccount.Format.ps1xml
│   │   └── DRMMAccount.Types.ps1xml
│   ├── [18 more domain folders...]
│   └── DRMMUser/
│       ├── DRMMUser.psm1
│       ├── DRMMUser.Format.ps1xml
│       └── DRMMUser.Types.ps1xml
```

### Module Loading Order

The cross-domain dependency graph is **resolved at script runtime** and embedded into `DattoRMM.Core.psm1`:

```powershell
using module '.\Private\Classes\Enums\Enums.psm1'
using module '.\Private\Classes\DRMMObject\DRMMObject.psm1'
using module '.\Private\Classes\DRMMToken\DRMMToken.psm1'
using module '.\Private\Classes\DRMMAPIKeySecret\DRMMAPIKeySecret.psm1'
using module '.\Private\Classes\DRMMAccount\DRMMAccount.psm1'
# ... (21 domains total)
```

**Why this order matters:** Classes inherit from `DRMMObject`, and the topological sort ensures base classes load before derived classes. Cross-domain dependencies (e.g., `DRMMDevice` references `DRMMFilterContext` from another domain) require the dependency to be loaded first.

---

## Technical Approach

### 1. **Monolithic File Parsing**

The script parses the original monolithic files using PowerShell AST and token analysis:

- **`Classes.psm1`:** Extracted via `#region` boundaries and `[System.Management.Automation.Language.Parser]::ParseInput()` for full AST analysis
  - Per-region parsing identifies class/enum/method/property definitions
  - Region names map directly to domain folder names (e.g., `#region DRMMActivity Log and related classes` → `DRMMActivityLog/`)
  - Full-file parse used for raw source block extraction (to preserve formatting/comments)

- **`Format.ps1xml` & `Types.ps1xml`:** Parsed via `XmlDocument`, views/types matched to domains by `<Type>` name resolution

### 2. **Comment Token Extraction (Binary Search)**

To locate raw source blocks efficiently:
- All comments in `Classes.psm1` are tokenized once via `[System.Management.Automation.PSParser]::Tokenize()`
- Tokens are **pre-sorted by line number** and stored in a `List[PSToken]`
- For each class definition, **binary search** finds the preceding comment block in O(log n) time
- Extracts raw source from comment start line to class end line (preserves original formatting)

**Why not AST source positions?** AST doesn't preserve original formatting; token walk ensures `#` comments and vertical spacing are intact.

### 3. **PSD1 Merge Strategy**

`ClassDocContent.psd1` is structured as:
```powershell
@{
    DRMMAccount = @{
        DRMMAccount = @{
            PropertyDescriptions = @{ Uid = "..."; Name = "..." }
            MethodDescriptions = @{ GetSummary = "..." }
            Notes = @{ ... }
            RelatedLinks = @( ... )
        }
        DRMMAccountDescriptor = @{ ... }
    }
}
```

Merge approach:
- Load PSD1 and index by domain → class name
- For each class block extracted from source:
  - Extract existing `.SYNOPSIS`/`.DESCRIPTION` (preserve these — they're already good)
  - Inject **new** `.NOTES` section with PSD1 Notes
  - Inject **new** `.LINK` section with RelatedLinks
  - For each **property**: insert `# PropertyDescription` comment directly above property line
  - For each **method**: insert `<# .SYNOPSIS ... .OUTPUTS ... #>` comment above method line
  - If property/method not in PSD1, leave as-is (no change)

**Result:** Class blocks with enriched inline documentation, ready for AST scraping by `Build-ClassDocs.ps1`.

### 4. **Dependency Resolution (Topological Sort)**

Two sorts are performed:

#### Intra-Domain Sort (per domain .psm1)
- Classes within the same domain may have inheritance relationships
- Example: `DRMMAccountDevicesStatus : DRMMObjectBase` must come after `DRMMObjectBase` in the same file
- Topological sort ensures base classes appear first

#### Cross-Domain Sort
- Classes in `DRMMAccount` domain may depend on classes in `DRMMObject` domain
- The script computes the **minimal topological sort** of domains
- Domains with no cross-domain dependencies can be reordered safely; domains with explicit dependencies are ordered accordingly
- Result: **load order** embedded in `DattoRMM.Core.psm1`'s `using module` statements

**Implementation:** 
- Build adjacency list of domain dependencies from class inheritance chains
- Kahn's algorithm for topological sort
- Fallback: alphabetical if no dependencies detected

### 5. **File Writing with `using module` Headers**

Each domain `.psm1` file includes:
```powershell
# Domain: [DomainName]
# Purpose: Houses [DomainName] and related domain models
# Dependencies: [list of domains this one depends on]

using module '../Enums/Enums.psm1'
using module '../DRMMObject/DRMMObject.psm1'

#region [DomainName]

# [Raw class source blocks with merged PSD1 content]

#endregion
```

**Why `using module` in each file?** 
- PowerShell 7.4+ requires `using module` at file scope for runtime type resolution
- Without explicit `using`, derived classes cannot locate base class definitions
- If a domain imports only the parent domains it needs, we still include full chain for safety (no harm)

### 6. **Manifest & Root PSM1 Rewrite**

**`DattoRMM.Core.psd1` changes:**
```powershell
# OLD
FormatsToProcess = @('DattoRMM.Core.Format.ps1xml')
TypesToProcess = @('DattoRMM.Core.Types.ps1xml')

# NEW
FormatsToProcess = @(
    'Private\Classes\DRMMAccount\DRMMAccount.Format.ps1xml'
    'Private\Classes\DRMMActivityLog\DRMMActivityLog.Format.ps1xml'
    # ... (16 files total)
)
TypesToProcess = @(
    'Private\Classes\DRMMAccount\DRMMAccount.Types.ps1xml'
    'Private\Classes\DRMMActivityLog\DRMMActivityLog.Types.ps1xml'
    # ... (16 files total)
)
```

**`DattoRMM.Core.psm1` changes:**
```powershell
# OLD
using module '.\Private\Classes\Classes.psm1'

# NEW
using module '.\Private\Classes\Enums\Enums.psm1'
using module '.\Private\Classes\DRMMObject\DRMMObject.psm1'
# ... (21 modules in topological order)
```

---

## Key Design Decisions

### 1. **Single-Pass Operation**
The script is designed to be idempotent-safe and comprehensive. Running it:
- Reads all source files once
- Performs all parsing, merging, sorting in memory
- Writes all new files at the end
- Archives originals in a single shot

**Why?** Reduces risk of partial state (if script fails midway, archives protect originals).

### 2. **Preserve Source Formatting**
Raw source blocks are extracted via token walk, not AST `.Extent`, to preserve:
- Original indentation and whitespace
- Inline comments (`#` comments within function bodies)
- Vertical spacing (blank lines between logical groups)

### 3. **No Dynamic Dependency Loading**
The load order is **computed statically** via topological sort, not resolved at runtime via `Get-ChildItem` or `Import-Module`.

**Why?** Prevents accidental circular dependencies and ensures reproducible load order across environments.

### 4. **PSD1 as Transitional Artifact**
The PSD1 is spliced into classes but remains in the repository as a fallback. After migration:
- `Build-ClassDocs.ps1` prefers inline comments (AST scrape)
- Fallback to PSD1 for legacy docs (for backward compat)
- Once all classes verified with inline docs, delete PSD1

### 5. **Domain Folders Over File Names**
Classes are stored in domain folders (e.g., `DRMMAccount/DRMMAccount.psm1`) not as individual files, because:
- Format/Types files must co-locate with class file
- Each domain is self-contained (independent development)
- Clear visual structure in IDE (folder = domain)

---

## Usage

### Dry Run (Recommended First)
```powershell
cd c:\Users\boab\OneDrive\Modules\DattoRMM.Core\Build
& .\Migrate-ClassStructure.ps1 -DryRun
```

Output shows:
- All domains processed (21)
- All files that *would* be written
- Load order
- "DRY RUN - no files were written"

### Full Migration
```powershell
& .\Migrate-ClassStructure.ps1
```

Writes all files, displays same summary, archives originals.

### Skip PSD1 Merge
If you want to defer PSD1 merge, use:
```powershell
& .\Migrate-ClassStructure.ps1 -SkipPsd1Merge
```

Classes will not have enriched PSD1 content; can be added later.

---

## Post-Migration Checklist

### 1. **Validate Module Load**
```powershell
Import-Module .\DattoRMM.Core\DattoRMM.Core.psd1 -Force
Get-Module DattoRMM.Core
```

Ensure:
- No "Unable to find type" errors
- No "Unexpected attribute" parse errors
- 118 types exported (classes + enums)

### 2. **Run PSScriptAnalyzer**
```powershell
Invoke-ScriptAnalyzer -Path .\DattoRMM.Core\Private\Classes -Recurse -Severity Warning
```

Check for:
- Unused variables/imports
- Inconsistent naming
- Potential logic errors

### 3. **Update Build-ClassDocs.ps1**
Replace single-file parse:
```powershell
# OLD
$ClassesFile = Join-Path $ModuleRoot 'DattoRMM.Core\Private\Classes\Classes.psm1'
$Ast = [System.Management.Automation.Language.Parser]::ParseFile($ClassesFile, [ref]$null, [ref]$Null)

# NEW
$ClassFiles = Get-ChildItem (Join-Path $ModuleRoot 'DattoRMM.Core\Private\Classes') -Filter '*.psm1' -Recurse -Exclude '_Archive'
foreach ($File in $ClassFiles) {
    $Ast = [System.Management.Automation.Language.Parser]::ParseFile($File.FullName, [ref]$null, [ref]$null)
    # Extract classes per file (no need for #region parsing anymore)
}
```

**Why?** Domain name is now parent folder, not #region. This simplifies the build script.

### 4. **Verify Inline Documentation**
Spot-check a few classes to ensure PSD1 content merged correctly:
```powershell
# Open a generated .psm1 file, e.g., DattoRMM.Core\Private\Classes\DRMMDevice\DRMMDevice.psm1
# Verify DRMMDevice class has:
# - .SYNOPSIS from original
# - .DESCRIPTION from original
# - .NOTES section with PSD1 Notes
# - Property comments above each property
# - Method comments above methods
```

### 5. **Test Function Documentation Pipeline**
Run `Build-ClassDocs.ps1` to ensure markdown output is generated correctly:
```powershell
& .\Build\Build-ClassDocs.ps1
```

Verify:
- No errors during AST scrape
- Markdown files generated in `docs/about/classes/`
- Method/Property descriptions match PSD1 content

### 6. **Retire ClassDocContent.psd1** (Optional, Post-Validation)
Once all classes have inline docs verified:
```powershell
# Move to archive
mv .\Build\ClassDocContent.psd1 .\Build\_Archive\ClassDocContent.psd1
# Remove fallback from Build-ClassDocs.ps1 (if using one)
```

---

## Important Notes

### Parse Warnings
During script execution, you may see:
```
WARNING: Parse errors in region '[DomainName]': Unable to find type [DRMMObject]
```

**This is expected and harmless.** 
- Each region is parsed in isolation (without the full file context)
- The missing base class is defined in another region
- The full-file parse (used for raw source extraction) succeeds
- Final `.psm1` files include full `using module` chains, so PS7 resolves all types at runtime

### Archive Naming
Archives use ISO8601 timestamp:
```
_Archive/20260403-103120-Classes.psm1
_Archive/20260403-103120-DattoRMM.Core.Format.ps1xml
_Archive/20260403-103120-DattoRMM.Core.Types.ps1xml
```

All three are timestamped together, making rollback trivial if needed.

### PowerShell Version
- **Required:** PowerShell 7.4+ Core
- **Not supported:** Windows PowerShell 5.1
- `using module` is a PS7+ feature; older versions will fail at import

---

## Rollback

If migration fails or you need to revert:

1. **Restore from archive:**
   ```powershell
   $ts = '20260403-103120'  # From archive folder
   cp ".\Private\Classes\_Archive\$ts-Classes.psm1" ".\Private\Classes\Classes.psm1"
   cp ".\Private\Classes\_Archive\$ts-DattoRMM.Core.Format.ps1xml" ".\DattoRMM.Core\DattoRMM.Core.Format.ps1xml"
   cp ".\Private\Classes\_Archive\$ts-DattoRMM.Core.Types.ps1xml" ".\DattoRMM.Core\DattoRMM.Core.Types.ps1xml"
   ```

2. **Revert `DattoRMM.Core.psm1` and `.psd1`** to pre-migration versions from git

3. **Delete domain folders:**
   ```powershell
   Get-ChildItem '.\Private\Classes' -Directory -Exclude '_Archive' | Remove-Item -Recurse
   ```

---

## Summary

**Migrate-ClassStructure.ps1** is a comprehensive refactoring tool that:
- **Splits** monolithic files into domain structures
- **Merges** external documentation into inline comments
- **Resolves** cross-domain dependencies via topological sort
- **Preserves** source formatting and comments
- **Archives** originals for safe rollback

One operation, zero manual refactoring, fully reversible.
