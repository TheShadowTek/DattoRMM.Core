<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMThrottleStatus {
    <#
    .SYNOPSIS
        Retrieves a detailed snapshot of the current API rate limits, counts, and local throttle state.

    .DESCRIPTION
        The Get-RMMThrottleStatus function provides a combined view of the Datto RMM API rate-status
        endpoint data and the local sliding-window throttle model. It calls the rate-status API to
        fetch fresh read and write counts, limits, and per-operation bucket status, then merges
        this with the local throttle tracking state (timestamps, utilisation, flags, thresholds).

        The Datto RMM API tracks reads and writes as independent quotas:
        - accountCount / accountRateLimit   → read (GET) operations only
        - accountWriteCount / accountWriteRateLimit → write (PUT/POST/DELETE) operations only

        The returned DRMMThrottleStatus object includes:
        - Active throttle profile and configured thresholds
        - Independent read and write utilisation (both API-reported and locally tracked)
        - Throttle and pause flags reflecting the current state before drift adjustment
        - Independent read and write delay values in milliseconds
        - Calibration metadata for both read and write tracks
        - A Buckets collection of DRMMThrottleBucket objects covering the read bucket,
          write bucket, and all per-operation write buckets (both mapped and unidentified)

        Each bucket reports its Type (Read, Write, or Operation), Name, Limit, ApiCount,
        LocalCount, and computed Utilisation ratio.

        This function is designed for monitoring, diagnostics, and sample capture during long-running
        load tests. It does not modify any throttle state. For the raw API response without local
        enrichment, use Get-RMMRequestRate instead.

    .EXAMPLE
        Get-RMMThrottleStatus

        Retrieves the current combined throttle status snapshot.

    .EXAMPLE
        $Status = Get-RMMThrottleStatus
        PS > $Status.GetSummary()

        Retrieves throttle status and displays a summary of utilisation, flags, and delay.

    .EXAMPLE
        Get-RMMThrottleStatus | Select-Object -ExpandProperty Buckets | Format-Table

        Retrieves throttle status and displays all rate-limit buckets in a table.

    .EXAMPLE
        (Get-RMMThrottleStatus).Buckets | Where-Object Type -eq 'Operation' | Sort-Object Utilisation -Descending

        Retrieves and filters only per-operation buckets, sorted by utilisation.

    .EXAMPLE
        $Status = Get-RMMThrottleStatus
        PS > $Status.Buckets | Where-Object {$_.Utilisation -gt 0}

        Shows only buckets with active utilisation for quick load test monitoring.

    .INPUTS
        None. You cannot pipe objects to Get-RMMThrottleStatus.

    .OUTPUTS
        DRMMThrottleStatus. Returns a throttle status object with the following properties:
        - Profile (string): Active throttle profile name
        - AccountUid (string): Account unique identifier from the API
        - WindowSizeSeconds (int): Rolling window size in seconds
        - ReadUtilisation (double): Read utilisation ratio (higher of API or local)
        - WriteUtilisation (double): Write utilisation ratio (higher of API or local)
        - AccountCutOffRatio (double): API-reported account cut-off ratio
        - ThrottleUtilisationThreshold (double): Configured threshold at which throttling activates
        - PauseThreshold (double): Computed threshold at which hard pause activates
        - Throttle (bool): Whether soft throttling is currently active
        - Pause (bool): Whether hard pause is currently active
        - ReadDelayMs (double): Current computed read delay in milliseconds
        - WriteDelayMs (double): Current computed write delay in milliseconds
        - DelayMultiplier (double): Configured read delay multiplier
        - WriteDelayMultiplier (double): Configured write delay multiplier
        - ReadLastCalibrationUtc (datetime): UTC time of the last read calibration
        - WriteLastCalibrationUtc (datetime): UTC time of the last write calibration
        - ReadSamplesAtLastCalibration (int): Local read samples at last calibration
        - WriteSamplesAtLastCalibration (int): Local write samples at last calibration
        - Buckets (DRMMThrottleBucket[]): Collection of all tracked rate-limit buckets

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        This function calls the rate-status API endpoint to fetch fresh data, which itself
        counts as a read request against the account rate limit.

        The throttle state reported is a pre-drift-adjustment snapshot. The actual throttle
        engine may adjust utilisation values during calibration cycles.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMThrottleStatus.md

    .LINK
        Get-RMMRequestRate

    .LINK
        Connect-DattoRMM

    .LINK
        about_DattoRMM.CoreThrottling

    .LINK
        about_DRMMThrottleStatus
    #>

    [CmdletBinding()]
    param ()

    process {

        # Fetch fresh rate-status from the API
        $RateInfo = Invoke-ApiMethod -Path 'system/request_rate' -Method GET

        Write-Debug "ThrottleStatus: API returned Read=$($RateInfo.accountCount)/$($RateInfo.accountRateLimit), Write=$($RateInfo.accountWriteCount)/$($RateInfo.accountWriteRateLimit)"

        # --- Build the result object ---
        $Result = [DRMMThrottleStatus]::new()
        $Result.Profile = $Script:RMMThrottle.Profile
        $Result.AccountUid = $RateInfo.accountUid
        $Result.WindowSizeSeconds = $RateInfo.slidingTimeWindowSizeSeconds
        $Result.AccountCutOffRatio = $RateInfo.accountCutOffRatio
        $Result.ThrottleUtilisationThreshold = $Script:RMMThrottle.ThrottleUtilisationThreshold
        $Result.PauseThreshold = $RateInfo.accountCutOffRatio - $Script:RMMThrottle.ThrottleCutOffOverhead
        $Result.DelayMultiplier = $Script:RMMThrottle.DelayMultiplier
        $Result.WriteDelayMultiplier = $Script:RMMThrottle.WriteDelayMultiplier
        $Result.ReadLastCalibrationUtc = $Script:RMMThrottle.ReadLastCalibrationUtc
        $Result.WriteLastCalibrationUtc = $Script:RMMThrottle.WriteLastCalibrationUtc
        $Result.ReadSamplesAtLastCalibration = $Script:RMMThrottle.ReadSamplesAtLastCalibration
        $Result.WriteSamplesAtLastCalibration = $Script:RMMThrottle.WriteSamplesAtLastCalibration

        # --- Compute utilisation from both sources (same logic as Update-Throttle, pre-drift) ---
        $ApiReadUtil = $RateInfo.accountCount / [math]::Max($RateInfo.accountRateLimit, 1)
        $LocalReadUtil = $Script:RMMThrottle.ReadLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.ReadLimit, 1)
        $Result.ReadUtilisation = [math]::Max($ApiReadUtil, $LocalReadUtil)

        $ApiWriteUtil = 0.0
        $LocalWriteUtil = 0.0

        if ($RateInfo.accountWriteRateLimit -gt 0) {

            $ApiWriteUtil = $RateInfo.accountWriteCount / [math]::Max($RateInfo.accountWriteRateLimit, 1)
            $LocalWriteUtil = $Script:RMMThrottle.WriteLocalTimestamps.Count / [math]::Max($Script:RMMThrottle.WriteLimit, 1)

        }

        $Result.WriteUtilisation = [math]::Max($ApiWriteUtil, $LocalWriteUtil)

        # --- Compute flags and delays (mirrors Update-Throttle logic, pre-adjustment) ---
        $ReadThrottle = ($Result.ReadUtilisation -ge $Script:RMMThrottle.ThrottleUtilisationThreshold)
        $WriteThrottle = ($Result.WriteUtilisation -ge $Script:RMMThrottle.ThrottleUtilisationThreshold)
        $Result.Throttle = ($ReadThrottle -or $WriteThrottle)
        $Result.Pause = ($Result.ReadUtilisation -ge $Result.PauseThreshold) -or ($Result.WriteUtilisation -ge $Result.PauseThreshold)

        if ($ReadThrottle) {

            $Result.ReadDelayMs = $Result.ReadUtilisation * $Script:RMMThrottle.DelayMultiplier

        } else {

            $Result.ReadDelayMs = 0

        }

        if ($WriteThrottle) {

            $Result.WriteDelayMs = $Result.WriteUtilisation * $Script:RMMThrottle.WriteDelayMultiplier

        } else {

            $Result.WriteDelayMs = 0

        }

        # --- Build bucket collection ---
        $BucketList = [System.Collections.Generic.List[DRMMThrottleBucket]]::new()

        # Read bucket
        $ReadBucket = [DRMMThrottleBucket]::new()
        $ReadBucket.Type = 'Read'
        $ReadBucket.Name = 'Read'
        $ReadBucket.Limit = $RateInfo.accountRateLimit
        $ReadBucket.ApiCount = $RateInfo.accountCount
        $ReadBucket.LocalCount = $Script:RMMThrottle.ReadLocalTimestamps.Count
        $ReadBucket.Utilisation = $Result.ReadUtilisation
        $BucketList.Add($ReadBucket)

        # Write bucket
        $WriteBucket = [DRMMThrottleBucket]::new()
        $WriteBucket.Type = 'Write'
        $WriteBucket.Name = 'Write'
        $WriteBucket.Limit = $RateInfo.accountWriteRateLimit
        $WriteBucket.ApiCount = $RateInfo.accountWriteCount
        $WriteBucket.LocalCount = $Script:RMMThrottle.WriteLocalTimestamps.Count
        $WriteBucket.Utilisation = $Result.WriteUtilisation
        $BucketList.Add($WriteBucket)

        # Per-operation write buckets from API response
        if ($null -ne $RateInfo.operationWriteStatus) {

            $RateInfo.operationWriteStatus.PSObject.Properties | ForEach-Object {

                $OpName = $_.Name
                $OpBucket = [DRMMThrottleBucket]::new()
                $OpBucket.Type = 'Operation'
                $OpBucket.Name = $OpName
                $OpBucket.Limit = $_.Value.limit
                $OpBucket.ApiCount = $_.Value.count

                # Merge local tracking if bucket exists locally
                if ($Script:RMMThrottle.OperationBuckets.ContainsKey($OpName)) {

                    $OpBucket.LocalCount = $Script:RMMThrottle.OperationBuckets[$OpName].LocalTimestamps.Count

                } else {

                    $OpBucket.LocalCount = 0

                }

                # Utilisation is higher of API or local
                $ApiOpUtil = $OpBucket.ApiCount / [math]::Max($OpBucket.Limit, 1)
                $LocalOpUtil = $OpBucket.LocalCount / [math]::Max($OpBucket.Limit, 1)
                $OpBucket.Utilisation = [math]::Max($ApiOpUtil, $LocalOpUtil)

                $BucketList.Add($OpBucket)

            }
        }

        # Include any locally tracked operation buckets not present in the API response
        if ($Script:RMMThrottle.OperationBuckets -and $Script:RMMThrottle.OperationBuckets.Count -gt 0) {

            $ApiOpNames = @()

            if ($null -ne $RateInfo.operationWriteStatus) {

                $ApiOpNames = @($RateInfo.operationWriteStatus.PSObject.Properties.Name)

            }

            $Script:RMMThrottle.OperationBuckets.GetEnumerator() | ForEach-Object {

                if ($_.Key -notin $ApiOpNames) {

                    $UnmappedBucket = [DRMMThrottleBucket]::new()
                    $UnmappedBucket.Type = 'Operation'
                    $UnmappedBucket.Name = $_.Key
                    $UnmappedBucket.Limit = $_.Value.Limit
                    $UnmappedBucket.ApiCount = 0
                    $UnmappedBucket.LocalCount = $_.Value.LocalTimestamps.Count
                    $UnmappedBucket.Utilisation = $UnmappedBucket.LocalCount / [math]::Max($UnmappedBucket.Limit, 1)

                    $BucketList.Add($UnmappedBucket)

                }
            }
        }

        $Result.Buckets = $BucketList.ToArray()

        Write-Debug "ThrottleStatus: Built $($Result.Buckets.Count) buckets — Read=$([math]::Round($Result.ReadUtilisation * 100, 2))%, Write=$([math]::Round($Result.WriteUtilisation * 100, 2))%, Throttle=$($Result.Throttle), Pause=$($Result.Pause)"

        $Result

    }
}

