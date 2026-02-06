<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>

# Plural noun 'Keys' is used in the function name to reflect that both Access and Secret keys are reset.
function Reset-RMMAPIKeys {
    <#
    .SYNOPSIS
        Resets the authenticated user's API access and secret keys in Datto RMM.

    .DESCRIPTION
        The Reset-RMMAPIKeys function regenerates the API access key and secret key for the
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
        $newKeys = Reset-RMMAPIKeys -ReturnNewKey

        Resets the API keys and returns the new key/secret object. Capture the output to retrieve the new secret.

    .EXAMPLE
        Reset-RMMAPIKeys

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
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Reset-RMMAPIKeys.md
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
            Invoke-APIMethod @APIMethod | ForEach-Object {[DRMMAPIKeySecret]::FromAPIMethod($_)}

        } else {

            Write-Verbose "Resetting API keys without returning new key/secret."
            Invoke-APIMethod @APIMethod | Out-Null

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

