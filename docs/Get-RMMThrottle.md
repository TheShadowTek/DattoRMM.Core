# Get-RMMThrottle

## SYNOPSIS
Gets the current and configured throttling settings for Datto-RMM.

## SYNTAX

```
Get-RMMThrottle [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns the current session's ThrottleAggressiveness (Cautious, Medium, Aggressive),
the corresponding DelayMultiplier and LowUtilCheckInterval, and if available,
the persisted configuration values from Get-RMMConfig.

## EXAMPLES

EXAMPLE 1
```
Get-RMMThrottle
```

Returns the current and configured throttling settings.

## PARAMETERS

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

