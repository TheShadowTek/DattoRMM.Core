<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
#region DRMMObject - Base Class
<#
.SYNOPSIS
    Base class for all DattoRMM.Core domain objects, providing shared utility methods for API response parsing, property access, and data masking.
.DESCRIPTION
    The DRMMObject class is the root base class for all domain model classes in the DattoRMM.Core module. It provides a set of shared static utility methods used across the class hierarchy: safe property value retrieval (GetValue), API date parsing that handles both epoch timestamps and ISO 8601 strings (ParseApiDate), sensitive data masking (MaskString), and API response shape validation (ValidateShape). All domain classes inherit from DRMMObject and gain access to these utilities without needing to reimplement them.
#>
class DRMMObject {

    DRMMObject() {}

    <#
    .SYNOPSIS
        Safely retrieves the value of a specified property from a PSCustomObject, returning null if the property does not exist.
    .DESCRIPTION
        The GetValue method checks whether the specified key exists on the input object before accessing it, preventing property-not-found errors when processing API responses that may omit optional fields.
    .OUTPUTS
        The value of the named property on the input object, or null if the object is null or the property does not exist.
    #>
    static [object] GetValue([pscustomobject]$InputObject, [string]$Key) {

        if ($null -eq $InputObject) {

            return $null

        }

        if ($InputObject.PSObject.Properties.Name -contains $Key) {

            return $InputObject.$Key

        }

        return $null

    }

    <#
    .SYNOPSIS
        Validates that a PSCustomObject contains all specified required properties, used to verify API response structures before processing.
    .DESCRIPTION
        The ValidateShape method guards against malformed or incomplete API responses by confirming that all expected property names are present on the sample object before the caller attempts to access them. Returns false if the sample or required properties list is null.
    .OUTPUTS
        True if the sample object contains all required properties; false otherwise.
    #>
    static [bool] ValidateShape([pscustomobject]$Sample, [string[]]$RequiredProperties) {

        if ($null -eq $Sample -or $null -eq $RequiredProperties) {

            return $false

        }

        $Names = $Sample.PSObject.Properties.Name
        foreach ($Prop in $RequiredProperties) {

            if (-not ($Names -contains $Prop)) {

                return $false

            }

        }

        return $true

    }

    <#
    .SYNOPSIS
        Parses an API date value that may be an epoch timestamp (milliseconds or seconds) or an ISO 8601 string, normalising it to a UTC DateTime.
    .DESCRIPTION
        The ParseApiDate method handles the variety of date formats returned by the Datto RMM API. Numeric values larger than 9,999,999,999 are treated as millisecond epoch timestamps; smaller numeric values are treated as second epoch timestamps. String values are parsed as ISO 8601. The DateTime.MinValue sentinel (-62135596800000 ms) is treated as null. If parsing fails entirely, DateTime and Epoch are returned as null with the original Raw value preserved.
    .OUTPUTS
        A hashtable with three keys: DateTime (UTC System.DateTime or null), Epoch (Unix timestamp in seconds as long, or null), and Raw (the original input value).
    #>
    static [hashtable] ParseApiDate([object]$Value) {

        if ($null -eq $Value) {

            return @{ DateTime = $null; Epoch = $null; Raw = $null }

        }

        # Handle numeric epoch timestamps (int, long, double, or numeric strings)
        if ($Value -is [int] -or $Value -is [long] -or $Value -is [double] -or ($Value -is [string] -and $Value -match '^\-?\d+(\.\d+)?$')) {

            $Num = [double]$Value

            # Treat DateTime.MinValue sentinel as null (-62135596800000 ms or -62135596800 seconds)
            if ($Num -eq -62135596800000 -or $Num -eq -62135596800) {

                return @{ DateTime = $null; Epoch = $null; Raw = $Value }

            }

            if ($Num -gt 9999999999) {

                # Milliseconds
                $Dto = [DateTimeOffset]::FromUnixTimeMilliseconds([long]$Num)
                $EpochSeconds = [long]$Dto.ToUnixTimeSeconds()

            } elseif ($Num -lt -9999999999) {

                # Negative milliseconds
                $Dto = [DateTimeOffset]::FromUnixTimeMilliseconds([long]$Num)
                $EpochSeconds = [long]$Dto.ToUnixTimeSeconds()

            } else {

                # Seconds (possibly with decimal milliseconds)
                $Dto = [DateTimeOffset]::FromUnixTimeSeconds($Num)
                $EpochSeconds = [long]$Num

            }

            return @{ DateTime = $Dto.UtcDateTime; Epoch = $EpochSeconds; Raw = $Value }

        }

        try {

            $Dto = [DateTimeOffset]::Parse([string]$Value)
            $EpochSeconds = [long]$Dto.ToUnixTimeSeconds()
            return @{ DateTime = $Dto.UtcDateTime; Epoch = $EpochSeconds; Raw = $Value }

        } catch {

            return @{ DateTime = $null; Epoch = $null; Raw = $Value }

        }
    }

    <#
    .SYNOPSIS
        Masks a string value by replacing characters beyond a specified visible count with a mask character, used to obscure sensitive data such as API keys or secrets.
    .DESCRIPTION
        The MaskString method returns a version of the input string where only the first VisibleChars characters are shown and the remainder are replaced with MaskChar (default: asterisk). If the string is null or empty, three mask characters are returned. If the string is shorter than or equal to VisibleChars, the entire string is masked. This method is used to protect sensitive data in verbose and debug output.
    .OUTPUTS
        The masked string, with VisibleChars characters visible at the start and the remainder replaced by the MaskChar character.
    #>
    static [string] MaskString([string]$Value, [int]$VisibleChars = 1, [string]$MaskChar = '*') {

        if ($null -eq $Value -or $Value -eq '') {

            return ($MaskChar * 3)

        }

        $StringValue = [string]$Value
        if ($VisibleChars -le 0) {

            return ($MaskChar * $StringValue.Length)

        }

        if ($StringValue.Length -le $VisibleChars) {

            return ($MaskChar * $StringValue.Length)

        }

        $Visible = $StringValue.Substring(0, [math]::Min($VisibleChars, $StringValue.Length))
        $MaskedCount = $StringValue.Length - $Visible.Length
        return ($Visible + ($MaskChar * $MaskedCount))

    }
}
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC5qlFKjy/eHdng
# +s6kicCrBC4gz64u0UKv2Nl0WKHpXqCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIiHyAJW/5ObFN9swfTcrcDk3gqf
# na4CR1ZXvxpPfS9XMA0GCSqGSIb3DQEBAQUABIIBAAmwpu/mOGa+JkRdGc4pr7dB
# xOa6uUpVWzoD1w44Ieo/YdSNS1U/5Db/A7QsJXlM92BHZCfMuwwiy/KC0ZEQFo3H
# RgTJ66VTKt3NsYFHyVFla7mMvpaGfDj7gm4G1tJHFKlitswa4+E+uEhBDCbL8k2M
# j2+C8JjPEYcmdBqxH/qfyuY8cTxKhHDEoRFTN0/BE791t5fXqaFX2p9uUsaIUpF2
# jtq6gm9WDx2f18mEuypZb0F2x52IyrktFPe0HnxLrjs4pmYOC+Q+DqON4bydwHxu
# akc1qC9PSccSu381ir3Ku+u9RxpihpfxVh6DfpeRmyKqyUw8nv5ImYuPqgM74C4=
# SIG # End signature block
