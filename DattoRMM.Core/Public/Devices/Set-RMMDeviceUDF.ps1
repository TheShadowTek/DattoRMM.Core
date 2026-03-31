<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Set-RMMDeviceUDF {
    <#
    .SYNOPSIS
        Sets user-defined fields on a device in Datto RMM.

    .DESCRIPTION
        The Set-RMMDeviceUDF function updates one or more user-defined fields (UDF1-UDF30) on a
        device in the Datto RMM system. UDFs are custom fields that can store additional metadata
        about devices for organisational and reporting purposes.

        Important behaviors:
        - Fields included in the request with empty values will be cleared (set to null)
        - Fields not included in the request will retain their current values
        - You only need to specify the fields you want to update

    .PARAMETER Device
        A DRMMDevice object to update. Accepts pipeline input from Get-RMMDevice.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of the device to update.

    .PARAMETER UDF1 through UDF30
        User-defined field values (1-30). Each UDF parameter is optional.
        Set to empty string to clear a field, or omit to leave unchanged.
        Cannot be used with -UDFFields parameter.

    .PARAMETER UDFFields
        A hashtable of UDF fields to update. Keys should be in the format 'udf1', 'udf2', etc.
        Example: @{udf1='Value1'; udf5='Value5'; udf10=''}
        Cannot be used with individual UDF parameters.

    .PARAMETER Force
        Bypasses the confirmation prompt.

    .EXAMPLE
        Set-RMMDeviceUDF -DeviceUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -UDF1 "Department: IT" -UDF2 "Owner: John"

        Sets UDF1 and UDF2 on a device, leaving other UDFs unchanged.

    .EXAMPLE
        Get-RMMDevice -Hostname "SERVER01" | Set-RMMDeviceUDF -UDF5 "Production" -UDF10 "Critical"

        Updates UDF5 and UDF10 via pipeline.

    .EXAMPLE
        Set-RMMDeviceUDF -DeviceUid $DeviceUid -UDF1 "" -Force

        Clears UDF1 (sets to null) without confirmation.

    .EXAMPLE
        Get-RMMDevice -FilterId 100 | Set-RMMDeviceUDF -UDF3 "Datacenter: East"

        Updates UDF3 for all devices in filter 100.

    .EXAMPLE
        Set-RMMDeviceUDF -DeviceUid $DeviceUid -UDFFields @{udf1='IT Department'; udf2='John Smith'; udf5=''}

        Updates multiple UDF fields using a hashtable. UDF5 is cleared.

    .EXAMPLE
        $UDFs = @{udf10='Production'; udf15='Critical'; udf20='Datacenter: West'}
        PS > Get-RMMDevice -Hostname "SERVER*" | Set-RMMDeviceUDF -UDFFields $UDFs -Force

        Updates multiple UDF fields on all servers matching the hostname pattern without confirmation.

    .INPUTS
        DRMMDevice. You can pipe device objects from Get-RMMDevice.
        You can also pipe objects with DeviceUid or Uid properties.

    .OUTPUTS
        None. This function does not return any output.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Best practices for UDF usage:
        - Establish consistent naming conventions across your organisation
        - Document which UDFs are used for what purpose
        - Use UDFs for data that doesn't fit standard device properties
        - Consider using UDFs for: location, department, owner, cost center, project codes, etc.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Set-RMMDeviceUDF.md

    .LINK
        about_DRMMDevice

    .LINK
        Get-RMMDevice
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByDeviceUidIndividual', SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(
            ParameterSetName = 'ByDeviceObjectIndividual',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceObjectHashtable',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMDevice]
        $Device,

        [Parameter(
            ParameterSetName = 'ByDeviceUidIndividual',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceUidHashtable',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Uid')]
        [guid]
        $DeviceUid,

        [Parameter(
            ParameterSetName = 'ByDeviceObjectHashtable',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceUidHashtable',
            Mandatory = $true
        )]
        [hashtable]
        $UDFFields,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF1,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF2,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF3,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF4,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF5,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF6,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF7,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF8,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF9,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF10,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF11,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF12,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF13,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF14,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF15,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF16,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF17,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF18,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF19,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF20,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF21,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF22,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF23,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF24,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF25,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF26,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF27,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF28,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF29,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF30,

        [Parameter()]
        [switch]
        $Force
    )

    process {

        if ($Device) {

            $DeviceUid = $Device.Uid
            $DeviceName = $Device.Hostname
        }
        else {

            $DeviceName = "device $DeviceUid"
        }

        $Target = "device '$DeviceName' (UID: $DeviceUid)"

        if (-not $PSCmdlet.ShouldProcess($Target, "Update user-defined fields")) {

            return
        }

        Write-Debug "Updating UDF fields for device $DeviceUid"

        # Build request body based on parameter set
        $Body = @{}

        if ($PSCmdlet.ParameterSetName -match 'Hashtable') {

            # Validate hashtable keys
            $validUDFs = 1..30 | ForEach-Object {"udf$_"}

            foreach ($key in $UDFFields.Keys) {

                if ($key -notin $validUDFs) {

                    Write-Error "Invalid UDF key: $key. Valid keys are udf1 through udf30."
                    return

                }
            }

            # Add UDF fields from hashtable
            foreach ($key in $UDFFields.Keys) {

                $Body[$key.ToLower()] = $UDFFields[$key]

            }

        } else {

            # Add UDF fields from individual parameters
            for ($i = 1; $i -le 30; $i++) {

                $ParamName = "UDF$i"

                if ($PSBoundParameters.ContainsKey($ParamName)) {

                    $Body["udf$i"] = $PSBoundParameters[$ParamName]

                }
            }
        }

        if ($Body.Count -eq 0) {

            Write-Warning "No UDF fields were specified for update"
            return
        }

        $APIMethod = @{
            Path = "device/$DeviceUid/udf"
            Method = 'Post'
            Body = $Body
        }

        Invoke-ApiMethod @APIMethod | Out-Null
    }
}


