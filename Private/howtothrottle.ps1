$Message = @"
!The following configuration options are intended for advanced users only.  
If you are modifying these values, you should already understand the implications and accept 
full responsibility for any rate-limit or service-impact risks.


             .-------------------------. 
            | .-----------------------. |
            | |      _                | |
            | |     \ \               | |
            | |      \ \              | |
            | |       > >             | |
            | |      / /              | |
            | |     /_/    _______    | |
            | |           |_______|   | |
            | '-----------------------' |
             '-------------------------' 

             HOW TO CUSTOMISE THROTTLING
             ---------------------------

 1. Open the DattoRMM.Core module folder on your system: `$HOME/.DattoRMM.Core/config.json
 2. Edit the "ThrottleAggressiveness" setting to one of the following values:
    - "Cautious"   : Minimal API usage, suitable for very low rate limits
    - "Medium"     : Balanced API usage and caution (default)
    - "Aggressive" : Higher API usage, suitable for high rate limits

Alternativley, you can override module throttling profile preset completly.
DO THIS AT YOUR OWN RISK.

Manually set any of the following throttle values in your config JSON to override the module presets:
    - ThrottleAggressiveness       : Set to "Custom" to enable custom values
    - LowUtilCheckInterval         : Number of requests between throttle recalculation when utilisation is low (default 25)
    - DelayMultiplier              : Multiplier for calculating delay when throttling (in ms) - default 750
    - ThrottleOverhead             : Fraction of rate limit to reserve as safety margin (default 0.05)
    - ThrottleUtilisationThreshold : Utilisation threshold to start throttling (default 0.5)

 Any of these keys present in your config file will override the corresponding module preset at startup.
 "ThrottleAggressiveness": "Custom" is required for override settings to be applied. Excluded values will use module defaults.

 Example custom config section:
 {
     "ThrottleAggressiveness": "Custom",
     "DelayMultiplier": 600,
     "LowUtilCheckInterval": 30,
     "ThrottleOverhead": 0.03,
     "ThrottleUtilisationThreshold": 0.6
 }

 Save the file and reload the module for changes to take effect.

 Testing, use this command or similar in one or more concurrent sessions to simulate high API usage:

     1..1000 | ForEach-Object { Get-RMMSite -Debug | Get-RMMAlert -Status All -Debug | Out-Null }

 Throttle debug messages will show current utilisation and delay calculation results.

     DEBUG: Throttling:
            Utilisation=61.17%
            ThrottleUtilisationThreshold=0.5
            LowUtilCheckInterval=25
            CheckInterval=10
            RequestCount=367
            Remaining=233
            DelayMS=458.75
            Pause=False

 Enjoy, and try not to get banned.
 TheShadowTek

"@

Write-Host $Message -ForegroundColor DarkGreen