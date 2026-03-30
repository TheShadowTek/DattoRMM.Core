# Get-RMMJob

## SYNOPSIS
Retrieves job information from the Datto RMM API by JobUid or from an ActivityLog object.

## SYNTAX

JobUid (Default)
```
Get-RMMJob -JobUid <Guid> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

ActivityLog
```
Get-RMMJob -ActivityLog <DRMMActivityLog> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves information about jobs (component executions) in the Datto RMM system.
You can specify a JobUid
directly, or pipe ActivityLog objects (from Get-RMMActivityLog) to retrieve job details for each log entry.
When piping ActivityLog objects, the -UseExperimentalDetailClasses switch must be used with Get-RMMActivityLog
to provide the required detail type.
Non-job activity logs are safely skipped with a warning.
This function
supports retrieving jobs for actions such as Deployment (execution), Create (new job), and Generic (unknown action).

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMJob -JobUid "12067610-8504-48e3-b5de-60e48416aaad"
```

Retrieves basic information about a specific job by its unique identifier.

EXAMPLE 2
```powershell
Get-RMMActivityLog -Entity Device -UseExperimentalDetailClasses | Get-RMMJob
```

Retrieves job details for all job-related activity logs for devices.
The -UseExperimentalDetailClasses switch
is required to provide the correct detail type for piping.

EXAMPLE 3
```powershell
Get-RMMActivityLog -Entity Device -Category Job -UseExperimentalDetailClasses | Where-Object { $_.Details.JobName -eq 'Patch Critical Servers' } | Get-RMMJob
```

Retrieves job details for all jobs named 'Patch Critical Servers' from device activity logs.

## PARAMETERS

### -JobUid
The unique identifier (GUID) of the job to retrieve.

```yaml
Type: Guid
Parameter Sets: JobUid
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ActivityLog
An activity log object (from Get-RMMActivityLog -UseExperimentalDetailClasses) containing job details.
Can be
piped to this function.
Non-job activity logs are skipped with a warning.

```yaml
Type: DRMMActivityLog
Parameter Sets: ActivityLog
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

## INPUTS

System.Guid, DRMMActivityLog. You can pipe ActivityLog objects to this function.
## OUTPUTS

DRMMJob. Returns job objects with status, timestamps, and execution details.
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.
For details on -UseExperimentalDetailClasses, see Get-RMMActivityLog help.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Jobs/Get-RMMJob.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Jobs/Get-RMMJob.md))
- [about_DRMMJob](../../about/classes/DRMMJob/about_DRMMJob.md)
- [Get-RMMActivityLog](../ActivityLog/Get-RMMActivityLog.md)
