<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '..\DRMMObject\DRMMObject.psm1'
<#
.SYNOPSIS
    Represents a variable in the DRMM system, including its name, value, scope, and other attributes.
.DESCRIPTION
    The DRMMVariable class models a variable within the DRMM platform, encapsulating properties such as Id, Name, Value, Scope, SiteUid, and IsSecret. It provides a constructor and a static method to create an instance from API response data. The class also includes methods to determine if the variable is global or site-specific, as well as a method to generate a summary string of the variable's information.
#>
class DRMMVariable : DRMMObject {

    # The unique identifier of the variable.
    [long]$Id
    # The name of the variable.
    [string]$Name
    # The value of the variable.
    [object]$Value
    # The scope of the variable.
    [string]$Scope
    # The unique identifier (UID) of the site associated with the variable.
    [Nullable[guid]]$SiteUid
    # Indicates whether the variable is a secret variable.
    [bool]$IsSecret

    DRMMVariable() : base() {

    }

    static [DRMMVariable] FromAPIMethod([pscustomobject]$Response, [string]$Scope, [Nullable[guid]]$SiteUid) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Variable = [DRMMVariable]::new()
        $Variable.Id = $Response.id
        $Variable.Name = $Response.name
        $Variable.Value = $Response.value
        $Variable.IsSecret = $Response.masked
        $Variable.Scope = $Scope
        $Variable.SiteUid = $SiteUid

        return $Variable

    }

    <#
    .SYNOPSIS
        Determines if the variable is global in scope.
    .DESCRIPTION
        The IsGlobal method checks the Scope property of the variable to determine if it is global in scope. It returns true if the Scope is equal to 'Global', and false otherwise.
    .OUTPUTS
        True if the variable is global in scope; otherwise, false.
    #>
    [bool] IsGlobal() { return ($this.Scope -eq 'Global') }

    <#
    .SYNOPSIS
        Determines if the variable is site-specific in scope.
    .DESCRIPTION
        The IsSite method checks the Scope property of the variable to determine if it is site-specific in scope. It returns true if the Scope is equal to 'Site', and false otherwise.
    .OUTPUTS
        True if the variable is site-specific in scope; otherwise, false.
    #>
    [bool] IsSite()   { return ($this.Scope -eq 'Site') }


    <#
    .SYNOPSIS
        Generates a summary string for the variable, including its name, scope, and value.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the variable's name, scope, and value. If the Scope property is not set, it defaults to 'Global'. The method also accounts for secret variables, which are masked in the API response.
    .OUTPUTS
        A summary string that includes the name, scope, and value of the variable.
    #>
    [string] GetSummary() {

        # API already returns masked values for secret variables
        $ScopeValue = if ($this.Scope) { $this.Scope } else { 'Global' }

        return "$($this.Name) [$ScopeValue] = $($this.Value)"

    }
}
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBWqzpyY2SdlmcH
# 8P1vQ564SbGQhRe1fgNNS2qF2HOyj6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBnl9Dea9b188KUyY5ff4dJEa3nq
# op1Al+kDCZexNrpQMA0GCSqGSIb3DQEBAQUABIIBAEGwNLRuvyKe/RICwjaL043c
# VThCoHWZjspiRfR4juOcBwv3Og77ZKTE3XS1JSspcrosnjwUjLwUwnEKuxMWCa0/
# TA5aZJmkCWkPDQ6D7kyL1uMCgXgjIrsk2YpGe3qXy26KFMkW5BxHQSGX9EpWiz1a
# npfmR6h9yorMnSsaO0XVa/IzrptgOEgva/oS1FCALsJKGp8537g8ZmrfmTfSsMj+
# hHv4yLaBDkn0iu5DMNq6Y5fLq25oPNzcd8V3t0/4lzU5v4Y1Vi8PKa7VmaPZkzBe
# hnFaF8oo52BCw2RqUzmaBkomqU9m97KvnX+FL9YKWikh7qMd/TAp5QpUZjYE+GE=
# SIG # End signature block
