<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Set-RMMConfig {
    <#
    .SYNOPSIS
        Configures the current DattoRMM.Core session and optionally saves settings persistently.

    .DESCRIPTION
        Set-RMMConfig allows you to configure the current session's settings for the DattoRMM.Core module. You can update platform, page size, throttling, and token expiration for the current session. Use -Persist to save these settings to the configuration file for future sessions. Use -Default to reset all settings to module defaults (both in session and config).

        The TokenExpireHours setting controls how often the module will proactively refresh the API token before expiry. Changing this value does not invalidate the current token; it only updates the local refresh interval. Lower values mean the token is refreshed more frequently, reducing risk of accidental expiration during long sessions. Higher values mean the same token is reused longer, which may or may not offer a security benefit (less frequent token changes, but not invalidated on update). Note: The token is only refreshed locally; the previous token remains valid until it naturally expires or is revoked by the API provider.

    .PARAMETER Platform
        Sets the default Datto RMM platform region for connections in the current session. Valid values: Pinotage, Concord, Vidal, Merlot, Zinfandel, Syrah. Use -Persist to save as the default for future sessions.

    .PARAMETER PageSize
        Sets the default page size for API requests in the current session. Valid range: 1-250 (actual max depends on your Datto RMM account). Use -Persist to save as the default for future sessions.

    .PARAMETER ThrottleProfile
        Sets the throttling profile for API requests in the current session. Valid values: Cautious, Medium, Aggressive. Default is Medium. Use -Persist to save as the default for future sessions.

    .PARAMETER TokenExpireHours
        Sets the token refresh interval (in hours) for the current session. Valid range: 1-100. Default is 100. Use -Persist to save as the default for future sessions.

    .PARAMETER ApiMaxRetries
        Sets the maximum number of retry attempts for failed API requests. Valid range: 1-10. Default is 5. Use -Persist to save as the default for future sessions.

    .PARAMETER ApiRetryIntervalSeconds
        Sets the wait time in seconds between retry attempts. Valid range: 1-300. Default is 10. Use -Persist to save as the default for future sessions.

    .PARAMETER ApiTimeoutSeconds
        Sets the timeout in seconds for API requests. Valid range: 10-300. Default is 60. Use -Persist to save as the default for future sessions.

    .PARAMETER Persist
        If specified, saves the provided settings to the configuration file for future sessions. Without -Persist, changes apply only to the current session.

    .PARAMETER Default
        Resets all settings to module defaults in the current session. If used with -Persist, also deletes the persistent configuration file (full factory reset). Without -Persist, only the current session is affected and the saved config remains unchanged.

    .PARAMETER Force
        Skips confirmation prompts for impactful actions (such as resetting or saving configuration). Use with -Default or -Persist to bypass -Confirm and proceed immediately.

    .NOTES
        Confirmation logic is handled up front with early returns, ensuring efficient and predictable behavior.

    .EXAMPLE
        Set-RMMConfig -Platform Merlot

        Sets the default platform to Merlot for the current session only.

    .EXAMPLE
        Set-RMMConfig -Platform Pinotage -PageSize 100 -Persist

        Sets both the default platform and page size, and saves them for future sessions.

    .EXAMPLE
        Set-RMMConfig -ThrottleProfile Cautious -TokenExpireHours 50

        Configures advanced throttling and token refresh settings for the current session only.

    .EXAMPLE
        Set-RMMConfig -Default

        Resets all configuration to module defaults, both in session and in the config file.

    .INPUTS
        None. You cannot pipe objects to Set-RMMConfig.

    .OUTPUTS
        None. This function updates the session and/or persistent configuration file.

    .NOTES
        Configuration is stored at: $HOME/.DattoRMM.Core/config.json At least one parameter must be specified unless using -Default. Settings take effect immediately in the session. Use -Persist to save for future sessions.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Config/Set-RMMConfig.md

    .LINK
        Connect-DattoRMM
        Save-RMMConfig
        Get-RMMConfig
        Reset-RMMConfig
        Set-RMMPageSize
        about_DattoRMM.CoreThrottling
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(
            ParameterSetName = 'Set',
            Mandatory = $false
        )]
        [RMMPlatform]
        $Platform,

        [Parameter(
            ParameterSetName = 'Set',
            Mandatory = $false
        )]
        [ValidateRange(1, 250)]
        [int]
        $PageSize,

        [Parameter(
            ParameterSetName = 'Set',
            Mandatory = $false
        )]
        [RMMThrottleProfile]
        $ThrottleProfile,

        [Parameter(
            ParameterSetName = 'Set',
            Mandatory = $false
        )]
        [ValidateRange(1, 100)]
        [int]
        $TokenExpireHours,

        [Parameter(
            ParameterSetName = 'Set',
            Mandatory = $false
        )]
        [ValidateRange(1, 10)]
        [int]
        $ApiMaxRetries,

        [Parameter(
            ParameterSetName = 'Set',
            Mandatory = $false
        )]
        [ValidateRange(1, 300)]
        [int]
        $ApiRetryIntervalSeconds,

        [Parameter(
            ParameterSetName = 'Set',
            Mandatory = $false
        )]
        [ValidateRange(10, 300)]
        [int]
        $ApiTimeoutSeconds,

        [Parameter(
            ParameterSetName = 'Set',
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName = 'Default',
            Mandatory = $false
        )]
        [switch]
        $Persist,

        [Parameter(
            ParameterSetName = 'Default',
            Mandatory = $true
        )]
        [switch]
        $Default,

        [Parameter(
            Mandatory = $false
        )]
        [switch]
        $Force 
    )

    # Ensure at least one parameter is provided

    if (($PSBoundParameters.Keys | Where-Object {$_ -notin 'Persist', 'Default', 'Force'}).Count -lt 1) {

        throw "At least one configuration parameter must be specified."
        
    }

    if ($Default -and (-not $Force -and -not $PSCmdlet.ShouldProcess("DattoRMM.Core configuration", "Reset to default settings"))) {

        Write-Warning "No action taken. Use -Default to reset settings to defaults."
        return

    }

    if ($Persist -and (-not $Force -and -not $PSCmdlet.ShouldProcess("DattoRMM.Core configuration", "Update persistent configuration"))) {

        Write-Warning "No action taken. Use -Persist to save settings to persistent configuration."
        return

    } 

    if ($Default) {

        Write-Verbose "Resetting configuration to default settings."

        # Reset session variables to defaults
        $Script:TokenExpireHours = 100
        $Script:SessionPlatform = $null
        $Script:SessionPageSize = $null
        $Script:PageSize = $null

        # Reset throttle to default profile (Medium)
        $Script:RMMThrottle.Profile = 'DefaultProfile'

        foreach ($Key in $Script:ThrottleProfileDefaults['DefaultProfile'].Keys) {

            $Script:RMMThrottle[$Key] = $Script:ThrottleProfileDefaults['DefaultProfile'][$Key]

        }

        if ($Persist) {

            if (Test-Path -Path $Script:ConfigPath) {

                Remove-Item -Path $Script:ConfigPath -Force
                Write-Verbose "Deleted configuration file at: $Script:ConfigPath"

            }

            # Clear Config* tracking variables to reflect the now-empty persistent state
            $Script:ConfigPlatform = $null
            $Script:ConfigPageSize = $null
            $Script:ConfigThrottleProfile = $null
            $Script:ConfigTokenExpireHours = $null
            $Script:ConfigApiMaxRetries = $null
            $Script:ConfigApiRetryIntervalSeconds = $null
            $Script:ConfigApiTimeoutSeconds = $null

        }

        return

    }

    # Read existing config if updating saved config
    if ($Persist) {

        $Config = Read-ConfigFile

        if ($null -eq $Config) {

            [hashtable]$Config = @{}

        }
    }

    switch ($PSBoundParameters.Keys) {

        'PageSize' {
            
            # If PageSize parameter greater than account max, ot will not be saved to config
            if ($null -eq $Script:MaxPageSize) {
                
                Write-Warning "MaxPageSize is unknown. Connect-DattoRMM must be run to determine account maximum page size before setting PageSize.$(if ($Persist) {"PageSize $PageSize will not be saved."})"
                $Script:SessionPageSize = $PageSize
                
            } elseif ($PageSize -gt $Script:MaxPageSize) {
                
                Write-Warning "Requested page size ($PageSize) exceeds account maximum ($($Script:MaxPageSize)). Setting to maximum.$(if ($Persist) {"PageSize $PageSize will not be saved."})"
                $Script:PageSize = $Script:MaxPageSize
                $Script:SessionPageSize = $Script:MaxPageSize
                
            } else {
                
                Write-Verbose "Set PageSize to: $PageSize"
                $Script:PageSize = $PageSize
                $Script:SessionPageSize = $PageSize

                if ($Persist) {

                    $Config['PageSize'] = $PageSize
                
                }
            }
        }
        
        'Platform' {

            Write-Verbose "Set Platform to: $Platform"
            $Script:SessionPlatform = $Platform.ToString()

            if ($Persist) {

                $Config['Platform'] = $Platform.ToString()

            }
        }

        'ThrottleProfile' {

            # Set throttle profile — iterate profile keys generically to stay in sync with ThrottleProfiles.psd1
            $ProfileName = [RMMThrottleProfile]::GetName($ThrottleProfile)
            Write-Verbose "Set ThrottleProfile to: $ProfileName"
            $Script:RMMThrottle.Profile = $ProfileName

            foreach ($Key in $Script:ThrottleProfileDefaults[$ProfileName].Keys) {

                $Script:RMMThrottle[$Key] = $Script:ThrottleProfileDefaults[$ProfileName][$Key]

            }

            if ($Persist) {

                $Config['ThrottleProfile'] = $ProfileName

            }
        }

        'TokenExpireHours' {

            Write-Verbose "Set TokenExpireHours to: $TokenExpireHours"
            $Script:TokenExpireHours = $TokenExpireHours

            if ($Persist) {

                $Config['TokenExpireHours'] = $TokenExpireHours

            }
        }

        'ApiMaxRetries' {

            Write-Verbose "Set ApiMaxRetries to: $ApiMaxRetries"
            $Script:ApiMethodRetry.MaxRetries = $ApiMaxRetries

            if ($Persist) {

                $Config['ApiMaxRetries'] = $ApiMaxRetries

            }
        }

        'ApiRetryIntervalSeconds' {

            Write-Verbose "Set ApiRetryIntervalSeconds to: $ApiRetryIntervalSeconds"
            $Script:ApiMethodRetry.RetryIntervalSeconds = $ApiRetryIntervalSeconds

            if ($Persist) {

                $Config['ApiRetryIntervalSeconds'] = $ApiRetryIntervalSeconds

            }
        }

        'ApiTimeoutSeconds' {

            Write-Verbose "Set ApiTimeoutSeconds to: $ApiTimeoutSeconds"
            $Script:ApiMethodRetry.TimeoutSeconds = $ApiTimeoutSeconds

            if ($Persist) {

                $Config['ApiTimeoutSeconds'] = $ApiTimeoutSeconds

            }
        }
    }

    if ($Persist) {

        # Write config file
        $Success = Write-ConfigFile -Config $Config

        if ($Success) {

            switch ($PSBoundParameters.Keys) {

                'PageSize' {
                    $Script:ConfigPageSize = $Script:PageSize
                }

                'Platform' {
                    $Script:ConfigPlatform = $Script:SessionPlatform
                }

                'ThrottleProfile' {
                    $Script:ConfigThrottleProfile = $Script:RMMThrottle.Profile
                }

                'TokenExpireHours' {
                    $Script:ConfigTokenExpireHours = $Script:TokenExpireHours
                }

                'ApiMaxRetries' {
                    $Script:ConfigApiMaxRetries = $Script:ApiMethodRetry.MaxRetries
                }

                'ApiRetryIntervalSeconds' {
                    $Script:ConfigApiRetryIntervalSeconds = $Script:ApiMethodRetry.RetryIntervalSeconds
                }

                'ApiTimeoutSeconds' {
                    $Script:ConfigApiTimeoutSeconds = $Script:ApiMethodRetry.TimeoutSeconds
                }
            }

            Write-Host "Configuration saved successfully." -ForegroundColor Green

        } else {

            throw "Failed to save configuration."

        }
    }
}


