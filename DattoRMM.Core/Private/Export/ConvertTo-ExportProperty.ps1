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
