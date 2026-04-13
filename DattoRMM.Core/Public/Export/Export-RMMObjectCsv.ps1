<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Export-RMMObjectCsv {
    <#
    .SYNOPSIS
        Exports DattoRMM.Core objects to a flattened CSV file using named transforms.

    .DESCRIPTION
        The Export-RMMObjectCsv function accepts DattoRMM.Core objects via pipeline (or -InputObject),
        detects the object type automatically, applies a named transform to flatten nested properties,
        and writes each row directly to a CSV file for low memory usage.

        Built-in transforms are provided for DRMMSite, DRMMDevice, and DRMMAlert. Each type includes a
        'Default' and 'Summary' transform. The -TransformName parameter supports tab completion and
        defaults to 'Default' if not specified.

        Users can define custom transforms for any DattoRMM.Core class by creating an
        ExportTransforms.psd1 file in $HOME/.DattoRMM.Core/. Custom transforms are merged with built-in
        transforms at module load. A user entry with the same class and transform name as a built-in
        entry will override the built-in version.

        For DRMMDevice exports, the -IncludeUdf and -Udf parameters control whether user-defined
        fields are appended to the transform output. By default, UDFs are excluded to keep exports
        clean. -IncludeUdf adds all UDF columns (Udf1-Udf300) for consistent schema across appends.
        -Udf accepts a string array to include specific UDFs (e.g. 'Udf1', 'Udf5').

        Objects are written to disk individually in the process block. This streaming approach keeps
        memory usage constant regardless of pipeline size, making it safe for Azure Automation and
        large exports.

    .PARAMETER InputObject
        The DattoRMM.Core object to export. Accepts pipeline input. All objects in a single pipeline
        invocation must be the same type.

    .PARAMETER Path
        The file path for the CSV output. Parent directories must exist.

    .PARAMETER Append
        Appends to an existing CSV file instead of overwriting. The caller is responsible for ensuring
        schema compatibility when appending.

    .PARAMETER IncludeTimestamp
        Adds an 'ExportTimestamp' column with the current UTC date and time to each row.

    .PARAMETER IncludeUdf
        Includes all user-defined fields (Udf1-Udf300) in the export for consistent column schema.
        Only valid for DRMMDevice objects. Ignored for other types.

    .PARAMETER Udf
        Includes specific user-defined fields by name (e.g. 'Udf1', 'Udf5'). Only valid for
        DRMMDevice objects. Ignored for other types.

    .PARAMETER Force
        Overwrites the output file without prompting if it already exists.

    .EXAMPLE
        Get-RMMSite | Export-RMMObjectCsv -Path .\Sites.csv

        Exports all sites using the default transform.

    .EXAMPLE
        Get-RMMDevice | Export-RMMObjectCsv -Path .\Devices.csv -TransformName Summary

        Exports all devices using the Summary transform (fewer columns).

    .EXAMPLE
        Get-RMMAlert -Status All | Export-RMMObjectCsv -Path .\Alerts.csv -IncludeTimestamp

        Exports all alerts with a UTC timestamp column appended to each row.

    .EXAMPLE
        Get-RMMDevice | Export-RMMObjectCsv -Path .\Devices.csv -IncludeUdf

        Exports all devices with all UDF columns (Udf1-Udf300) appended.

    .EXAMPLE
        Get-RMMDevice | Export-RMMObjectCsv -Path .\Devices.csv -Udf 'Udf1', 'Udf5', 'Udf10'

        Exports all devices with specific UDF columns appended.

    .EXAMPLE
        Get-RMMSite | Export-RMMObjectCsv -Path .\Sites.csv -Append

        Appends site data to an existing CSV file.

    .INPUTS
        DRMMObject. Accepts any DattoRMM.Core typed object via pipeline. Built-in transforms are
        provided for DRMMSite, DRMMDevice, and DRMMAlert. Custom transforms can be defined for any class.

    .OUTPUTS
        None. Writes output to the specified CSV file.

    .NOTES
        Custom export transforms can be defined by creating an ExportTransforms.psd1 file in
        $HOME/.DattoRMM.Core/. The file uses the same format as the built-in transforms:

            @{
                'DRMMSite' = @{
                    'MyCustomView' = @(
                        'Name'
                        'Description'
                        @{Name = 'Devices'; Path = 'DevicesStatus.NumberOfDevices'}
                    )
                }
            }

        Simple string entries become direct property names. Hashtable entries with Name and Path
        keys support dot-notation for nested property access. User transforms are loaded at module
        import and merged with built-in transforms. Restart the module to pick up changes.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Export/Export-RMMObjectCsv.md

    .LINK
        Get-RMMSite

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMAlert
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMObject]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter()]
        [switch]
        $Append,

        [Parameter()]
        [switch]
        $IncludeTimestamp,

        [Parameter()]
        [switch]
        $IncludeUdf,

        [Parameter()]
        [string[]]
        $Udf,

        [Parameter()]
        [switch]
        $Force

    )

    dynamicparam {

        $ParamDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        # Build ValidateSet from all loaded transform names across all types
        if ($Script:ExportTransforms -and $Script:ExportTransforms.Count -gt 0) {

            $AllTransformNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

            foreach ($TypeKey in $Script:ExportTransforms.Keys) {

                foreach ($TransformKey in $Script:ExportTransforms[$TypeKey].Keys) {

                    [void]$AllTransformNames.Add($TransformKey)

                }
            }

            if ($AllTransformNames.Count -gt 0) {

                $TransformAttribute = [System.Management.Automation.ParameterAttribute]::new()
                $TransformAttribute.Mandatory = $false

                $ValidateSetAttribute = [System.Management.Automation.ValidateSetAttribute]::new([string[]]$AllTransformNames)

                $AttributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
                $AttributeCollection.Add($TransformAttribute)
                $AttributeCollection.Add($ValidateSetAttribute)

                $TransformParam = [System.Management.Automation.RuntimeDefinedParameter]::new(
                    'TransformName',
                    [string],
                    $AttributeCollection
                )
                $TransformParam.Value = 'Default'

                $ParamDictionary.Add('TransformName', $TransformParam)

            }
        }

        return $ParamDictionary

    }

    begin {

        $Initialized = $false
        $RowCount = 0
        $DetectedTypeName = $null
        $SelectProperties = $null
        $ExportParams = $null

        # Resolve dynamic parameter value
        if ($PSBoundParameters.ContainsKey('TransformName')) {

            $TransformName = $PSBoundParameters['TransformName']

        } else {

            $TransformName = 'Default'

        }

        # Resolve output path early — fail fast on bad paths
        $ResolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

        # Handle file overwrite decision before any pipeline processing
        if (-not $Append) {

            Write-Debug "Output file: $ResolvedPath"

            if ((Test-Path $ResolvedPath) -and -not $Force) {

                if (-not $PSCmdlet.ShouldProcess($ResolvedPath, "Overwrite existing file")) {

                    $Script:ExportCancelled = $true
                    return

                }
            }

            # Clear file so process block can append rows with consistent behaviour
            if (Test-Path $ResolvedPath) {

                Remove-Item -Path $ResolvedPath -Force
                Write-Debug "Cleared existing file: $ResolvedPath"

            }
        }

        $Script:ExportCancelled = $false

    }

    process {

        if ($Script:ExportCancelled) {return}

        $TypeName = $InputObject.GetType().Name

        # First-object initialization: detect type, validate transform, build properties
        if (-not $Initialized) {

            $DetectedTypeName = $TypeName
            Write-Verbose "Detected object type: $DetectedTypeName"

            # Validate transform exists for the detected type
            if (-not $Script:ExportTransforms.ContainsKey($DetectedTypeName)) {

                Write-Error "No export transforms are defined for type '$DetectedTypeName'. Define a custom transform in $HOME/.DattoRMM.Core/ExportTransforms.psd1." -ErrorAction Stop
                return

            }

            $TypeTransforms = $Script:ExportTransforms[$DetectedTypeName]

            if (-not $TypeTransforms.ContainsKey($TransformName)) {

                $AvailableNames = ($TypeTransforms.Keys | Sort-Object) -join ', '
                Write-Error "Transform '$TransformName' is not defined for type '$DetectedTypeName'. Available transforms: $AvailableNames" -ErrorAction Stop
                return

            }

            Write-Verbose "Using transform '$TransformName' for type '$DetectedTypeName'"

            # Convert transform entries to Select-Object properties
            $TransformEntries = $TypeTransforms[$TransformName]
            $SelectProperties = ConvertTo-ExportProperty -TransformEntries $TransformEntries

            # Handle UDF parameters for DRMMDevice
            if ($DetectedTypeName -eq 'DRMMDevice') {

                if ($IncludeUdf) {

                    Write-Verbose "Including all UDF columns (Udf1-Udf$([DRMMDeviceUdfs]::MaxUdfCount))"

                    for ($i = 1; $i -le [DRMMDeviceUdfs]::MaxUdfCount; $i++) {

                        $UdfName = "Udf$i"

                        $SelectProperties += @{
                            Name = $UdfName
                            Expression = [scriptblock]::Create("`$_.Udfs.$UdfName")
                        }
                    }

                } elseif ($Udf) {

                    Write-Verbose "Including specified UDFs: $($Udf -join ', ')"

                    foreach ($UdfName in $Udf) {

                        # Validate UDF name format and range
                        if ($UdfName -notmatch '^Udf(\d{1,3})$') {

                            Write-Warning "Skipping invalid UDF name '$UdfName'. Expected format: Udf1, Udf2, ... Udf$([DRMMDeviceUdfs]::MaxUdfCount)."
                            continue

                        }

                        $UdfNum = [int]$Matches[1]

                        if ($UdfNum -lt 1 -or $UdfNum -gt [DRMMDeviceUdfs]::MaxUdfCount) {

                            Write-Warning "Skipping out-of-range UDF '$UdfName'. Valid range: Udf1-Udf$([DRMMDeviceUdfs]::MaxUdfCount)."
                            continue

                        }

                        $SelectProperties += @{
                            Name = $UdfName
                            Expression = [scriptblock]::Create("`$_.Udfs.$UdfName")
                        }
                    }
                }

            } elseif ($IncludeUdf -or $Udf) {

                Write-Warning "-IncludeUdf and -Udf parameters are only applicable to DRMMDevice objects. Ignoring."

            }

            # Add timestamp column if requested
            if ($IncludeTimestamp) {

                $SelectProperties += @{
                    Name = 'ExportTimestamp'
                    Expression = {(Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss')}
                }

                Write-Verbose "ExportTimestamp column enabled"

            }

            # Build Export-Csv parameters — always append since begin block handles file creation
            $ExportParams = @{
                Path = $ResolvedPath
                NoTypeInformation = $true
                Encoding = 'UTF8'
                Append = $true
            }

            $Initialized = $true

            Write-Verbose "Exporting $DetectedTypeName objects to $ResolvedPath"

        } elseif ($TypeName -ne $DetectedTypeName) {

            Write-Error "Mixed object types are not supported. Expected '$DetectedTypeName' but received '$TypeName'." -ErrorAction Stop
            return

        }

        # Stream each object directly to file
        $InputObject | Select-Object $SelectProperties | Export-Csv @ExportParams

        $RowCount++

    }

    end {

        if ($Script:ExportCancelled) {return}

        if ($RowCount -eq 0) {

            Write-Verbose "No objects received; nothing to export."

        } else {

            Write-Verbose "Export complete: $RowCount rows written to $ResolvedPath"

        }
    }
}
