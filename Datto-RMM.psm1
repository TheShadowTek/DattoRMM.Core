# Datto-RMM.psm1
# Main module file for Datto RMM API v2 PowerShell module

# Initialize script-scoped auth object
$Script:RMMAuth = $null

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

# Token refresh interval (hours)
$Script:TokenExpireHours = 100

# Dot-source all .ps1 files in Private folder
Get-ChildItem -Path $PSScriptRoot\Private -Filter *.ps1 -Recurse | ForEach-Object {

    . $_.FullName

}

# Dot-source all .ps1 files in Public folder (if exists)
if (Test-Path $PSScriptRoot\Public) {
    Get-ChildItem -Path $PSScriptRoot\Public -Filter *.ps1 -Recurse | ForEach-Object {

        . $_.FullName

    }
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