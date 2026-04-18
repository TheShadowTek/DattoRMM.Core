<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>

# Throttle profile presets for multi-bucket rate limit management.
# Each profile controls delay curves, calibration frequency, and write operation conservatism.
#
# Calibration interval is calculated dynamically from sample confidence and drift:
#   CalibrationBaseSeconds:      ceiling interval when confidence is high and drift is zero.
#   CalibrationMinSeconds:       absolute floor to prevent excessive API calibration calls.
#   CalibrationConfidenceCount:  number of local window samples required before the interval
#                                reaches the full base. Fewer samples = shorter interval = more
#                                frequent calibration to establish an accurate picture early.
#   DriftThresholdPercent:       drift gap (API vs Local) at which accelerated calibration begins.
#                                Lower values detect concurrent sessions earlier (1.5-2% recommended).
#   DriftScalingFactor:          how aggressively the interval shrinks as drift exceeds the threshold.
#                                Higher values produce shorter intervals for the same drift magnitude.
#
#   ConfidenceFactor = Min(1.0, LocalSampleCount / CalibrationConfidenceCount)
#   DriftFactor      = 1 / (1 + (DriftGap / DriftThreshold) * DriftScaling)
#   Interval         = Max(Min, Base * ConfidenceFactor * DriftFactor)
#
# UnknownOperationSafetyFactor: fractional delay applied to write operations with no explicit operation mapping.
# Note: Profiles tuned for up to 5 concurrent heavy-use sessions sharing the same API quota.

@{
    'Cautious' = @{
        DelayMultiplier = 1000
        CalibrationBaseSeconds = 5
        CalibrationMinSeconds = 0.5
        CalibrationConfidenceCount = 30
        DriftThresholdPercent = 0.01
        DriftScalingFactor = 3
        ThrottleUtilisationThreshold = 0.2
        ThrottleCutOffOverhead = 0.08
        UnknownOperationSafetyFactor = 0.5
    }
    'Medium' = @{
        DelayMultiplier = 500
        CalibrationBaseSeconds = 8
        CalibrationMinSeconds = 0.5
        CalibrationConfidenceCount = 50
        DriftThresholdPercent = 0.02
        DriftScalingFactor = 2
        ThrottleUtilisationThreshold = 0.3
        ThrottleCutOffOverhead = 0.05
        UnknownOperationSafetyFactor = 0.3
    }
    'Aggressive' = @{
        DelayMultiplier = 250
        CalibrationBaseSeconds = 5
        CalibrationMinSeconds = 0.5
        CalibrationConfidenceCount = 40
        DriftThresholdPercent = 0.02
        DriftScalingFactor = 1.5
        ThrottleUtilisationThreshold = 0.45
        ThrottleCutOffOverhead = 0.04
        UnknownOperationSafetyFactor = 0.15
    }
    'DefaultProfile' = @{
        DelayMultiplier = 500
        CalibrationBaseSeconds = 8
        CalibrationMinSeconds = 0.5
        CalibrationConfidenceCount = 50
        DriftThresholdPercent = 0.02
        DriftScalingFactor = 2
        ThrottleUtilisationThreshold = 0.3
        ThrottleCutOffOverhead = 0.05
        UnknownOperationSafetyFactor = 0.3
    }
}
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAhlIV+vqRPr6Vw
# FvJ9Em+7YH9Y7IVD2sFx4Y4a1DqVlqCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDSqxmzudOKqM6z4lAz2lJY+qZdd
# MY32dw3tAHlvdhnhMA0GCSqGSIb3DQEBAQUABIIBAEww1R/sAvesFXrz8egiyHs9
# J/MqyBiRqQOHIwLIa09VVsn34MfhdES4DiO44W2htzPxhKjXTORYGZvmWYcyhc5p
# VWzLSZHy0AN2fFJ/MiqYnBpMxAgjCZ3NTaj8tyuh0+I5Imairzer7mK9vl0ZWhgi
# 7XrdzLwAc9pFq8Z9h3qTXHut9WVE146OUiaBVadWY/7V6GtPMXGBwrSLrpEAEX1E
# xpb7+rD/alXhZruSFse35WNQWjEk4C57TlkVNfmBitUO2LeoWXHhbLnOTuiPM93Z
# b9JPPQg1bJCXK2P6gy0fOAC99LAZhwT8o3uyIqWxfoPpZr6t2QAQ+iWCQyotfvE=
# SIG # End signature block
