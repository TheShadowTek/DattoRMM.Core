# Get-RMMJob

## SYNOPSIS
{{ Fill in the Synopsis }}

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
{{ Fill in the Description }}

## EXAMPLES

Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -ActivityLog
{{ Fill ActivityLog Description }}

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

### -JobUid
{{ Fill JobUid Description }}

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

## INPUTS

DRMMActivityLog

## OUTPUTS

System.Object
## NOTES

