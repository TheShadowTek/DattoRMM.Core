<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Defines the extended property types that can be requested when retrieving site information.

.DESCRIPTION
    The RMMSiteExtendedProperty enum defines the types of extended properties that can be requested
    for a site in the Datto RMM platform. These extended properties allow callers to request additional
    related data when fetching site information, such as the site's settings, variables, or filters.
#>
enum RMMSiteExtendedProperty {
    Settings
    Variables
    Filters
}

<#
.SYNOPSIS
    Defines the scope levels available within the Datto RMM platform.

.DESCRIPTION
    The RMMScope enum defines the scope levels available within the Datto RMM platform. Scope
    determines whether a resource such as a variable or filter applies globally across all sites
    or is restricted to a specific site.
#>
enum RMMScope {
    Global
    Site
}

<#
.SYNOPSIS
    Defines the available Datto RMM platform instances used for API and portal URL construction.

.DESCRIPTION
    The RMMPlatform enum defines the available Datto RMM platform instances. Each value represents
    a specific regional or deployment platform endpoint identified by its codename. The platform value
    is used internally to construct API base URLs and portal URLs for the correct Datto RMM instance.
#>
enum RMMPlatform {
    Pinotage
    Concord
    Vidal
    Merlot
    Zinfandel
    Syrah
}

<#
.SYNOPSIS
    Defines the API request throttling profiles for controlling request rate limits.

.DESCRIPTION
    The RMMThrottleProfile enum defines the available API request throttling profiles for the
    Datto RMM module. Each profile controls the rate at which API requests are sent, balancing
    between performance and API rate limit compliance. Selecting a more cautious profile reduces
    the risk of hitting API rate limits at the cost of slower execution.
#>
enum RMMThrottleProfile {
    Medium
    Aggressive
    Cautious
    DefaultProfile
}