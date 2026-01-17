# DattoRMM.Core.psm1
# Main module file for Datto RMM API v2 PowerShell module

# Initialize script-scoped auth object
$Script:RMMAuth = $null

# Default configuration values (fallback if config file doesn't exist or fails to load)
$Script:ConfigDefaultPlatform = $null
$Script:ConfigDefaultPageSize = $null
$Script:TokenExpireHours = 100

# Throttle defaults
$Script:ThrottleAggressionDefaults = @{
    'Cautious'   = @{
        DelayMultiplier = 1000
        LowUtilCheckInterval = 25
        ThrottleUtilisationThreshold = 0.25
    }
    'Medium'     = @{
        DelayMultiplier = 750
        LowUtilCheckInterval = 25
        ThrottleUtilisationThreshold = 0.5
    }
    'Aggressive' = @{
        DelayMultiplier = 500
        LowUtilCheckInterval = 50
        ThrottleUtilisationThreshold = 0.75
    }
    'Default'    = @{
        DelayMultiplier = 750
        LowUtilCheckInterval = 25
        ThrottleUtilisationThreshold = 0.5
    }
}

# Throttling state
$Script:RMMThrottle = @{
    CheckInterval = 1           # How often to check rate limits (in seconds) - force initial check
    CheckCount = 1              # Number of checks since last update - force initial delay
    Utilisation = 0             # Current rate limit utilisation (0 to 1) - force initial update
    LowUtilCheckInterval = 25   # How often to check rate when utilisation is low (<=50%)
    DelayMultiplier = 750       # Multiplier for calculating delay when throttling
    DelayMS = 0                 # Current delay in milliseconds
    Pause = $false              # Whether to pause requests entirely
    Throttle = $false           # Whether to throttle requests
}

# Dot-source classes in Private/Classes folder - dependency order
. $PSScriptRoot\Private\Classes\DRMMEnums.ps1
. $PSScriptRoot\Private\Classes\DRMMAccount.ps1
. $PSScriptRoot\Private\Classes\DRMMActivityLog.ps1
. $PSScriptRoot\Private\Classes\DRMMAlert.ps1
. $PSScriptRoot\Private\Classes\DRMMComponent.ps1
. $PSScriptRoot\Private\Classes\DRMMNetworkInterface.ps1
. $PSScriptRoot\Private\Classes\DRMMDeviceAudit.ps1
. $PSScriptRoot\Private\Classes\DRMMEsxiHostAudit.ps1
. $PSScriptRoot\Private\Classes\DRMMPrinterAudit.ps1
. $PSScriptRoot\Private\Classes\DRMMJob.ps1
. $PSScriptRoot\Private\Classes\DRMMDevice.ps1
. $PSScriptRoot\Private\Classes\DRMMVariable.ps1
. $PSScriptRoot\Private\Classes\DRMMFilter.ps1
. $PSScriptRoot\Private\Classes\DRMMSite.ps1
. $PSScriptRoot\Private\Classes\DRMMNetMapping.ps1
. $PSScriptRoot\Private\Classes\DRMMStatus.ps1
. $PSScriptRoot\Private\Classes\DRMMUser.ps1

# Dot-source remaining .ps1 files in Private folder
Get-ChildItem -Path $PSScriptRoot\Private -Filter *.ps1 | ForEach-Object {

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

        if ($LoadedConfig.PSObject.Properties.Name -contains 'ThrottleAggressiveness') {

            $Aggresiveness = $LoadedConfig.ThrottleAggressiveness
            Write-Verbose "  ThrottleAggressiveness: $($Aggresiveness)"

            $DelayMultiplier = $Script:ThrottleAggressionDefaults[$Aggresiveness].DelayMultiplier
            $LowUtilCheckInterval = $Script:ThrottleAggressionDefaults[$Aggresiveness].LowUtilCheckInterval
                
        }

        $Script:ConfigLowUtilCheckInterval = $LowUtilCheckInterval
        $Script:RMMThrottle.LowUtilCheckInterval = $LowUtilCheckInterval
        Write-Verbose "  LowUtilCheckInterval: $($Script:RMMThrottle.LowUtilCheckInterval)"

        $Script:ConfigDelayMultiplier = $DelayMultiplier
        $Script:RMMThrottle.DelayMultiplier = $DelayMultiplier
        Write-Verbose "  DelayMultiplier: $($Script:RMMThrottle.DelayMultiplier)"

    }

    if ($LoadedConfig.PSObject.Properties.Name -contains 'TokenExpireHours') {
        
        $Script:TokenExpireHours = $LoadedConfig.TokenExpireHours
        Write-Verbose "  TokenExpireHours: $($Script:TokenExpireHours)"

    }

} catch {

    Write-Verbose "Configuration file not loaded: $_"

}

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