# SIG # Begin signature block
# MIIcXwYJKoZIhvcNAQcCoIIcUDCCHEwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBZ5s++OI6bNNsP
# 8Zm8v2E/HHslKLDQzpIan+33jGnHE6CCFogwggNKMIICMqADAgECAhB464iXHfI6
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
# CQQxIgQg2CpD19OLYaECbY1mkMFouzL/T8DANtc/DozXUkyt1VkwDQYJKoZIhvcN
# AQEBBQAEggEAQzL3L2Ishq/JerXkB54A6cYJ/rsqC+NcHyxonHoGX6v9wdu5eEDu
# bs2CHvYJw9ZcwKwkbCZd48m63+r+YhwhKm9DHXQrmjj6bVHGAQXmStZcdFLg66FS
# wk8FtKZDxHlYwiPK1/F3HiGPSn5dXt0N7U+eJ4M0YugHPZYbcS66dlnCMt1DkMeC
# PJHRfKxgso1A4yrhguKPPkzprdoEM2FTpYeCfMebAv/oWKjqwAtrM3ymdoPUAy0m
# bEChQqX5DxHMyKgyjs6j7zPchnF5Ss/RFXjRZnuPNQXDPzx9vrt608HkYkYM8TCw
# MiCSL79FlTz0IsQmjVj+X2XbUkLsP/c3l6GCAyYwggMiBgkqhkiG9w0BCQYxggMT
# MIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5j
# LjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNB
# NDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUD
# BAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0yNjAzMzEwMDMwMjlaMC8GCSqGSIb3DQEJBDEiBCBxSW1W5nW6NRvd5uRONnwN
# 5kiNP3rofAeqIfOQBvSdVjANBgkqhkiG9w0BAQEFAASCAgCv+r0oPxsnPYo3FZ/d
# GuZNt0bn7qVUCAbujugFBpG/S4p+1fdU7RPQCBRl16gHe4rQeylaPYQ0Uo8YixkG
# yzLuvAcJdK5cpbdjcfD9I4f+wK1SnvReWZOYdju7wN3tqU6ecM94Z80cMihSgdXt
# zvbRokNBrFVwMkyw8dPP6uFvN30ePNzyhPf7kyKzGxO9YHtKuZH9Mo41pLCt6Px3
# 7DOcVVERT76XO96ycayIW7uQulDAqmh8iLO2nsioNkBXeZgpBtUdNV/rwUa+uZwb
# vHz1bwrgVSraShpCD5PA32XptyEanb2+VWZxRGu+VbmdSIpmxZc7AAUNnyBaRxP9
# cqLg59yi9ssezUWkzDuH8Vif9tP33zZXTP9iewrMKiu297l47s1Aa6ALW3FM5/4m
# az3bRZm3oA7OjDKj/F2OzXIct2cZs0JLDDZ+0ayHsoNoo58n7PB/AcvxwKvcHOj3
# 2AJrqx8MRx49uhMO0nUi6vM5rNxMWnn5rwne4Wmq3Ng53njVBNYbhDBMJ15xd2V4
# GGwpNvUgwbl82pJQwHGXgfAAiiFtjAgE1+BYvdAc2P4rliPzJFVJsCwkAWVWdvW0
# Qm70WasBz3efu6rcLhvX9yKh8n0hy/As8WdzZWTSziQWdgMYq4Z527Fv3ONFiN+N
# n5Wy0FBAvTMrQ72y+fUerRTAtg==
# SIG # End signature block
