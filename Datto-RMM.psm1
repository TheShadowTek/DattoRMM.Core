# Datto-RMM.psm1
# Main module file for Datto RMM API v2 PowerShell module

# Default API base URL
$Script:APIUrl = 'https://pinotage-api.centrastage.net'
$Script:API = "$APIUrl/api/v2"


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