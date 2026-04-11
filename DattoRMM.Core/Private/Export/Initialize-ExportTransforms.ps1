<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Loads built-in and user-defined export transforms into module state.
.DESCRIPTION
    Reads the built-in ExportTransforms.psd1 from Private/Data and optionally merges
    user-defined transforms from $HOME/.DattoRMM.Core/ExportTransforms.psd1.

    User transforms are additive. A user entry with the same class and transform name
    as a built-in entry will override the built-in version.

    The merged result is stored in $Script:ExportTransforms for use by Export-RMMObjectCsv.
#>
function Initialize-ExportTransforms {
    [CmdletBinding()]
    param ()

    # Load built-in transforms
    $BuiltInPath = Join-Path $PSScriptRoot '..\Data\ExportTransforms.psd1'

    if (Test-Path $BuiltInPath) {

        $Script:ExportTransforms = Import-PowerShellDataFile -Path $BuiltInPath
        Write-Debug "Loaded built-in export transforms from $BuiltInPath"

    } else {

        $Script:ExportTransforms = @{}
        Write-Warning "Built-in export transforms file not found at $BuiltInPath"

    }

    # Load user-defined transforms from profile directory
    $UserPath = Join-Path (Join-Path $HOME '.DattoRMM.Core') 'ExportTransforms.psd1'

    if (Test-Path $UserPath) {

        try {

            $UserTransforms = Import-PowerShellDataFile -Path $UserPath
            Write-Verbose "Loading user export transforms from $UserPath"

            foreach ($TypeName in $UserTransforms.Keys) {

                if (-not $Script:ExportTransforms.ContainsKey($TypeName)) {

                    $Script:ExportTransforms[$TypeName] = @{}

                }

                foreach ($TransformName in $UserTransforms[$TypeName].Keys) {

                    $Script:ExportTransforms[$TypeName][$TransformName] = $UserTransforms[$TypeName][$TransformName]
                    Write-Debug "User transform loaded: $TypeName/$TransformName"

                }
            }

        } catch {

            Write-Warning "Failed to load user export transforms from $UserPath`: $($_.Exception.Message)"

        }
    }
}
