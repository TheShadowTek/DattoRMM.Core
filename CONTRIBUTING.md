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
  - [Comment-Based Help Requirements](#comment-based-help-requirements)
  - [Parameter Set Design](#parameter-set-design)
  - [Pipeline Input and Parameter Binding](#pipeline-input-and-parameter-binding)
  - [API Method Splatting](#api-method-splatting)
  - [Object Instantiation with FromAPIMethod](#object-instantiation-with-fromapimethod)
  - [Complete Function Example](#complete-function-example)
  - [Invoke-RMMApiMethod (Public API Passthrough)](#invoke-rmmapimethod-public-api-passthrough)
  - [Adding a Public Function](#adding-a-public-function)
  - [Rationale for Orchestration-Only Public Functions](#rationale-for-orchestration-only-public-functions)
  - [Error Handling Expectations](#error-handling-expectations)
  - [Parameter Validation](#parameter-validation)
  - [Common Mistakes to Avoid](#common-mistakes-to-avoid)
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
- Includes **full comment-based help** (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.INPUTS`, `.OUTPUTS`, `.NOTES`, `.LINK`)
- Uses **PascalCase** parameters with descriptive, intent-based names
- Returns **typed class objects** (e.g. `[DRMMDevice]`, `[DRMMAlert]`), not raw `PSObject`
- Supports **pipeline input** where appropriate via `[Parameter(ValueFromPipeline)]`

### Comment-Based Help Requirements

Every public function requires complete comment-based help. The following sections are mandatory:

| Section | Required | Purpose |
|---------|----------|---------|
| `.SYNOPSIS` | Yes | One-line summary of the function |
| `.DESCRIPTION` | Yes | Detailed behaviour description including scopes, pipeline support, and caveats |
| `.PARAMETER` | Yes (each) | Description of every parameter, including type and intent |
| `.EXAMPLE` | Yes (2+) | At least two usage examples with descriptions |
| `.INPUTS` | Yes | Pipeline input types accepted (e.g. `DRMMSite`, `DRMMFilter`) |
| `.OUTPUTS` | Yes | Return type(s) and key properties |
| `.NOTES` | Yes | Authentication requirements, related guidance |
| `.LINK` | Yes | Online documentation URL and related commands/topics |

**Online Documentation Link:**

The first `.LINK` entry must be a hardcoded URL pointing to the function's online documentation. This URL is constructed from the `DocsBaseUrl` in the module manifest and the function's domain path:

```powershell
.LINK
    https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/<Domain>/<FunctionName>.md
```

Subsequent `.LINK` entries reference related about_ topics and functions by name:

```powershell
.LINK
    about_DRMMDevice

.LINK
    Get-RMMSite
```

### Parameter Set Design

Public functions use parameter sets to control API scope and define mutually exclusive parameter combinations. Parameter sets are a core architectural pattern — they determine which API endpoint is called, what parameters are valid, and how pipeline input is routed.

**Naming convention:** Parameter set names follow the pattern `<Scope><Action>`:

| Pattern | Example | Meaning |
|---------|---------|---------|
| `Global` / `GlobalAll` | Default account-level scope | Queries the global (account) endpoint |
| `GlobalById` | Specific resource by ID at account scope | Uses the account endpoint with an ID filter |
| `GlobalByName` | Specific resource by name at account scope | Uses the account endpoint with a name filter |
| `SiteAll` | All resources at a site | Queries the site-specific endpoint |
| `SiteById` | Specific resource by ID at a site | Uses the site endpoint with an ID filter |
| `ByDeviceObject` | Input from a piped device | Routes via the device's UID |
| `ByDeviceUid` | Input from an explicit UID | Routes directly to the device endpoint |

**Rules:**

- Every function must declare `DefaultParameterSetName` in `[CmdletBinding()]`
- Parameter sets control which API path is constructed — they are not just UI convenience
- A parameter may belong to multiple parameter sets (e.g. `$Id` in both `GlobalById` and `SiteById`)
- Use `[Parameter(Mandatory)]` to enforce required combinations within each set

### Pipeline Input and Parameter Binding

Pipeline input follows a strict convention:

- **Module class objects** (e.g. `[DRMMSite]`, `[DRMMFilter]`, `[DRMMDevice]`) are accepted via `ValueFromPipeline = $true`
- **Scalar identifiers** (UIDs, IDs, names) are **not** pipeline-bound — they are positional or named parameters only
- `ValueFromPipelineByPropertyName` is used sparingly and only where it aligns with a clear property contract

**Why:** Class objects carry rich context (UIDs, scopes, related metadata) that scalar values cannot provide. Piping a `[DRMMSite]` object gives the function access to `$Site.Uid`, `$Site.Name`, and scope information. Piping a bare UID string loses this context.

```powershell
# Correct: Class object via pipeline
[Parameter(ValueFromPipeline = $true)]
[DRMMSite] $Site,

# Correct: Scalar identifier as named parameter (not pipeline)
[Parameter(Mandatory = $true)]
[guid] $DeviceUid
```

### API Method Splatting

Public functions build a parameter splat hashtable for `Invoke-ApiMethod` (the private API orchestrator). This keeps request construction explicit and readable.

**Standard pattern:**

```powershell
$ApiMethod = @{
    Path        = "site/$($Site.Uid)/devices"
    Method      = 'Get'
    Paginate    = $true
    PageElement = 'devices'
}

Invoke-ApiMethod @ApiMethod | ForEach-Object {

    [DRMMDevice]::FromAPIMethod($_, $Script:SessionPlatform)

}
```

**Conventions:**

- Name the splat `$ApiMethod` (singular, PascalCase)
- Always include `Path` and `Method`
- Include `Paginate` and `PageElement` for list endpoints
- Include `Body` for PUT/POST requests
- The splat is constructed inside the parameter set switch, not outside — each branch builds its own request

### Object Instantiation with `FromAPIMethod`

API responses are converted to typed domain objects using the static `FromAPIMethod()` pattern defined on each class. Public functions do not construct class instances directly — they delegate to this factory method.

**Common signatures:**

```powershell
# Simple conversion — response only
[DRMMAccount]::FromAPIMethod($Response)

# With scope context
[DRMMFilter]::FromAPIMethod($_, $Scope, $Script:SessionPlatform)

# With parent object context
[DRMMSiteFilter]::FromAPIMethod($_, $Site, $Script:SessionPlatform)

# With scope and identifier
[DRMMVariable]::FromAPIMethod($_, 'Site', $SiteUid)
```

**Rules:**

- Always use `FromAPIMethod()` — never construct class instances with `[ClassName]::new()` followed by manual property assignment
- The method handles null checking, property mapping, and type coercion
- Additional context parameters (scope, platform, parent objects) are passed as needed by the class

### Complete Function Example

The following example demonstrates all conventions working together:

```powershell
function Get-RMMFilter {
    <#
    .SYNOPSIS
        Retrieves filters from the Datto RMM API.
    .DESCRIPTION
        The Get-RMMFilter function retrieves filters at different scopes:
        global (account-level) or site-level. Filters can be retrieved by
        ID, name, or all filters at a given scope.
    .PARAMETER Site
        A DRMMSite object to retrieve filters for. Accepts pipeline input.
    .PARAMETER Id
        Retrieve a specific filter by its numeric ID.
    .PARAMETER Name
        Retrieve a filter by its name (exact match).
    .PARAMETER FilterType
        Filter the results by type. Valid values: 'All', 'Default', 'Custom'.
    .EXAMPLE
        Get-RMMFilter
        Retrieves all filters at the account level.
    .EXAMPLE
        Get-RMMSite -Name "Main Office" | Get-RMMFilter
        Gets all filters for the "Main Office" site.
    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite.
    .OUTPUTS
        DRMMFilter. Returns typed filter objects.
    .NOTES
        Requires an active connection via Connect-DattoRMM.
    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Filter/Get-RMMFilter.md
    .LINK
        about_DRMMFilter
    .LINK
        Get-RMMDevice
    #>

    [CmdletBinding(DefaultParameterSetName = 'GlobalAll')]
    param (

        [Parameter(ParameterSetName = 'SiteAll', Mandatory, ValueFromPipeline)]
        [Parameter(ParameterSetName = 'SiteById', Mandatory, ValueFromPipeline)]
        [DRMMSite] $Site,

        [Parameter(ParameterSetName = 'GlobalById', Mandatory)]
        [Parameter(ParameterSetName = 'SiteById', Mandatory)]
        [int] $Id,

        [Parameter(ParameterSetName = 'GlobalByName', Mandatory)]
        [ValidateSet('All', 'Default', 'Custom')]
        [string] $FilterType = 'All'

    )

    process {

        # Parameter set determines API scope
        if ($PSCmdlet.ParameterSetName -match '^Site') {

            # Build API method splat for site-scoped request
            $ApiMethod = @{
                Path        = "site/$($Site.Uid)/filters"
                Method      = 'Get'
                Paginate    = $true
                PageElement = 'filters'
            }

            Invoke-ApiMethod @ApiMethod | ForEach-Object {

                [DRMMSiteFilter]::FromAPIMethod($_, $Site, $Script:SessionPlatform)

            }

        } else {

            # Global scope — build and invoke
            $ApiMethod = @{
                Path        = 'filter/default-filters'
                Method      = 'Get'
                Paginate    = $true
                PageElement = 'filters'
            }

            Invoke-ApiMethod @ApiMethod | ForEach-Object {

                [DRMMFilter]::FromAPIMethod($_, 'Global', $Script:SessionPlatform)

            }
        }
    }
}
```

### Invoke-RMMApiMethod (Public API Passthrough)

`Invoke-RMMApiMethod` is the only public function that exposes the private `Invoke-ApiMethod` helper directly. It provides advanced users with access to arbitrary API endpoints while preserving all module infrastructure (authentication, throttling, retries, pagination).

All other public functions call `Invoke-ApiMethod` internally and return typed objects. `Invoke-RMMApiMethod` returns raw `PSObject` responses — it is the escape hatch, not the standard path.

### Adding a Public Function

1. Create the function file in the appropriate `Public/<Domain>/` folder.
2. Write full comment-based help with all mandatory sections (see [Comment-Based Help Requirements](#comment-based-help-requirements)).
3. Include the hardcoded online documentation URL as the first `.LINK` entry.
4. Design parameter sets that map to API scopes (see [Parameter Set Design](#parameter-set-design)).
5. Accept module class objects via pipeline; use scalar identifiers as named parameters only.
6. Build an `$ApiMethod` splat and call `Invoke-ApiMethod` — do not call `Invoke-RestMethod` directly.
7. Use `[ClassName]::FromAPIMethod()` to instantiate return objects.
8. Add the function name to the `FunctionsToExport` list in `DattoRMM.Core.psd1`.
9. Do not add business logic — delegate to private helpers and classes.

Public function signatures are part of the module's contract. Do not modify existing signatures without discussion.

### Rationale for Orchestration-Only Public Functions

Public functions must remain thin orchestration layers. This architectural boundary is intentional and preserves:

- **Stable, predictable public API** — Functions do not contain domain logic that might change with internal refactoring
- **Clear separation of concerns** — Orchestration (public), logic (private), modelling (classes)
- **Testability** — Business logic in private helpers can be unit tested in isolation
- **Consistent behaviour** — All domains follow the same pattern
- **Reduced API risk** — Internal logic changes do not leak out to users

**Consequence:** If you find yourself tempted to add logic to a public function, create a private helper instead. The boundary exists to protect the API surface.

### Error Handling Expectations

To maintain consistent error semantics across the module:

- **Public functions must not suppress or swallow errors** from private helpers — let errors propagate naturally
- **Errors may be wrapped only to add context** — e.g., catching a low-level API error and re-throwing with the device UID for clarity
- **API-level errors originate in private helpers**, not public functions — do not add custom error messages in orchestration
- **Public functions throw terminating errors** for invalid or contradictory input — parameter validation errors should stop execution
- **Avoid non-terminating errors** unless there is explicit, documented reason (rare edge cases only)

**Example — correct error handling:**

```powershell
# BAD: Suppressing errors
Invoke-ApiMethod @ApiMethod -ErrorAction SilentlyContinue

# BAD: Adding custom error logic to public function
if ($null -eq $result) {
    Write-Warning "Device not found"
    return
}

# GOOD: Let private helpers handle errors, let them propagate
$result = Invoke-ApiMethod @ApiMethod

# GOOD: Add context for troubleshooting
try {
    $result = Get-RMMDevice -DeviceUid $uid
} catch {
    throw "Failed to retrieve device $uid : $_"
}
```

### Parameter Validation

Use parameter sets and validation attributes to enforce valid invocation paths:

- **Parameter sets** control which API endpoint is called — use them for scope and action filtering
- **`[ValidateSet(...)]`** for enums and restricted values
- **`[Mandatory]`** for required parameters within a parameter set
- **Type declarations** enforce input types at parse time (e.g., `[DRMMSite]`, `[guid]`)
- **Avoid inline validation logic** — use attributes and parameter sets instead

Validation failures should be caught early by PowerShell before the function body runs.

### Common Mistakes to Avoid

Contributors frequently introduce inconsistencies by:

1. **Adding business logic directly to public functions** — Move it to `Private/` helpers
2. **Returning raw API responses or untyped PSCustomObject** — Always use `[ClassName]::FromAPIMethod()`
3. **Forgetting to update `FunctionsToExport`** in `DattoRMM.Core.psd1` — New functions won't be exported
4. **Using non-approved PowerShell verbs** — Only use standard verbs (Get, Set, New, Remove, Connect, Disconnect, Resolve, etc.)
5. **Embedding static data in functions** — Create `.psd1` files in `Private/Data/` instead
6. **Parameters that mirror API structure** — Parameter names should express user intent, not API fields (e.g., `$DeviceId` not `$id`)
7. **Implementing retry, pagination, or request construction in public functions** — Delegate to `Invoke-ApiMethod`
8. **Returning different types depending on parameter combinations** — Keep return types consistent (or use formal parameter-set-specific outputs)

These patterns break consistency and violate the module's architectural expectations.

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
| `Build-FunctionDocs.ps1` | Extracts public function help via PlatyPS, generates command documentation, and builds the command index |
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

**Templates:** The repository includes PR and issue templates to standardise contributions. Use the PR template when opening pull requests (see `.github/PULL_REQUEST_TEMPLATE.md`) — it includes sections for summary, related issues, change details, test instructions, and a pre-merge checklist. For new issues, use the templates under `.github/ISSUE_TEMPLATE/` (for example `bug_report.md` and `feature_request.md`). These templates help reviewers and maintainers triage and validate contributions more quickly.

---

## Security

See [SECURITY.md](SECURITY.md) for vulnerability reporting procedures.

Key design principles:

- API credentials are accepted as `SecureString` and never stored in plain text.
- Verbose and debug output must not leak sensitive data.
- Do not introduce new external dependencies without discussion.
