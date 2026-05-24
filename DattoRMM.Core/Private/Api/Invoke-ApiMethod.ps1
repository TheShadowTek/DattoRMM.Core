<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Invokes an API method, building the request parameters and handling authentication, and pagination as needed.
.DESCRIPTION
    This function constructs the necessary parameters for an API request, including authentication headers and query
    parameters. It checks for token expiration and refreshes the token if auto-refresh is enabled. It also supports 
    paginated requests by automatically fetching subsequent pages until all data is retrieved.

#>
function Invoke-ApiMethod {
    [CmdletBinding(DefaultParameterSetName = 'Default')]

    param (

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = 'Get',

        [hashtable]
        $Parameters,

        [object]
        $Body,

        # Enable pagination
        [Parameter(
            ParameterSetName = 'Paginate',
            Mandatory = $false
        )]
        [switch]
        $Paginate,

        # Name of the element in the response that contains the paginated items
        [Parameter(
            ParameterSetName = 'Paginate',
            Mandatory = $true
        )]
        [string]
        $PageElement
    )
    
    # Ensure we are connected and have a valid token before making the API call
    if (-not $script:RMMAuth) {

        throw "Not connected. Use Connect-DattoRMM first."

    }

    # Check token expiration with buffer (UTC comparison)
    # Refresh proactively before expiry to prevent mid-pagination failures
    $Now = [datetime]::UtcNow
    $RefreshThreshold = $script:RMMAuth.ExpiresAt.AddMinutes(-$Script:TokenRefreshBufferMinutes)

    if ($Now -gt $RefreshThreshold) {

        if ($script:RMMAuth.AutoRefresh) {

            # Refresh
            $RefreshConnectParams = @{
                Key = $script:RMMAuth.Key
                Secret = $script:RMMAuth.Secret
                AutoRefresh = $true
            }

            switch ($Script:RMMAuth.Keys) {

                'Proxy' {$RefreshConnectParams.Proxy = $script:RMMAuth.Proxy}
                'ProxyCredential' {$RefreshConnectParams.ProxyCredential = $script:RMMAuth.ProxyCredential}

            }

            Connect-DattoRMM @RefreshConnectParams

        } else {

            throw "Token expired. Reconnect with Connect-DattoRMM. Use -AutoRefresh to enable automatic token refresh."

        }
    }

    # Trim '/' and '?' from path if present to avoid double slashes in URI and issues with query parameters
    if ($Path.StartsWith('/')) {

        $Path = $Path.TrimStart('/')

    }

    if ($Path.EndsWith('?')) {

        $Path = $Path.TrimEnd('?')

    }

    # Build the request parameters for Invoke-RestMethod, including authentication headers and any query parameters
    $RequestParams = @{
        Uri = "$API/$Path"
        Method = $Method
        ContentType = 'application/json'
        Headers = $RMMAuth.AuthHeader
        TimeoutSec = $Script:ApiMethodRetry.TimeoutSeconds
    }

    # Add proxy settings if configured
    switch ($Script:RMMAuth.Keys) {

        'Proxy' {$RequestParams.Proxy = $script:RMMAuth.Proxy}
        'ProxyCredential' {$RequestParams.ProxyCredential = $script:RMMAuth.ProxyCredential}

    }

    if ($Parameters) {

        $QueryParams = @($Parameters.GetEnumerator() | ForEach-Object {"$($_.Key)=$($_.Value)"})
        $RequestParams.Uri += '?' + ($QueryParams -join '&')

    }

    # Add page size parameter for paginated requests
    if ($Paginate -and $Script:PageSize) {

        $PageSizeParam = "max=$($Script:PageSize)"

        if ($RequestParams.Uri -match '\?') {

            $RequestParams.Uri += "&$PageSizeParam"

        } else {

            $RequestParams.Uri += "?$PageSizeParam"

        }
    }

    if ($Body) {

        $RequestParams.Body = $Body | ConvertTo-Json -Depth 10
        $RequestParams.ContentType = 'application/json'

    }

    try {

        Write-Debug "Invoking RMM API: $Method $Path"
        Write-Debug "Uri: $($RequestParams.Uri)"

        # Classify the operation for multi-bucket throttle tracking
        $OperationName = Resolve-ThrottleOperationName -Path $Path -Method $Method

        if ($Paginate) {

            $Result = Invoke-ApiRestMethod -Parameters $RequestParams -Method $Method -OperationName $OperationName

            # Parse the original URI to extract query parameters (excluding max and page)
            $OriginalUri = [System.Uri]$RequestParams.Uri
            $OriginalParams = @{}
            
            if ($OriginalUri.Query) {

                $QueryString = $OriginalUri.Query.TrimStart('?')

                foreach ($Param in $QueryString.Split('&')) {

                    $KeyValue = $Param.Split('=')

                    if ($KeyValue.Count -eq 2 -and $KeyValue[0] -notin @('max', 'page')) {

                        $OriginalParams[$KeyValue[0]] = $KeyValue[1]

                    }
                }
            }

            $Result.$PageElement

            while ($Result.pageDetails.nextPageUrl) {

                $NextUrl = $Result.pageDetails.nextPageUrl

                # If we have original parameters, check which ones are missing from nextPageUrl - workaround for API not preserving all query params
                if ($OriginalParams.Count -gt 0) {

                    $NextUri = [System.Uri]$NextUrl
                    $ExistingParams = @()
                    
                    # Parse the nextPageUrl to see what parameters it already has
                    if ($NextUri.Query) {

                        $NextQueryString = $NextUri.Query.TrimStart('?')

                        foreach ($Param in $NextQueryString.Split('&')) {

                            $KeyValue = $Param.Split('=')

                            if ($KeyValue.Count -eq 2) {

                                $ExistingParams += $KeyValue[0]

                            }
                        }
                    }

                    # Only add parameters that are missing from the nextPageUrl
                    $MissingParams = $OriginalParams.GetEnumerator() | Where-Object { $_.Key -notin $ExistingParams }
                    
                    if ($MissingParams) {

                        $AdditionalParams = ($MissingParams | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '&'
                        
                        if ($NextUrl -match '\?') {

                            $NextUrl = "$NextUrl&$AdditionalParams"

                        } else {

                            $NextUrl = "$NextUrl?$AdditionalParams"
                            
                        }
                    }
                }

                Write-Debug "Fetching next page: $NextUrl"
                $RequestParams.Uri = $NextUrl
                $Result = Invoke-ApiRestMethod -Parameters $RequestParams -Method $Method -OperationName $OperationName
                $Result.$PageElement

            }

        } else {
            
            Invoke-ApiRestMethod -Parameters $RequestParams -Method $Method -OperationName $OperationName

        }

    } catch {

        throw $_

    }
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC81vS8yFrKIumT
# vvJCUTFU5LAn04THfDArsjcl82EOSKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHgxSd/RFESVsZ3CE8kjUZcgbyqH
# fijJDKdX55yb+KNSMA0GCSqGSIb3DQEBAQUABIIBAEK8zpXf85CqiqDrYmBmoYhr
# 2Z3GdjwApHf0lTrMQgsvMp0/u+xIEEmypKkTdF/+u3XSlFsdDPDqLC7o8p04xb8N
# guXTpwzpgCnjVBbwuu7kwAhScidxwUCndLM12uzj1cM+O5TG+jUxTTWyjg48wxyQ
# Srljg2qauEx3QL62RHVjUyzFHF6jIIOuGReaZUcIK2BRc8RQjJJf+L7+GVsQhLEa
# F3RjLAbDF6feblG1OW+cA2/3bhdYoAGPEnaMDkwJiffo1R8n7xRjTcyvOp0p27H+
# y8vMMWF6tjcWCjhpw+wzyuzQ7ZyVjK/12FSZR4EN1XZFWJNfjKky78aoZNu1Vlo=
# SIG # End signature block
