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
    - "Cautious"   : Conservative, optimized for 3-5 concurrent sessions
    - "Medium"     : Balanced for 2-3 concurrent sessions (default)
    - "Aggressive" : High-throughput single session

Alternatively, you can override the module throttling profile preset completely.
DO THIS AT YOUR OWN RISK.

Manually set any of the following throttle values in your config JSON to override the module presets:
    - ThrottleProfile                : Set to "Custom" to enable custom values
    - DelayMultiplier                : Multiplier for delay calculation (in ms) - default 750
    - CalibrationBaseSeconds         : Ceiling interval when confidence high and drift low - default 8
    - CalibrationMinSeconds          : Absolute floor to prevent API spam - default 0.5
    - CalibrationConfidenceCount     : Samples required for full confidence - default 50
    - DriftThresholdPercent          : Drift gap triggering accelerated calibration - default 0.02 (2%)
    - DriftScalingFactor             : How aggressively interval shrinks with drift - default 2
    - ThrottleUtilisationThreshold   : Utilisation threshold to start delays - default 0.3
    - ThrottleCutOffOverhead         : Safety margin below pause threshold - default 0.05
    - WriteDelayMultiplier           : Delay multiplier for write operations - default 1000
    - UnknownOperationSafetyFactor   : Fractional delay for unmapped writes - default 0.3

 Any of these keys present in your config file will override the corresponding module preset at startup.
 "ThrottleProfile": "Custom" is required for override settings to be applied. Excluded values will use module defaults.

 Example custom config section:
 {
     "ThrottleProfile": "Custom",
     "DelayMultiplier": 900,
     "CalibrationBaseSeconds": 10,
     "CalibrationConfidenceCount": 60,
     "DriftThresholdPercent": 0.015,
     "ThrottleUtilisationThreshold": 0.4
 }

 Save the file and reload the module for changes to take effect.

 Testing: use this command or similar in one or more concurrent sessions to simulate high API usage:

     1..1000 | % {Get-RMMSite -Debug | Get-RMMAlert -Status All -Debug | Out-Null}

 Throttle debug messages will show calibration triggers, confidence, and drift detection:

DEBUG: Throttle: Calibrating (interval, 3.2s since last, interval 3.2s, confidence 40%, samples 20, +10 since last).
DEBUG: Throttle: Local prune window 60s | Account 20->20 | Write 0->0
DEBUG: Throttle Calibration:
        Account Utilisation: 22.33% (API: 22.33%, Local: 20.5%)
        Write Utilisation: 0%
        Local Counts: Account=20, Write=0
        API Counts: Account=134, Write=0
        Account Limit: 600 | Write Limit: 600
        Operation Buckets: 16
        Pause Threshold: 85%
        Throttle: False | Pause: False
        Delay MS: 0
        
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