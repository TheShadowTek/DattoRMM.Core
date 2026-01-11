# Get-RMMPageSize

## SYNOPSIS
Gets the current and maximum page size for Datto RMM API queries in the
current session.

## SYNTAX

```
Get-RMMPageSize [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns the current page size used for Datto RMM API queries in this session,
as well as the maximum allowed by your Datto RMM account (typically 250).
The page size determines how many results are returned per API request.

## EXAMPLES

EXAMPLE 1
```
Get-RMMPageSize
```

Returns the current and maximum page size for API queries.

## PARAMETERS

## INPUTS

## OUTPUTS

PSCustomObject with CurrentPageSize and MaximumPageSize properties.
## NOTES
The page size can be changed for the current session using Set-RMMPageSize.
For large pipelines, using a smaller page size (such as 100) can improve
responsiveness and reduce memory usage, as each page is returned to the pipeline
as soon as it is received.

## RELATED LINKS

[Set-RMMPageSize
Set-RMMConfig
Get-RMMConfig
Reset-RMMConfig]()


