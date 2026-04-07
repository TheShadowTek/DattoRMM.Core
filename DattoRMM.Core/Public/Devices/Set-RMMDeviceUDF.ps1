<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Set-RMMDeviceUdf {
    <#
    .SYNOPSIS
        Sets user-defined fields on a device in Datto RMM.

    .DESCRIPTION
        The Set-RMMDeviceUdf function updates one or more user-defined fields (UDF1-UDF30) on a
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
        Set-RMMDeviceUdf -DeviceUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -UDF1 "Department: IT" -UDF2 "Owner: John"

        Sets UDF1 and UDF2 on a device, leaving other UDFs unchanged.

    .EXAMPLE
        Get-RMMDevice -Hostname "SERVER01" | Set-RMMDeviceUdf -UDF5 "Production" -UDF10 "Critical"

        Updates UDF5 and UDF10 via pipeline.

    .EXAMPLE
        Set-RMMDeviceUdf -DeviceUid $DeviceUid -UDF1 "" -Force

        Clears UDF1 (sets to null) without confirmation.

    .EXAMPLE
        Get-RMMDevice -FilterId 100 | Set-RMMDeviceUdf -UDF3 "Datacenter: East"

        Updates UDF3 for all devices in filter 100.

    .EXAMPLE
        Set-RMMDeviceUdf -DeviceUid $DeviceUid -UDFFields @{udf1='IT Department'; udf2='John Smith'; udf5=''}

        Updates multiple UDF fields using a hashtable. UDF5 is cleared.

    .EXAMPLE
        $UDFs = @{udf10='Production'; udf15='Critical'; udf20='Datacenter: West'}
        PS > Get-RMMDevice -Hostname "SERVER*" | Set-RMMDeviceUdf -UDFFields $UDFs -Force

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
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceUidHashtable',
            Mandatory = $true
        )]
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
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCL44i16jiRWxHX
# 9erdvHLA7xA1B0CIhP3c/WGkCmBoJ6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDbQJo2cc1Uyqrv/I83Um/OuG9pU
# Xbwx5ybEReMvqx3aMA0GCSqGSIb3DQEBAQUABIIBAGZuW0JS8vpUEAdEsa2X+baD
# z8QTG/SqXJqWheAaIy+7+UE1t2Wku/xUCGJA1oePGTGdf6l6jIhTBMF83SGTrZ8c
# zj4wjQtcdZZ4tK00gB/LXbvG1KB7qymLDTc7tlcF10lDHBy3GI2NnOZiI9FgGDeD
# RpE8GTE/zjXFUYwaOj5m+GIcgGtTjAGwDabz61oMKyfjP39HNbjOaIkXTFR9g1aZ
# 5o/u1kGUULuUwODiAHzsYQXajzYV7rWOrbuq70qtb/DbGlugUReNSlEqAcbF41kW
# XuTCGtKOBzvg4u6nGgbVKyVTpc7j4Roil3WgCJYa5iizgt5e0xbRzKUowcqoAP8=
# SIG # End signature block
