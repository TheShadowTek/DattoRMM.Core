<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
enum RMMSiteExtendedProperty {
    Settings
    Variables
    Filters
}

enum RMMScope {
    Global
    Site
}

enum RMMPlatform {
    Pinotage
    Concord
    Vidal
    Merlot
    Zinfandel
    Syrah
}

enum RMMThrottleProfile {
    Medium
    Aggressive
    Cautious
    DefaultProfile
}