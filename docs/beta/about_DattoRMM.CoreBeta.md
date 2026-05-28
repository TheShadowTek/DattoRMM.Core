# about_DattoRMM.CoreBeta

## SHORT DESCRIPTION

Describes the status, expectations, and participation guidelines for the DattoRMM.Core beta, including how to provide anonymised schema data for undocumented API structures.

## LONG DESCRIPTION

The DattoRMM.Core module is feature‑complete for general use and is now entering a structured beta period. The goal of this beta is to validate behaviour across diverse environments, refine the adaptive throttling engine, and collect anonymised schema data for undocumented API structures such as activity log entries and alert contexts.

The module is stable, safe to use, and suitable for real‑world testing. Some areas remain intentionally conservative until broader usage provides additional insight.

---

## STATUS AND EXPECTATIONS

### Current Status

The DattoRMM.Core module is stable and suitable for real‑world use during the beta period. All major domains — authentication, configuration, typed classes, pagination, and pipeline behaviour — are complete and behave consistently across environments.

Some areas have limited real‑world coverage so far, including printer audits, ESXi host audits, and certain alert context types that are currently based on documented structures rather than observed data. These features are implemented and expected to work, and they will benefit from broader testing during the beta.

The beta period is open‑ended to ensure the module matures against real‑world usage before v1.

---

### Areas Under Active Refinement

#### Adaptive Throttling
The throttling engine is fully functional and protects against account‑wide limits. It will continue to be tuned as more real‑world telemetry becomes available. The current behaviour is intentionally conservative in edge cases.

#### Activity Log Schema Coverage
Some activity log entry types remain undocumented. The module handles these safely using generic classes, and dedicated types will be added as anonymised schema data becomes available from testers.

#### Platform Coverage
The module is developed and tested primarily on Windows. Azure Automation Account runbook deployment has been validated, including Managed Identity and Key Vault credential patterns. Limited testing has been performed on Linux (Ubuntu 24.04.1 LTS). No testing has been performed on macOS. The module is expected to work on all platforms supported by PowerShell 7.4+, and OS-specific feedback is especially valuable during the beta.

---

### Expectations During Beta

#### What Will Change
- Throttling refinements  
- Additional typed classes for undocumented structures  
- Documentation updates  
- Optional enhancements to CSV export  
- Occasional breaking changes, always documented and justified  

#### What Will Not Change
- Command names and parameter sets  
- Object model structure  
- Authentication behaviour  
- Pipeline patterns  
- Configuration keys  

The module’s architecture is stable; refinements are additive.

---

## OPTIONAL ANONYMISED DATA CONTRIBUTION

To expand coverage for undocumented activity log details and alert contexts, testers can optionally provide anonymised schema data.

Only structural information is collected — discriminator values, property names, and property types. No values, identifiers, or environment-specific data are included.

- For **alert context** collection scripts and submission guidance, see [about_DattoRMM.CoreAlertContextDiscovery](../about/about_DattoRMM.CoreAlertContextDiscovery.md).
- For **activity log details** collection scripts and submission guidance, see [about_DattoRMM.CoreActivityLogDiscovery](../about/about_DattoRMM.CoreActivityLogDiscovery.md).

---

## FEATURES COMING IN v1 (OR EARLIER)

### Additional Typed Classes
As anonymised schema data becomes available, new typed classes will be added for undocumented activity log entries, undocumented alert contexts, and any new structures introduced during the beta period.

---

## ROADMAP TO v1

v1 will be declared when:

- Throttling behaviour is fully tuned  
- Activity log and alert context coverage is more complete  
- Documentation is fully aligned with the module's architecture  
- Cross-platform testing coverage is sufficient (Linux, macOS)

The beta period remains open‑ended to ensure the module reaches the right level of maturity before v1.

---

## SEE ALSO

- [Beta Guide](DattoRMM.Core-Beta-Guide.md) — Getting started, usage, and feedback guidance
- [Beta Examples](DattoRMM.Core-Beta-Examples.md) — Detailed worked examples (Azure Automation, CSV exports, type extensions, UDF expansion)
- [about_DattoRMM.Core](../about/about_DattoRMM.Core.md)  
- [about_DattoRMM.CoreThrottling](../about/about_DattoRMM.CoreThrottling.md)  
- [about_DattoRMM.CoreAlertContextDiscovery](../about/about_DattoRMM.CoreAlertContextDiscovery.md)  
- [about_DattoRMM.CoreActivityLogDiscovery](../about/about_DattoRMM.CoreActivityLogDiscovery.md)  
- [about_DattoRMM.CoreConfiguration](../about/about_DattoRMM.CoreConfiguration.md)  
- [about_DattoRMM.CoreExport](../about/about_DattoRMM.CoreExport.md)  
- [about_DattoRMM.CoreTypeExtensions](../about/about_DattoRMM.CoreTypeExtensions.md)  
- [about_DattoRMM.CoreFormatExtensions](../about/about_DattoRMM.CoreFormatExtensions.md)
