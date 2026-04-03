<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Set-RMMVariable {
    <#

    .SYNOPSIS
        Updates an existing variable in the Datto RMM account or site.

    .DESCRIPTION
        The Set-RMMVariable function updates the name and/or value of an existing variable at either
        the account (global) level or at a specific site level. The function always fetches the latest
        state of the variable before updating to ensure changes are made against the current platform
        value. If a DRMMVariable object is piped in, the function checks for staleness and prompts the
        user if the object differs from the current value.

        NOTE: The Masked property can only be set during variable creation and cannot be changed after
        the variable has been created. Use New-RMMVariable with -Masked to create a masked variable.

    .PARAMETER Variable
        A DRMMVariable object to update. Accepts pipeline input from Get-RMMVariable.

    .PARAMETER VariableId
        The unique identifier of the variable to update.

    .PARAMETER SiteUid
        The unique identifier (GUID) of the site containing the variable. Required when updating
        site-level variables by VariableId.

    .PARAMETER Name
        The name of the variable to update (used for lookup when not using VariableId).

    .PARAMETER NewName
        The new name for the variable. If not specified, the existing name is preserved. Use this
        parameter to rename the variable.

    .PARAMETER Value
        The new value for the variable. If not specified, the current value is retained.
        Accepts both string and SecureString.
        
        When a SecureString is provided:
        - The value is securely converted for the API call
        - Plaintext is cleared from memory immediately after use
        - Note: The Masked property cannot be changed after creation

    .PARAMETER Force
        Bypasses the confirmation prompt.

    .EXAMPLE
        Get-RMMVariable -Name "CompanyName" | Set-RMMVariable -Value "Contoso Corporation"

        Updates the value of an account-level variable via pipeline.

    .EXAMPLE
        $Secret = Read-Host -AsSecureString -Prompt "Enter new password"
        PS > Get-RMMVariable -Name "AdminPassword" | Set-RMMVariable -Value $Secret

        Updates a masked variable value using SecureString for enhanced security.

    .EXAMPLE
        Set-RMMVariable -VariableId 12345 -NewName "CompanyName" -Value "New Company Ltd"

        Updates both name and value of an account-level variable by ID.

    .EXAMPLE
        Get-RMMSite -Name "Main Office" | Get-RMMVariable -Name "SiteCode" | Set-RMMVariable -Value "MO002"

        Updates a site-level variable via pipeline.

    .EXAMPLE
        Set-RMMVariable -SiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -Name "BackupPath" -Value "\\newserver\backup"

        Updates a site-level variable by specifying site UID and variable name.

    .EXAMPLE
        Set-RMMVariable -VariableId 12345 -NewName "NewVarName"

        Renames an account-level variable by ID, keeping the current value.

    .INPUTS
        DRMMVariable. You can pipe variable objects from Get-RMMVariable.
        You can also pipe objects with VariableId and SiteUid properties.

    .OUTPUTS
        DRMMVariable. Returns the updated variable object.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        The Masked property cannot be changed after a variable is created. If you need
        to change a variable to be masked (or unmasked), you must delete and recreate it.

        If a DRMMVariable object is piped in, the function checks for staleness and prompts
        the user if the object is out of date compared to the current platform value.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Variables/Set-RMMVariable.md
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
        [Parameter(
            ParameterSetName = 'ByVariableName'
        )]
        [guid]
        $SiteUid,

        [Parameter(
            ParameterSetName = 'ByVariableName',
            Mandatory = $true
        )]
        [string]
        $Name,

        [Parameter(
            Mandatory = $false
        )]
        [string]
        $NewName,

        [Parameter(
            Mandatory = $false

        )]
        [object]
        $Value,

        [Parameter(
            Mandatory = $false
        )]
        [switch]
        $Force
    )

    process {

        # Get current variable for current value and staleness check
        $CurrentVariable = $null

        switch ($PSCmdlet.ParameterSetName) {

            'ByVariableObject' {

                if ($Variable.Scope -eq 'Site') {

                    $CurrentVariable = Get-RMMVariable -SiteUid $Variable.SiteUid -Id $Variable.Id

                } else {

                    $CurrentVariable = Get-RMMVariable -Id $Variable.Id

                }

                if ($null -eq $CurrentVariable) {

                    throw "Variable $($Variable.Name) with ID $($Variable.Id) not found in scope $($Variable.Scope)."

                } else {

                    $Stale = $false

                    if ($Variable.Name -ne $CurrentVariable.Name -or $Variable.Value -ne $CurrentVariable.Value) {

                        $Stale = $true

                    }

                    if ($Stale) {

                        $StaleMessage = "The variable object provided is stale compared to the current platform value."
                        $StaleMessage += "`nCurrent Name: $($CurrentVariable.Name), Provided Name: $($Variable.Name)"
                        $StaleMessage += "`nCurrent Value: $($CurrentVariable.Value), Provided Value: $($Variable.Value)"
                        
                        if (-not $PSCmdlet.ShouldContinue($StaleMessage, "Proceed with update?") -and -not $Force) {

                            return

                        }
                    }
                }
            }

            'ByVariableId' {
                
                if ($PSBoundParameters.ContainsKey('SiteUid')) {

                    $CurrentVariable = Get-RMMVariable -SiteUid $SiteUid -Id $VariableId

                } else {

                    $CurrentVariable = Get-RMMVariable -Id $VariableId

                }
            }

            'ByVariableName' {

                if ($PSBoundParameters.ContainsKey('SiteUid')) {

                    $CurrentVariable = Get-RMMVariable -SiteUid $SiteUid -Name $Name

                } else {

                    $CurrentVariable = Get-RMMVariable -Name $Name

                }
            }
        }

        # Validate variable exists
        if ($null -eq $CurrentVariable) {

            throw "Variable not found for update."

        }

        # Handle SecureString value conversion
        $PlainValue = $null

        if ($PSBoundParameters.ContainsKey('Value')) {

            if ($Value -is [SecureString]) {

                $PlainValue = ConvertFrom-SecureStringToPlaintext -SecureString $Value
                Write-Verbose "SecureString detected - converting securely for API call"

            } else {

                $PlainValue = $Value

            }
        }

        # Set new values based on current if not specified
        $Body = @{
            name = $null
            value = $null
        }

        switch ($PSBoundParameters.Keys) {

            'NewName' {$Body.name = $NewName}
            default  {$Body.name = $CurrentVariable.Name}
            
        }

        switch ($PSBoundParameters.Keys) {

            'Value'  {$Body.value = $PlainValue}
            default  {$Body.value = $CurrentVariable.Value}

        }

        if ($CurrentVariable.Scope -eq 'Site') {

            $Path = "site/$($CurrentVariable.SiteUid)/variable/$($CurrentVariable.Id)"

        } else {

            $Path = "account/variable/$($CurrentVariable.Id)"
        }

        $APIMethod = @{
            Path = $Path
            Method = 'Post'
            Body = $Body
        }

        try {

            Invoke-ApiMethod @APIMethod -WarningAction Stop | Out-Null


        } catch {

            Write-Warning "Failed to update variable: $($CurrentVariable.Name)"
            return

        }

        # Fetch the updated variable since API doesn't return it
        $RefreshVariable = @{
            Id = $CurrentVariable.Id
        }

        if ($CurrentVariable.Scope -eq 'Site') {

            $RefreshVariable.SiteUid = $CurrentVariable.SiteUid

        }

        Get-RMMVariable @RefreshVariable

    }

    end {

        # Clear plaintext value from memory
        $PlainValue = $null

    }
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAvQWwLvAMjNrvR
# 8DuF9NnG5TlwTf3oL8CMoXPcws+PjqCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINANga4HX7MNY/TTJ/aALnG9L6gX
# YyzoA5iceCRmZuJIMA0GCSqGSIb3DQEBAQUABIIBAFy7IoVXn1zmGQvw1lffqPl6
# NfSansB+DINnH0BQ3M7ZUVitPQx3V0MXQ/XjLFen2KUJNcD2pRH1asktRlK2zbew
# OZXVmmB3fCwFXTW6PuWSth5IYwNRTw+RnO2NCFo6a8r235BKFDnVS0ReMHwptzJo
# XcTKxyFp8yypiu6741j9imu7S0d7U2pznggRgA6k2xBO21dHyaufS2Lzf8rXMbVy
# A5QCRkefzFEwY5n4ZCEmhJh6c1Pz/W9SvhwJNdiv2o5r3x+5FuBB0jWF3vUvLsed
# lVEqBKmicKdMCJgmLmpR4cr/YsDO24c1nC2+4fadUcEoaWqKdwl0M8whn9JojmU=
# SIG # End signature block
