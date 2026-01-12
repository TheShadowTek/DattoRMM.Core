# New-RMMQuickJob

## SYNOPSIS
Creates a quick job on a device in Datto RMM.

## SYNTAX

ByDeviceUidWithComponentUid (Default)
```
New-RMMQuickJob -DeviceUid <Guid> -JobName <String> -ComponentUid <Guid> [-Variables <Hashtable>] [-Force]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

ByDeviceObjectWithComponentUid
```
New-RMMQuickJob -Device <DRMMDevice> -JobName <String> -ComponentUid <Guid> [-Variables <Hashtable>] [-Force]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

ByDeviceObjectWithComponent
```
New-RMMQuickJob -Device <DRMMDevice> -JobName <String> -Component <DRMMComponent> [-Variables <Hashtable>]
 [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

ByDeviceUidWithComponent
```
New-RMMQuickJob -DeviceUid <Guid> -JobName <String> -Component <DRMMComponent> [-Variables <Hashtable>]
 [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The New-RMMQuickJob function creates and executes a quick (ad-hoc) job on a specific
device using a component from your account.
Quick jobs are useful for running one-off
scripts or automation tasks on devices without creating a scheduled job.

Component variables can be provided as a hashtable where keys are variable names and
values are the variable values.
Only provide variables that the component requires.

## EXAMPLES

EXAMPLE 1
```
New-RMMQuickJob -DeviceUid $DeviceUid -JobName "Get System Info" -ComponentUid $ComponentUid
```

Creates a quick job on a device using a component that requires no variables.

EXAMPLE 2
```
$Device = Get-RMMDevice -Hostname "SERVER01"
$Component = Get-RMMComponent | Where-Object {$_.Name -eq "Restart Service"}
New-RMMQuickJob -Device $Device -JobName "Restart IIS" -Component $Component -Variables @{serviceName='W3SVC'}
```

Creates a quick job to restart a service, passing the service name as a variable.

EXAMPLE 3
```
Get-RMMDevice -FilterId 100 | New-RMMQuickJob -JobName "Update Windows" -ComponentUid $CompUid -Force
```

Creates quick jobs on all devices in a filter without confirmation.

EXAMPLE 4
```
$Vars = @{
    path = 'C:\Logs'
    days = '30'
    recurse = 'true'
}
New-RMMQuickJob -DeviceUid $DeviceUid -JobName "Clean Old Logs" -ComponentUid $CompUid -Variables $Vars
```

Creates a quick job with multiple variables passed as a hashtable.

EXAMPLE 5
```
$Component = Get-RMMComponent | Where-Object {$_.Name -like "*PowerShell*"} | Select-Object -First 1
$Component.GetInputVariables() | Select-Object Name, Type
Get-RMMDevice -Hostname "WKS*" | New-RMMQuickJob -JobName "Run PowerShell" -Component $Component
```

Gets a component, checks its required input variables, then creates jobs on multiple devices.

## PARAMETERS

### -Device
A DRMMDevice object to run the job on.
Accepts pipeline input from Get-RMMDevice.

```yaml
Type: DRMMDevice
Parameter Sets: ByDeviceObjectWithComponentUid, ByDeviceObjectWithComponent
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -DeviceUid
The unique identifier (GUID) of the device to run the job on.

```yaml
Type: Guid
Parameter Sets: ByDeviceUidWithComponentUid, ByDeviceUidWithComponent
Aliases: Uid

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -JobName
A descriptive name for this job instance.
This helps identify the job in job history.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Component
A DRMMComponent object from Get-RMMComponent.
The job will execute this component.

```yaml
Type: DRMMComponent
Parameter Sets: ByDeviceObjectWithComponent, ByDeviceUidWithComponent
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComponentUid
The unique identifier (GUID) of the component to execute.
Use Get-RMMComponent to find
available components and their UIDs.

```yaml
Type: Guid
Parameter Sets: ByDeviceUidWithComponentUid, ByDeviceObjectWithComponentUid
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Variables
A hashtable of component variables.
Keys are variable names, values are the values to
pass to the component.
Example: @{computerName='SERVER01'; port='3389'}

Only provide variables that the component requires.
Variable names must match the
component's input variable names exactly (case-sensitive).

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Bypasses the confirmation prompt.

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

DRMMDevice. You can pipe device objects from Get-RMMDevice.
You can also pipe objects with DeviceUid or Uid properties.
## OUTPUTS

DRMMJob. Returns the created job object with its status and unique identifier.
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

Best practices:
- Use descriptive job names to identify jobs in history
- Check component input variables with Component.GetInputVariables()
- Test components on a single device before running on multiple devices
- Monitor job status with Get-RMMJob to verify completion
- Use -WhatIf to preview job creation without executing

## RELATED LINKS


[about_DRMMDevice](https://github.com/boabf/Datto-RMM/blob/main/docs/about_DRMMDevice.md)
[Get-RMMDevice](https://github.com/boabf/Datto-RMM/blob/main/docs/Get-RMMDevice.md)
[Get-RMMComponent](https://github.com/boabf/Datto-RMM/blob/main/docs/Get-RMMComponent.md)
[Get-RMMJob](https://github.com/boabf/Datto-RMM/blob/main/docs/Get-RMMJob.md)
[about_DRMMJob](https://github.com/boabf/Datto-RMM/blob/main/docs/about_DRMMJob.md)
[Get-RMMComponent](https://github.com/boabf/Datto-RMM/blob/main/docs/Get-RMMComponent.md)
[about_DRMMComponent](https://github.com/boabf/Datto-RMM/blob/main/docs/about_DRMMComponent.md)

