# Get-RMMThrottleStatus

## SYNOPSIS
Retrieves a detailed snapshot of the current API rate limits, counts, and local throttle state.

## SYNTAX

```
Get-RMMThrottleStatus [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMThrottleStatus function provides a combined view of the Datto RMM API rate-status
endpoint data and the local sliding-window throttle model.
It calls the rate-status API to
fetch fresh account and write counts, limits, and per-operation bucket status, then merges
this with the local throttle tracking state (timestamps, utilisation, flags, thresholds).

The returned DRMMThrottleStatus object includes:
- Active throttle profile and configured thresholds
- Global account and write utilisation (both API-reported and locally tracked)
- Throttle and pause flags reflecting the current state before drift adjustment
- Current computed delay in milliseconds
- Calibration metadata (last calibration time, sample count)
- A Buckets collection of DRMMThrottleBucket objects covering the account bucket,
  write bucket, and all per-operation write buckets (both mapped and unidentified)

Each bucket reports its Type (Account, Write, or Operation), Name, Limit, ApiCount,
LocalCount, and computed Utilisation ratio.

This function is designed for monitoring, diagnostics, and sample capture during long-running
load tests.
It does not modify any throttle state.
For the raw API response without local
enrichment, use Get-RMMRequestRate instead.

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMThrottleStatus
```

Retrieves the current combined throttle status snapshot.

EXAMPLE 2
```powershell
$Status = Get-RMMThrottleStatus
$Status.GetSummary()
```

Retrieves throttle status and displays a summary of utilisation, flags, and delay.

EXAMPLE 3
```powershell
Get-RMMThrottleStatus | Select-Object -ExpandProperty Buckets | Format-Table
```

Retrieves throttle status and displays all rate-limit buckets in a table.

EXAMPLE 4
```powershell
(Get-RMMThrottleStatus).Buckets | Where-Object Type -eq 'Operation' | Sort-Object Utilisation -Descending
```

Retrieves and filters only per-operation buckets, sorted by utilisation.

EXAMPLE 5
```powershell
$Status = Get-RMMThrottleStatus
$Status.Buckets | Where-Object {$_.Utilisation -gt 0}
```

Shows only buckets with active utilisation for quick load test monitoring.

## PARAMETERS

## INPUTS

None. You cannot pipe objects to Get-RMMThrottleStatus.
## OUTPUTS

DRMMThrottleStatus. Returns a throttle status object with the following properties:
- Profile (string): Active throttle profile name
- AccountUid (string): Account unique identifier from the API
- WindowSizeSeconds (int): Rolling window size in seconds
- AccountUtilisation (double): Global account utilisation ratio (higher of API or local)
- WriteUtilisation (double): Global write utilisation ratio (higher of API or local)
- AccountCutOffRatio (double): API-reported account cut-off ratio
- ThrottleUtilisationThreshold (double): Configured threshold at which throttling activates
- PauseThreshold (double): Computed threshold at which hard pause activates
- Throttle (bool): Whether soft throttling is currently active
- Pause (bool): Whether hard pause is currently active
- DelayMs (double): Current computed delay in milliseconds
- DelayMultiplier (double): Configured global delay multiplier
- WriteDelayMultiplier (double): Configured write delay multiplier
- LastCalibrationUtc (datetime): UTC time of the last calibration
- SamplesAtLastCalibration (int): Local account samples at last calibration
- Buckets (DRMMThrottleBucket[]): Collection of all tracked rate-limit buckets
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

This function calls the rate-status API endpoint to fetch fresh data, which itself
counts as an API request against the account rate limit.

The throttle state reported is a pre-drift-adjustment snapshot.
The actual throttle
engine may adjust utilisation values during calibration cycles.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMThrottleStatus.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMThrottleStatus.md))
- [Get-RMMRequestRate](./Get-RMMRequestRate.md)
- [Connect-DattoRMM](../Auth/Connect-DattoRMM.md)
- [about_DattoRMM.CoreThrottling](../../about/about_DattoRMM.CoreThrottling.md)
- [about_DRMMThrottleStatus](../../about/classes/DRMMThrottleStatus/about_DRMMThrottleStatus.md)
