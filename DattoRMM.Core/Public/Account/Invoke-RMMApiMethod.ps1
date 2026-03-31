<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Invoke-RMMApiMethod {
    <#
    .SYNOPSIS
        Invokes an arbitrary Datto RMM API endpoint and returns the untyped response as a PSObject.

    .DESCRIPTION
        The Invoke-RMMApiMethod function is a generic wrapper for calling any Datto RMM API v2
        endpoint. It handles authentication, token refresh, proxy configuration, retry logic, and
        optional pagination — the same infrastructure used by all other module functions — but
        returns the response as an untyped PSObject without mapping it to a module class.

        Because the module uses Invoke-RestMethod internally, the JSON response from the API is
        automatically deserialised into PowerShell objects. The returned data is not raw JSON —
        it is a fully usable PSObject hierarchy. If you need to inspect the raw JSON payload,
        use a dedicated API tool such as Postman (usage of which is outside the scope of this
        module).

        This function is useful when:
        - You need to call a new or undocumented API endpoint that is not yet wrapped by
          a dedicated module function.
        - You want to inspect the untyped response structure returned by the API for debugging
          or exploration.
        - You are testing or prototyping against the API before a typed function is available.

        The Path parameter is the relative API path appended to the base URL (e.g.
        https://<region>.centrastage.net/api/v2). You do not need to include the base URL
        or the /api/v2 prefix — only the path segment that follows it.

    .PARAMETER Path
        The relative API path to call, appended after /api/v2/.

        Do not include the base URL or the /api/v2 prefix. Only provide the path segment
        that follows it.

        Examples of valid Path values:
        - 'account'                        → GET /api/v2/account
        - 'account/users'                  → paginated user list
        - 'device/abc-123-uid'             → single device by UID
        - 'site/abc-123-uid/settings'      → site settings

    .PARAMETER Method
        The HTTP method to use for the request. Defaults to Get.

        Accepted values are those supported by System.Net.Http.HttpMethod:
        Get, Post, Put, Patch, Delete, Head, Options, Trace.

        Typical usage:
        - Get      Retrieve data (default)
        - Post     Create or update a resource
        - Put      Create or replace a resource
        - Patch    Partial update of a resource
        - Delete   Remove a resource

    .PARAMETER Parameters
        A hashtable of query string parameters to append to the request URL. Each key must
        match a query parameter name defined by the API endpoint being called.

        Each key-value pair is converted to a URL query parameter and appended automatically.
        Do not include query parameters in the Path — use this parameter instead.

        The exact parameters available depend on the endpoint. Refer to the Datto RMM API
        documentation for the supported query parameters on each path. Common examples:

        - filterId         Filter devices by a filter ID (long)
        - hostname         Filter devices by hostname (partial match)
        - deviceType       Filter devices by device type (partial match)
        - operatingSystem  Filter devices by OS (partial match)
        - siteName         Filter devices/sites by site name (partial match)
        - page             Retrieve a specific page of results (int)

        Note: All paginated endpoints accept a 'page' parameter. The module's typed public
        functions always retrieve all pages automatically. This function allows you to request
        a specific page via Parameters if needed (e.g. @{page = 2}).

    .PARAMETER Body
        An object or hashtable to send as the JSON request body. Applies to Post, Put, and
        Patch requests.

        The value is automatically serialised to JSON via ConvertTo-Json before being sent.
        Pass native PowerShell objects or hashtables — do not pre-serialise to a JSON string.

    .PARAMETER Paginate
        Enables automatic pagination. When specified, the function follows the
        pageDetails.nextPageUrl link in each response until all pages have been retrieved,
        streaming each page's items to the pipeline as they arrive.

        Pagination requires the PageElement parameter so the function knows which property
        of the response object contains the array of items to extract from each page.

        If the endpoint does not return paginated data (no pageDetails.nextPageUrl in the
        response), the function returns the single response as normal.

        The module's configured page size (Set-RMMConfig -PageSize) is applied automatically
        when Paginate is used. To retrieve a single specific page instead, omit Paginate and
        pass the page number via the Parameters parameter (e.g. @{page = 3}).

    .PARAMETER PageElement
        The name of the property in the API response object that contains the array of items
        for paginated endpoints.

        Each Datto RMM paginated endpoint wraps its result array under a different property
        name. You must specify the correct property so the function can extract the items
        from each page.

        Common PageElement values for known endpoints:
        - 'devices'            → device list endpoints
        - 'sites'              → site list endpoints
        - 'alerts'             → alert list endpoints
        - 'activityLogs'       → activity log endpoints
        - 'users'              → user list endpoints
        - 'dnetSiteMappings'   → Datto Networking mapping endpoints
        - 'components'         → component library endpoints
        - 'filters'            → filter list endpoints
        - 'jobs'               → job list endpoints

        If unsure of the correct value, call the endpoint without Paginate first and inspect
        the returned object's property names to identify which property holds the result array.

    .EXAMPLE
        Invoke-RMMApiMethod -Path 'account'

        Calls GET /api/v2/account and returns the account data as an untyped PSObject.

    .EXAMPLE
        Invoke-RMMApiMethod -Path 'account/users' -Paginate -PageElement 'users'

        Retrieves all users across all pages, streaming each user object to the pipeline.

    .EXAMPLE
        Invoke-RMMApiMethod -Path 'account/devices' -Parameters @{hostname = 'SERVER'} -Paginate -PageElement 'devices'

        Retrieves all devices with 'SERVER' in the hostname, with automatic pagination.

    .EXAMPLE
        Invoke-RMMApiMethod -Path 'account/devices' -Parameters @{page = 2}

        Retrieves a single page (page 2) of the device list without automatic
        pagination. The full response object is returned including pageDetails.

    .EXAMPLE
        Invoke-RMMApiMethod -Path 'account/sites' -Paginate -PageElement 'sites'

        Retrieves all sites across all pages.

    .EXAMPLE
        $Body = @{
            name        = 'Test Site'
            description = 'Created via Invoke-RMMApiMethod'
            onDemand    = $false
        }
        PS > Invoke-RMMApiMethod -Path 'site' -Method Put -Body $Body

        Creates a new site by sending a PUT request with a JSON body.

    .EXAMPLE
        Invoke-RMMApiMethod -Path 'device/abc-123-uid'

        Retrieves a single device by UID without pagination.

    .EXAMPLE
        $Result = Invoke-RMMApiMethod -Path 'account/alerts/open' -Paginate -PageElement 'alerts'
        PS > $Result | Select-Object alertUid, alertMessage

        Retrieves all open alerts and selects specific properties from the untyped response.

    .INPUTS
        None. You cannot pipe objects to Invoke-RMMApiMethod.

    .OUTPUTS
        PSObject. Returns the untyped, deserialised API response as a PowerShell object. The
        shape of the returned object depends entirely on the endpoint called. When Paginate is
        used, the pagination wrapper is removed and individual items from the PageElement array
        are streamed to the pipeline.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        This is a pass-through wrapper — it does not validate the API path, map responses
        to typed classes, or interpret error payloads beyond what the underlying
        infrastructure already provides.

        For known endpoints with dedicated functions (e.g. Get-RMMDevice, Get-RMMSite),
        prefer using the typed function for a richer, documented experience.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Invoke-RMMApiMethod.md

    .LINK
        Connect-DattoRMM

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMSite
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default')]

    param (

        [Parameter(
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = 'Get',

        [hashtable]
        $Parameters,

        [object]
        $Body,

        [Parameter(
            ParameterSetName = 'Paginate',
            Mandatory = $false
        )]
        [switch]
        $Paginate,

        [Parameter(
            ParameterSetName = 'Paginate',
            Mandatory = $true
        )]
        [string]
        $PageElement

    )

    process {

        Write-Verbose "Invoking API: $Method $Path"

        # Build splatting hashtable for Invoke-ApiMethod
        $InvokeApiMethod = @{
            Path   = $Path
            Method = $Method
        }

        if ($Parameters) {

            $InvokeApiMethod.Parameters = $Parameters

        }

        if ($Body) {

            $InvokeApiMethod.Body = $Body

        }

        if ($Paginate) {

            $InvokeApiMethod.Paginate = $true
            $InvokeApiMethod.PageElement = $PageElement

        }

        Invoke-ApiMethod @InvokeApiMethod

    }
}

# SIG # Begin signature block
# MIIcXwYJKoZIhvcNAQcCoIIcUDCCHEwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCvRPG6XOV7iz8n
# jLpKyvxDCITl7vIKhAj17Au3KFtvwqCCFogwggNKMIICMqADAgECAhB464iXHfI6
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
# CQQxIgQgqfNzXlwHkm69lu440sS0jLBCIvszZ3tPeGrzjZOedyswDQYJKoZIhvcN
# AQEBBQAEggEAeb2a+SBN227lZRBXb4iWDKAcvbkiGR/+m3yjYo9xkAyD89JUbXS/
# 8ICiSL9QZo8ZCbT6BqL0TgZT2K3r+mBlfL+kO469qrrL45P3YNsmJ/R+/MjB67Ms
# A9wnE9bcw1ieFcORY0qrWsii21UDItw21ZOgQZL62pFuXI7X6rsKnuQFeRAim83U
# SAYQQ7ib5yYiYwRSM67HSUOpIhF5LZYh0pkJQ81B8A2NXtV8HbNB5O6ln1I3JG+J
# 4LY+LbHQqDqtNbLimCi4LS8J2Z+FfiO63chjDYIByqJ/09lQVAPpr51n33AJ3TyI
# JMWP9/RZe2UgbAaRAh8UWT0fVZcxJd6meaGCAyYwggMiBgkqhkiG9w0BCQYxggMT
# MIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5j
# LjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNB
# NDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUD
# BAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0yNjAzMzEwMDMwMzBaMC8GCSqGSIb3DQEJBDEiBCCJbgCdzhszhraLMQ5z6XJI
# y7jhBGx7CR+11pYxox6zZjANBgkqhkiG9w0BAQEFAASCAgBbrt3SMg+ZD84dbLlG
# cJn22DCfo5F2q0kxfeKm1tNpD46xZ7jC6sF8q5tgACStmFkw5ZI5yFBlN6UyDocL
# DLdoHdsGh9zHMv2H1HYd0OfAGjpYA11uKfDWL4xpJL0vGNCcItiGmvct4+AX+b5O
# 4PxqMYSp/Oieq9qqxhhtKCH9goWmkubYTMP/SEyAwvRiMWN9JM3PZ96nouVroAD8
# abT9a0ltxqj0X+DfvSQS6stDj8EnQRrCBoe1nTUqjjRPebCYZrLWv29wWI/DjYqW
# hF11xvKckCjNsO8p5lwuNuGSan12eBUPLroBQzOt2hbUlKx3TZcKTNdt792iuzme
# dHcRuZ5YfP4ZMPUs2rDgxvWoFCLJggHgWDrAGehP8yijZxwQh7MwIyN4yINSeZXY
# cXIPlx8J8r8YcAMNT8VC1Lw/FQ2nDZ2UIfX6Gc4f5iKedAgnYQTl8Ci/cOnDChoo
# M+3NQfRWSUqMxJIQXi0ayflX31Y3FEuM6cyD3kEamhXA1DVHKlGKnMbrg2scJz7Q
# Nugvt6NMnh5t0Lh64ZUS8QSpaFzsHzNoinYHVj/roiJd2orA+S6YHOle881sJwGS
# sHCyHG+9c/+DGLmB0PuhXnoeVyjqpZ32SOQYuBB+//JJXkKRn0Yh35jFS4+nyvx1
# k1NnSmAjkQ+JQo8xmdZKCHsMGQ==
# SIG # End signature block
