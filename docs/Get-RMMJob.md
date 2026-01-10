# Get-RMMJob

## SYNOPSIS
Retrieves job information from the Datto RMM API.

## SYNTAX

JobByUid (Default)
```
Get-RMMJob -JobUid <Guid> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

JobComponents
```
Get-RMMJob -JobUid <Guid> [-Components] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

JobStdErr
```
Get-RMMJob -JobUid <Guid> -DeviceUid <Guid> [-StdErr] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

JobStdOut
```
Get-RMMJob -JobUid <Guid> -DeviceUid <Guid> [-StdOut] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

JobResults
```
Get-RMMJob -JobUid <Guid> -DeviceUid <Guid> [-Results] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMJob function retrieves information about jobs (component executions) in the
Datto RMM system.
It supports multiple query modes:

- Job details by JobUid
- Job results for a specific device
- Job stdout (standard output) for a specific device
- Job stderr (error output) for a specific device
- Components associated with a job

Jobs in Datto RMM represent executions of components (scripts/monitors) and can be
queried to get execution status, results, and output logs.

## EXAMPLES

EXAMPLE 1
```
Get-RMMJob -JobUid "12067610-8504-48e3-b5de-60e48416aaad"
```

Retrieves basic information about a specific job.

EXAMPLE 2
```
Get-RMMJob -JobUid $JobUid -DeviceUid $DeviceUid -Results
```

Retrieves the execution results for a job on a specific device.

EXAMPLE 3
```
Get-RMMJob -JobUid $JobUid -DeviceUid $DeviceUid -StdOut
```

Retrieves the standard output from a job execution on a specific device.

EXAMPLE 4
```
Get-RMMJob -JobUid $JobUid -DeviceUid $DeviceUid -StdErr
```

Retrieves the error output from a job execution on a specific device.

EXAMPLE 5
```
Get-RMMJob -JobUid $JobUid -Components
```

Retrieves all components that are part of the specified job.

EXAMPLE 6
```
$Job = Get-RMMJob -JobUid $JobUid
if ($Job.Status -eq "Failed") {
    Get-RMMJob -JobUid $JobUid -DeviceUid $Job.DeviceUid -StdErr
}
```

Retrieves job details and checks for errors if the job failed.

EXAMPLE 7
```
$JobUid = "12067610-8504-48e3-b5de-60e48416aaad"
Get-RMMDevice -FilterId 100 | Get-RMMJob -JobUid $JobUid -StdOut | ConvertFrom-Csv
```

Gets devices from filter 100, retrieves the stdout from a specific job execution on each device,
and parses the output as CSV data for further processing.

## PARAMETERS

### -JobUid
The unique identifier (GUID) of the job to retrieve.
Required for all parameter sets.

```yaml
Type: Guid
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -DeviceUid
The unique identifier (GUID) of the device.
Required when retrieving job results,
stdout, or stderr.

```yaml
Type: Guid
Parameter Sets: JobStdErr, JobStdOut, JobResults
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Results
Switch to retrieve job results for a specific device.
Requires both JobUid and DeviceUid.

```yaml
Type: SwitchParameter
Parameter Sets: JobResults
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -StdOut
Switch to retrieve job standard output for a specific device.
Requires both JobUid
and DeviceUid.

```yaml
Type: SwitchParameter
Parameter Sets: JobStdOut
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -StdErr
Switch to retrieve job error output for a specific device.
Requires both JobUid
and DeviceUid.

```yaml
Type: SwitchParameter
Parameter Sets: JobStdErr
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Components
Switch to retrieve all components associated with a job.
Requires JobUid.

```yaml
Type: SwitchParameter
Parameter Sets: JobComponents
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

System.Guid. You can pipe JobUid and DeviceUid from other functions.
## OUTPUTS

DRMMJob. Returns job objects with status, timestamps, and execution details.
DRMMJobResults. Returns job result objects when using -Results.
DRMMJobStdData. Returns standard output/error lines when using -StdOut or -StdErr.
DRMMJobComponent. Returns component objects when using -Components.
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

Job output (stdout/stderr) is typically used for troubleshooting component execution issues.

## RELATED LINKS

[about_DRMMJob]()

[New-RMMQuickJob]()

[Get-RMMComponent]()

[about_DRMMJob]()

[New-RMMQuickJob]()

[Get-RMMComponent]()

