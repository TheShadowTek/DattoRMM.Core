# Load module tools functions
. "$PSScriptRoot\Functions\Tools.ps1"

# Import Activity Log definitions
$ActivityLogDefinitionsPath = "$PSScriptRoot\data\ActivityLogDefinitions.json"
#$ActivityLogDefinitions = Get-Content $ActivityLogDefinitionsPath -Raw | ConvertFrom-Json -AsHashtable
$ActivityLogDefinitions = Get-Content $ActivityLogDefinitionsPath -Raw | Convert-PSCustomObjectToHash -Recurse

# dot-source all function files
Get-ChildItem -Path "$PSScriptRoot\Functions\*.ps1" | Foreach-Object {. $_.FullName}

# Module variables
$ModuleBase = $PSScriptRoot
$APIUrl = 'https://pinotage-api.centrastage.net'
$API = "$APIUrl/api/v2"
$AccessTokenExpires = $null                     # Set when Connect-RMMService run
$PageMax = 100                                # Maximum number of objects per page, will be defined after successful connection to platform

# API request rate throttling parameters
$CurrentRequestRate = $null                     # Current API request rate
$RequestThrottleWaitSeconds = 10                # Time after throttle pause before request will be attempted again in seconds
$RequestThrottleTimeoutSeconds = 300            # Maximum wait timeout in seconds
$RequestRateReview = 10                         # How many request can be made before request rate is reviewed
$RequestRateCheck = $RequestRateReview + 1      # How many request have been made since last request rate review - set to trigger request rate review on first request
$RequestRatePercent = $null                     # Current request rate percentage - updated when module loads
$RequestRateDelay = 0                           # Current throttle delay between requests (Milliseconds)
$RequestRateThrottling = @(                     # Request rate throttling parameters
    [PSCustomObject][Ordered]@{
        RequestRateMinPercent = 0
        RequestRateMaxPercent = 70
        RequestRateReview = 30
        DelayMilliseconds = 0
    },
    [PSCustomObject][Ordered]@{
        RequestRateMinPercent = 70
        RequestRateMaxPercent = 75
        RequestRateReview = 20
        DelayMilliseconds = 200
    },
    [PSCustomObject][Ordered]@{
        RequestRateMinPercent = 75
        RequestRateMaxPercent = 80
        RequestRateReview = 10
        DelayMilliseconds = 300
    },
    [PSCustomObject][Ordered]@{
        RequestRateMinPercent = 80
        RequestRateMaxPercent = 85
        RequestRateReview = 10
        DelayMilliseconds = 500
    },
    [PSCustomObject][Ordered]@{
        RequestRateMinPercent = 85
        RequestRateMaxPercent = 100
        RequestRateReview = $null
        DelayMilliseconds = 'Pause'
    }
)
