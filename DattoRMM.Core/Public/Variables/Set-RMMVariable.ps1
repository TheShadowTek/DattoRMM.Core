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
# MIIcXwYJKoZIhvcNAQcCoIIcUDCCHEwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAvQWwLvAMjNrvR
# 8DuF9NnG5TlwTf3oL8CMoXPcws+PjqCCFogwggNKMIICMqADAgECAhB464iXHfI6
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
# XpF9pOzFLMUwggWNMIIEdaADAgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3
# DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAX
# BgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3Vy
# ZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBH
# NDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIw
# aTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLK
# EdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4Tm
# dDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembu
# d8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnD
# eMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1
# XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVld
# QnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTS
# YW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSm
# M9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzT
# QRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6Kx
# fgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/
# MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv
# 9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBr
# MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUH
# MAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYG
# BFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72a
# rKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFID
# yE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/o
# Wajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv
# 76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30
# fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQwgga0MIIE
# nKADAgECAhANx6xXBf8hmS5AQyIMOkmGMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNV
# BAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdp
# Y2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0y
# NTA1MDcwMDAwMDBaFw0zODAxMTQyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYD
# VQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBH
# NCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEwggIiMA0GCSqG
# SIb3DQEBAQUAA4ICDwAwggIKAoICAQC0eDHTCphBcr48RsAcrHXbo0ZodLRRF51N
# rY0NlLWZloMsVO1DahGPNRcybEKq+RuwOnPhof6pvF4uGjwjqNjfEvUi6wuim5ba
# p+0lgloM2zX4kftn5B1IpYzTqpyFQ/4Bt0mAxAHeHYNnQxqXmRinvuNgxVBdJkf7
# 7S2uPoCj7GH8BLuxBG5AvftBdsOECS1UkxBvMgEdgkFiDNYiOTx4OtiFcMSkqTtF
# 2hfQz3zQSku2Ws3IfDReb6e3mmdglTcaarps0wjUjsZvkgFkriK9tUKJm/s80Fio
# cSk1VYLZlDwFt+cVFBURJg6zMUjZa/zbCclF83bRVFLeGkuAhHiGPMvSGmhgaTzV
# yhYn4p0+8y9oHRaQT/aofEnS5xLrfxnGpTXiUOeSLsJygoLPp66bkDX1ZlAeSpQl
# 92QOMeRxykvq6gbylsXQskBBBnGy3tW/AMOMCZIVNSaz7BX8VtYGqLt9MmeOreGP
# RdtBx3yGOP+rx3rKWDEJlIqLXvJWnY0v5ydPpOjL6s36czwzsucuoKs7Yk/ehb//
# Wx+5kMqIMRvUBDx6z1ev+7psNOdgJMoiwOrUG2ZdSoQbU2rMkpLiQ6bGRinZbI4O
# Lu9BMIFm1UUl9VnePs6BaaeEWvjJSjNm2qA+sdFUeEY0qVjPKOWug/G6X5uAiynM
# 7Bu2ayBjUwIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4E
# FgQU729TSunkBnx6yuKQVvYv1Ensy04wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5n
# P+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcG
# CCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQu
# Y29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGln
# aUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNV
# HSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIB
# ABfO+xaAHP4HPRF2cTC9vgvItTSmf83Qh8WIGjB/T8ObXAZz8OjuhUxjaaFdleMM
# 0lBryPTQM2qEJPe36zwbSI/mS83afsl3YTj+IQhQE7jU/kXjjytJgnn0hvrV6hqW
# Gd3rLAUt6vJy9lMDPjTLxLgXf9r5nWMQwr8Myb9rEVKChHyfpzee5kH0F8HABBgr
# 0UdqirZ7bowe9Vj2AIMD8liyrukZ2iA/wdG2th9y1IsA0QF8dTXqvcnTmpfeQh35
# k5zOCPmSNq1UH410ANVko43+Cdmu4y81hjajV/gxdEkMx1NKU4uHQcKfZxAvBAKq
# MVuqte69M9J6A47OvgRaPs+2ykgcGV00TYr2Lr3ty9qIijanrUR3anzEwlvzZiiy
# fTPjLbnFRsjsYg39OlV8cipDoq7+qNNjqFzeGxcytL5TTLL4ZaoBdqbhOhZ3ZRDU
# phPvSRmMThi0vw9vODRzW6AxnJll38F0cuJG7uEBYTptMSbhdhGQDpOXgpIUsWTj
# d6xpR6oaQf/DJbg3s6KCLPAlZ66RzIg9sC+NJpud/v4+7RWsWCiKi9EOLLHfMR2Z
# yJ/+xhCx9yHbxtl5TPau1j/1MIDpMPx0LckTetiSuEtQvLsNz3Qbp7wGWqbIiOWC
# nb5WqxL3/BAPvIXKUjPSxyZsq8WhbaM2tszWkPZPubdcMIIG7TCCBNWgAwIBAgIQ
# CoDvGEuN8QWC0cR2p5V0aDANBgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0
# ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMB4XDTI1
# MDYwNDAwMDAwMFoXDTM2MDkwMzIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNV
# BAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBTSEEyNTYgUlNB
# NDA5NiBUaW1lc3RhbXAgUmVzcG9uZGVyIDIwMjUgMTCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBANBGrC0Sxp7Q6q5gVrMrV7pvUf+GcAoB38o3zBlCMGMy
# qJnfFNZx+wvA69HFTBdwbHwBSOeLpvPnZ8ZN+vo8dE2/pPvOx/Vj8TchTySA2R4Q
# KpVD7dvNZh6wW2R6kSu9RJt/4QhguSssp3qome7MrxVyfQO9sMx6ZAWjFDYOzDi8
# SOhPUWlLnh00Cll8pjrUcCV3K3E0zz09ldQ//nBZZREr4h/GI6Dxb2UoyrN0ijtU
# DVHRXdmncOOMA3CoB/iUSROUINDT98oksouTMYFOnHoRh6+86Ltc5zjPKHW5KqCv
# pSduSwhwUmotuQhcg9tw2YD3w6ySSSu+3qU8DD+nigNJFmt6LAHvH3KSuNLoZLc1
# Hf2JNMVL4Q1OpbybpMe46YceNA0LfNsnqcnpJeItK/DhKbPxTTuGoX7wJNdoRORV
# bPR1VVnDuSeHVZlc4seAO+6d2sC26/PQPdP51ho1zBp+xUIZkpSFA8vWdoUoHLWn
# qWU3dCCyFG1roSrgHjSHlq8xymLnjCbSLZ49kPmk8iyyizNDIXj//cOgrY7rlRyT
# laCCfw7aSUROwnu7zER6EaJ+AliL7ojTdS5PWPsWeupWs7NpChUk555K096V1hE0
# yZIXe+giAwW00aHzrDchIc2bQhpp0IoKRR7YufAkprxMiXAJQ1XCmnCfgPf8+3mn
# AgMBAAGjggGVMIIBkTAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBTkO/zyMe39/dfz
# kXFjGVBDz2GM6DAfBgNVHSMEGDAWgBTvb1NK6eQGfHrK4pBW9i/USezLTjAOBgNV
# HQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwgZUGCCsGAQUFBwEB
# BIGIMIGFMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXQYI
# KwYBBQUHMAKGUWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRy
# dXN0ZWRHNFRpbWVTdGFtcGluZ1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNydDBfBgNV
# HR8EWDBWMFSgUqBQhk5odHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRU
# cnVzdGVkRzRUaW1lU3RhbXBpbmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcmwwIAYD
# VR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4IC
# AQBlKq3xHCcEua5gQezRCESeY0ByIfjk9iJP2zWLpQq1b4URGnwWBdEZD9gBq9fN
# aNmFj6Eh8/YmRDfxT7C0k8FUFqNh+tshgb4O6Lgjg8K8elC4+oWCqnU/ML9lFfim
# 8/9yJmZSe2F8AQ/UdKFOtj7YMTmqPO9mzskgiC3QYIUP2S3HQvHG1FDu+WUqW4da
# IqToXFE/JQ/EABgfZXLWU0ziTN6R3ygQBHMUBaB5bdrPbF6MRYs03h4obEMnxYOX
# 8VBRKe1uNnzQVTeLni2nHkX/QqvXnNb+YkDFkxUGtMTaiLR9wjxUxu2hECZpqyU1
# d0IbX6Wq8/gVutDojBIFeRlqAcuEVT0cKsb+zJNEsuEB7O7/cuvTQasnM9AWcIQf
# VjnzrvwiCZ85EE8LUkqRhoS3Y50OHgaY7T/lwd6UArb+BOVAkg2oOvol/DJgddJ3
# 5XTxfUlQ+8Hggt8l2Yv7roancJIFcbojBcxlRcGG0LIhp6GvReQGgMgYxQbV1S3C
# rWqZzBt1R9xJgKf47CdxVRd/ndUlQ05oxYy2zRWVFjF7mcr4C34Mj3ocCVccAvlK
# V9jEnstrniLvUxxVZE/rptb7IRE2lskKPIJgbaP5t2nGj/ULLi49xTcBZU8atufk
# +EMF/cWuiC7POGT75qaL6vdCvHlshtjdNXOCIUjsarfNZzGCBS0wggUpAgEBMFEw
# PTEWMBQGA1UECgwNUm9iZXJ0IEZhZGRlczEjMCEGA1UEAwwaRGF0dG9STU0uQ29y
# ZSBDb2RlIFNpZ25pbmcCEHjriJcd8jqCSwSQMNPKs2wwDQYJYIZIAWUDBAIBBQCg
# gYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0B
# CQQxIgQg0A2Brgdfsw1j9NMn9oAucb0vqBdjLOgDmJx4JGZm4kgwDQYJKoZIhvcN
# AQEBBQAEggEAXLsihVefXOYZC/DWV9+o+Xo19JqewH4Mg2cfQFDcztlRWK09DHdX
# QxdD9eMsV6fYpQk1wPalEfVqyS1GUrbNt7A5ldWaYHd8LAVdNbo+5ZK2HkhjA1FP
# D5Gc7Y0IWjpryvbfkEoUOdVLRF4wfCm3MmhdxMrHIWnzLKmK7rvjWP2Ka7tLR3tT
# anOeCBGADqTbEE7bV0fJq59LYvN/ytcxtXIDlAJGR5/MUTBjmfhkISaEmHpzU/P9
# b1K+HAk12K/ajmvfH7kW4EHSNYXe9S8ux52VUSoEqaJwp0wImCYualHhyv9iwM7b
# hzWcLb7h9p1RwShpaop3CXQzzCGf0miOZaGCAyYwggMiBgkqhkiG9w0BCQYxggMT
# MIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5j
# LjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNB
# NDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUD
# BAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0yNjAzMzEwMDMwNDFaMC8GCSqGSIb3DQEJBDEiBCA3EFU024u96FYZT9jxE43c
# uTnaX9d3dfvucxsV4hWwLDANBgkqhkiG9w0BAQEFAASCAgAscyFsp+zZ+MyQlvmE
# FwDZ6fxF30CDzJZAhEAIhfsowyeuhyJMyvYhEgJw39kI16nd8/68jhEDIoHmr6ko
# kizh17rHFSDiPxw3jr2pmB6njirKjtVVMNzGcy0d/YH39rPks6Nm9JzVFbXcQg6L
# LyhJAJGBv6CKQ7qzeltzomYhrsablfZ2Eka37E3jMjJ6sfCzTu8y/7QSlujLv/fW
# a7dqZKUVpY3p7/gQaCSYOkYp0jRFNzlLSTjImtGdowpPO/ndO2RsR+B9AaEOSIGa
# xeIqzYfPo11Dy0GnFAt3sObbnsUftvanyQgrtkQVe/yZ8FPVYbQCiWO+BbVtE68E
# liYqyvU3dwNsx74NunH7NZDL91k8SlO5dz3I9fFnM1cvlr4dHIYkWZX0Mz9V3Twn
# QJRF4rZe/eazxGOHdSbR5JrRQHRsBhKOAhi8UVg5tOs7n8WRcVk2Y77JI64WmHiA
# DCZQdBsQ5CJwZEG4NqlzgbwT27cPhxeD2KR7vML6ps+cLCPO8uKR7yh/fRuk0tgK
# dPkK06LXicZc+xm0Xudi+XjPacgG5gf8zidJVL+oi8BzKhE11LbnhVRiiiGgenGb
# qy4YLKICN3aF+cSnP3AbN18100krYHGKNbLeCwoB72VtCi94AMd3U1Klx+XUIfjP
# ke/CwS1fEgo+PLwIn16+VPOEyQ==
# SIG # End signature block
