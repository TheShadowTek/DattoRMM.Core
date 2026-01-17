function Get-ConfigFilePath {
    <#
    .SYNOPSIS
        Returns the path to the DattoRMM.Core configuration file.
    #>
    [CmdletBinding()]
    param()

    $ConfigDir = Join-Path $HOME '.DattoRMM.Core'
    $ConfigFile = Join-Path $ConfigDir 'config.json'

    return $ConfigFile
    
}
