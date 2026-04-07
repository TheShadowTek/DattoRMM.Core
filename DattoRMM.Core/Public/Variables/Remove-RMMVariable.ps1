<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Remove-RMMVariable {
    <#
    .SYNOPSIS
        Deletes a variable from the Datto RMM account or site.

    .DESCRIPTION
        The Remove-RMMVariable function permanently deletes a variable from either the
        account (global) level or from a specific site.

        This is a destructive operation that cannot be undone. Use the -Confirm parameter
        to prompt for confirmation before deleting each variable.

    .PARAMETER Variable
        A DRMMVariable object to delete. Accepts pipeline input from Get-RMMVariable.

    .PARAMETER VariableId
        The unique identifier of the variable to delete.

    .PARAMETER SiteUid
        The unique identifier (GUID) of the site containing the variable. Required when
        deleting site-level variables by VariableId.

    .EXAMPLE
        Get-RMMVariable -Name "OldVariable" | Remove-RMMVariable

        Deletes an account-level variable via pipeline.

    .EXAMPLE
        Remove-RMMVariable -VariableId 12345 -Confirm:$false

        Deletes an account-level variable by ID without prompting for confirmation.

    .EXAMPLE
        Get-RMMSite -Name "Closed Office" | Get-RMMVariable | Remove-RMMVariable -Confirm

        Deletes all variables from a site with confirmation prompts.

    .EXAMPLE
        Remove-RMMVariable -SiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -VariableId 67890

        Deletes a site-level variable by specifying site UID and variable ID.

    .INPUTS
        DRMMVariable. You can pipe variable objects from Get-RMMVariable.
        You can also pipe objects with VariableId and SiteUid properties.

    .OUTPUTS
        None. This function does not return any output.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        This operation is permanent and cannot be undone. Variables are immediately
        deleted from the Datto RMM system.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Variables/Remove-RMMVariable.md
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByVariableObject', SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(
            ParameterSetName = 'ByVariableObject',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMVariable]
        $Variable,

        [Parameter(
            ParameterSetName = 'ByVariableId',
            Mandatory = $true
        )]
        [long]
        $VariableId,

        [Parameter(
            ParameterSetName = 'ByVariableId'
        )]
        [guid]
        $SiteUid
    )

    process {

        # Determine scope and set working values
        if ($Variable) {

            $VariableId = $Variable.Id
            $Scope = $Variable.Scope
            $VariableName = $Variable.Name
            
            if ($Scope -eq 'Site') {

                $SiteUid = $Variable.SiteUid

            }

        } else {

            # When using VariableId parameter, determine scope by presence of SiteUid
            if ($PSBoundParameters.ContainsKey('SiteUid')) {

                $Scope = 'Site'

            } else {

                $Scope = 'Global'

            }

            $VariableName = "{$VariableId}"

        }

        if ($Scope -eq 'Site') {

            $Target = "site variable '$VariableName' (ID: $VariableId) from site $SiteUid"

        } else {

            $Target = "account variable '$VariableName' (ID: $VariableId)"

        }

        if (-not $PSCmdlet.ShouldProcess($Target, "Delete variable permanently")) {

            return

        }

        Write-Debug "Deleting RMM variable $VariableId at $Scope scope"

        # Determine API path based on scope
        if ($Scope -eq 'Site') {

            $Path = "site/$SiteUid/variable/$VariableId"

        } else {

            $Path = "account/variable/$VariableId"

        }

        $APIMethod = @{
            Path = $Path
            Method = 'Delete'
        }

        Invoke-ApiMethod @APIMethod | Out-Null

    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCG5D5qnKX4HISQ
# skk4MRgqDpnlc6czTaTm74zrVEhoeaCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIF4rT+HTdFg/ar1awRrmkYrchkBM
# ba02q9t9ueHscssJMA0GCSqGSIb3DQEBAQUABIIBAGXG+/wAZjLygXqsGLXpy7qh
# kJLc45dnfl+yeP1PZ0h+VfgXUjrrCNNTGEbF7bNXuKZZ9uKIogWdn3/Y5NMQ1wjo
# Qt8jS0R2WddhAjOto32ZoMhOtscqPwy5Z8gi/9hwirw9RGqeRS1W0cuRvsMM3MH1
# PMPtBjy/9dHC8Fk8pMur94/DvTcnrbonBW8Uc+h+u15v9KRivkolwODEH21qR1M0
# icj5yQnTDFCfyKC7WtfT8bwZZhz6R5VQyOcL8Ggbanixl4Kt0B9XE/2bdlyKJlrc
# vFw19YZx+2rtNqxOQJ480MLXl3i3+8zqYCXSlmJL1MZQssPrC1iFYi8wN5hUSbU=
# SIG # End signature block
