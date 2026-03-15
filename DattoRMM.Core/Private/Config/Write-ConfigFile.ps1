<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Write-ConfigFile {
    <#
    .SYNOPSIS
        Writes the DattoRMM.Core configuration file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Config
    )

    try {

        $ConfigDir = Split-Path -Path $Script:ConfigPath -Parent

        # Create directory if it doesn't exist
        if (-not (Test-Path $ConfigDir)) {

            New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null
            Write-Verbose "Created configuration directory: $ConfigDir"

        }

        # Convert to JSON and write
        $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $Script:ConfigPath -Force -ErrorAction Stop
        Write-Verbose "Configuration saved to: $Script:ConfigPath"

        return $true

    } catch {

        Write-Warning "Failed to write configuration file: $_"
        return $false
        
    }
}

