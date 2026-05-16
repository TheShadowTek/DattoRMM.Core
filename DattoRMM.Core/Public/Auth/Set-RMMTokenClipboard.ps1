<#
	Copyright (c) 2025-2026 Robert Faddes
	SPDX-License-Identifier: MPL-2.0
#>
function Set-RMMTokenClipboard {
	<#
	.SYNOPSIS
		Copies the current Datto RMM API access token to the clipboard.

	.DESCRIPTION
		Copies the current session access token to the system clipboard.
		No token value is written to the console, terminal output, or transcript.

		WARNING: The access token is sensitive. Clipboard managers, cloud clipboard
		synchronisation (Windows 11 Cloud Clipboard), and other applications running in
		the same user session may access clipboard content. Clear the clipboard after use.

		If Windows Cloud Clipboard synchronisation is enabled, the token may be transmitted
		to Microsoft servers. Disable Cloud Clipboard before using this command in
		sensitive environments.

	.NOTES
		This command requires confirmation and has ConfirmImpact set to High.
		Use -Force to suppress the confirmation prompt in automation scripts.

	.EXAMPLE
		Set-RMMTokenClipboard
		Copies the current API access token to the clipboard after confirmation.

	.EXAMPLE
		Set-RMMTokenClipboard -Force
		Copies the token to the clipboard without prompting for confirmation.

	.LINK
		https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Set-RMMTokenClipboard.md

	.LINK
		Connect-DattoRMM

	.LINK
		Disconnect-DattoRMM

	.LINK
		about_DattoRMM.CoreAuthentication
	#>
	[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
	param(
		[switch]
        $Force
	)

	if ($null -eq $Script:RMMAuth) {

		throw "No authentication token found. Please connect first."

	}

	Write-Warning "The access token is sensitive. Clear the clipboard after use. Cloud Clipboard synchronisation may expose this value outside the current session."

	if ($Force -or $PSCmdlet.ShouldProcess("clipboard", "Copy API access token")) {

		Set-Clipboard -Value $Script:RMMAuth.AccessToken
		Write-Host "Access token copied to clipboard."

	}
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDn05mkPt9Wr9XE
# 03GNivu23EUXsZzIwwnbBHDDjfRqZ6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFwNGazyn2cNKTGSJ7pnREZd0L7F
# 7CWx0lToF6oS4zgvMA0GCSqGSIb3DQEBAQUABIIBAFWX5N7umm7UJOqegwlLjVem
# nmTf4JB8CNmure6IE9w205h1Mat9fvQ1Y9pDLVrlObPAYhYDYBAFdFlEN2tYtOVo
# SLUaGLwYwZSP+UAzcqis8WGIM9TuVmNUCLZjS3oiNYdncZZ+ipniHvvCqi7Tucft
# AZarhd/YIERK4JmyjvJx1OOHzozuKIIjt8e6tC5hzSzhEVzex75CywYbjJKOVCz0
# Tbbt2eGcvIKIDiJQde2yQ9Xq4bYyx6ebtdD7aT2lvpVAUKYHBJ9EpALOW+1GrYn/
# tjhuTw3O7iBaa5jRIEhk/IqyYuGDh1MIvo/bjBcGMVlzC/yiRE9dFiHZ8xTUXU0=
# SIG # End signature block
