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
# MIIcXwYJKoZIhvcNAQcCoIIcUDCCHEwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCM3kILN4gHGlpY
# Xdk0uC/mVH9gJrAIeYFEl713gl5PiKCCFogwggNKMIICMqADAgECAhB464iXHfI6
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
# CQQxIgQgKPH6hQ2lWnLeHHP9Z1bp7EuNh70j2CH4m45/dsdJL5UwDQYJKoZIhvcN
# AQEBBQAEggEAdyt3jYWW6csmqbmJT9UtsdJEMJPiKWZgByHv1BoecG9jC25ZeYiB
# tiedTuGQPPKLGhOw0XHot9WnNzuleDQdoGaNw4DWLKdbJYhy2T8RWmkg/Intr0S7
# C3uqOEvl1xffY/KQ8A0M4JD4L6XupLGgfWBV0qFKlnRg4s9qHzu26GZmbTxtMwxS
# s48wAatDSjQzjmeWU0hk71zq9mrsx1nGD1Dwk/Uw5/GrVa/o8aThGJJmL5r9FlaF
# mJ2ju0maMe/C3Fn4EJOhX0s6HFJqHq3uSvCdVTM/iNN199Mm8+2xjJfeUW/ooMJA
# ME0NWHjfr3QgwK38Yh/RTYDD5Oh04qHFnqGCAyYwggMiBgkqhkiG9w0BCQYxggMT
# MIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5j
# LjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNB
# NDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUD
# BAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0yNjAzMzEwMDMwMjJaMC8GCSqGSIb3DQEJBDEiBCDxIhBJ/efPN9NgmYHj8RYo
# KIAMk0v6EaqoBqMx33WByTANBgkqhkiG9w0BAQEFAASCAgA15Z5MltKMG0ji9xQB
# Q6t5+bvq0A1qxIQXgKxcJnuxipGqIGGno5CLJCHync4FZYms96qUepCE0LM1kt2H
# ONbWRt/PILvbCtI7CIG+p1s2RtVhnBnTlgYzr8fhepgE6fydGLldlqOOgfOIDTJx
# P7OvWWVShyu0O2u4lCBpQmDKd/gH26lrwidCuk+5ckf2Fq1or7pp2O4NdB4gzh6s
# K/OMGmR7SyWutIGsNMYsvnKk2h9OPw51ak05p6l5ciMQ8OY/uuXruawD271ZjYRN
# NPb5nEbw8IhoNdAPecKKlTaxKCUgeE9dw1quPIGEgfFQKD27i30Kxg5Yoh733ZcJ
# 5sk2jYcHWailBy09ntPZ01uFsh2VrGrUA5tqG56mENqD9iMS4j0Ev6U48hcMKFCk
# w7ngjRdRVXGFML1lzT+62YhfgwbtiSpajwPX6NQKMjArJFDWvwaCX96lhavSiFp7
# Mh813F62zdtbeMvcZh+oVxW/UB3Z6ErCDp81IUN8GYzGIiHZ9geG0Z4VtBWvzGgf
# x7VbIa3TzGH2ar2duSR7e0XWASAFG6XxGu7br7L6lEQB8XA7tgNFWf5ej9PRgYjf
# tegpaGA7QxNz+fr4E6fPcCQlqfryFEWzmnAaTFoQgq4/7eakzT/+MR6z+0Av60ky
# F0u9GzEpXPHNjJlV38TDgPEsxA==
# SIG # End signature block
