function Write-ConfigFile {
    <#
    .SYNOPSIS
        Writes the Datto-RMM configuration file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Config
    )

    try {

        $ConfigPath = Get-ConfigFilePath
        $ConfigDir = Split-Path -Path $ConfigPath -Parent

        # Create directory if it doesn't exist
        if (-not (Test-Path $ConfigDir)) {

            New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null
            Write-Verbose "Created configuration directory: $ConfigDir"

        }

        # Convert to JSON and write
        $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Force -ErrorAction Stop
        Write-Verbose "Configuration saved to: $ConfigPath"

        return $true

    } catch {

        Write-Warning "Failed to write configuration file: $_"
        return $false
        
    }
}
