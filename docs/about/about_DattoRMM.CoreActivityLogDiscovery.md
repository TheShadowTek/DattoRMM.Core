# about_DattoRMM.CoreActivityLogDiscovery

## SHORT DESCRIPTION

Describes the activity log details type system, the default generic behaviour and the experimental typed dispatch, and provides a guide for beta testers to collect and report anonymised schema data for undocumented detail combinations.

## LONG DESCRIPTION

Each activity log entry returned by `Get-RMMActivityLog` includes a `Details` property containing structured information about the specific action recorded. The shape of this data varies by entity type (`Device`, `User`), category (`job` and others), and action (`deployment`, `create`, and others) — forming a three-level polymorphic structure identified by the combination of those three fields rather than a single discriminator property.

The Datto RMM API does not document the structure of activity log details. The complete set of entity/category/action combinations, and what properties each carries, is unknown. Coverage in the module is based entirely on observed data from testing. The scope is open-ended — Datto can introduce new combinations at any time through new job actions, monitor types, or UI features — and is unlikely to be complete unless the API is formally documented.

### Default Behaviour: All Details Are Generic

`Get-RMMActivityLog` returns `DRMMActivityLogDetailsGeneric` for all `Details` objects by default. This class captures every property returned by the API as a dynamic member on the object. No data is lost, but there are no named typed properties, and no class-level dispatch by entity or category.

This is a deliberate difference from `Get-RMMAlert`, which always returns a typed alert context object — including `DRMMAlertContextGeneric` as the fallback — regardless of any switch. Activity log typed dispatch is experimental and requires explicit opt-in:

```powershell
# Default: all Details objects are DRMMActivityLogDetailsGeneric
Get-RMMActivityLog

# Experimental typed dispatch based on Entity / Category / Action
Get-RMMActivityLog -UseExperimentalDetailClasses
```

Without `-UseExperimentalDetailClasses`, every `Details` object is `DRMMActivityLogDetailsGeneric` regardless of entity, category, or action.

### The Three-Level Dispatch Hierarchy

When `-UseExperimentalDetailClasses` is used, the module attempts to dispatch details through three levels. Each level has a typed fallback for combinations not yet mapped:

| Level | Discriminator Field | Example Values |
|---|---|---|
| 1 — Entity | `Entity` | `Device`, `User` |
| 2 — Category | `EventCategory` | `job` |
| 3 — Action | `EventAction` | `deployment`, `create` |

| Class | Role | Instantiated when |
|---|---|---|
| `DRMMActivityLogDetailsGeneric` | Catch-all | `-UseExperimentalDetailClasses` not used; or entity not recognised |
| `DRMMActivityLogEntityDevice` | Entity base | Entity is `Device` — base class only, not directly instantiated |
| `DRMMActivityLogDetailsDeviceGeneric` | Category fallback | Entity is `Device`; category not yet mapped |
| `DRMMActivityLogDetailsDeviceJob` | Category base | Entity is `Device`, category is `job` — base class only, not directly instantiated |
| `DRMMActivityLogDetailsDeviceJobGeneric` | Action fallback | Entity is `Device`, category is `job`; action not yet mapped |
| `DRMMActivityLogDetailsDeviceRemote` | Category base | Entity is `Device`, category is `remote` — base class only, not directly instantiated |
| `DRMMActivityLogDetailsDeviceRemoteGeneric` | Action fallback | Entity is `Device`, category is `remote`; action not yet mapped |
| `DRMMActivityLogDetailsDeviceDevice` | Category base | Entity is `Device`, category is `device` — base class only, not directly instantiated |
| `DRMMActivityLogDetailsDeviceDeviceGeneric` | Action fallback | Entity is `Device`, category is `device`; action not yet mapped |
| `DRMMActivityLogEntityUser` | Entity base | Entity is `User` — base class only, not directly instantiated |
| `DRMMActivityLogDetailsUserGeneric` | User fallback | Entity is `User`; any category/action |

### Currently Mapped Combinations

The following Entity/Category/Action combinations have dedicated typed classes:

| Entity | Category | Action | Class |
|---|---|---|---|
| `Device` | `job` | `deployment` | `DRMMActivityLogDetailsDeviceJobDeployment` |
| `Device` | `job` | `create` | `DRMMActivityLogDetailsDeviceJobCreate` |
| `Device` | `remote` | `chat` | `DRMMActivityLogDetailsDeviceRemoteChat` |
| `Device` | `remote` | `jrto` | `DRMMActivityLogDetailsDeviceRemoteJrto` |
| `Device` | `device` | `move.device` | `DRMMActivityLogDetailsDeviceDeviceMoveDevice` |

