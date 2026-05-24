<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Resolves an API path and HTTP method to a rate-limit operation name.
.DESCRIPTION
    Uses the explicit operation mapping table to classify an API request. If no explicit
    match is found, infers an operation name from the path structure and HTTP method using
    Datto RMM naming conventions. Returns $null for GET requests, which are not write-limited.
    Unknown write operations emit a debug trace indicating inference.
#>
function Resolve-ThrottleOperationName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method
    )

    # GET requests are never write-limited — no operation name needed
    if ($Method -eq 'Get') {

        return $null

    }

    # Normalise: strip query parameters and any leading api/v2/ or v2/ prefix
    $NormPath = ($Path -replace '\?.*$', '') -replace '^(api/)?v2/', '' -replace '^/', ''

    # Replace GUIDs and numeric IDs in path segments with {id} placeholder for mapping lookup
    $TemplatePath = $NormPath -replace '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}', '{id}' -replace '(?<=(/|^))\d+(?=(/|$))', '{id}'

    # Try explicit mapping first
    $MapKey = "$($Method.ToString().ToUpper()):$TemplatePath"

    if ($Script:OperationMapping.ContainsKey($MapKey)) {

        Write-Debug "Throttle: Operation classified via mapping — $MapKey → $($Script:OperationMapping[$MapKey])"
        
        return $Script:OperationMapping[$MapKey]

    }

    # Fallback: infer operation name from path segments and HTTP method
    $Segments = ($TemplatePath -replace '/{id}', '' -replace '{id}/', '' -replace '{id}', '') -split '/' | Where-Object {$_}

    $MethodSuffix = switch ($Method.ToString().ToUpper()) {

        'POST' {'update'}
        'PUT' {'create'}
        'DELETE' {'delete'}
        'PATCH' {'update'}
        default {'unknown'}

    }

    $InferredName = ($Segments -join '-') + "-$MethodSuffix"
    Write-Debug "Throttle: Operation name inferred (no explicit mapping) — $MapKey → $InferredName"

    return $InferredName

}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAkrAv4jX1gGyeI
# sLr835sv+9eH69enRIpUAUP5O1V4cqCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIIgHGbXurszacvPCGdFSy0uDK9e
# ipvnU77D/J70Q8GbMA0GCSqGSIb3DQEBAQUABIIBAF+imQ3y1VkSnsobZBcXv3x7
# 6UmoHUx0QVF0gTwBKzY8R+rXEhUs3owSFXFOuzQLO1NNkgbs8USGcwcbdevGqnkv
# jtWwN4r9xAnA7dTCJiVTJlOV1LQn8ePVZiCUd+khLs3WSxM8eXi4jOJvBzsmh5v8
# FOJVdF95iCNdGPPNULgZABfZ86uQi4ynAxjYcWyJoNf91j061/dkW0eXN9Yx1Hm0
# WGPOuSRwa/32EocHyWz8nlSBfhI0VAZpU563YZtuuJixIrbcirHips1OMpnaJ14j
# iRGiwzbc8MTT7nDNEg1gqRqNv4wqockoRw0a+3TJi/34ry1zQYY8EHWBtyQm4ls=
# SIG # End signature block
