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
# WriteDelayMultiplier: delay multiplier applied to write bucket pressure (separate from global read/write DelayMultiplier).
# UnknownOperationSafetyFactor: fractional delay applied to write operations with no explicit operation mapping.
# Note: Profiles tuned for up to 5 concurrent heavy-use sessions sharing the same API quota.

@{
    'Cautious' = @{
        DelayMultiplier = 1500
        CalibrationBaseSeconds = 5
        CalibrationMinSeconds = 0.5
        CalibrationConfidenceCount = 30
        DriftThresholdPercent = 0.01
        DriftScalingFactor = 3
        ThrottleUtilisationThreshold = 0.15
        ThrottleCutOffOverhead = 0.10
        WriteDelayMultiplier = 1750
        UnknownOperationSafetyFactor = 0.5
    }
    'Medium' = @{
        DelayMultiplier = 750
        CalibrationBaseSeconds = 8
        CalibrationMinSeconds = 0.5
        CalibrationConfidenceCount = 50
        DriftThresholdPercent = 0.02
        DriftScalingFactor = 2
        ThrottleUtilisationThreshold = 0.3
        ThrottleCutOffOverhead = 0.05
        WriteDelayMultiplier = 1000
        UnknownOperationSafetyFactor = 0.3
    }
    'Aggressive' = @{
        DelayMultiplier = 300
        CalibrationBaseSeconds = 15
        CalibrationMinSeconds = 1
        CalibrationConfidenceCount = 80
        DriftThresholdPercent = 0.02
        DriftScalingFactor = 1.5
        ThrottleUtilisationThreshold = 0.5
        ThrottleCutOffOverhead = 0.04
        WriteDelayMultiplier = 750
        UnknownOperationSafetyFactor = 0.1
    }
    'DefaultProfile' = @{
        DelayMultiplier = 750
        CalibrationBaseSeconds = 8
        CalibrationMinSeconds = 0.5
        CalibrationConfidenceCount = 50
        DriftThresholdPercent = 0.02
        DriftScalingFactor = 2
        ThrottleUtilisationThreshold = 0.3
        ThrottleCutOffOverhead = 0.05
        WriteDelayMultiplier = 1000
        UnknownOperationSafetyFactor = 0.3
    }
}