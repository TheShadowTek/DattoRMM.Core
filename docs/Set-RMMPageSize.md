# Set-RMMPageSize

## SYNOPSIS
Sets the default page size for Datto RMM API queries in the current session.

## SYNTAX

```
Set-RMMPageSize [-PageSize] <Int32> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Sets the number of results returned per page for Datto RMM API queries in the
current session.
The maximum allowed is determined by your Datto RMM account
(typically 250).
If you specify a value above the maximum, it will be capped.
The default page size is loaded from your configuration file if present and
valid, otherwise the account maximum is used at connection time.

## EXAMPLES

EXAMPLE 1
```
Set-RMMPageSize -PageSize 100
```

Sets the page size to 100 for all subsequent API queries in the session (if
allowed by your account).

## PARAMETERS

### -PageSize
The number of results to return per page for API queries.
Must be a positive
integer.
Values above your account's maximum (usually 250) will be capped.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES
The page size setting only affects the current session and is not persisted.
The default and maximum page size is typically 250, but may vary by account.
The value is set at connection time based on your config and account limits.

For large pipelines, using a smaller page size (such as 100) can improve
responsiveness and reduce memory usage, as each page is returned to the pipeline
as soon as it is received.

## RELATED LINKS

[Get-RMMPageSize](https://github.com/boabf/Datto-RMM/blob/main/docs/Get-RMMPageSize.md)


