<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
#region DRMMObject - Base Class
class DRMMObject {

    DRMMObject() {}

    static <#
 .SYNOPSIS
     Safely retrieves the value of a specified property from a PSCustomObject, returning null if the property does not exist.
 .OUTPUTS
     The value associated with the specified key in the input object, or null if the key does not exist.
 #>
 [object] GetValue([pscustomobject]$InputObject, [string]$Key) {

        if ($null -eq $InputObject) {

            return $null

        }

        if ($InputObject.PSObject.Properties.Name -contains $Key) {

            return $InputObject.$Key

        }

        return $null

    }

    static <#
 .SYNOPSIS
     Validates that a PSCustomObject contains all specified required properties, used to verify API response structures before processing.
 .OUTPUTS
     A boolean value indicating whether the sample object contains all the required properties.
 #>
 [bool] ValidateShape([pscustomobject]$Sample, [string[]]$RequiredProperties) {

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

    static <#
 .SYNOPSIS
     Handle numeric epoch timestamps (int, long, double, or numeric strings)
 .OUTPUTS
     The DateTime representation of the given API date value, or null if the value cannot be parsed as a date.
 #>
 [hashtable] ParseApiDate([object]$Value) {

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

    static <#
 .SYNOPSIS
     Masks a string value by replacing characters beyond a specified visible count with a mask character, used to obscure sensitive data such as API keys or secrets.
 .OUTPUTS
     The masked string with the specified number of visible characters at the start.
 #>
 [string] MaskString([string]$Value, [int]$VisibleChars = 1, [string]$MaskChar = '*') {

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