# SIG # Begin signature block
# MIIcXwYJKoZIhvcNAQcCoIIcUDCCHEwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCL44i16jiRWxHX
# 9erdvHLA7xA1B0CIhP3c/WGkCmBoJ6CCFogwggNKMIICMqADAgECAhB464iXHfI6
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
# CQQxIgQgNtAmjZxzVTKqu/8jzdSb864b2lRdvDHnJsRF4y+rHdowDQYJKoZIhvcN
# AQEBBQAEggEAZm5bQlLy+lQQB0SxrZf5toPPxBMb9KpcmpaF4BojL7v5QTW3ZaS7
# /FQIYkDWh48ZMZ1/qXqMiFMEwXzdIZOtnxzOPjCNC1x1lni0rTSAH8tdu8bUoHur
# KYsNNzu2VwXXSUMcHLcYjY2c5mIj0WAYN4NGkTwZMT/ONcVRjBo6Pmb4YhyAa1OM
# AbANpvPrWgwrJ+M/f0c1uM5oiRdMVH2DVpnmj+7WQZRQu5TA4OIAfOxhBdqPNhXu
# tY6tu6rvSq1v8NsaW6BRF41KUSoBxsXjWRZe5MIa0o4HO+Di7qcaBtUrJVOlzuPh
# GiKXdaAIlhrmKLOC3l7TFtHMpSjByqgA/6GCAyYwggMiBgkqhkiG9w0BCQYxggMT
# MIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5j
# LjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNB
# NDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUD
# BAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0yNjAzMzEwMDMwMzZaMC8GCSqGSIb3DQEJBDEiBCAMJ2y6/6qswqe2z8KJp99N
# 2qqI6/mShdJKtYKhrJAsOTANBgkqhkiG9w0BAQEFAASCAgBVPUI+WSQ0STC0rFSf
# 9qB2lsQ0oWO9DcdqkOxhmq1SfOrozABaOBQjz98IcNQ6HNnVWrpOBax8qdOOSIkZ
# PcLSPty/JtT/NyQDMdOnqH6wT1xUkvlwx8gdgfQXOjhJg0WIS14ydsVCMG75J/1s
# OQ2vDWPAQ0ouYglhtMVEnKSpsveg+RpY3QwRhCsT1DCT7GhEt+hikJTqvi6jo0II
# 8XyiCZUNdSf6pFEiF3vkpxStDCRE+4MRdpIT1mr4jc9NLGQWsB5Rp7Lp3wUYVouv
# kQmGIm4Ezs5b1+lCoeM9Qh7rwbJwyI5+rc5Hqex9hheFTOuy24jppXprpM1mCy4s
# 995/sPizzOMfAQPkteqEnHhJIsme0703fbSyy5fZS9vGncbd1ztdpSY3fHAhjW7O
# VE5AwCIBND1pPkTnKWzV5Z+wGh2vbgIQ0zYnTnE8Y5wiUgMwhj70qVLmjrcKo72B
# hRJKJc13Q8Z9xOfnuGlfj6J7RqwI/m1qWusc58quLO7fLoKESfD9rb/oQQcJNS9G
# dW6A2IEn8OhZMbs1qJTeGFY3ZRhrMYU2yZBEwK5MSQNjAcBw2sECSpIfIRWau4/H
# utLzvOjHzXBLsqSUeQrV3e93+AT/SO5hCouxFUNAb/1EAMAVukzxXZVif5y1iSvB
# /BE7hfIO5RFEEnPk0zw71+3y3w==
# SIG # End signature block
