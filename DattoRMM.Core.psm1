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
    'Cautious' = @{
        DelayMultiplier = 1000
        LowUtilCheckInterval = 25
        ThrottleUtilisationThreshold = 0.25
        ThrottleOverhead = 0.1
    }
    'Medium' = @{
        DelayMultiplier = 750
        LowUtilCheckInterval = 25
        ThrottleUtilisationThreshold = 0.5
        ThrottleOverhead = 0.05
    }
    'Custom' = @{
        DelayMultiplier = 750
        LowUtilCheckInterval = 25
        ThrottleUtilisationThreshold = 0.5
        ThrottleOverhead = 0.05
    }
    'Aggressive' = @{
        DelayMultiplier = 500
        LowUtilCheckInterval = 50
        ThrottleUtilisationThreshold = 0.75
        ThrottleOverhead = 0.04
    }
    'Default' = @{
        DelayMultiplier = 750
        LowUtilCheckInterval = 25
        ThrottleUtilisationThreshold = 0.5
        ThrottleOverhead = 0.05
    }
}

# Initialize throttle state variable, and set safe defaults
$Script:RMMThrottle = @{
    CheckInterval = 1                   # Force intilisation of throttle state
    CheckCount = 1                      # Number of checks since last update - force initial delay
    Utilisation = 0                     # Current rate limit utilisation (0 to 1) - force initial update
    LowUtilCheckInterval = 25           # Utilisation limit before delaying requests - throttling activation threshold
    DelayMultiplier = 750               # Multiplier for calculating delay when throttling
    DelayMS = 0                         # Current delay in milliseconds
    Pause = $false                      # Whether to pause requests entirely
    Throttle = $false                   # Whether to throttle requests
    ThrottleOverhead = 0.05             # Fraction of rate limit to reserve as safety margin (default 5%)
    ThrottleUtilisationThreshold = 0.5  # Utilisation threshold to start throttling
}

# Dot-source classes in Private/Classes folder - dependency order
Write-Debug "Loading DattoRMM.Core classes..."
Write-Debug "  Loading DRMMEnums..."
. $PSScriptRoot\Private\Classes\DRMMEnums.ps1
Write-Debug "  Loading DRMMAccount..."
. $PSScriptRoot\Private\Classes\DRMMAccount.ps1
Write-Debug "  Loading DRMMActivityLog..."
. $PSScriptRoot\Private\Classes\DRMMActivityLog.ps1
Write-Debug "  Loading DRMMAlert..."
. $PSScriptRoot\Private\Classes\DRMMAlert.ps1
Write-Debug "  Loading DRMMComponent..."
. $PSScriptRoot\Private\Classes\DRMMComponent.ps1
Write-Debug "  Loading DRMMNetworkInterface..."
. $PSScriptRoot\Private\Classes\DRMMNetworkInterface.ps1
Write-Debug "  Loading DRMMDeviceAudit..."
. $PSScriptRoot\Private\Classes\DRMMDeviceAudit.ps1
Write-Debug "  Loading DRMMEsxiHostAudit..."
. $PSScriptRoot\Private\Classes\DRMMEsxiHostAudit.ps1
Write-Debug "  Loading DRMMPrinterAudit..."
. $PSScriptRoot\Private\Classes\DRMMPrinterAudit.ps1
Write-Debug "  Loading DRMMJob..."
. $PSScriptRoot\Private\Classes\DRMMJob.ps1
Write-Debug "  Loading DRMMDevice..."
. $PSScriptRoot\Private\Classes\DRMMDevice.ps1
Write-Debug "  Loading DRMMVariable..."
. $PSScriptRoot\Private\Classes\DRMMVariable.ps1
Write-Debug "  Loading DRMMFilter..."
. $PSScriptRoot\Private\Classes\DRMMFilter.ps1
Write-Debug "  Loading DRMMSite..."
. $PSScriptRoot\Private\Classes\DRMMSite.ps1
Write-Debug "  Loading DRMMNetMapping..."
. $PSScriptRoot\Private\Classes\DRMMNetMapping.ps1
Write-Debug "  Loading DRMMStatus..."
. $PSScriptRoot\Private\Classes\DRMMStatus.ps1
Write-Debug "  Loading DRMMUser..."
. $PSScriptRoot\Private\Classes\DRMMUser.ps1

