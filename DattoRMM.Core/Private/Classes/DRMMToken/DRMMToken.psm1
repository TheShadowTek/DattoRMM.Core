using module '..\DRMMObject\DRMMObject.psm1'

<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Represents an OAuth access token response from the Datto RMM API.
.DESCRIPTION
    The DRMMToken class encapsulates the OAuth token information returned by the Datto RMM authentication endpoint. It includes the access token (stored as a secure string), token type, expiration date, scope, and JWT identifier. This class provides a static method to create an instance from the API response object, ensuring the access token is securely stored and the expires_in value is converted to a DateTime for easier time-based operations.
#>
class DRMMToken : DRMMObject {

    # The OAuth access token, stored as a secure string to protect sensitive credential data.
    [securestring]$AccessToken
    # The type of the access token (e.g., Bearer).
    [string]$TokenType
    # The expiration date and time of the access token, calculated from the token lifetime at the point of creation.
    [datetime]$Expires
    # The OAuth scope granted by the access token.
    [string]$Scope
    # The unique JWT identifier for the access token.
    [string]$Jti

    DRMMToken() : base() {

    }

    static [DRMMToken] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Token = [DRMMToken]::new()
        $Token.AccessToken = ConvertTo-SecureString -String $Response.access_token -AsPlainText -Force
        $Response.access_token = $null # Clear plain text token from memory
        $Token.TokenType = $Response.token_type
        $Token.Expires = [datetime]::UtcNow.AddSeconds($Response.expires_in)
        $Token.Scope = $Response.scope
        $Token.Jti = $Response.jti

        return $Token

    }
}