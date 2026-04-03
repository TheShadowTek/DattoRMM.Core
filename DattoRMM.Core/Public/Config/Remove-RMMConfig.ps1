<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Remove-RMMConfig {
    <#
    .SYNOPSIS
        Deletes the persistent DattoRMM.Core configuration file (factory reset for future sessions).

    .DESCRIPTION
        Remove-RMMConfig deletes the configuration file at $HOME/.DattoRMM.Core/config.json, removing all saved settings.
        This does not affect the current session or in-memory configuration.
        To apply defaults in the current session, use Set-RMMConfig -Default or reload the module.

    .PARAMETER Force
        Bypasses the confirmation prompt and immediately deletes the configuration file.

    .EXAMPLE
        Remove-RMMConfig

        Prompts for confirmation before deleting the configuration file.

    .EXAMPLE
        Remove-RMMConfig -Force

        Deletes the configuration file without prompting for confirmation.

    .INPUTS
        None. You cannot pipe objects to Remove-RMMConfig.

    .OUTPUTS
        None. Displays a message indicating success or failure.

    .NOTES
        Configuration file location: $HOME/.DattoRMM.Core/config.json
        This function only deletes the configuration file. Current session values remain unchanged until the module is reloaded.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Config/Remove-RMMConfig.md

    .LINK
        Save-RMMConfig
        Get-RMMConfig
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [switch]
        $Force
    )

    $ConfigPath = $Script:ConfigPath

    if (-not (Test-Path $ConfigPath)) {

        Write-Warning "No configuration file exists. Nothing to delete."
        return

    }

    if ($Force -or $PSCmdlet.ShouldProcess("DattoRMM.Core configuration $ConfigPath", "Delete config file")) {

        try {

            Remove-Item -Path $ConfigPath -Force -ErrorAction Stop
            Write-Host "Configuration file deleted. Defaults will be used in future sessions." -ForegroundColor Green
            Write-Warning "Current session configuration remains active. Reload the module to apply defaults."

        } catch {

            Write-Error "Failed to delete configuration file: $_"

        }
    }
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC6qxwRVC0/3jaa
# FuzLIBxAQGJZ8igoJvY4+XIBske+daCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICjtJwewax+zN7gvjf77DFvs3ODk
# khbqLm/z9IO3IYJJMA0GCSqGSIb3DQEBAQUABIIBADJ+LsQhwVrA0R5jfcJ3xrhE
# Ls2BknXZuxh/rHaPVCW3mGldzhIoWchDwRjJ4xu6PNs/RgElGlYOlMXkm7cGFXs5
# fDE0zJ3Fcq+EYHriDJtWBPKkSpve29+JvsNdY99HrsLACYaXs5/8w2FDDYxmh2My
# yc6Ln+3TlpLyeUtuD+RyZ708RSYgu80jk+dsEHc5/I1QSzOT9rnz6vaKdqU9ymgC
# C1Ipqc00VhVF4bdsAwlTCOtR6SXtIJ/IDMdFRnqLyPzWqarWbQYJTbg6WwbIi1a5
# EEO1aIqyw1Db3tdO/WkYqeQmxY4ngfcSOzIiU+8NSCTuTXtxeX7vLUYx64S+FoY=
# SIG # End signature block
