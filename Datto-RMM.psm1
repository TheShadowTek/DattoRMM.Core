# Datto-RMM.psm1
# Main module file for Datto RMM API v2 PowerShell module

# Initialize script-scoped auth object
$Script:RMMAuth = $null

# Default configuration values (fallback if config file doesn't exist or fails to load)
$Script:ConfigDefaultPlatform = $null
$Script:ConfigDefaultPageSize = $null
$Script:ConfigLowUtilCheckInterval = 50
$Script:TokenExpireHours = 100

# Throttling state
$Script:RMMThrottle = @{
    CheckInterval = 1
    CheckCount = 1
    Utilisation = 0
    LowUtilCheckInterval = 50 # How often to check rate when utilisation is low (<=50%)
    DelayMS = 0
    Pause = $false
    Throttle = $false
}

# Dot-source classes.ps1 first (enums and classes must be loaded before other files)
. $PSScriptRoot\Private\Classes\DRMMEnums.ps1
. $PSScriptRoot\Private\Classes\DRMMObject.ps1
. $PSScriptRoot\Private\Classes\DRMMAccount.ps1
. $PSScriptRoot\Private\Classes\DRMMActivityLog.ps1
. $PSScriptRoot\Private\classes.ps1

# Dot-source remaining .ps1 files in Private folder
Get-ChildItem -Path $PSScriptRoot\Private -Filter *.ps1 -Recurse | 
    Where-Object { $_.Name -ne 'classes.ps1' } |
    ForEach-Object {

        . $_.FullName

    }

# Dot-source all .ps1 files in Public folder (if exists)
if (Test-Path $PSScriptRoot\Public) {
    Get-ChildItem -Path $PSScriptRoot\Public -Filter *.ps1 -Recurse | ForEach-Object {

        . $_.FullName

    }
}

# Load configuration from file if it exists
try {
    $LoadedConfig = Read-ConfigFile

    if ($null -ne $LoadedConfig) {
        Write-Verbose "Loading configuration from file..."

        if ($LoadedConfig.PSObject.Properties.Name -contains 'DefaultPlatform') {
            $Script:ConfigDefaultPlatform = $LoadedConfig.DefaultPlatform
            Write-Verbose "  DefaultPlatform: $($Script:ConfigDefaultPlatform)"
        }

        if ($LoadedConfig.PSObject.Properties.Name -contains 'DefaultPageSize') {
            $Script:ConfigDefaultPageSize = $LoadedConfig.DefaultPageSize
            Write-Verbose "  DefaultPageSize: $($Script:ConfigDefaultPageSize)"
        }

        if ($LoadedConfig.PSObject.Properties.Name -contains 'LowUtilCheckInterval') {
            $Script:ConfigLowUtilCheckInterval = $LoadedConfig.LowUtilCheckInterval
            $Script:RMMThrottle.LowUtilCheckInterval = $LoadedConfig.LowUtilCheckInterval
            Write-Verbose "  LowUtilCheckInterval: $($Script:ConfigLowUtilCheckInterval)"
        }

        if ($LoadedConfig.PSObject.Properties.Name -contains 'TokenExpireHours') {
            $Script:TokenExpireHours = $LoadedConfig.TokenExpireHours
            Write-Verbose "  TokenExpireHours: $($Script:TokenExpireHours)"
        }
    }
} catch {
    Write-Verbose "Configuration file not loaded: $_"
}

# Export functions from Public folder (if any)
# This will be updated as functions are added
# Export-ModuleMember -Function *

# Module removal handler - cleanup module variables
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    # Remove authentication variable
    if ($Script:RMMAuth) {

        Remove-Variable -Name RMMAuth -Scope Script -ErrorAction SilentlyContinue

    }
    
    # Remove throttle state variable
    if ($Script:RMMThrottle) {

        Remove-Variable -Name RMMThrottle -Scope Script -ErrorAction SilentlyContinue

    }
    
    # Remove token expiration variable
    if ($Script:TokenExpireHours) {

        Remove-Variable -Name TokenExpireHours -Scope Script -ErrorAction SilentlyContinue
        
    }
}