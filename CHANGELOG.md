# Changelog

All notable changes to DattoRMM.Core are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.6.0] — 2026-07-15 — First Stable Release

### Summary

First stable release, published to the PowerShell Gallery. Removes the beta tag established in
v0.5.50. This release adds support for Datto RMM's 300-UDF expansion, promotes the experimental
activity log detail class hierarchy to its first complete coverage across all known entity and
category combinations, and adds a new `Get-RMMDeviceSoftware` function.

### Added

- `Get-RMMDeviceSoftware` — retrieves installed software for a device; accepts pipeline from `Get-RMMDevice`; returns `DRMMDeviceAuditSoftware` objects
- `Get-RMMActivityLog` `-UseExperimentalDetailClasses` switch — opt-in typed dispatch for activity log detail objects; off by default (all details remain `DRMMActivityLogDetailsGeneric` without the switch)
- `DRMMActivityLogEntityDevice` and `DRMMActivityLogEntityUser` — new base classes normalising the six entity-level properties common to all DEVICE and USER activity log details
- Full `DEVICE` entity detail class coverage — specific classes for `job` (deployment, create), `remote` (chat, jrto), `device` (move.device), and `patch` (audit) actions; entity-level and category-level generic fallbacks for unmapped combinations
- Full `USER` entity detail class coverage across 14 categories — `account`, `component`, `device`, `monitor`, `site`, `user`, `agent`, `policy`, `authUser`, `branding`, `email.recipient`, `filter`, `job`, `web.remote.chat`, and `web.remote` — with specific action classes and generic fallbacks throughout
- `about_DattoRMM.CoreActivityLogDiscovery` — new concept topic describing the three-level entity/category/action dispatch model, default generic behaviour, opt-in typed dispatch, and a discovery guide for identifying unmapped detail combinations

### Changed

- `DRMMDeviceUdfs` extended from 30 to 300 UDF properties (`Udf31`–`Udf300`); new `static [int]$MaxUdfCount = 300` constant used throughout all range checks
- `Export-RMMObjectCsv` UDF loops updated to `1..[DRMMDeviceUdfs]::MaxUdfCount`; `-Udf` parameter range validation updated accordingly
- `DRMMDevice` class methods (`SetUdf`, `ClearUdf`, `ClearUdfs`, `GetUdfAsJson`, `GetUdfAsCsv`) updated to use `MaxUdfCount` for range validation and iteration
- Module manifest `Prerelease` tag removed; version bumped to `0.6.0`

### Breaking Changes

- `Set-RMMDeviceUdf` — individual `-UDF1` through `-UDF30` parameters and the corresponding `ByDeviceUidIndividual`/`ByDeviceObjectIndividual` parameter sets have been removed; use `-UdfFields @{udf1='Value'; udf5='Value'}` (hashtable mode) or `-UdfNumber`/`-UdfValue` (single mode) instead; UDF values are validated to 255 characters maximum

---

## [0.5.50] — 2026-03-31 — Public Beta

### Summary

First public beta release. The module is stable and suitable for real-world use.
All major domains — authentication, configuration, typed classes, pagination,
throttle management, and pipeline behaviour — are complete and consistent across
environments.

### Added

- `Invoke-RMMApiMethod` — generic API wrapper for calling any Datto RMM API endpoint not yet covered by a dedicated function
- Multi-bucket throttle monitoring and configurable throttle profiles via `Set-ThrottleDefaults`
- `DRMMAlertContextGeneric` extended with `PropertyTypes` and `GetSummary()` for schema discovery during beta testing
- Alert context discovery guide (`about_DattoRMM.CoreAlertContextDiscovery`)
- Full beta documentation set including authentication, configuration, security, and throttling guides
- `DRMMActivityLogEntityDevice` and `DRMMActivityLogEntityUser` base classes for entity-level abstraction in activity log details
- `DRMMActivityLogDetailsDeviceGeneric` and `DRMMActivityLogDetailsUserGeneric` for safe handling of unknown activity log categories
- Device audit routing via `DeviceClass`-based dispatch

### Changed

- Throttle system fully rewritten for multi-bucket rate limit support with real-time monitoring
- All internal API naming standardised to PascalCase (`Api` not `API`) across functions, parameters, and variables
- `Account` throttle bucket renamed to `Read` throughout the throttle layer for clarity
- `Get-RMMDevice` refactored with improved parameter handling and pipeline support
- DateTime handling aligned to UTC throughout
- `SecureString` and credential handling reviewed and hardened
- Private folder restructured for clearer domain separation
- Types and format files (`DattoRMM.Core.Types.ps1xml`, `DattoRMM.Core.Format.ps1xml`) refactored with consistent List and Table views for all user-facing classes

### Fixed

- `New-RMMVariable` and `Set-RMMConfig` parameter binding bug fixes
- Alert context handling correctness improvements

### Minimum Requirements

- PowerShell 7.4 (Core only)
- Windows

---

## Pre-release development history

Versions 0.1.0 through 0.5.49 represent the private development history of the module prior to public release. Significant milestones include:

- `0.5.36` — Enhanced authentication with token handling and multiple parameter sets
- `0.5.33` — Job retrieval refactor
- `0.5.32` — ActivityLog entity hierarchy and DEVICE/USER abstraction
- `0.5.27–0.5.31` — Experimental ActivityLog details classes (graduated to stable in 0.5.50)
- `0.5.0` — Initial typed class model, pagination, and throttle foundation
