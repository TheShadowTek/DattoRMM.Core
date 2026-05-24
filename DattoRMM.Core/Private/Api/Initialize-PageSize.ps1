<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Initialize-PageSize {
    <#
    .SYNOPSIS
        Retrieves the account's maximum page size and configures the module's page size settings.

    .DESCRIPTION
        This internal function queries the Datto RMM API to determine the account's maximum allowed
        page size for paginated requests. It then sets the module's page size based on a priority order:
        
        1. Existing session page size (if within account limits)
        2. Configured default page size (if within account limits)
        3. Previously set page size (if within account limits)
        4. Account maximum page size
        
        This function also serves as a connection test, as it requires a valid authentication token
        to successfully query the API.

    .EXAMPLE
        Initialize-RMMPageSize
        
        Queries the API and configures page size settings.

    .NOTES
        This is an internal function used by Connect-DattoRMM and potentially other functions
        that need to validate or refresh page size configuration.
        
        Sets the following script-scope variables:
        - $Script:MaxPageSize: Account's maximum allowed page size
        - $Script:PageSize: Currently active page size for API requests
        - $Script:SessionPageSize: Session's configured page size
        
        Requires an active authentication token in $Script:RMMAuth.
    #>

    [CmdletBinding()]
    param()

    Write-Debug "Testing connection to Datto RMM API & setting maxpage size."
    
    $PageSizeMethod = @{
        Path = "system/pagination"
        Method = 'Get'
    }

    $AccountMaxPageSize = (Invoke-ApiMethod @PageSizeMethod).max
    $Script:MaxPageSize = $AccountMaxPageSize

    # Check if there's a configured default page size
    If ($null -ne $Script:SessionPageSize -and $Script:SessionPageSize -le $AccountMaxPageSize) {

        $Script:PageSize = $Script:SessionPageSize
        Write-Verbose "Set page size to existing session value: $($Script:PageSize)."

    } elseif ($null -ne $Script:ConfigPageSize -and $Script:ConfigPageSize -le $AccountMaxPageSize) {

        $Script:PageSize = $Script:ConfigPageSize
        Write-Verbose "Set page size to configured default: $($Script:PageSize)."

    } elseif ($null -ne $Script:PageSize -and $Script:PageSize -le $AccountMaxPageSize) {

        # If PageSize was previously set in this session and is within limits, keep it
        Write-Verbose "Retaining previously set page size: $($Script:PageSize)."

    } else {

        $Script:PageSize = $AccountMaxPageSize
        Write-Verbose "Set page size to account maximum: $($Script:PageSize)."

    }

    $Script:SessionPageSize = $Script:PageSize
    Write-Verbose "Using page size: $($Script:PageSize)."
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDwTGykY07r7Z/w
# jiNykaZ8oMXeJnUR2OWjkF6SE3PspaCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEII693kFUm2Q/Yda4xDELV3FujyFD
# TMc1TZR8uE1xi0gGMA0GCSqGSIb3DQEBAQUABIIBAJo5+pM+L0/Tz7jzs7Rk9GX2
# L9h4Enr6RrouZhwC6Dq/tC4CFuXL3sDsSjdxHkiedZJA5cjngEsKrxycKtUBspym
# 3PoWZQb8OeUgJ7PzUfpDb/lw3kFUC65OKt2zQ7NXfFdiCgIDx5Bz533t/2eYr3hB
# j/j0Y4iByCErARJzc8hLvnYL6mln7mNPdN/INY3RoeoCK2YFKKj/vdy5rZvCYX1b
# hbcC1nxnISeY/3Au4EFPKMCmKvtyXG7w+aIG+dNTBnuwmf1bj02jX/7gLeAtiE0k
# sa/qiGhPBWEg1rWWd8v2WeI6AAlJ6m3gGZomiLlVlgHTJMlwM/FPd4txFk9WfZA=
# SIG # End signature block
