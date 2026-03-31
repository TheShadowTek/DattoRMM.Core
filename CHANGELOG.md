# Changelog

All notable changes to DattoRMM.Core are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
