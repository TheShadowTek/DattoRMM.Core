<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Set-RMMDeviceUdf {
    <#
    .SYNOPSIS
        Sets user-defined fields on a device in Datto RMM.

    .DESCRIPTION
        The Set-RMMDeviceUdf function updates one or more user-defined fields (Udf1-Udf300) on a
        device in the Datto RMM system. UDFs are custom fields that can store additional metadata
        about devices for organisational and reporting purposes.

        The function supports two modes of operation:
        - Hashtable mode: Use -UdfFields to update multiple UDFs at once with a hashtable of
          key-value pairs (e.g., @{udf1='Value1'; udf50='Value50'}).
        - Single mode: Use -UdfNumber and -UdfValue to update a single UDF by number.

        Important behaviors:
        - Fields included in the request with empty values will be cleared (set to null)
        - Fields not included in the request will retain their current values
        - You only need to specify the fields you want to update
        - UDF values are limited to 255 characters

    .PARAMETER Device
        A DRMMDevice object to update. Accepts pipeline input from Get-RMMDevice.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of the device to update.

    .PARAMETER UdfFields
        A hashtable of UDF fields to update. Keys should be in the format 'udf1', 'udf2', etc.
        Values are limited to 255 characters each.
        Example: @{udf1='Value1'; udf5='Value5'; udf10=''}
        Cannot be used with -UdfNumber/-UdfValue parameters.

    .PARAMETER UdfNumber
        The UDF number (1-300) to update. Must be used with -UdfValue.
        Cannot be used with -UdfFields parameter.

    .PARAMETER UdfValue
        The value to set for the specified UDF. Limited to 255 characters.
        Set to empty string to clear the field. Must be used with -UdfNumber.
        Cannot be used with -UdfFields parameter.

    .PARAMETER Force
        Bypasses the confirmation prompt.

    .EXAMPLE
        Set-RMMDeviceUdf -DeviceUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -UdfNumber 1 -UdfValue "Department: IT"

        Sets Udf1 on a device, leaving other UDFs unchanged.

    .EXAMPLE
        Set-RMMDeviceUdf -DeviceUid $DeviceUid -UdfFields @{udf1='IT Department'; udf2='John Smith'; udf5=''}

        Updates multiple UDF fields using a hashtable. Udf5 is cleared.

    .EXAMPLE
        Set-RMMDeviceUdf -DeviceUid $DeviceUid -UdfNumber 1 -UdfValue '' -Force

        Clears Udf1 (sets to null) without confirmation.

    .EXAMPLE
        Get-RMMDevice -FilterId 100 | Set-RMMDeviceUdf -UdfNumber 3 -UdfValue "Datacenter: East"

        Updates Udf3 for all devices in filter 100.

    .EXAMPLE
        $UDFs = @{udf10='Production'; udf15='Critical'; udf200='Datacenter: West'}
        PS > Get-RMMDevice -Hostname "SERVER*" | Set-RMMDeviceUdf -UdfFields $UDFs -Force

        Updates multiple UDF fields on all servers matching the hostname pattern without confirmation.

    .EXAMPLE
        Set-RMMDeviceUdf -DeviceUid $DeviceUid -UdfFields @{udf150='Custom Data'; udf275='Extended'}

        Sets high-numbered UDFs (available since Datto RMM 14.9.0).

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
    [CmdletBinding(DefaultParameterSetName = 'ByDeviceUidHashtable', SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(
            ParameterSetName = 'ByDeviceObjectHashtable',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceObjectSingle',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMDevice]
        $Device,

        [Parameter(
            ParameterSetName = 'ByDeviceUidHashtable',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceUidSingle',
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
        $UdfFields,

        [Parameter(
            ParameterSetName = 'ByDeviceObjectSingle',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceUidSingle',
            Mandatory = $true
        )]
        [ValidateRange(1, 300)]
        [int]
        $UdfNumber,

        [Parameter(
            ParameterSetName = 'ByDeviceObjectSingle',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceUidSingle',
            Mandatory = $true
        )]
        [ValidateLength(0, 255)]
        [AllowEmptyString()]
        [string]
        $UdfValue,

        [Parameter()]
        [switch]
        $Force
    )

    process {

        if ($Device) {

            $DeviceUid = $Device.Uid
            $DeviceName = $Device.Hostname

        } else {

            $DeviceName = "device $DeviceUid"
        }

        $Target = "device '$DeviceName' (UID: $DeviceUid)"

        if (-not $Force -and -not $PSCmdlet.ShouldProcess($Target, "Update user-defined fields")) {

            return
        }

        Write-Debug "Updating UDF fields for device $DeviceUid"

        # Build request body based on parameter set
        $Body = @{}

        if ($PSCmdlet.ParameterSetName -match 'Hashtable') {

            foreach ($Key in $UdfFields.Keys) {

                if ($Key -notmatch '^udf(\d{1,3})$') {

                    Write-Error "Invalid UDF key: '$Key'. Keys must be in the format 'udf1' through 'udf300'."
                    return
                }

                $Number = [int]$Matches[1]

                if ($Number -lt 1 -or $Number -gt [DRMMDeviceUdfs]::MaxUdfCount) {

                    Write-Error "Invalid UDF key: '$Key'. UDF number must be between 1 and $([DRMMDeviceUdfs]::MaxUdfCount)."
                    return
                }

                $Value = $UdfFields[$Key]

                if ($null -ne $Value -and $Value.Length -gt 255) {

                    Write-Error "UDF value for '$Key' exceeds 255 characters ($($Value.Length) characters)."
                    return
                }

                $Body[$Key.ToLower()] = $Value
            
            }

        } else {

            $Body["udf$UdfNumber"] = $UdfValue

        }

        if ($Body.Count -eq 0) {

            Write-Warning "No UDF fields were specified for update."
            return

        }

        Write-Verbose "Setting $($Body.Count) UDF field(s) on $Target"

        $ApiMethodParams = @{
            Path   = "device/$DeviceUid/udf"
            Method = 'Post'
            Body = $Body
        }

        Invoke-ApiMethod @ApiMethodParams | Out-Null
        
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
