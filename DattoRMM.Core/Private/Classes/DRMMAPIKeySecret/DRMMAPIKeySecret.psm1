using module '..\DRMMObject\DRMMObject.psm1'

<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Represents API key and secret information for authenticating with the DRMM API.
.DESCRIPTION
    The DRMMAPIKeySecret class encapsulates the API key, API secret, and associated username for a DRMM account. It provides a static method to create an instance of the class from a typical API response object that contains these credentials. The API secret is stored as a secure string to enhance security when handling sensitive information.
.LINK
    Reset-RMMApiKeys
#>
class DRMMAPIKeySecret : DRMMObject {

    # API authentication key.
    [string]$ApiKey
    # API authentication secret.
    [securestring]$ApiSecret
    # Username associated with the API key and secret.
    [string]$Username

    DRMMAPIKeySecret() : base() {

    }

    static [DRMMAPIKeySecret] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $KeySecret = [DRMMAPIKeySecret]::new()
        $KeySecret.ApiKey = $Response.apiAccessKey
        $KeySecret.ApiSecret = ConvertTo-SecureString -String $Response.apiSecretKey -AsPlainText -Force
        $Response.apiSecretKey = $null # Clear plain text secret from memory
        $KeySecret.Username = $Response.userName

        return $KeySecret

    }

}