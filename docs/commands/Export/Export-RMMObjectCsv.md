# Export-RMMObjectCsv

## SYNOPSIS
Exports DattoRMM.Core objects to a flattened CSV file using named transforms.

## SYNTAX

```
Export-RMMObjectCsv [-InputObject] <DRMMObject> [-Path] <String> [-Append] [-IncludeTimestamp] [-IncludeUdf]
 [[-Udf] <String[]>] [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [-TransformName <String>] [<CommonParameters>]
```

## DESCRIPTION
The Export-RMMObjectCsv function accepts DattoRMM.Core objects via pipeline (or -InputObject),
detects the object type automatically, applies a named transform to flatten nested properties,
and writes each row directly to a CSV file for low memory usage.

Built-in transforms are provided for DRMMSite, DRMMDevice, and DRMMAlert.
Each type includes a
'Default' and 'Summary' transform.
The -TransformName parameter supports tab completion and
defaults to 'Default' if not specified.

Users can define custom transforms for any DattoRMM.Core class by creating an
ExportTransforms.psd1 file in $HOME/.DattoRMM.Core/.
Custom transforms are merged with built-in
transforms at module load.
A user entry with the same class and transform name as a built-in
entry will override the built-in version.

For DRMMDevice exports, the -IncludeUdf and -Udf parameters control whether user-defined
fields are appended to the transform output.
By default, UDFs are excluded to keep exports
clean.
-IncludeUdf adds all UDF columns (Udf1-Udf300) for consistent schema across appends.
-Udf accepts a string array to include specific UDFs (e.g.
'Udf1', 'Udf5').

Objects are written to disk individually in the process block.
This streaming approach keeps
memory usage constant regardless of pipeline size, making it safe for Azure Automation and
large exports.

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMSite | Export-RMMObjectCsv -Path .\Sites.csv
```

Exports all sites using the default transform.

EXAMPLE 2
```powershell
Get-RMMDevice | Export-RMMObjectCsv -Path .\Devices.csv -TransformName Summary
```

Exports all devices using the Summary transform (fewer columns).

EXAMPLE 3
```powershell
Get-RMMAlert -Status All | Export-RMMObjectCsv -Path .\Alerts.csv -IncludeTimestamp
```

Exports all alerts with a UTC timestamp column appended to each row.

EXAMPLE 4
```powershell
Get-RMMDevice | Export-RMMObjectCsv -Path .\Devices.csv -IncludeUdf
```

Exports all devices with all UDF columns (Udf1-Udf300) appended.

EXAMPLE 5
```powershell
Get-RMMDevice | Export-RMMObjectCsv -Path .\Devices.csv -Udf 'Udf1', 'Udf5', 'Udf10'
```

Exports all devices with specific UDF columns appended.

EXAMPLE 6
```powershell
Get-RMMSite | Export-RMMObjectCsv -Path .\Sites.csv -Append
```

Appends site data to an existing CSV file.

## PARAMETERS

### -InputObject
The DattoRMM.Core object to export.
Accepts pipeline input.
All objects in a single pipeline
invocation must be the same type.

```yaml
Type: DRMMObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Path
The file path for the CSV output.
Parent directories must exist.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Append
Appends to an existing CSV file instead of overwriting.
The caller is responsible for ensuring
schema compatibility when appending.

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

### -IncludeTimestamp
Adds an 'ExportTimestamp' column with the current UTC date and time to each row.

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

### -IncludeUdf
Includes all user-defined fields (Udf1-Udf300) in the export for consistent column schema.
Only valid for DRMMDevice objects.
Ignored for other types.

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

### -Udf
Includes specific user-defined fields by name (e.g.
'Udf1', 'Udf5').
Only valid for
DRMMDevice objects.
Ignored for other types.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Overwrites the output file without prompting if it already exists.

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

### -TransformName
{{ Fill TransformName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

DRMMObject. Accepts any DattoRMM.Core typed object via pipeline. Built-in transforms are
provided for DRMMSite, DRMMDevice, and DRMMAlert. Custom transforms can be defined for any class.
## OUTPUTS

None. Writes output to the specified CSV file.
## NOTES
Custom export transforms can be defined by creating an ExportTransforms.psd1 file in
$HOME/.DattoRMM.Core/.
The file uses the same format as the built-in transforms:

    @{
        'DRMMSite' = @{
            'MyCustomView' = @(
                'Name'
                'Description'
                @{Name = 'Devices'; Path = 'DevicesStatus.NumberOfDevices'}
            )
        }
    }

Simple string entries become direct property names.
Hashtable entries with Name and Path
keys support dot-notation for nested property access.
User transforms are loaded at module
import and merged with built-in transforms.
Restart the module to pick up changes.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Export/Export-RMMObjectCsv.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Export/Export-RMMObjectCsv.md))
- [Get-RMMSite](../Sites/Get-RMMSite.md)
- [Get-RMMDevice](../Devices/Get-RMMDevice.md)
- [Get-RMMAlert](../Alerts/Get-RMMAlert.md)
- [about_DattoRMM.CoreExport](../../about/about_DattoRMM.CoreExport.md)
