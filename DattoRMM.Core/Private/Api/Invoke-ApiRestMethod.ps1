<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Invokes an API method with built-in retry logic, multi-bucket throttling, and error handling.
.DESCRIPTION
    This function wraps Invoke-RestMethod with retry logic, multi-bucket throttle gating, and request
    recording. Before each attempt, the request is evaluated against global account, global write, and
    per-operation write buckets. After a successful response, the request is recorded in the local
    sliding-window counters for accurate utilisation tracking between calibrations.
#>
function Invoke-ApiRestMethod {
    [CmdletBinding()]
    param(

        [hashtable]
        $Parameters,

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = 'Get',

        [string]
        $OperationName
    )

    $Attempt = 0
    $Success = $false
    $LastError = $null
    $TokenRefreshAttempted = $false

    # Retry loop
    while (-not $Success -and $Attempt -le $Script:ApiMethodRetry.MaxRetries) {

        # Check API throttle status and apply any necessary delays before making the API call
        try {

             Invoke-ApiThrottle -Method $Method -OperationName $OperationName -ErrorAction Stop

        } catch {

            throw "Failed to check API throttle status. Error: $_"

        }

        try {

            $Response = Invoke-RestMethod @Parameters -ErrorAction Stop
            $Success  = $true

            # Record successful request in local sliding-window counters
            Add-ThrottleRequest -Method $Method -OperationName $OperationName

        } catch {

            $Attempt++
            $LastError = $_
            $StatusCode = $LastError.Exception.Response.StatusCode.value__

            # Record the request if it reached the server — any HTTP status code means quota was consumed
            # regardless of whether the response was a success or an error
            if ($StatusCode) {

                Add-ThrottleRequest -Method $Method -OperationName $OperationName

            }

            # Try to get the actual API error message from the response body
            if ($LastError.ErrorDetails.Message) {

                $ApiMessage = $LastError.ErrorDetails.Message

            } else {

                $ApiMessage = $LastError.Exception.Response.StatusDescription

            }

            # Determine if we should retry based on status code, with generic messages, and termination conditions - based on documented API behaviour
            switch ($StatusCode) {

                500 {

                    # Terminating condition after max retries
                    $Generic = "Internal server error. Please try again later or contact support."
                    $ShouldRetry = $true

                }

                400 {

                    # Non-terminating condition no retry
                    $Generic = "Invalid request. Please check your parameters and data."
                    Write-Warning "$Generic`nAPI Response: $ApiMessage"
                    return $null

                }

                401 {

                    # Reactive token refresh — safety net for mid-request expiry (e.g., during long pagination runs)
                    if (-not $TokenRefreshAttempted -and $script:RMMAuth.AutoRefresh) {

                        Write-Verbose "Received 401. Attempting token refresh before failing."
                        $TokenRefreshAttempted = $true

                        $RefreshConnectParams = @{
                            Key = $script:RMMAuth.Key
                            Secret = $script:RMMAuth.Secret
                            AutoRefresh = $true
                        }

                        switch ($Script:RMMAuth.Keys) {

                            'Proxy' {$RefreshConnectParams.Proxy = $script:RMMAuth.Proxy}
                            'ProxyCredential' {$RefreshConnectParams.ProxyCredential = $script:RMMAuth.ProxyCredential}

                        }

                        try {

                            Connect-DattoRMM @RefreshConnectParams
                            $Parameters.Headers = $script:RMMAuth.AuthHeader
                            $Attempt--
                            $ShouldRetry = $true

                        } catch {

                            Write-Warning "Authorization failed. Token refresh also failed.`nRefresh error: $($_.Exception.Message)"
                            $ShouldRetry = $false

                        }

                    } else {

                        # Terminating condition no retry
                        $Generic = "Authorization failed. Please check your credentials."
                        $ShouldRetry = $false

                    }
                }

                403 {

                    # Terminating condition no retry — throw immediately with clear context
                    $Generic = "Access denied. You do not have permission to access this resource."
                    throw "$Generic`nAPI Response: $ApiMessage"

                }

                404 {
                    
                    # Non-terminating condition no retry
                    $Generic = "Resource not found. Please check the resource identifier."
                    Write-Warning "$Generic`nAPI Response: $ApiMessage"
                    return $null

                }

                409 {

                    # Non-terminating condition after max retries
                    $Generic = "Conflict detected. The resource is being modified elsewhere or there is a data conflict."

                    if ($Attempt -le $Script:ApiMethodRetry.MaxRetries) {

                        $ShouldRetry = $true

                    } else {

                        Write-Warning "$Generic`nAPI Response: $ApiMessage"
                        return $null

                    }
                }

                429 {

                    # Non-terminating condition after max retries
                    # 120s backoff is intentional protection against unexpected external factors and uncontrolled workflows
                    $Generic = "Rate limit exceeded. Too many requests have been made in a short period."

                    if ($OperationName) {

                        Write-Warning "Rate limit exceeded on operation '$OperationName'. Waiting 2 minutes before retrying @ $((Get-Date).AddSeconds(120).ToString("HH:mm:ss"))..."

                    } else {

                        Write-Warning "Rate limit exceeded. Waiting 2 minutes before retrying @ $((Get-Date).AddSeconds(120).ToString("HH:mm:ss"))..."

                    }

                    Start-Sleep -Seconds 120
                    Update-Throttle
                    $ShouldRetry = $true

                }

                default {

                    # Non-terminating condition after max retries - uncertain if this should be terminating
                    $Generic = "Unexpected error occurred."

                    if ($Attempt -lt $Script:ApiMethodRetry.MaxRetries) {

                        $ShouldRetry = $true

                    } else {

                        Write-Warning "$Generic`nAPI Response: $ApiMessage"
                        return $null

                    }
                }
            }

            if ($ShouldRetry -and $Attempt -le $Script:ApiMethodRetry.MaxRetries) {

                Write-Warning "Retry in $($Script:ApiMethodRetry.RetryIntervalSeconds) seconds. Attempt $Attempt of $($Script:ApiMethodRetry.MaxRetries)..."
                Start-Sleep -Seconds $Script:ApiMethodRetry.RetryIntervalSeconds

            } else {

                break

            }
        }
    }

    if ($Success) {

        return $Response

    } else {

        throw "Failed to invoke API method after $($Script:ApiMethodRetry.MaxRetries) attempts. Last error: $($LastError.Exception.Message)"

    }
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAAFiNj0Y3AUNwJ
# IIs/iBCEh/eU65LXYreRqja3znva7aCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEID7MUy+f1iAfhAL6MVLxCtpu44Fi
# ldCA0v08JQFvnrobMA0GCSqGSIb3DQEBAQUABIIBAAdP9spcLbVkXQlSC+7oNK6N
# jmOt1tcp9eQwe/pxDDQpE8M3LDPQD1d9chzH4S/TSy7CeqpcFW9/te3o5rpEhGw8
# zsz7v3inV3Fo0sPeNODXN8XyJCO2e4sysZIHt4U7/0jqKVNszLR+p5XNa9482AZ8
# CiMTKTAZoeqZM51tslm4FBhAuBJtyM1hbl5KnvMIwY3va1oghbDu05WGfnREObNW
# ObdEuzCnYhKHhaeJn2HoQTmazNxjYaK+p65jYX4FA3dfCExsGJsWX9u9/M/x6cgv
# 9R3IRS9KBDTI358CalVajlPopMTONyDToLMmCuK0o+cbRpbn3jnM5xDtda4C9Tw=
# SIG # End signature block
