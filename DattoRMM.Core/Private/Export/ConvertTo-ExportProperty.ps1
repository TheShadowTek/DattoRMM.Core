<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Converts export transform entries into Select-Object-compatible property definitions.
.DESCRIPTION
    Takes an array of transform entries from ExportTransforms.psd1 and converts them into
    an array suitable for Select-Object -Property.

    Simple string entries are passed through as direct property names.

    Hashtable entries with a Name key support three resolution modes:

    Path    — Dot-notation for nested property access (e.g. 'DevicesStatus.NumberOfDevices').
              Also resolves ETS ScriptProperties added via Types.ps1xml.
              Validated against ^[a-zA-Z_][a-zA-Z0-9_.]*$ to prevent injection.

    Method  — A parameterless method name (e.g. 'GetSummary'). Resolves class methods and
              ETS ScriptMethods added via Types.ps1xml.
              Validated against ^[a-zA-Z_][a-zA-Z0-9_]*$ to prevent injection.

    Expression — A string expression evaluated as a scriptblock (e.g. '$_.GetSummary()').
                 Supports member access on $_, string operations, conditionals, and comparisons.
                 Validated by Test-ExportExpression using layered security:
                   1. Length cap (500 characters)
                   2. ASCII character whitelist
                   3. PowerShell AST parsing with whitelisted node types only
                   4. Variable restriction ($_ $null $true $false only)
                 Cmdlet calls, .NET type access, arbitrary variables, assignments,
                 redirections, and scriptblock literals are blocked.

    If a hashtable contains more than one of Path, Method, or Expression, the entry is
    skipped with a warning.
#>
function ConvertTo-ExportProperty {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory = $true)]
        [array]
        $TransformEntries

    )

    $Properties = [System.Collections.Generic.List[object]]::new()

    foreach ($Entry in $TransformEntries) {

        if ($Entry -is [string]) {

            $Properties.Add($Entry)

        } elseif ($Entry -is [hashtable] -and $Entry.ContainsKey('Name')) {

            $PropertyName = $Entry.Name

            # Count how many resolution keys are present
            $ResolutionKeys = @('Path', 'Method', 'Expression') | Where-Object {$Entry.ContainsKey($_)}

            if ($ResolutionKeys.Count -ne 1) {

                Write-Warning "Skipping transform property '$PropertyName': must contain exactly one of Path, Method, or Expression (found: $($ResolutionKeys -join ', '))"
                continue

            }

            $Calculated = $null

            if ($Entry.ContainsKey('Path')) {

                $PropertyPath = $Entry.Path

                # Validate path contains only safe property-access characters
                if ($PropertyPath -notmatch '^[a-zA-Z_][a-zA-Z0-9_.]*$') {

                    Write-Warning "Skipping transform property '$PropertyName': invalid path '$PropertyPath'"
                    continue

                }

                $Calculated = @{
                    Name = $PropertyName
                    Expression = [scriptblock]::Create("`$_.$PropertyPath")
                }

            } elseif ($Entry.ContainsKey('Method')) {

                $MethodName = $Entry.Method

                # Validate method name contains only safe identifier characters
                if ($MethodName -notmatch '^[a-zA-Z_][a-zA-Z0-9_]*$') {

                    Write-Warning "Skipping transform property '$PropertyName': invalid method name '$MethodName'"
                    continue

                }

                $Calculated = @{
                    Name = $PropertyName
                    Expression = [scriptblock]::Create("`$_.$MethodName()")
                }

            } elseif ($Entry.ContainsKey('Expression')) {

                $ExpressionString = $Entry.Expression

                # Layered validation: length, characters, AST nodes, variable restriction
                if (-not (Test-ExportExpression -Expression $ExpressionString -PropertyName $PropertyName)) {

                    continue

                }

                $Calculated = @{
                    Name = $PropertyName
                    Expression = [scriptblock]::Create($ExpressionString)
                }
            }

            if ($Calculated) {

                $Properties.Add($Calculated)

            }

        } else {

            Write-Warning "Skipping unrecognised transform entry: $($Entry | ConvertTo-Json -Compress -Depth 1)"

        }
    }

    return $Properties.ToArray()
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAJU25ookLbBfwe
# dWMbb9cCmizhZ6FIYi7x52ZSv0js3aCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIdlH7Sj1PRsB0lFmn6Y0wck0FBD
# CF4YPwuIHPIDnB3vMA0GCSqGSIb3DQEBAQUABIIBAJiFx0N3UJw2TD2TAITONQGB
# bz/IZF1aFg0WEu9CWUWvQrk9pbXMgmsJabCii/jIaQLUL2nKijWNuE1NjbpB8Kt0
# qDh1CZ1cVoMnRctS90zctj/XkQ0CjTbIm65D6TogE8P/nE1bzP1O+fUFVI9/O/pq
# zAWXkDxzw/3FRbJ5x9wbM1FMy/EJnJAXkeB/bGj2/ngw8lsWo6tQNxuCQTVj0kjv
# ZsQ+wVMTn5wrbxkmCmGPP9zrRQFcY1ur6avrhoswFGzRY2aFwFztTw6DkbPlUz/B
# NTr0C82zOP2BhAoTphGAuqVgSoTQVFdUrpaswL1lGUkHL+6Zk0pYILg1ctLxZHs=
# SIG # End signature block