# SIG # Begin signature block
# MIIcXwYJKoZIhvcNAQcCoIIcUDCCHEwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA6v45mvyhS8xZX
# JKd15MnkDMW8fbHDUSa1cUZ8DitqG6CCFogwggNKMIICMqADAgECAhB464iXHfI6
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
# XpF9pOzFLMUwggWNMIIEdaADAgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3
# DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAX
# BgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3Vy
# ZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBH
# NDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIw
# aTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLK
# EdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4Tm
# dDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembu
# d8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnD
# eMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1
# XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVld
# QnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTS
# YW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSm
# M9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzT
# QRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6Kx
# fgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/
# MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv
# 9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBr
# MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUH
# MAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYG
# BFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72a
# rKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFID
# yE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/o
# Wajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv
# 76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30
# fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQwgga0MIIE
# nKADAgECAhANx6xXBf8hmS5AQyIMOkmGMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNV
# BAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdp
# Y2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0y
# NTA1MDcwMDAwMDBaFw0zODAxMTQyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYD
# VQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBH
# NCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEwggIiMA0GCSqG
# SIb3DQEBAQUAA4ICDwAwggIKAoICAQC0eDHTCphBcr48RsAcrHXbo0ZodLRRF51N
# rY0NlLWZloMsVO1DahGPNRcybEKq+RuwOnPhof6pvF4uGjwjqNjfEvUi6wuim5ba
# p+0lgloM2zX4kftn5B1IpYzTqpyFQ/4Bt0mAxAHeHYNnQxqXmRinvuNgxVBdJkf7
# 7S2uPoCj7GH8BLuxBG5AvftBdsOECS1UkxBvMgEdgkFiDNYiOTx4OtiFcMSkqTtF
# 2hfQz3zQSku2Ws3IfDReb6e3mmdglTcaarps0wjUjsZvkgFkriK9tUKJm/s80Fio
# cSk1VYLZlDwFt+cVFBURJg6zMUjZa/zbCclF83bRVFLeGkuAhHiGPMvSGmhgaTzV
# yhYn4p0+8y9oHRaQT/aofEnS5xLrfxnGpTXiUOeSLsJygoLPp66bkDX1ZlAeSpQl
# 92QOMeRxykvq6gbylsXQskBBBnGy3tW/AMOMCZIVNSaz7BX8VtYGqLt9MmeOreGP
# RdtBx3yGOP+rx3rKWDEJlIqLXvJWnY0v5ydPpOjL6s36czwzsucuoKs7Yk/ehb//
# Wx+5kMqIMRvUBDx6z1ev+7psNOdgJMoiwOrUG2ZdSoQbU2rMkpLiQ6bGRinZbI4O
# Lu9BMIFm1UUl9VnePs6BaaeEWvjJSjNm2qA+sdFUeEY0qVjPKOWug/G6X5uAiynM
# 7Bu2ayBjUwIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4E
# FgQU729TSunkBnx6yuKQVvYv1Ensy04wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5n
# P+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcG
# CCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQu
# Y29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGln
# aUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNV
# HSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIB
# ABfO+xaAHP4HPRF2cTC9vgvItTSmf83Qh8WIGjB/T8ObXAZz8OjuhUxjaaFdleMM
# 0lBryPTQM2qEJPe36zwbSI/mS83afsl3YTj+IQhQE7jU/kXjjytJgnn0hvrV6hqW
# Gd3rLAUt6vJy9lMDPjTLxLgXf9r5nWMQwr8Myb9rEVKChHyfpzee5kH0F8HABBgr
# 0UdqirZ7bowe9Vj2AIMD8liyrukZ2iA/wdG2th9y1IsA0QF8dTXqvcnTmpfeQh35
# k5zOCPmSNq1UH410ANVko43+Cdmu4y81hjajV/gxdEkMx1NKU4uHQcKfZxAvBAKq
# MVuqte69M9J6A47OvgRaPs+2ykgcGV00TYr2Lr3ty9qIijanrUR3anzEwlvzZiiy
# fTPjLbnFRsjsYg39OlV8cipDoq7+qNNjqFzeGxcytL5TTLL4ZaoBdqbhOhZ3ZRDU
# phPvSRmMThi0vw9vODRzW6AxnJll38F0cuJG7uEBYTptMSbhdhGQDpOXgpIUsWTj
# d6xpR6oaQf/DJbg3s6KCLPAlZ66RzIg9sC+NJpud/v4+7RWsWCiKi9EOLLHfMR2Z
# yJ/+xhCx9yHbxtl5TPau1j/1MIDpMPx0LckTetiSuEtQvLsNz3Qbp7wGWqbIiOWC
# nb5WqxL3/BAPvIXKUjPSxyZsq8WhbaM2tszWkPZPubdcMIIG7TCCBNWgAwIBAgIQ
# CoDvGEuN8QWC0cR2p5V0aDANBgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0
# ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMB4XDTI1
# MDYwNDAwMDAwMFoXDTM2MDkwMzIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNV
# BAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBTSEEyNTYgUlNB
# NDA5NiBUaW1lc3RhbXAgUmVzcG9uZGVyIDIwMjUgMTCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBANBGrC0Sxp7Q6q5gVrMrV7pvUf+GcAoB38o3zBlCMGMy
# qJnfFNZx+wvA69HFTBdwbHwBSOeLpvPnZ8ZN+vo8dE2/pPvOx/Vj8TchTySA2R4Q
# KpVD7dvNZh6wW2R6kSu9RJt/4QhguSssp3qome7MrxVyfQO9sMx6ZAWjFDYOzDi8
# SOhPUWlLnh00Cll8pjrUcCV3K3E0zz09ldQ//nBZZREr4h/GI6Dxb2UoyrN0ijtU
# DVHRXdmncOOMA3CoB/iUSROUINDT98oksouTMYFOnHoRh6+86Ltc5zjPKHW5KqCv
# pSduSwhwUmotuQhcg9tw2YD3w6ySSSu+3qU8DD+nigNJFmt6LAHvH3KSuNLoZLc1
# Hf2JNMVL4Q1OpbybpMe46YceNA0LfNsnqcnpJeItK/DhKbPxTTuGoX7wJNdoRORV
# bPR1VVnDuSeHVZlc4seAO+6d2sC26/PQPdP51ho1zBp+xUIZkpSFA8vWdoUoHLWn
# qWU3dCCyFG1roSrgHjSHlq8xymLnjCbSLZ49kPmk8iyyizNDIXj//cOgrY7rlRyT
# laCCfw7aSUROwnu7zER6EaJ+AliL7ojTdS5PWPsWeupWs7NpChUk555K096V1hE0
# yZIXe+giAwW00aHzrDchIc2bQhpp0IoKRR7YufAkprxMiXAJQ1XCmnCfgPf8+3mn
# AgMBAAGjggGVMIIBkTAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBTkO/zyMe39/dfz
# kXFjGVBDz2GM6DAfBgNVHSMEGDAWgBTvb1NK6eQGfHrK4pBW9i/USezLTjAOBgNV
# HQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwgZUGCCsGAQUFBwEB
# BIGIMIGFMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXQYI
# KwYBBQUHMAKGUWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRy
# dXN0ZWRHNFRpbWVTdGFtcGluZ1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNydDBfBgNV
# HR8EWDBWMFSgUqBQhk5odHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRU
# cnVzdGVkRzRUaW1lU3RhbXBpbmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcmwwIAYD
# VR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4IC
# AQBlKq3xHCcEua5gQezRCESeY0ByIfjk9iJP2zWLpQq1b4URGnwWBdEZD9gBq9fN
# aNmFj6Eh8/YmRDfxT7C0k8FUFqNh+tshgb4O6Lgjg8K8elC4+oWCqnU/ML9lFfim
# 8/9yJmZSe2F8AQ/UdKFOtj7YMTmqPO9mzskgiC3QYIUP2S3HQvHG1FDu+WUqW4da
# IqToXFE/JQ/EABgfZXLWU0ziTN6R3ygQBHMUBaB5bdrPbF6MRYs03h4obEMnxYOX
# 8VBRKe1uNnzQVTeLni2nHkX/QqvXnNb+YkDFkxUGtMTaiLR9wjxUxu2hECZpqyU1
# d0IbX6Wq8/gVutDojBIFeRlqAcuEVT0cKsb+zJNEsuEB7O7/cuvTQasnM9AWcIQf
# VjnzrvwiCZ85EE8LUkqRhoS3Y50OHgaY7T/lwd6UArb+BOVAkg2oOvol/DJgddJ3
# 5XTxfUlQ+8Hggt8l2Yv7roancJIFcbojBcxlRcGG0LIhp6GvReQGgMgYxQbV1S3C
# rWqZzBt1R9xJgKf47CdxVRd/ndUlQ05oxYy2zRWVFjF7mcr4C34Mj3ocCVccAvlK
# V9jEnstrniLvUxxVZE/rptb7IRE2lskKPIJgbaP5t2nGj/ULLi49xTcBZU8atufk
# +EMF/cWuiC7POGT75qaL6vdCvHlshtjdNXOCIUjsarfNZzGCBS0wggUpAgEBMFEw
# PTEWMBQGA1UECgwNUm9iZXJ0IEZhZGRlczEjMCEGA1UEAwwaRGF0dG9STU0uQ29y
# ZSBDb2RlIFNpZ25pbmcCEHjriJcd8jqCSwSQMNPKs2wwDQYJYIZIAWUDBAIBBQCg
# gYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0B
# CQQxIgQgVVcpl0xmsh3kye7kr4cPNPTqZn2SizwTZ9gvQsDa2GUwDQYJKoZIhvcN
# AQEBBQAEggEAOIKU1dN1rrtCnJAlj+MM3qxQGJlhbu2AYnEt2McWdXFJDklDjgV2
# 0Kt2GmMbhWYRtWZKQ6INcwtP4TnUAyg/QGFGsWahG7PtjyKYnxM1qy9Tk6s1cf70
# gaA34OgubdeqU7GEiY+NHqPTZiA/hhlhcVPyci/UzeM/6Ftvc5bWs9Mv5IBYnDl6
# mjQkA04fp+953PA/TIlJZsdWzGm3x04txeFiCAQaHf2/QRnUwd5sPdeIzPr8vhAe
# TcuaX4ueqPLdD/nA+NiGkNi465ruSz0QgP0mdAc31dwIjpzSn6T5boPSPFj5V3BU
# /7XJsHnPLMWuCzt2FZqSQ2EYIYN1WDHToqGCAyYwggMiBgkqhkiG9w0BCQYxggMT
# MIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5j
# LjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNB
# NDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUD
# BAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0yNjAzMzEwMDMwMzRaMC8GCSqGSIb3DQEJBDEiBCDUqVsSLa2+56wGwRRULO2z
# gX2382BTxgmiKsTk2BcFdTANBgkqhkiG9w0BAQEFAASCAgA55S9f0fb88p5M58C6
# b717nUN9/m7FFLvbVYqehxTwZcZVDgqfEV2GkGpiz7ThEc5OfqralI+7Kphn1DYC
# faw9FZEog165xpmV1HjW3ZfUDSC3N0OuoV2VaFgt5ZwYrexnFGBV3TJyD0Zjtpr1
# 0M/oxb32Li+qUszYMrQv2ALtJrWZf20aoI54cv1dvqzJXAaFVNqdbM4BUAIhGcM9
# z7rZMS4PmxFCVHIzvThu9HKzmN3Frc4FZyNtE7/3OK61EMw+/Rs1V1IyrgN11jqI
# Zd38hfGYaKtt1B1YVZyZFqNjcX/6z2DCkQT5Bdti5YtExxLbPWm7rDMxkrIImuia
# TA3I7uaNSaV6fhiWY3SqNNzeUlh+n7eZdGlAdNdAXkYGoydmaBk50vBSTny0rBcF
# azjTFSOxx6nCl1Kgoy8OmTJ2POVzqFdHDSbRnykfykXQ2IK+E988jO1wyMwxmYd0
# f0YP23XtvhKeCsukBUCctWagKZrf/EQfFYQ+DseaH4lCzIYk3clbayHmcc8XZaDu
# b1lHOzG6LVfyl5G8mW3e3szqt/5Sppqaw8pzRNco7MZuM061PBsuRMqEQhyWyYvp
# sjrIh81CHdugLB6+ypXK51DmMjEpEb0dF+FzTvv/mv2KOKA3cCyXZQr+7vPuAsyq
# 1len4mwz9dGxQke0R19/OBM57w==
# SIG # End signature block
