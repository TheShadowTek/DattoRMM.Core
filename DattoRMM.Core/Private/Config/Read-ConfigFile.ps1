<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Read-ConfigFile {
    <#
    .SYNOPSIS
        Reads the DattoRMM.Core configuration file.
    #>
    [CmdletBinding()]
    param()

    try {
        $ConfigPath = $Script:ConfigPath

        if (Test-Path $ConfigPath) {

            $ConfigContent = Get-Content -Path $ConfigPath -Raw -ErrorAction Stop
            $Config = $ConfigContent | ConvertFrom-Json -AsHashtable -ErrorAction Stop
            return $Config
            
        }

        return $null

    } catch {

        Write-Warning "Failed to read configuration file: $_"
        return $null

    }
}

