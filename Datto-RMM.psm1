# Datto-RMM.psm1
# Main module file for Datto RMM API v2 PowerShell module

# Default API base URL
$script:APIUrl = 'https://pinotage-api.centrastage.net'
$script:API = "$APIUrl/api/v2"


# Initialize script-scoped auth object
$script:RMMAuth = $null

# Throttling state
$script:RMMThrottle = @{
    Limit = 100
    Remaining = 100
    Reset = (Get-Date).AddMinutes(1)
    LastRequest = $null
    RequestCount = 0
    CheckInterval = 10
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