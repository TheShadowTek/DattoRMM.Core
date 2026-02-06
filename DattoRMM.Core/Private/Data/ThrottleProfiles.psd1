<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
@{
    'Cautious' = @{
        DelayMultiplier = 1250
        LowUtilCheckInterval = 25
        ThrottleUtilisationThreshold = 0.3
        ThrottleCutOffOverhead = 0.1
    }
    'Medium' = @{
        DelayMultiplier = 750
        LowUtilCheckInterval = 25
        ThrottleUtilisationThreshold = 0.5
        ThrottleCutOffOverhead = 0.05
    }
    'Aggressive' = @{
        DelayMultiplier = 500
        LowUtilCheckInterval = 50
        ThrottleUtilisationThreshold = 0.5
        ThrottleCutOffOverhead = 0.04
    }
    'DefaultProfile' = @{
        DelayMultiplier = 750
        LowUtilCheckInterval = 25
        ThrottleUtilisationThreshold = 0.5
        ThrottleCutOffOverhead = 0.05
    }
}