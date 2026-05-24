<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Request-ApiToken {
    <#
    .SYNOPSIS
        Requests a new API access token from the Datto RMM OAuth endpoint.

    .DESCRIPTION
        This internal function generates a new access token by making an OAuth password grant
        request to the Datto RMM API. It handles credential conversion, request construction,
        and secure cleanup of sensitive data.

    .PARAMETER Key
        The API key for authentication.

    .PARAMETER Secret
        The API secret as a SecureString.

    .PARAMETER APIUrl
        The base API URL for the target platform (e.g., https://pinotage-api.centrastage.net).

    .PARAMETER Proxy
        Optional proxy server URI for the request.

    .PARAMETER ProxyCredential
        Optional credentials for proxy authentication.

    .OUTPUTS
        PSCustomObject with properties: access_token, token_type, expires_in

    .NOTES
        This is an internal function used by Connect-DattoRMM. It automatically clears
        plaintext credentials from memory after use.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Key,

        [Parameter(Mandatory = $true)]
        [securestring]
        $Secret,

        [Parameter(Mandatory = $true)]
        [string]
        $APIUrl,

        [Parameter(Mandatory = $false)]
        [uri]
        $Proxy,

        [Parameter(Mandatory = $false)]
        [pscredential]
        $ProxyCredential
    )

    try {

        # Convert SecureString to plaintext
        $AuthSecret = ConvertFrom-SecureStringToPlaintext -SecureString $Secret

        # Build OAuth token request
        $PublicCredential = [PSCredential]::new('public-client', ('public' | ConvertTo-SecureString -AsPlainText -Force))
        $TokenRequest = @{
            Credential = $PublicCredential
            Uri = "$APIUrl/auth/oauth/token"
            Method = 'Post'
            Body = "grant_type=password&username=$Key&password=$AuthSecret"
            ContentType = 'application/x-www-form-urlencoded'
            TimeoutSec = $Script:ApiMethodRetry.TimeoutSeconds
        }


        switch ($PSBoundParameters.Keys) {

            'Proxy' {$TokenRequest.Proxy = $Proxy}
            'ProxyCredential' {$TokenRequest.ProxyCredential = $ProxyCredential}

        }

        # Make the request
        $Response = Invoke-RestMethod @TokenRequest
        Write-Verbose "Successfully authenticated to Datto RMM API."

        return $Response

    } catch {

        throw $_

    } finally {

        # Clear plaintext credentials from memory
        $AuthSecret = $null

    }
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAnLdrrzQ6YzVcL
# DHZXgLgE7/dpYTnqSBQXuSZfXQ1gG6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIN79sTVNHyqy6EEK/OGzqnmB+bRB
# R8FMgbp86EPTAtqDMA0GCSqGSIb3DQEBAQUABIIBAAal2RW6abZ7Etd+Nm2fhI8Z
# QSA5duIIm/pod6jD3qbQSwDj8LURuWP9FXuCNBeSAUHZ8LCqAKcyXWhTvYfHF2Jq
# opAfn4oGL96ONAwywD18Oq0QALe9VFWoiPCQMQ+vVS6xGr++bl5Nw49qXtrTyx7a
# DHJLjuLjudqbNLzSce4txIadgCxfuyRsqgfwKoXX8O1xEiA9BtxbISeNSkcalxhP
# rmeRiOxmlJILLCgok7UJh+8KpeEGWbFWtP1ZnKf+LjnnWoiwoqw4NP3pFUZnMePn
# Sbx0LcB8U9GOQKPgxY0Yrvb0LaNuWPrEHT2E1nOUlZvC7uq5rkXCI7/sNOUTbZQ=
# SIG # End signature block
