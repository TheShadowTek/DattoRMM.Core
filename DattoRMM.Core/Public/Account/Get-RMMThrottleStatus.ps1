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
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBZ5s++OI6bNNsP
# 8Zm8v2E/HHslKLDQzpIan+33jGnHE6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINgqQ9fTi2GhAm2NZpDBaLsy/0/A
# wDbXPw6M11JMrdVZMA0GCSqGSIb3DQEBAQUABIIBAEMy9y9iLIavyXq15AeeAOnG
# Cf67KgvjXB8saJx6Bl+r/cHbuXhA7m7Ngh72CcPWXMCsJGwmXePJut/q/mIcISpv
# Qx10K5o4+m1RxgEF5krWXHRS4OuhUsJPBbSmQ8R5WMIjytfxdx4hj0p+XV7dDe1P
# nieDNGLoBz2WG3EuunZZwjLdQ5DHgjyR0XysYLKNQOMq4YLijz5M6a3aBDNhU6WH
# gnzHmwL/6Fio6sALazN8pnaD1AMtJmxAoUKl+Q8RzMioMo7Oo+8z3IZxeUrP0RV4
# 0WZ7jzUFwz88fb67etPB5GJGDPEwsDIgki+/RZU89CLEJo1Y/l9l21JC7D/3N5c=
# SIG # End signature block
