<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Initialises the RMMThrottle script-scoped variable with safe static defaults.
.DESCRIPTION
    Populates $Script:RMMThrottle with default values for the multi-bucket throttle model.
    Called once at module load, before dot-sourcing private and public functions.

    The hash table serves two purposes:

    - Behaviour settings (DelayMultiplier, CalibrationBaseSeconds, etc.) provide working
      defaults that are overridden by Import-ThrottleProfile when a saved config is loaded.

    - Runtime state fields (ReadLimit, WriteLimit, timestamps, etc.) provide safe
      pre-connect fallback values. These are replaced with live-discovered values by
      Initialize-ThrottleState when Connect-DattoRMM is called.

    Read and write calibration timestamps are set to [datetime]::MinValue as pre-connect
    safe defaults only. Calibration is driven by Connect-DattoRMM via Initialize-ThrottleState
    and Update-Throttle, not by these sentinel values.

    The Datto RMM API tracks reads and writes as independent quotas:
    - accountCount / accountRateLimit   → read (GET) operations only
    - accountWriteCount / accountWriteRateLimit → write (PUT/POST/DELETE) operations only
    Read requests are evaluated against the read bucket; write requests are evaluated against
    write buckets (global write + per-operation). They do not overlap.
#>
function Set-ThrottleDefaults {
    [CmdletBinding()]
    param ()

    $Script:RMMThrottle = [ordered]@{
        Profile = 'DefaultProfile'                                                      # Active throttle profile name
        DelayMultiplier = 500                                                           # Delay multiplier for all bucket throttling (read and write)
        ThrottleCutOffOverhead = 0.05                                                   # Safety margin below accountCutOffRatio for pause trigger
        ThrottleUtilisationThreshold = 0.3                                              # Utilisation ratio at which throttling activates
        CalibrationBaseSeconds = 8                                                      # Ceiling interval at high confidence and zero drift
        CalibrationMinSeconds = 0.5                                                     # Absolute floor to prevent excessive API calibration calls
        CalibrationConfidenceCount = 50                                                 # Local samples needed before interval reaches full base
        CalibrationMaxSeconds = 20                                                      # Ceiling for stability-extended calibration interval
        CalibrationStabilityThreshold = 4                                               # Consecutive stable calibrations before interval begins extending
        DriftThresholdPercent = 0.02                                                    # Drift gap at which accelerated calibration begins (2%)
        DriftScalingFactor = 2                                                          # How aggressively interval shrinks as drift exceeds threshold
        UnknownOperationSafetyFactor = 0.3                                              # Fractional delay for unmapped write operations
        WindowSizeSeconds = 60                                                          # Rolling window size (discovered from API)
        ReadLimit = 600                                                                 # Read (GET) rate limit (discovered from API as accountRateLimit)
        AccountCutOffRatio = 0.9                                                        # Account cut-off ratio (discovered from API)
        WriteLimit = 600                                                                # Write rate limit (discovered from API as accountWriteRateLimit)
        ReadLocalTimestamps = [System.Collections.Generic.List[datetime]]::new()        # Local timestamps for read (GET) requests
        WriteLocalTimestamps = [System.Collections.Generic.List[datetime]]::new()       # Local timestamps for write (PUT/POST/DELETE) requests
        OperationBuckets = @{}                                                          # Per-operation write buckets (discovered from API)
        ReadLastCalibrationUtc = [datetime]::MinValue                                   # Pre-connect safe default; overwritten by Initialize-ThrottleState on connect
        WriteLastCalibrationUtc = [datetime]::MinValue                                  # Pre-connect safe default; overwritten by Initialize-ThrottleState on connect
        ReadSamplesAtLastCalibration = 0                                                # Local read sample count at last calibration (for request gate)
        WriteSamplesAtLastCalibration = 0                                               # Local write sample count at last calibration (for request gate)
        ReadStableCalibrationCount = 0                                                  # Consecutive stable read calibrations since last instability reset
        WriteStableCalibrationCount = 0                                                 # Consecutive stable write calibrations since last instability reset
        ReadUtilisation = 0.0                                                           # Computed read utilisation (accountCount / accountRateLimit)
        WriteUtilisation = 0.0                                                          # Computed write utilisation (accountWriteCount / accountWriteRateLimit)
        ReadDelayMS = 0                                                                 # Current computed read delay in milliseconds
        WriteDelayMS = 0                                                                # Current computed write delay in milliseconds
        Pause = $false                                                                  # Hard pause flag
        Throttle = $false                                                               # Soft throttle flag
    }
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDsGGoKC9VpzrtA
# m83EUOsgr4fNv6wmSiJiV5obo+fMR6CCA04wggNKMIICMqADAgECAhB464iXHfI6
# gksEkDDTyrNsMA0GCSqGSIb3DQEBCwUAMD0xFjAUBgNVBAoMDVJvYmVydCBGYWRk
# ZXMxIzAhBgNVBAMMGkRhdHRvUk1NLkNvcmUgQ29kZSBTaWduaW5nMB4XDTI2MDMz
# MTAwMTMzMFoXDTI4MDMzMTAwMjMzMFowPTEWMBQGA1UECgwNUm9iZXJ0IEZhZGRl
# czEjMCEGA1UEAwwaRGF0dG9STU0uQ29yZSBDb2RlIFNpZ25pbmcwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQChn1EpMYQgl1RgWzQj2+wp2mvdfb3UsaBS
# nxEVGoQ0gj96tJ2MHAF7zsITdUjwaflKS1vE6wAlOg5EI1V79tJCMxzM0bFpOdR1
# L5F2HE/ovIAKNkHxFUF5qWU8vVeAsOViFQ4yhHpzLen0WLF6vhmc9eH23dLQy5fy
# tELZQEc2WbQFa4HMAitP/P9kHAu6CUx5s4woLIOyyR06jkr3l9vk0sxcbCxx7+dF
# RrsSLyPYPH+bUAB8+a0hs+6qCeteBuUfLvGzpMhpzKAsY82WZ3Rd9X38i32dYj+y
# dYx+nx+UEMDLjDJrZgnVa8as4RojqVLcEns5yb/XTjLxDc58VatdAgMBAAGjRjBE
# MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU
# H+B0vf97dYXqdUX1YMcWhFsY6fcwDQYJKoZIhvcNAQELBQADggEBAJmD4EEGNmcD
# 1JtFoRGxuLJaTHxDwBsjqcRQRE1VPZNGaiwIm8oSQdHVjQg0oIyK7SEb02cs6n6Y
# NZbwf7B7WZJ4aKYbcoLug1k1x9SoqwBmfElECeJTKXf6dkRRNmrAodpGCixR4wMH
# KXqwqP5F+5j7bdnQPiIVXuMesxc4tktz362ysph1bqKjDQSCBpwi0glEIH7bv5Ms
# Ey9Gl3fe+vYC5W06d2LYVebEfm9+7766hsOgpdDVgdtnN+e6uwIJjG/6PTG6TMDP
# y+pr5K6LyUVYJYcWWUTZRBqqwBHiLGekPbxrjEVfxUY32Pq4QfLzUH5hhUCAk4HN
# XpF9pOzFLMUxggIDMIIB/wIBATBRMD0xFjAUBgNVBAoMDVJvYmVydCBGYWRkZXMx
# IzAhBgNVBAMMGkRhdHRvUk1NLkNvcmUgQ29kZSBTaWduaW5nAhB464iXHfI6gksE
# kDDTyrNsMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKEC
# gAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwG
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIK6es/uaCXXJFk3Yb/RFetPfJqkd
# iaVjYhMM2x578QInMA0GCSqGSIb3DQEBAQUABIIBAA7y7UQ/stsVlJpFk+Q0OtN1
# Ysw2jjuZWnWo3zdzy9GUXkLlpgDs0br9u/YepamRRkk9hU6HBr7JX9KSsHXD4M09
# hHQ16CX4in+PM+4T1hV64p6pVzLqLtjrFRHI163Be/eAj1Eo7tSy+TDzIZgahqMa
# E+FLmEv0LDPfD0pq5iYQtkmhv+QtKw3N0QRA3prQWGpzwk+ypYPUM8zl/qh9JYfW
# YJwzsk6hvltt/c9Bpy+FvlbbiT72VLMomlMTjLO/FjQvTO7X3CU3rhgLCosliZJ/
# v2e2bO0Zq18Neva/fScnPM6X9qxFyntGNBHirojUTnlMdVcBlj59EDvHTbP2hr4=
# SIG # End signature block
