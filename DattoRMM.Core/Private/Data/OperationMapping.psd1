<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>

# Maps HTTP method and normalised API path to the operation name used in operationWriteStatus.
# Path templates use {id} as a placeholder for any GUID or numeric identifier.
# Keys are formatted as 'METHOD:path/template' (no leading /v2/ or api/v2/ prefix).
# Values must match the keys returned by the API's operationWriteStatus response.

@{

    # PUT operations (creates and moves)
    'PUT:site' = 'site-create'
    'PUT:site/{id}/variable' = 'site-variable-create'
    'PUT:device/{id}/site/{id}' = 'device-move'
    'PUT:device/{id}/quickjob' = 'device-job-create'
    'PUT:account/variable' = 'account-variable-create'

    # POST operations (updates and actions)
    'POST:site/{id}' = 'site-update'
    'POST:site/{id}/variable/{id}' = 'site-variable-update'
    'POST:site/{id}/settings/proxy' = 'site-proxy-create'
    'POST:device/{id}/warranty' = 'device-warranty-create'
    'POST:device/{id}/udf' = 'device-udf-set'
    'POST:alert/{id}/resolve' = 'alert-resolve'
    'POST:account/variable/{id}' = 'account-variable-update'
    'POST:user/resetApiKeys' = 'user-reset-keys'

    # DELETE operations
    'DELETE:site/{id}/variable/{id}' = 'site-variable-delete'
    'DELETE:site/{id}/settings/proxy' = 'site-proxy-delete'
    'DELETE:account/variable/{id}' = 'account-variable-delete'

}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDSafKNKaQNev9R
# U7qj1bSX8cUGcOs4dJmKdW2BdafRFqCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDMGkWkeG9wrW89ctUs/+4ToAe+n
# 3IwmeuSwK8p9b76bMA0GCSqGSIb3DQEBAQUABIIBAJh+DtsplViFWnxGTYJZDiFG
# AgmiUNQdVdLbNNpy/VOF3scgbfnM+N5QBwJeAHUYxujeLixIES/eiRmIxsz3tLGk
# kEh+Bzu+Bi4js+JC8ec1ueRfrLcx+xpQmGDs0SmfNAnkiigk1c5Zr9b7jcrpQYMr
# QOjnwjgpU8vUtroeESvNdJ5BRA7bVPwIhnVvKfnwPcuTPPUZWqRJh6QT6OD7P8cu
# ObXKjh7aFueslABsKFAskSn+y4mkJYNa0exmJW8xyhJG2yanZJTUShRSfNckkt2q
# i/9Vo72U5OfelR8cs57gZsabBkrKgtjUaXSOj4P2wXa1weJS9ew88aLucYGucM4=
# SIG # End signature block