All other combinations fall back to the appropriate generic class in the hierarchy. This list will grow as anonymised schema data is contributed by testers.

### How This Differs from Alert Context Discovery

| | Alert Context | Activity Log Details |
|---|---|---|
| **Always typed** | Yes — `Get-RMMAlert` always dispatches, `DRMMAlertContextGeneric` as fallback | No — `DRMMActivityLogDetailsGeneric` for everything unless `-UseExperimentalDetailClasses` is used |
| **API documentation** | Partially documented (27 types in spec) | Not documented |
| **Discriminator** | Single `@class` property | Three-field combination: Entity + Category + Action |
| **Generic property access** | `.Properties` hashtable on `DRMMAlertContextGeneric` | Dynamic members on the object; enumerate via `PSObject.Properties` |
| **Coverage likelihood** | Approachable — bounded by the API spec | Open-ended — may never be complete |

> [!NOTE]
> No typed classes for `User` entity categories have been built yet — all user activity falls back to `DRMMActivityLogDetailsUserGeneric`. If you have user activities in your environment, the schema collection scripts will capture them. User category data is particularly useful as there are many observed category/action combinations with common shared properties that could support a structured class hierarchy.

### Accessing Dynamic Properties

For any generic details object, dynamic properties are attached directly to the object instance. Use `PSObject.Properties` to enumerate them:

```powershell
$Logs = Get-RMMActivityLog -UseExperimentalDetailClasses -Force

# Enumerate all properties on a generic details object
$Logs[0].Details.PSObject.Properties | Select-Object Name, Value

# Access a specific dynamic property by name
$Logs[0].Details.JobName
```

For objects that inherit from `DRMMActivityLogEntityDevice` or `DRMMActivityLogDetailsDeviceJob`, the inherited typed properties (`Entity`, `EventCategory`, `EventAction`, `DeviceHostname`, `DeviceUid`, `Uid`, and job-specific fields) are always accessible directly. Dynamic properties for unmapped fields are in addition to those.

---

## BETA DATA COLLECTION GUIDE

Activity log details are entirely undocumented. Schema data from real environments is the only way to build dedicated typed classes. The goal is to collect Entity, Category, Action, property names, and property types for each combination — **without collecting any values, hostnames, identifiers, site names, or any other environment-specific data**.

### Prerequisites

All collection scripts require `-UseExperimentalDetailClasses`. Without it, every entry is `DRMMActivityLogDetailsGeneric` and entity/category/action classification is lost, making it impossible to distinguish which combination produced which properties.

### Quick Discovery: List All Generic Detail Combinations

Lists every unmapped Entity/Category/Action combination in the last 24 hours across all sites:

```powershell
$GenericClasses = @(
    'DRMMActivityLogDetailsGeneric',
    'DRMMActivityLogDetailsDeviceGeneric',
    'DRMMActivityLogDetailsDeviceJobGeneric',
    'DRMMActivityLogDetailsDeviceRemoteGeneric',
    'DRMMActivityLogDetailsDeviceDeviceGeneric',
    'DRMMActivityLogDetailsUserGeneric'
)

Get-RMMActivityLog -UseExperimentalDetailClasses -Force |
    Where-Object {$_.Details.GetType().Name -in $GenericClasses} |
    Select-Object @{n='DetailsClass';e={$_.Details.GetType().Name}},
                  @{n='Entity';e={$_.Details.Entity}},
                  @{n='Category';e={$_.Details.EventCategory}},
                  @{n='Action';e={$_.Details.EventAction}} |
    Sort-Object DetailsClass, Entity, Category, Action -Unique |
    Format-Table -AutoSize
```

To extend the window:

```powershell
Get-RMMActivityLog -UseExperimentalDetailClasses -Force `
    -Start (Get-Date).AddDays(-7) -End (Get-Date) | ...
