$art = @(
    '             .-------------------------. ',
    '            | .-----------------------. |',
    '            | |      _                | |',
    '            | |     \ \               | |',
    '            | |      \ \              | |',
    '            | |       > >             | |',
    '            | |      / /              | |',
    '            | |     /_/    _______    | |',
    '            | |           |_______|   | |',
    '            | ''-----------------------'' |',
    '             ''-------------------------'' '
)

$post = @'
             HOW TO CUSTOMISE THROTTLING
             ---------------------------

!The following configuration options are intended for advanced users only.  
If you are modifying these values, you should already understand the implications and accept 
full responsibility for any rate-limit or service-impact risks.

 1. Open the DattoRMM.Core module folder on your system: `$HOME/.DattoRMM.Core/config.json
 2. Edit the "ThrottleProfile" setting to one of the following values:
    - "Cautious"   : Minimal API usage, suitable for very low rate limits
    - "Medium"     : Balanced API usage and caution (default)
    - "Aggressive" : Higher API usage, suitable for high rate limits

Alternatively, you can override module throttling profile preset completly.
DO THIS AT YOUR OWN RISK.

Manually set any of the following throttle values in your config JSON to override the module presets:
    - ThrottleProfile               : Set to "Custom" to enable custom values
    - LowUtilCheckInterval          : Number of requests between throttle recalculation when utilisation is low (default 25)
    - DelayMultiplier               : Multiplier for calculating delay when throttling (in ms) - default 750
    - ThrottleCutOffOverhead        : Fraction of rate limit to reserve as safety margin (default 0.05)
    - ThrottleUtilisationThreshold  : Utilisation threshold to start throttling (default 0.5)

 Any of these keys present in your config file will override the corresponding module preset at startup.
 "ThrottleProfile": "Custom" is required for override settings to be applied. Excluded values will use module defaults.

 Example custom config section:
 {
     "ThrottleProfile": "Custom",
     "DelayMultiplier": 600,
     "LowUtilCheckInterval": 30,
     "ThrottleCutOffOverhead": 0.03,
     "ThrottleUtilisationThreshold": 0.6
 }

 Save the file and reload the module for changes to take effect.

 Testing, use this command or similar in one or more concurrent sessions to simulate high API usage:

     1..1000 | % {Get-RMMSite -Debug | Get-RMMAlert -Status All -Debug | Out-Null}

 Throttle debug messages will show current utilisation and delay calculation results.

DEBUG: Throttling:
        Utilisation: 56%
        Throttle Utilisation Threshold: 50%
        Pause Utilisation Threshold: 86%
        Account Cut Off: 90%
        Throttle Cut Off Overhead: 4%
        LowUtilCheckInterval: 50
        Check Interval: 22
        Request Count: 336
        Remaining: 264
        Delay MS: 280
        Pause: False
        
 Enjoy, and try not to get banned.
 TheShadowTek
'@

# Smooth transition from dark green to green
$steps = 10
$sleepMs = [math]::Ceiling(5000 / $steps)
$ansiSteps = @(
    "`e[2;32m",      # dim green
    "`e[38;5;22m",   # dark green
    "`e[38;5;28m",   # medium-dark green
    "`e[38;5;34m",   # medium green
    "`e[38;5;40m",   # medium-bright green
    "`e[38;5;46m",   # bright green
    "`e[38;5;40m",   # medium-bright green
    "`e[38;5;34m",   # medium green
    "`e[38;5;28m",   # medium-dark green
    "`e[38;5;22m"    # dark green
)
for ($i = 0; $i -lt $steps; $i++) {
    Clear-Host
    $ansi = $ansiSteps[$i]
    foreach ($line in $art) {
        Write-Host "$ansi$line`e[0m"
    }
    Start-Sleep -Milliseconds $sleepMs
}

# Print the rest of the message
Write-Host $post -ForegroundColor DarkGreen