<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function ConvertFrom-SecureStringToPlaintext {
    <#
    .SYNOPSIS
        Converts a SecureString to plaintext using platform-appropriate methods.

    .DESCRIPTION
        This function decrypts a SecureString to plaintext, using the most secure method
        available for the current platform:
        
        - Windows: Uses Marshal::SecureStringToBSTR with immediate ZeroFreeBSTR to minimize
          exposure in managed memory and prevent garbage collector relocation.
        
        - Linux/macOS: Uses PSCredential.GetNetworkCredential() as Marshal BSTR methods
          are not available. Note: plaintext remains in managed memory until garbage collection.

    .PARAMETER SecureString
        The SecureString to convert to plaintext.

    .EXAMPLE
        $plaintext = ConvertFrom-SecureStringToPlaintext -SecureString $MySecureString

    .NOTES
        Security Considerations:
        - Always set the returned plaintext variable to $null when done
        - On Linux/macOS, plaintext persists in managed memory until GC runs
        - For high-security scenarios on non-Windows, consider calling [GC]::Collect() after use
        
        The function uses try/finally to ensure memory is zeroed on Windows even if errors occur.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [SecureString]
        $SecureString
    )
    
    if ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop') {
        
        # Windows: Use Marshal for maximum security
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        
        try {
            
            [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            
        } finally {
            
            # Always zero memory, even on errors
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
            
        }
        
    } else {
        
        # Linux/macOS: Use NetworkCredential (best available option)
        # Note: Plaintext remains in managed memory until GC
        $Credential = [PSCredential]::new('dummy', $SecureString)
        $Credential.GetNetworkCredential().Password
        
    }
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAb1IY/PhxsJjh6
# ZD4t10orNVZxWrSwON1p7zBoHSERZ6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIENL6JLDcrHTJlHKaFKWv3kZvXaF
# sKp+QEEx5UJfiKSlMA0GCSqGSIb3DQEBAQUABIIBACaGuTTjyCK2dIwnNW7DiLf6
# 5p8aHeH+F3WTvCGYIfTaq2mvduMcnC1zUTI+oXCfzNXMn0hO9bHfomwSGD0XbvBb
# mN9iH84k1n15b8RAK4bwCzLUyQEyhVjnnntf3Kaizd9VmE0S9owRrCH6JhhXNuil
# 8xQ07iIHCElLgIN7B74ICIB2MWS5i4dWzxSmOjwwcxNhu0MjT8Wxd2qrOUCgcn+j
# /srByopXxW8wSNjlXz/g5E1cVa2jBTocNmS+vY7MWFld1SP5JG2Y/LIXOQ4PY931
# HtcphOhsuLbAgIgaVO5h1820KIwVYJID57kjkdpkOJ9DQlJtPnwU0IIUIPMYlc8=
# SIG # End signature block
