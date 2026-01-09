function Read-ConfigFile {
    <#
    .SYNOPSIS
        Reads the Datto-RMM configuration file.
    #>
    [CmdletBinding()]
    param()

    try {
        $ConfigPath = Get-ConfigFilePath

        if (Test-Path $ConfigPath) {

            $ConfigContent = Get-Content -Path $ConfigPath -Raw -ErrorAction Stop
            $Config = $ConfigContent | ConvertFrom-Json -ErrorAction Stop
            return $Config
            
        }

        return $null

    } catch {

        Write-Warning "Failed to read configuration file: $_"
        return $null

    }
}