# Dot-source remaining .ps1 files in Private folder
Get-ChildItem -Path $PSScriptRoot\Private -Filter *.ps1 | Where-Object {$_.BaseName -ne 'howtothrottle'} | ForEach-Object {

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

    Write-Debug "Attempting to load configuration file..."
    $LoadedConfig = Read-ConfigFile

    if ($null -ne $LoadedConfig) {

        Write-Debug "Loading configuration from file..."

        if ($LoadedConfig.PSObject.Properties.Name -contains 'DefaultPlatform') {

            $Script:ConfigDefaultPlatform = $LoadedConfig.DefaultPlatform
            Write-Debug "  DefaultPlatform: $($Script:ConfigDefaultPlatform)"

        }

        if ($LoadedConfig.PSObject.Properties.Name -contains 'DefaultPageSize') {

            $Script:ConfigDefaultPageSize = $LoadedConfig.DefaultPageSize
            Write-Debug "  DefaultPageSize: $($Script:ConfigDefaultPageSize)"

        }

        if ($LoadedConfig.PSObject.Properties.Name -contains 'ThrottleAggressiveness') {

            if ($LoadedConfig.ThrottleAggressiveness -eq 'Custom') {

                $Aggresiveness = $LoadedConfig.ThrottleAggressiveness
                $Script:RMMThrottle.LowUtilCheckInterval = $Script:ThrottleAggressionDefaults[$Aggresiveness].DelayMultiplier
                $Script:RMMThrottle.DelayMultiplier = $Script:ThrottleAggressionDefaults[$Aggresiveness].LowUtilCheckInterval
                $Script:RMMThrottle.ThrottleOverhead = $Script:ThrottleAggressionDefaults[$Aggresiveness].ThrottleOverhead
                Write-Debug "  ThrottleAggressiveness: $($Aggresiveness)"
                Write-Debug "  LowUtilCheckInterval: $($Script:RMMThrottle.LowUtilCheckInterval)"
                Write-Debug "  DelayMultiplier: $($Script:RMMThrottle.DelayMultiplier)"
                Write-Debug "  ThrottleOverhead: $($Script:RMMThrottle.ThrottleOverhead)"

                # Load cusotm throttle values if present
                switch ($LoadedConfig.PSObject.Properties.Name) {

                    'DelayMultiplier' {
                        $Script:RMMThrottle.DelayMultiplier = $LoadedConfig.DelayMultiplier
                        Write-Debug "  CUSTOM: DelayMultiplier: $($Script:RMMThrottle.DelayMultiplier)"
                    }

                    'LowUtilCheckInterval' {
                        $Script:RMMThrottle.LowUtilCheckInterval = $LoadedConfig.LowUtilCheckInterval
                        Write-Debug "  CUSTOM: LowUtilCheckInterval: $($Script:RMMThrottle.LowUtilCheckInterval)"
                    }

                    'ThrottleOverhead' {
                        $Script:RMMThrottle.ThrottleOverhead = $LoadedConfig.ThrottleOverhead
                        Write-Debug "  CUSTOM: ThrottleOverhead: $($Script:RMMThrottle.ThrottleOverhead)"
                    }

                    'ThrottleUtilisationThreshold' {
                        $Script:RMMThrottle.ThrottleUtilisationThreshold = $LoadedConfig.ThrottleUtilisationThreshold
                        Write-Debug "  CUSTOM: ThrottleUtilisationThreshold: $($Script:RMMThrottle.ThrottleUtilisationThreshold)"
                    }
                }

            } 
        }

        if ($LoadedConfig.PSObject.Properties.Name -contains 'TokenExpireHours') {
            
            $Script:TokenExpireHours = $LoadedConfig.TokenExpireHours
            Write-Debug "  TokenExpireHours: $($Script:TokenExpireHours)"
    
        }

    } else {

        Write-Debug "No configuration file found; using default settings."

    }

} catch {

    Write-Debug "Configuration file not loaded: $_"

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