<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>

# Plural noun 'Keys' is used in the function name to reflect that both Access and Secret keys are reset.
function Reset-RMMApiKeys {
    <#
    .SYNOPSIS
        Resets the authenticated user's API access and secret keys in Datto RMM.

    .DESCRIPTION
        The Reset-RMMApiKeys function regenerates the API access key and secret key for the
        currently authenticated user. This invalidates the existing keys immediately.

        When using -ReturnNewKey, the API secret key (as shown in the Datto RMM UI) will NOT be returned in plain text, but as a SecureString for security. To convert the SecureString to plain text (not recommended unless absolutely necessary), use:
            Windows:
            [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($newKeys.ApiSecret))

            Linux/macOS:
            (New-Object System.Management.Automation.PSCredential('user', $newKeys.ApiSecret)).GetNetworkCredential().Password

        Only do this in a secure environment, and immediately clear any script or session logs that may contain the secret. Avoid exposing the secret in plain text whenever possible.

        WARNING: If you do not use -ReturnNewKey, this operation will immediately invalidate the current API connection. After running you will need to:
            1. Log in to the Datto RMM web portal
            2. Navigate to your user settings
            3. Generate or view your new API keys
            4. Update your stored credentials with the new keys
            5. Reconnect using Connect-DattoRMM with the new keys
        
            WARNING: This operation will immediately invalidate the current API connection.
            If you use -ReturnNewKey and capture the output, you will receive the new API key and secret (the secret as a SecureString).
            If you do not use -ReturnNewKey, the new keys will be discarded and you must retrieve new API keys from the Datto RMM web portal. To do this:

        This function is useful for security purposes when:
        - API keys may have been compromised
        - Regular key rotation as part of security policy
        - Revoking access from stolen or exposed credentials

    .PARAMETER ReturnNewKey
        If specified, returns the new API key and secret as a DRMMAPIKeySecret object (with the secret as a SecureString).
        You should capture the output in a variable to retrieve the new secret. If not specified, the new keys will be discarded.

    .EXAMPLE
        $newKeys = Reset-RMMApiKeys -ReturnNewKey

        Resets the API keys and returns the new key/secret object. Capture the output to retrieve the new secret.

    .EXAMPLE
        Reset-RMMApiKeys

        Resets the API keys with confirmation prompt. If -ReturnNewKey is not specified, the new keys are discarded.
        New keys must be retrieved from the Datto RMM web portal.

    .INPUTS
        None. This function does not accept pipeline input.

    .OUTPUTS
        DRMMAPIKeySecret (if -ReturnNewKey is specified), otherwise None.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        CRITICAL WARNINGS:
        - This function invalidates your current API session immediately
        - If you do not capture the new keys (with -ReturnNewKey), you must generate new keys via the Datto RMM web portal
        - If you lose the new secret, you will need to reset the keys again or generate new ones in the web portal
        - If you cannot access the web portal, contact Datto support

        Best practices:
        - Only reset keys when necessary (compromise, rotation policy)
        - Have web portal access available before resetting
        - Document key resets in your change management system
        - Notify team members if shared keys are being rotated
        - Update all automation scripts with new keys after reset

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Reset-RMMApiKeys.md
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter()]
        [switch]
        $ReturnNewKey
    )

    if ($ReturnNewKey) {

        $WarningMessage = @"
This will immediately invalidate your current API keys and disconnect your session.

You have chosen to retrieve the new API key and secret. The new secret will only be available in this session and will be returned as a SecureString.
You MUST securely store the new secret immediately. If you lose it, you will need to log in to the Datto RMM web portal to generate new API keys.

Are you sure you want to reset your API keys and retrieve the new secret?
"@

    } else {

        $WarningMessage = @"
This will immediately invalidate your current API keys and disconnect your session.

You have chosen NOT to retrieve the new API key and secret. The new secret will be discarded and cannot be retrieved later.
You will need to log in to the Datto RMM web portal to generate new API keys if you lose access.

Are you sure you want to reset your API keys? This action is irreversible unless you generate new keys in the web portal.
"@

    }

    Write-Warning $WarningMessage

    if (-not $PSCmdlet.ShouldContinue('Current session will be disconnected.', 'Reset API Keys')) {

        Write-Warning "API key reset operation cancelled by user."
        return

    }

    $APIMethod = @{
        Path = "user/resetApiKeys"
        Method = 'Post'
    }

    try {

        if ($ReturnNewKey) {

            Write-Verbose "Resetting API keys and returning new key/secret."
            Invoke-ApiMethod @APIMethod | ForEach-Object {[DRMMAPIKeySecret]::FromAPIMethod($_)}

        } else {

            Write-Verbose "Resetting API keys without returning new key/secret."
            Invoke-ApiMethod @APIMethod | Out-Null

        }

        Write-Verbose "Clearing stored authentication information."
        $Script:RMMAuth = $null
        $Script:MaxPageSize = $null
        $Script:APIUrl = $null
        $Script:API = $null
        $Script:PageSize = $null

    } catch {

        Write-Error "Failed to reset API keys: $_"
        throw

    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCnId8L3wVptMSq
# GYnhwUuVCrRmO93AWwTjYlNdKz+47KCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICOiapuZu6yrzxJBFJrdoNosRC0V
# 0zHefFm9gmxTWZWDMA0GCSqGSIb3DQEBAQUABIIBAAjYQM/g1tm37CdNdFtUkla1
# ipSeSgDTPnXTmmfUC7u3bJs3BGl46dfwVIj55BV3mWjXWKzQovz78CzM2zaKX+Sp
# L+Yr6EA/2/E1fqCefM/5G38eaqBVsBTlZMlVlT6fXRMdJjVVtBG75l9lsD+k6mfh
# 5+c/JGp8wpykTlk/nV44zHZGr+oyGWgUQZjOIx4fxmpxvgf5bbTZT3GDYTKypDrs
# NAxHLZNL8X13AJuvREy2SMyfRErqvB2VPzVJW9U6xj1mpGNfQ2RwKgRXTS+7jEI8
# e0Dw9KnKToqIAEatVHOrSVRgbE1VzbBcos+wrQNRtGanwZSQjDZJuLsg97f6/mA=
# SIG # End signature block
