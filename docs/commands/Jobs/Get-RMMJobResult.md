# Get-RMMJobResult

## SYNOPSIS
Retrieves job execution results and output for a specific device from the Datto RMM API.

## SYNTAX

JobUid (Default)
```
Get-RMMJobResult -JobUid <Guid> -DeviceUid <Guid> [-IncludeOutput] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

ActivityLog
```
Get-RMMJobResult -ActivityLog <DRMMActivityLog> [-IncludeOutput] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Retrieves execution results, standard output, and error output for a job on a specific device in the Datto RMM
system.
You can specify JobUid and DeviceUid directly, or pipe ActivityLog objects (from Get-RMMActivityLog)
with Entity: Device, Category: Job, and Action: Deployment.
The -UseExperimentalDetailClasses switch must be
used with Get-RMMActivityLog to provide the required detail type (DRMMActivityLogDetailsDeviceJobDeployment).
Non-deployment activity logs are safely skipped with a warning.

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMJobResult -JobUid $JobUid -DeviceUid $DeviceUid
```

Retrieves the execution results for a job on a specific device.

EXAMPLE 2
```powershell
Get-RMMJobResult -JobUid $JobUid -DeviceUid $DeviceUid -IncludeOutput
```

Retrieves the execution results and includes standard output and error output for the job.

EXAMPLE 3
```powershell
Get-RMMActivityLog -Entity Device -Category Job -Action Deployment -UseExperimentalDetailClasses | Get-RMMJobResult
```

Retrieves job results for all deployment job activity logs for devices.
The -UseExperimentalDetailClasses
switch is required to provide the correct detail type for piping.

## PARAMETERS

### -JobUid
The unique identifier (GUID) of the job.

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

### -DeviceUid
The unique identifier (GUID) of the device associated with the job results.

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
An activity log object (from Get-RMMActivityLog -Entity Device -Category Job -Action Deployment -UseExperimentalDetailClasses)
containing job deployment details.
Can be piped to this function.
Non-deployment
activity logs are skipped with a warning.

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

### -IncludeOutput
Switch to retrieve standard output and error output for the job result, if available.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

System.Guid, DRMMActivityLog. You can pipe ActivityLog objects to this function.
## OUTPUTS

DRMMJobResults. Returns job result objects. If -IncludeOutput is used, includes standard output and error output.
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.
For details on -UseExperimentalDetailClasses, see Get-RMMActivityLog help.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Jobs/Get-RMMJobResult.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Jobs/Get-RMMJobResult.md))
- [about_DRMMJobResult](../../about/about_DRMMJobResult.md)
- [Get-RMMActivityLog](../ActivityLog/Get-RMMActivityLog.md)
