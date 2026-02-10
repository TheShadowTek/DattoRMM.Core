<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Invokes an API method with built-in retry logic and error handling.
.DESCRIPTION
    This function wraps the Invoke-RestMethod cmdlet with additional logic to handle retries, throttling, and error handling. It checks the API throttle status before making the request and retries the request based on configurable parameters if certain errors occur.
#>
function Invoke-APIRestMethod {
    [CmdletBinding()]
    param(
        [hashtable]
        $Parameters
    )

    $Attempt      = 0
    $Success      = $false
    $LastError    = $null

    # Retry loop
    while (-not $Success -and $Attempt -le $Script:APIMethodRetry.MaxRetries) {

        # Check API throttle status and apply any necessary delays before making the API call
        try {

             Invoke-APIThrottle -ErrorAction Stop

        } catch {

            throw "Failed to check API throttle status. Error: $_"

        }

        try {

            $Response = Invoke-RestMethod @Parameters -ErrorAction Stop
            $Success  = $true

        } catch {

            $Attempt++
            $LastError = $_
            $StatusCode = $LastError.Exception.Response.StatusCode.value__
            
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

                    # Terminating condition no retry
                    $Generic = "Authorization failed. Please check your credentials."
                    $ShouldRetry = $false

                }

                403 {

                    # Terminating condition no retry
                    $Generic = "Access denied. You do not have permission to access this resource."
                    $ShouldRetry = $false

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

                    if ($Attempt -lt $Script:APIMethodRetry.MaxRetries) {

                        $ShouldRetry = $true

                    } else {

                        Write-Warning "$Generic`nAPI Response: $ApiMessage"
                        return $null

                    }
                }

                429 {

                    # Non-terminating condition after max retries
                    $Generic = "Rate limit exceeded. Too many requests have been made in a short period."
                    
                    # Hardcoded 429 2 minute wait in addition to retry interval
                    Write-Warning "Rate limit exceeded. Waiting 2 minutes before retrying @ $((Get-Date).AddSeconds(120).ToString("HH:mm:ss"))..."
                    Start-Sleep -Seconds 120
                    $ShouldRetry = $true

                }

                default {

                    # Non-terminating condition after max retries - uncertain if this should be terminating
                    $Generic = "Unexpected error occurred."
                    $ShouldRetry = $true

                    if ($Attempt -lt $Script:APIMethodRetry.MaxRetries) {

                        $ShouldRetry = $true

                    } else {

                        Write-Warning "$Generic`nAPI Response: $ApiMessage"
                        return $null

                    }
                }
            }


            if ($ShouldRetry -and $Attempt -le $Script:APIMethodRetry.MaxRetries) {

                Write-Warning "Retry in $($Script:APIMethodRetry.RetryIntervalSeconds) seconds. Attempt $Attempt of $($Script:APIMethodRetry.MaxRetries)..."
                Start-Sleep -Seconds $Script:APIMethodRetry.RetryIntervalSeconds

            } else {

                break

            }
        }
    }

    if ($Success) {

        return $Response

    } else {

        throw "Failed to invoke API method after $($Script:APIMethodRetry.MaxRetries) attempts. Last error: $($LastError.Exception.Message)"

    }
}
