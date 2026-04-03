# Contributing to DattoRMM.Core

Thank you for your interest in contributing to DattoRMM.Core. This guide explains the module's architecture, conventions, and build processes so that contributions align with the project's design.

## Table of Contents

- [Getting Started](#getting-started)
- [Repository Structure](#repository-structure)
- [Architecture Overview](#architecture-overview)
  - [Layered Design](#layered-design)
  - [Module Loading Order](#module-loading-order)
- [Classes](#classes)
  - [Per-Domain Class Files](#per-domain-class-files)
  - [Class Documentation Requirements](#class-documentation-requirements)
  - [Adding or Modifying a Class](#adding-or-modifying-a-class)
- [Private Helpers](#private-helpers)
- [Public Functions](#public-functions)
  - [Function Conventions](#function-conventions)
  - [Adding a Public Function](#adding-a-public-function)
- [Static Data](#static-data)
- [Formatting and Naming](#formatting-and-naming)
- [Build Processes](#build-processes)
  - [Documentation Generation](#documentation-generation)
  - [Code Signing](#code-signing)
  - [Release Packaging](#release-packaging)
- [Commit Messages](#commit-messages)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Security](#security)

---

## Getting Started

1. Fork the repository and clone your fork.
2. Create a feature branch from the current development branch.
3. Make your changes following the conventions described below.
4. Run `Get-ClassDocStatus.ps1` to verify 100% documentation coverage.
5. Submit a pull request with a clear description of your changes.

**Prerequisites:**

- PowerShell 7.4 or later
- A Datto RMM API key pair (for integration testing)

---

## Repository Structure

```
DattoRMM.Core/                  # Module root (shipped to users)
├── DattoRMM.Core.psd1          # Module manifest
├── DattoRMM.Core.psm1          # Module loader
├── DattoRMM.Core.Format.ps1xml # Default format definitions
├── DattoRMM.Core.Types.ps1xml  # Default type extensions
├── en-US/                      # Help files (about_ topics, help.txt)
├── Private/
│   ├── Classes/                # Per-domain class modules (.psm1)
│   ├── Api/                    # API request helpers
│   ├── Config/                 # Configuration management helpers
│   ├── Data/                   # Static data files (.psd1)
│   ├── Throttle/               # Rate-limiting logic
│   └── Util/                   # Utility helpers
└── Public/                     # Public API functions by domain
    ├── Account/
    ├── Alerts/
    ├── Auth/
    ├── Devices/
    ├── Filter/
    ├── Jobs/
    ├── Sites/
    ├── Variables/
    └── ...

Build/                          # Build and documentation scripts
docs/                           # Generated documentation output
Reference/                      # API specification files
```

---

## Architecture Overview

### Layered Design

The module follows a strict three-layer architecture. Each layer has clear responsibilities and boundaries:

```
┌─────────────────────────────────────┐
│  Public Functions  (Public/)        │  User-facing API. Orchestrates helpers and classes.
├─────────────────────────────────────┤
│  Private Helpers   (Private/)       │  Business logic, API integration, utilities.
├─────────────────────────────────────┤
│  Classes           (Private/Classes)│  Domain models, enums, typed objects.
└─────────────────────────────────────┘
```

**Rules:**

- Public functions orchestrate; they must not contain domain logic directly.
- Private helpers perform transformations and API calls; they must not call public functions.
- Classes define domain models and validation; they must not perform network calls or file I/O.

### Module Loading Order

The module loads in a strict sequence defined in `DattoRMM.Core.psm1`:

1. **Classes** — 21 `using module` statements in dependency order (base classes first, then dependents)
2. **Static data** — Throttle profiles, operation mappings, retry defaults from `Private/Data/`
3. **Private helpers** — All `.ps1` files under `Private/` are dot-sourced recursively
4. **Public functions** — All `.ps1` files under `Public/` are dot-sourced recursively
5. **Initialisation** — Throttle defaults and saved configuration are applied

Class loading order matters. If class B inherits from class A, class A must appear first in the `using module` list.

---

## Classes

### Per-Domain Class Files

Classes are organised by domain in individual `.psm1` files under `Private/Classes/<Domain>/`:

```
Private/Classes/
├── Enums/
│   └── Enums.psm1
├── DRMMObject/
│   └── DRMMObject.psm1              # Base class for all domain models
├── DRMMDevice/
│   ├── DRMMDevice.psm1
│   ├── DRMMDevice.Format.ps1xml
│   └── DRMMDevice.Types.ps1xml
├── DRMMAlert/
│   ├── DRMMAlert.psm1
│   ├── DRMMAlert.Format.ps1xml
│   └── DRMMAlert.Types.ps1xml
└── ...                               # 21 domain folders total
```

Each domain folder contains:

- **`<Domain>.psm1`** — Class definition with inline documentation (the source of truth)
- **`<Domain>.Format.ps1xml`** — PowerShell format definitions (table/list views)
- **`<Domain>.Types.ps1xml`** — PowerShell type extensions (script properties, methods)

A domain `.psm1` file is a **stable architectural artefact**. Do not split a domain file into multiple files or merge domain files together without explicit instruction.

### Class Documentation Requirements

Every class must have **100% documentation coverage**. This is enforced by the build pipeline. Missing documentation is treated as a code defect.

**Required on every class:**

```powershell
<#
.SYNOPSIS
    Brief one-line description.
.DESCRIPTION
    Detailed description of the class purpose and behaviour.
#>
class DRMMExample : DRMMObject {

    # Description of what this property represents
    [string] $Name

    # Device unique identifier from the API
    [guid] $DeviceUid

    <#
    .SYNOPSIS
        Brief method description.
    .DESCRIPTION
        Detailed method description.
    .OUTPUTS
        Return type and description.
    #>
    [DRMMDevice[]] GetDevices() {
        # implementation
    }
}
```

**Coverage rules:**

- Every class needs `.SYNOPSIS` and `.DESCRIPTION`
- Every public method needs `.SYNOPSIS`, `.DESCRIPTION`, and `.OUTPUTS`
- Every property needs an inline `# comment` describing its purpose
- Run `Build\Get-ClassDocStatus.ps1` to verify — it must report 0 gaps

### Adding or Modifying a Class

Any change to class properties, methods, or signatures requires coordinated updates:

1. Update the class definition in `<Domain>.psm1` (with help blocks)
2. Update or create `<Domain>.Format.ps1xml` if display output changes
3. Update or create `<Domain>.Types.ps1xml` if type extensions change
4. Verify documentation coverage with `Get-ClassDocStatus.ps1`
5. If adding a new domain, add a `using module` statement to `DattoRMM.Core.psm1` in the correct dependency position

Do not create new class files without discussing the design first.

---

## Private Helpers

Private helpers live under `Private/` and are organised by responsibility:

| Folder | Purpose |
|--------|---------|
| `Api/` | API request construction, invocation, pagination, token management |
| `Config/` | Configuration file read/write, saved settings |
| `Data/` | Static data files (throttle profiles, operation mappings, retry defaults) |
| `Throttle/` | Rate-limiting state, throttle profile management |
| `Util/` | General-purpose utility functions |

**Conventions:**

- Private functions use PascalCase names but are not exported.
- They are scoped as private by their location in `Private/`, not by a naming prefix.
- Private helpers must not call public functions.
- Integration logic (API calls, external system interaction) belongs here, not in classes.

**Typical API call flow:**

```
Public function (e.g. Get-RMMDevice)
  → Invoke-ApiMethod          (Private/Api — orchestrates request)
    → Invoke-ApiRestMethod    (Private/Api — low-level call with retry/throttle)
      → Invoke-RestMethod     (PowerShell built-in)
```

Request construction, invocation, and response handling are separated into distinct steps. Public functions build the request parameters, private helpers execute and manage retries, and classes model the response.

---

## Public Functions

### Function Conventions

Public functions are the module's stable API surface. Each function:

- Lives in `Public/<Domain>/` with the filename matching the function name exactly
- Uses an **approved PowerShell verb** (e.g. `Get-`, `Set-`, `Move-`, `Connect-`)
- Includes **full comment-based help** (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.INPUTS`, `.OUTPUTS`)
- Uses **PascalCase** parameters with descriptive, intent-based names
- Returns **typed class objects** (e.g. `[DRMMDevice]`, `[DRMMAlert]`), not raw `PSObject`
- Supports **pipeline input** where appropriate via `[Parameter(ValueFromPipeline)]`

**Example structure:**

```powershell
function Get-RMMDevice {
    <#
    .SYNOPSIS
        Retrieves device information from the Datto RMM API.
    .DESCRIPTION
        Detailed description of behaviour, scopes, and pipeline support.
    .PARAMETER DeviceUid
        The unique identifier (GUID) of the device.
    .EXAMPLE
        Get-RMMDevice -DeviceUid '12345678-1234-1234-1234-123456789abc'
    .INPUTS
        DRMMSite, DRMMFilter
    .OUTPUTS
        DRMMDevice
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (

        [Parameter(ValueFromPipeline)]
        [DRMMSite] $Site,

        [guid] $DeviceUid

    )

    # Orchestration logic — delegates to private helpers
}
```

### Adding a Public Function

1. Create the function file in the appropriate `Public/<Domain>/` folder.
2. Write full comment-based help with all parameter documentation and examples.
3. Use typed class objects for input and output.
4. Add the function name to the `FunctionsToExport` list in `DattoRMM.Core.psd1`.
5. Do not add business logic — delegate to private helpers and classes.

Public function signatures are part of the module's contract. Do not modify existing signatures without discussion.

---

## Static Data

Static configuration lives in `Private/Data/` as `.psd1` files:

| File | Purpose |
|------|---------|
| `ThrottleProfiles.psd1` | Predefined throttle profile defaults |
| `OperationMapping.psd1` | Maps API operations to rate-limit categories |
| `RetryDefaults.psd1` | Retry configuration for API calls |

Do not embed static data directly in functions. If you need a new lookup table or configuration set, add it as a `.psd1` file in this folder.

---

## Formatting and Naming

### Indentation and Spacing

- **Tabs** for indentation (tab size 4)
- Preserve existing vertical spacing; use blank lines to separate logical sections
- Tight horizontal spacing: `{$code}` not `{ $code }`
- Single space around assignment: `$Var = <value>`

### Naming Rules

| Element | Convention | Example |
|---------|-----------|---------|
| Functions | PascalCase, Verb-Noun | `Get-RMMDevice` |
| Parameters | PascalCase, intent-based | `$DeviceUid`, `$EnableLogging` |
| Variables | PascalCase | `$DeviceList`, `$ApiToken` |
| Classes | PascalCase | `DRMMDevice`, `DRMMAlert` |
| Acronyms | Standard casing | `Id`, `Api`, `Url`, `Guid` (not `ID`, `API`, `URL`, `GUID`) |
| Splatting | PascalCase + plural noun | `$InvokeParams`, `$RequestHeaders` |

### Logic Style

- No inline `if` for variable assignment
- No inline `for`/`foreach` for assignment
- Compute conditions first, assign inside blocks:

```powershell
if ($condition) {

    $result = 'ValueA'

} else {

    $result = 'ValueB'

}
```

---

## Build Processes

All build scripts are in the `Build/` folder.

### Documentation Generation

The documentation pipeline generates markdown reference docs and PowerShell help text from inline source documentation.

| Script | Purpose |
|--------|---------|
| `Build-ClassDocs.ps1` | Scans all per-domain `.psm1` files and generates markdown class reference documentation |
| `Build-FunctionDocs.ps1` | Extracts public function help via PlatyPS and generates command documentation |
| `Build-AllDocs.ps1` | Orchestrates full documentation build (classes, functions, help text conversion) |
| `Get-ClassDocStatus.ps1` | Reports documentation coverage — must show **0 gaps** before merge |

**To verify documentation coverage:**

```powershell
.\Build\Get-ClassDocStatus.ps1
```

This scans all class files and reports any missing `.SYNOPSIS`, `.DESCRIPTION`, or property comments. All gaps must be resolved before a pull request can be merged.

### Code Signing

All PowerShell files in the module are code-signed. After making changes, files must be re-signed before release.

| Script | Purpose |
|--------|---------|
| `Sign-Module.ps1` | Signs all `.ps1`, `.psm1`, `.psd1`, and `.ps1xml` files in the module |

See `Build/CODE-SIGNING-GUIDE.md` for certificate setup and signing workflow details.

**Note:** You do not need to sign files for a pull request. Signing is performed by the maintainer before release.

### Release Packaging

| Script | Purpose |
|--------|---------|
| `Build-ReleasePackage.ps1` | Creates a distributable release archive |

### Other Build Scripts

| Script | Purpose |
|--------|---------|
| `Update-LICENSE.ps1` | Ensures SPDX license headers are present on all PowerShell files |

---

## Commit Messages

Follow this convention for all commits:

```
<Type>: <Title>

- Bullet point details
```

### Types

| Type | Use |
|------|-----|
| `feat:` | New features or capabilities |
| `fix:` | Bug fixes |
| `refactor:` | Code restructuring (no behaviour change) |
| `docs:` | Documentation changes |
| `build:` | Build scripts, signing, packaging |
| `chore:` | Housekeeping, minor cleanup |

### Guidelines

- Use imperative mood: "Fix timing bug" not "Fixed" or "Fixes"
- Include a version tag if releasing: `feat: Add filter support (v0.6.0)`
- Be specific about affected areas (class names, function names, build artefacts)

**Example:**

```
refactor: Simplify pagination logic in Invoke-ApiMethod

- Replaced manual page tracking with cursor-based pagination
- Reduced nested conditionals in response handling
- No change to public API behaviour
```

---

## Pull Request Guidelines

1. **One concern per PR** — keep changes focused and reviewable.
2. **Documentation coverage** — run `Get-ClassDocStatus.ps1` and ensure 0 gaps.
3. **No public API changes** without prior discussion — parameter additions, removals, renamed functions, and output type changes all need agreement before implementation.
4. **Follow existing patterns** — match the style of surrounding code. If unsure, look at a similar existing function or class.
5. **Test your changes** — verify with a live API key pair if possible.
6. **Describe your changes** — explain what changed, why, and what testing was done.

---

## Security

See [SECURITY.md](SECURITY.md) for vulnerability reporting procedures.

Key design principles:

- API credentials are accepted as `SecureString` and never stored in plain text.
- Verbose and debug output must not leak sensitive data.
- Do not introduce new external dependencies without discussion.
