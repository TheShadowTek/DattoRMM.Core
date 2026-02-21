# GitHub Copilot Instructions

## Table of Contents

- [Purpose](#purpose)
- [Coding Style](#coding-style)
  - [Formatting and Linting](#formatting-and-linting)
    - [Vertical Spacing](#vertical-spacing)
    - [Horizontal Spacing](#horizontal-spacing)
    - [Inline Logic and One-Liners](#inline-logic-and-one-liners)
    - [Variable Declaration and Assignment](#variable-declaration-and-assignment)
  - [Naming Conventions](#naming-conventions)
    - [Functions](#functions)
    - [Parameters](#parameters)
    - [Variables](#variables)
    - [Splatting and Intent-Based Naming](#splatting-and-intent-based-naming)
    - [Classes and Enums](#classes-and-enums)
    - [Files and Modules](#files-and-modules)
    - [Acronyms and Capitalisation](#acronyms-and-capitalisation)
    - [General Naming Philosophy](#general-naming-philosophy)
- [File and Module Structure](#file-and-module-structure)
- [Refactoring Expectations](#refactoring-expectations)
- [Documentation Expectations](#documentation-expectations)
- [Summary: How Copilot Should Behave in This Repository](#summary-how-copilot-should-behave-in-this-repository)

## Purpose
This repository uses GitHub Copilot as an architectural assistant, not an autonomous code generator.  
Copilot should prioritise:
- Clarity, maintainability, and long‑term governance
- Explicit architectural reasoning
- Consistent style and predictable refactoring behaviour
- Respect for module boundaries and public API surfaces
- Explanations of *why* a suggestion is appropriate, not just *what* to type

Copilot should avoid:
- Overly clever or compressed code
- Hidden side effects or implicit behaviour
- Generating new patterns that conflict with existing architecture
- Making assumptions about secrets, infrastructure, or deployment

## Coding Style

### Formatting and Linting

#### Vertical Spacing
- Preserve all existing blank lines and vertical spacing exactly as written.
- Add vertical spacing to separate logical sections of code (parameters, variable declarations, logic blocks, return/output).
- Do not collapse multiple blank lines unless explicitly asked.
- Avoid dense, vertically compressed code — clarity comes from separation.

#### Horizontal Spacing
- Use tabs for indentation (tab size 4).
- Keep horizontal spacing tight: avoid unnecessary spaces around braces, parentheses, or operators.
- Preferred brace style is `{<code>}` rather than `{ <code> }`.
- Use a single space around assignment operators: `$Var = <value>`.
- Do not align multiple variable declarations using extra tabs or whitespace.

#### Inline Logic and One-Liners
- Avoid inline `if` statements except in very limited, simple cases (e.g., inside string interpolation).
- Do not use inline `if` for variable assignment (no `$var = if (...) { ... }`).
- Avoid inline `for`/`foreach` constructs for variable assignment.
- Logic and assignment should be clearly separated in the code.
- Prefer clarity over compactness — readability is the priority.

#### Variable Declaration and Assignment
- Variables must not be declared using inline control structures (`if`, `for`, `foreach`, etc.).
- Compute conditions first, then assign inside the relevant block.
- Preferred pattern:

  ```powershell
  if ($condition) {

     Do-Something
     $result = <expression>

  } else {

     Do-SomethingElse
     $result = <expression>

  }
  ```

### Naming Conventions

#### Functions
- Use PascalCase for all function names.
- Public functions must follow approved PowerShell Verb-Noun format (e.g., `Get-DeviceStatus`).
- Private functions do **not** use a leading underscore; they are placed in the `Private/` folder to indicate scope.
- Function names must be descriptive and explicit — avoid vague verbs or generic nouns.
- Prefer domain clarity (`Get-DeviceStatus`) over generic abstractions (`Invoke-Action`).

#### Parameters
- Use PascalCase for all parameter names.
- Parameter names should describe intent and meaning, not type (`DeviceId`, not `StringId`).
- Boolean parameters should express intent (`EnableLogging`, `ForceRefresh`, `IncludeInactive`).
- Acronyms follow standard casing rules: `Id`, `Api`, `Url`, `Guid`.

#### Variables
- Use PascalCase for all variable names.
- Variable names should reflect purpose and usage, not implementation detail.
- Avoid cryptic or single-letter names.
- Acronyms follow the same casing rules as parameters: `$DeviceId`, `$ApiToken`, `$SessionGuid`.
- Variables should be declared clearly inside logical blocks, not inline with control structures.

#### Splatting and Intent-Based Naming
- When preparing splatting hashtables, use names that reflect both **what** the data represents and **how** it will be used.
  - Example: `$InvokeParams` for a hashtable passed to `Invoke-RestMethod`.
- Splatting variables should be PascalCase and end with a plural noun when representing a collection of parameters.
- Avoid overly generic splat names (`$Params`, `$Options`) unless the context is extremely narrow.

#### Classes and Enums
- Use PascalCase for class and enum names.
- Class properties use PascalCase to align with .NET conventions.
- Class names should represent domain concepts, not implementation details.

#### Files and Modules
- Public modules use PascalCase (`MyModule.psm1`).
- Private helper files use lowercase with hyphens (`token-utils.ps1`, `private-helpers.ps1`).
- One public function per file unless functions are intentionally grouped.

#### Acronyms and Capitalisation
- Use standard PowerShell casing for acronyms:
  - `Id` (not `ID`)
  - `Api` (not `API`)
  - `Url` (not `URL`)
  - `Guid` (not `GUID`)
- Apply acronym casing consistently across functions, parameters, variables, and classes.

#### General Naming Philosophy
- Names must prioritise clarity, intent, and maintainability.
- Prefer explicit, descriptive names over clever or compressed ones.
- Names should reflect **what** something represents and **how** it is used.
- Consistency across the module is more important than brevity.

## File and Module Structure

### Public API Structure
- Public functions are organised by domain inside the `Public/` folder.
- Each domain has its own subfolder (e.g., `Public/Devices`, `Public/Auth`, `Public/Config`).
- File names must match the function name exactly.
- Only functions in `Public/<Domain>/` are exported via the module manifest.

### Private Structure
- Private implementation details live in the `Private/` folder.
- `Private/` contains:
  - `Classes/` for class definitions
  - `Data/` for static data, lookup tables, schemas
  - optional domain‑specific helper files

### Class File Structure

- All classes are defined in a single structured module file:
  - `Private/Classes/Classes.psm1`
- This file is imported using `using module` at the top of the main module file (`ModuleName.psm1`).
- The classes module is loaded **before any other code**, ensuring:
  - class definitions are available globally
  - inheritance works correctly
  - ScriptAnalyzer does not complain about ordering
  - downstream functions can rely on class types

#### Why a Single `.psm1` File
- PowerShell class inheritance and ScriptAnalyzer have known issues when classes are split across multiple files.
- A single `.psm1` ensures:
  - predictable load order
  - stable inheritance chains
  - no circular reference problems
  - no partial class visibility
- Copilot must not split classes into multiple files.

#### Regions and Organisation
- The classes module is divided into clearly named `#region` / `#endregion` blocks.
- Each class has its own region.
- Subclasses are grouped within or adjacent to their parent class region.
- Region names must be stable and descriptive to support documentation tooling.

#### Comment-Based Help for Documentation Metadata
- Every class includes `.SYNOPSIS` and `.DESCRIPTION` comment-based help.
- Every class method also includes `.SYNOPSIS` and `.DESCRIPTION`.
- These blocks are used to generate:
  - documentation metadata
  - markdown help files
  - about_ topics
  - class reference documentation
- Copilot must not omit or auto‑generate placeholder help blocks.

#### Class Ordering
- Classes appear in the following order:
  1. Base classes
  2. Domain models
  3. Utility classes
- This ordering ensures predictable inheritance and clean documentation output.

#### File Stability Rules
- Copilot must not:
  - split classes into multiple files
  - reorder classes
  - remove or rename regions
  - change the `.psm1` to `.ps1`
  - modify the load order in `ModuleName.psm1`
- The classes module is a **stable architectural artifact**, not a place for experimentation.

### Layering and Boundaries
- The module follows a strict layered architecture:
  1. Classes (domain models, base types, utilities)
  2. Private helpers (logic, transformations, integration)
  3. Public API (user-facing functions)
- Layers must not be mixed.
- Public functions orchestrate; they do not contain domain logic.
- Private helpers must not call public functions.

### Domain Segmentation
- Public functions are grouped by domain under `Public/<Domain>/`.
- Private helpers may optionally be grouped by domain under `Private/`.
- Classes represent domain concepts and must not contain integration logic.
- Integration logic belongs only in private helpers.

### Public API Governance
- Public functions define the stable API surface.
- Copilot must not:
  - create new public functions unless explicitly instructed
  - modify public function signatures
  - rename public functions
  - add or remove parameters
  - change output types
- Public functions must:
  - validate input
  - orchestrate private helpers and classes
  - return typed objects or structured output
  - avoid side effects unless explicitly intended

### Private API Rules
- Private functions may evolve more freely but must remain cohesive and domain-aligned.
- Private functions must not leak implementation details into the public API.
- Private functions must not introduce new dependencies without explicit instruction.

### Integration Logic
- Integration with external systems must:
  - live in private helper functions
  - use typed classes for request/response modelling
  - separate request construction, invocation, and response handling
- Integration logic must not appear in public functions or classes.

### Data and Static Assets
- Static data, schemas, and lookup tables live under `Private/Data/`.
- Static data must not be embedded directly into public functions.
- Copilot must not modify static data files unless explicitly asked.

### Class Architecture
- All classes live in `Private/Classes/Classes.psm1`.
- Loaded first via `using module` in the main module file.
- Classes define:
  - domain models
  - request/response types
  - validation logic
  - transformation helpers
- Classes must not:
  - perform network calls
  - read or write files
  - depend on module state
- Copilot must not create new class files or split the class module.

### Module Initialisation
- `Classes.psm1` is loaded first using `using module`.
- The main module file (`ModuleName.psm1`) must:
  - load classes first
  - dot-source private helpers
  - dot-source public functions
  - perform minimal initialisation
- Copilot must not add logic directly to the `.psm1`.

### Stability and Maintainability
- Architectural stability is a priority.
- Copilot must not propose large-scale reorganisations.
- New code must align with existing patterns, naming, and structure.
- Clarity and maintainability take precedence over cleverness or brevity.

### API Accuracy Expectations
<!-- This section will be completed in Task 16 -->

## Refactoring Expectations

### Deliberate Refactors
- Copilot must treat refactoring as an intentional, controlled activity.
- Refactors should preserve behaviour unless explicitly instructed otherwise.
- Copilot must:
  - explain the purpose of the refactor
  - outline the steps it intends to take
  - maintain architectural boundaries
  - preserve naming conventions, formatting rules, and file structure
- Refactors must not:
  - introduce new patterns
  - alter public API surfaces
  - change output types
  - merge or split files without instruction
- When refactoring, Copilot should prioritise:
  - clarity
  - maintainability
  - reduction of duplication
  - improved separation of concerns
  - alignment with existing architecture

### Assisted Explanations and Fixes
- When the user asks for help understanding code, Copilot should:
  - explain the behaviour clearly
  - identify architectural or stylistic issues
  - propose improvements aligned with this instruction file
- When fixing code, Copilot must:
  - preserve intent
  - avoid unnecessary rewrites
  - avoid introducing new dependencies
  - avoid altering unrelated logic
- Copilot should provide:
  - reasoning behind changes
  - before/after comparisons when helpful
  - guidance on how the fix aligns with module architecture

## Documentation Expectations

### README and Architecture Notes
- The README must provide a clear, high‑level overview of the module’s purpose, architecture, and usage.
- Copilot should help maintain the README by:
  - ensuring examples reflect the current public API
  - updating terminology to match naming conventions
  - keeping architectural descriptions aligned with the module’s actual structure
- Copilot must not:
  - invent new features or capabilities
  - describe APIs that do not exist
  - add speculative roadmap items
- Architecture notes should:
  - summarise the layered design (Classes → Private Helpers → Public API)
  - describe domain segmentation
  - explain how classes are loaded and used
  - outline the documentation pipeline and region‑based class structure
- Copilot should ensure architecture notes remain:
  - accurate
  - concise
  - aligned with the real module structure
  - free from implementation details that belong in code comments or about_ topics

### Contributor Documentation
- Contributor documentation must help new contributors understand:
  - the module’s architecture
  - the purpose of each top‑level folder
  - naming conventions
  - formatting and linting rules
  - how classes, regions, and documentation metadata work
  - how to safely extend the public API
- Copilot should assist by:
  - ensuring examples match the current architecture
  - keeping terminology consistent with this instruction file
  - updating contributor guidance when architectural rules evolve
- Copilot must not:
  - invent new contributor workflows
  - introduce undocumented patterns
  - describe processes that do not exist in the repository
- Contributor documentation should emphasise:
  - the layered architecture (Classes → Private Helpers → Public API)
  - the single‑file class module and region structure
  - the documentation pipeline and how comment‑based help is consumed
  - the importance of not modifying public API signatures without explicit approval
- All contributor guidance must remain:
  - explicit
  - stable
  - aligned with the repository’s governance model
  - free from speculation or assumptions about future features

### Inline Documentation and Comments
- Inline documentation must prioritise clarity, intent, and maintainability.
- Comments should explain *why* something is done, not restate *what* the code already expresses.
- Copilot should add comments when:
  - architectural decisions are not obvious
  - logic depends on external constraints (API quirks, vendor behaviour, ordering requirements)
  - a function or block performs a non‑obvious transformation
  - a workaround or defensive pattern is required

#### Write-Verbose and Write-Debug Usage
- The module follows traditional PowerShell design guidance:
  - **Write-Verbose** is used for operational narration (what the function is doing).
  - **Write-Debug** is used for deeper diagnostic detail (why a branch was taken, what data was transformed).
- Copilot should:
  - prefer Write-Verbose/Write-Debug for runtime insight instead of excessive inline comments
  - ensure messages are meaningful, concise, and aligned with the module’s terminology
  - avoid leaking sensitive data in verbose or debug output
- Copilot must not:
  - replace architectural comments with verbose/debug output
  - generate noisy or redundant messages
  - add verbose/debug output to classes or static data files

#### Comment-Based Help
- **Public functions** require full comment-based help, including:
  - `.SYNOPSIS`
  - `.DESCRIPTION`
  - `.PARAMETER` blocks for each parameter
  - `.EXAMPLE` blocks where appropriate
  - any additional help sections used by the documentation pipeline
- **Classes and class methods** require only:
  - `.SYNOPSIS`
  - `.DESCRIPTION`
- Class help blocks are used exclusively for:
  - documentation metadata generation
  - markdown class reference output
  - about_ topic generation
- Copilot must not invent examples, parameters, or behaviour that does not exist.

#### Comment Quality Expectations
- Comments should be:
  - concise but meaningful
  - aligned with the module’s terminology
  - stable and predictable for automated documentation tooling
- Copilot should ensure comments remain accurate during refactors and update them when logic changes.

### Automated Documentation Pipeline
- This repository uses automated build scripts to generate:
  - Markdown help for all public functions
  - About_ help topics
  - Class reference documentation
  - Knowledge metadata extracted from class definitions and regions
  - PowerShell help.txt files for distribution

#### Behaviour Expectations for Copilot
- Copilot must ensure that all comment-based help is structurally correct and compatible with the documentation tooling.
- Copilot must not:
  - invent metadata fields
  - add undocumented behaviour
  - generate placeholder or speculative examples
  - modify documentation pipeline scripts unless explicitly instructed
- Copilot should:
  - maintain consistent `.SYNOPSIS` and `.DESCRIPTION` blocks in classes and class methods
  - ensure public functions include full help blocks with correct parameter documentation
  - keep region names stable and descriptive to support metadata extraction
  - update help text when refactoring changes behaviour or parameters

#### Stability Requirements
- The documentation pipeline depends on:
  - region naming consistency
  - class ordering
  - predictable comment-based help structure
  - stable public API signatures
- Copilot must not introduce changes that break these assumptions.
- All documentation output must remain aligned with the module’s architecture, naming conventions, and domain model.

## Summary: How Copilot Should Behave in This Repository
Copilot acts as an architectural assistant. It should:
- Prioritise clarity, maintainability, and governance.
- Follow the structure and rules defined in this file.
- Respect module boundaries, public API surfaces, and documentation pipelines.
- Avoid inventing patterns, metadata, or API fields.
- Provide reasoning, not just output.

This summary is a behavioural anchor; detailed rules are defined in the sections above.