```

### Detailed Collection: Capture Schema Information

Collects the Entity/Category/Action combination, the generic class name, property names, and property types for each unique combination. No values are included — only structural information:

```powershell
$GenericClasses = @(
    'DRMMActivityLogDetailsGeneric',
    'DRMMActivityLogDetailsDeviceGeneric',
    'DRMMActivityLogDetailsDeviceJobGeneric',
    'DRMMActivityLogDetailsDeviceRemoteGeneric',
    'DRMMActivityLogDetailsDeviceDeviceGeneric',
    'DRMMActivityLogDetailsUserGeneric'
)

$Logs = Get-RMMActivityLog -UseExperimentalDetailClasses -Force `
    -Start (Get-Date).AddDays(-7) -End (Get-Date)

$SchemaReport = $Logs |
    Where-Object {$_.Details.GetType().Name -in $GenericClasses} |
    Group-Object {
        "$($_.Details.GetType().Name)|$($_.Details.Entity)|$($_.Details.EventCategory)|$($_.Details.EventAction)"
    } |
    ForEach-Object {

        $Sample = $_.Group[0].Details

        $Props = $Sample.PSObject.Properties |
            ForEach-Object {
                $TypeName = if ($null -ne $_.Value) {$_.Value.GetType().Name} else {'<null>'}
                "$($_.Name) [$TypeName]"
            } |
            Join-String -Separator '; '

        [pscustomobject]@{
            DetailsClass = $Sample.GetType().Name
            Entity       = $Sample.Entity
            Category     = $Sample.EventCategory
            Action       = $Sample.EventAction
            Count        = $_.Count
            Properties   = $Props
        }

    }

$SchemaReport | Format-Table -AutoSize -Wrap
```

### Export for Reporting

```powershell
$SchemaReport | Export-Csv -Path 'ActivityLogDetailsSchemaReport.csv' -NoTypeInformation
```

Or copy to clipboard:

```powershell
$SchemaReport | ConvertTo-Csv -NoTypeInformation | Set-Clipboard
```

### Count Entries Per Unmapped Combination

Helps prioritise which combinations to implement first:

```powershell
$Logs |
    Where-Object {$_.Details.GetType().Name -in $GenericClasses} |
    Group-Object {
        "$($_.Details.Entity) / $($_.Details.EventCategory) / $($_.Details.EventAction)"
    } |
    Select-Object Count, Name |
    Sort-Object Count -Descending
```

### All-Sites Extended Window

For broader coverage in large environments:

```powershell
$GenericClasses = @(
    'DRMMActivityLogDetailsGeneric',
    'DRMMActivityLogDetailsDeviceGeneric',
    'DRMMActivityLogDetailsDeviceJobGeneric',
    'DRMMActivityLogDetailsDeviceRemoteGeneric',
    'DRMMActivityLogDetailsDeviceDeviceGeneric',
    'DRMMActivityLogDetailsUserGeneric'
)

Get-RMMSite | Get-RMMActivityLog -UseExperimentalDetailClasses -Force `
    -Start (Get-Date).AddDays(-30) -End (Get-Date) |
    Where-Object {$_.Details.GetType().Name -in $GenericClasses} |
    Group-Object {
        "$($_.Details.GetType().Name)|$($_.Details.Entity)|$($_.Details.EventCategory)|$($_.Details.EventAction)"
    } |
    Select-Object Count, Name |
    Sort-Object Count -Descending
```

### What to Report

When reporting undocumented combinations, please include:

1. **The CSV or table output** from the schema collection script — Entity, Category, Action, and property names/types.
2. **Count per combination** — helps prioritise which classes to implement first.
3. **Any `User` entity activity** — none has been observed in testing; a single example would be valuable.
4. **Property types for nullable or complex fields** — a single sample may show `<null>` for optional fields; multiple samples help identify the true type.
5. **Any combination where `DRMMActivityLogDetailsGeneric` is returned** (rather than a deeper generic) — this indicates an unrecognised entity and is the most fundamental gap.

Submit reports via [GitHub Issues](https://github.com/TheShadowTek/DattoRMM.Core/issues).

---

## SEE ALSO

- [about_DattoRMM.CoreAlertContextDiscovery](about_DattoRMM.CoreAlertContextDiscovery.md) — Equivalent guide for alert context schema discovery
- [Get-RMMActivityLog](../commands/ActivityLog/Get-RMMActivityLog.md) — Command reference including `-UseExperimentalDetailClasses`
- [Beta Overview](../beta/about_DattoRMM.CoreBeta.md) — Activity log schema coverage is listed as an active refinement area
