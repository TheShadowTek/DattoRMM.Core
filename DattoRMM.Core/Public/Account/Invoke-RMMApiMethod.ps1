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
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCvRPG6XOV7iz8n
# jLpKyvxDCITl7vIKhAj17Au3KFtvwqCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKnzc15cB5JuvZbuONLEtIywQiL7
# M2d7T3hq842TnncrMA0GCSqGSIb3DQEBAQUABIIBAHm9mvkgTdtu5WUQV2+Ilgyg
# HL25Ihkf/pt8o2KPcZAMg/PSVG10v/CAoki/UGaPGQm0+gai9E4GU9it6/pgZXy/
# pDuOvaq6y+OT92DbJif0fvzIweuzLAPcJxPW3MNYnhXDkWNKq1rIottVAyLcNtWT
# oEGS+tqRblyO1+q7Cp7kBXkQIpvN1EgGEEO4m+cmImMEUjOux0lDqSIReS2WIdKZ
# CUPNQfANjV7VfB2zQeTupZ9SNyRvieC2Pi2x0Kg6rTWy4pgouC0vCdmfhX4jut3I
# Yw2CAcqif9PZUFQD6a+dZ99wCd08iCTFj/f0WXtlIGwGkQIfFFk9H1WXMSXepnk=
# SIG # End signature block
