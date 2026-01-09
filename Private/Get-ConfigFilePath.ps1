function Get-ConfigFilePath {
    <#
    .SYNOPSIS
        Returns the path to the Datto-RMM configuration file.
    #>
    [CmdletBinding()]
    param()

    $ConfigDir = Join-Path $HOME '.datto-rmm'
    $ConfigFile = Join-Path $ConfigDir 'config.json'

    return $ConfigFile
    
}
