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
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCHSBsrUcMV74/X
# R1K1Hp651FJikvoAaFX1YmsGb94JpaCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHpILrB4V6z379O2dkRst85Nf56Y
# 7PWNI8bLUw4C2Jb9MA0GCSqGSIb3DQEBAQUABIIBAINo8z4HPoHwA7kiQ4OsQ03Z
# 72q+0lyh1FY1wg12rCXoSsjPYE1bAOH9cJ2Ntv8rZ0wSK2voa5GZ+Ede37sP8Efq
# H0HHYFLt+mndjpS4DG8CyAklgTO5+EsV/Nk0h6rSNVODfSasZQnbkj4T0MTLHKUL
# b5luTTo3Nc3MTKraiCToqqNWWEFI1P+7l9WlzBX/ObRz8gwcLJ3oT7hN+eaHEpYP
# zZsmajKlwMZbdcLaq81wUxHEelgjVHbRjwG7FQmNnvrRZVpCYMXtBLKPu2IczelF
# bZVN4dd7IdNzOpeBhnuaOTtGWmLNHWleDHuXQAXqKOWeTaabXQMTsZK6E3erysg=
# SIG # End signature block
