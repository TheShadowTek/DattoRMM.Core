<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Request-APIToken {
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
            TimeoutSec = $Script:APIMethodRetry.TimeoutSeconds
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
