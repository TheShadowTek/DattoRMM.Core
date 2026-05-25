<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Loads persisted configuration from disk and applies it to session-scoped variables.
.DESCRIPTION
    Reads the saved configuration file via Read-ConfigFile and populates all Script-scoped
    configuration variables used throughout the session. This includes platform, page size,
    token expiry, API retry settings, and the active throttle profile.

    If no configuration file is found, the throttle profile defaults to 'DefaultProfile'
    and all other session variables remain at their module-initialisation defaults.

    If a configuration file is present but an error occurs during application, a non-terminating
    error is written and the session may be partially configured.

    Called once during module load, after all Private and Public functions have been dot-sourced.
#>
function Initialize-SavedConfig {
    [CmdletBinding()]
    param ()

    Write-Verbose "Attempting to load configuration file..."

    $SavedConfig = Read-ConfigFile

    if ($null -ne $SavedConfig) {

        try {

            switch ($SavedConfig.Keys) {

                'Platform' {
                    $Script:ConfigPlatform = $SavedConfig.Platform
                    $Script:SessionPlatform = $SavedConfig.Platform
                    Write-Verbose "Platform: $($Script:ConfigPlatform)"
                }

                'PageSize' {
                    $Script:ConfigPageSize = $SavedConfig.PageSize
                    $Script:SessionPageSize = $SavedConfig.PageSize
                    Write-Verbose "PageSize: $($Script:ConfigPageSize)"
                }

                'TokenExpireHours' {
                    $Script:TokenExpireHours = $SavedConfig.TokenExpireHours
                    $Script:ConfigTokenExpireHours = $SavedConfig.TokenExpireHours
                    Write-Verbose "TokenExpireHours: $($Script:TokenExpireHours)"
                }

                'ApiMaxRetries' {
                    $Script:ApiMethodRetry.MaxRetries = $SavedConfig.ApiMaxRetries
                    $Script:ConfigApiMaxRetries = $SavedConfig.ApiMaxRetries
                    Write-Verbose "ApiMaxRetries: $($Script:ApiMethodRetry.MaxRetries)"
                }

                'ApiRetryIntervalSeconds' {
                    $Script:ApiMethodRetry.RetryIntervalSeconds = $SavedConfig.ApiRetryIntervalSeconds
                    $Script:ConfigApiRetryIntervalSeconds = $SavedConfig.ApiRetryIntervalSeconds
                    Write-Verbose "ApiRetryIntervalSeconds: $($Script:ApiMethodRetry.RetryIntervalSeconds)"
                }

                'ApiTimeoutSeconds' {
                    $Script:ApiMethodRetry.TimeoutSeconds = $SavedConfig.ApiTimeoutSeconds
                    $Script:ConfigApiTimeoutSeconds = $SavedConfig.ApiTimeoutSeconds
                    Write-Verbose "ApiTimeoutSeconds: $($Script:ApiMethodRetry.TimeoutSeconds)"
                }

                'TokenRefreshBufferMinutes' {
                    $Script:TokenRefreshBufferMinutes = $SavedConfig.TokenRefreshBufferMinutes
                    $Script:ConfigTokenRefreshBufferMinutes = $SavedConfig.TokenRefreshBufferMinutes
                    Write-Verbose "TokenRefreshBufferMinutes: $($Script:TokenRefreshBufferMinutes)"
                }

                'ThrottleProfile' {

                    Import-ThrottleProfile -Config $SavedConfig

                }
            }

        } catch {

            Write-Error "Error loading saved config $($Script:ConfigPath). Session settings may be incomplete: $($_.Exception.Message)"

        }

    } else {

        $Script:RMMThrottle.Profile = 'DefaultProfile'
        Write-Verbose "No configuration file found; using default settings."

    }

}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBprV36wMdsCLm/
# szp/XzU64V7klqdsh/7639KLQu/TDKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKzGtH2xGjMygnMwFSHvUTbCmleS
# ix/0kkojiWlf16MyMA0GCSqGSIb3DQEBAQUABIIBAItsK8g+Np4PBKZbgf0Dv9LI
# WseuVi5YeVz1uTFQoh/oyNIe26GYRzZrhxm/UDav8VlyUQyVDkVGIGiR6TUPhh2g
# xND+f58CIdkydVoGiSekLYd8KbSD7EsBgbS2R8BpCKHaU6zPjdtjVlGUTttPJaHY
# K2Io34cVnE2OrxuGBF+q9Vc3gAGdr6GeFeNJveVu7+SRprC6EA8i5A9dvu89qBQs
# mFxP1bvZQqBysDo7A6Cuw96ZgzwRibcwEhiVnljXeJXpaqm2PfCQ6JISGZWRryqb
# f7DLkTwveUMF3eFwHnBKfCzfxwFCeM9t7JVBjxQ5ZzN3sGfkznuPLMQnp+JisLg=
# SIG # End signature block
