<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Validates an expression string for safe use in export transforms.
.DESCRIPTION
    Applies layered security validation to an expression string before it is converted
    to a scriptblock by ConvertTo-ExportProperty.

    Layer 1 — Length gate: rejects expressions longer than 500 characters.
    Layer 2 — Character whitelist: rejects expressions containing characters outside a
              safe ASCII set (letters, digits, common punctuation, comparison operators).
    Layer 3 — AST validation: parses the expression with the PowerShell parser and walks
              the entire AST tree. Only whitelisted node types are permitted. This blocks
              cmdlet/function calls, .NET type access, assignment statements, redirections,
              and scriptblock literals.
    Layer 4 — Variable restriction: only $_, $null, $true, and $false are permitted.
              Access to arbitrary variables ($env:, $Host, $Error, etc.) is blocked.

    Returns $true if the expression passes all layers, $false otherwise.
    Writes a verbose message describing the first failing layer.

    This function does not create or execute a scriptblock. It only validates.
#>
function Test-ExportExpression {
    [CmdletBinding()]
    [OutputType([bool])]
    param (

        [Parameter(Mandatory = $true)]
        [string]
        $Expression,

        [Parameter(Mandatory = $true)]
        [string]
        $PropertyName

    )

    # Layer 1: Length gate
    if ($Expression.Length -gt 500) {

        Write-Warning "Skipping transform property '$PropertyName': expression exceeds 500 character limit ($($Expression.Length) characters)"
        return $false

    }

    # Layer 2: ASCII character whitelist (fast gate before parsing)
    # Allows: letters, digits, underscore, whitespace, dot, $, (), {}, [], quotes,
    # backtick, comma, hyphen, colon, pipe, /, semicolon, =, !, <, >, ?, #, @, +, *, %
    if ($Expression -notmatch '^[A-Za-z0-9_\s\.\$\(\)\{\}\[\]''\"`,\-\:\|\/\;\=\!\<\>\?\#\@\+\*\%]+$') {

        Write-Warning "Skipping transform property '$PropertyName': expression contains disallowed characters"
        return $false

    }

    # Layer 3: AST validation — parse and walk the tree
    $ParseErrors = $null
    $Tokens = $null
    $Ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $Expression,
        [ref]$Tokens,
        [ref]$ParseErrors
    )

    if ($ParseErrors.Count -gt 0) {

        Write-Warning "Skipping transform property '$PropertyName': expression has syntax errors ($($ParseErrors[0].Message))"
        return $false

    }

    # Whitelisted AST node types — only structural, access, and conditional nodes
    $AllowedNodeTypes = @(
        'ScriptBlockAst'
        'NamedBlockAst'
        'StatementBlockAst'
        'PipelineAst'
        'CommandExpressionAst'
        'MemberExpressionAst'
        'InvokeMemberExpressionAst'
        'VariableExpressionAst'
        'StringConstantExpressionAst'
        'ExpandableStringExpressionAst'
        'ConstantExpressionAst'
        'BinaryExpressionAst'
        'UnaryExpressionAst'
        'IfStatementAst'
        'ParenExpressionAst'
        'SubExpressionAst'
        'ArrayExpressionAst'
        'ArrayLiteralAst'
        'IndexExpressionAst'
        'HashtableAst'
        'HashtablePairAst'
        'TernaryExpressionAst'
    )

    # Allowed variable names — only pipeline object and PowerShell built-in constants
    $AllowedVariables = @('_', 'null', 'true', 'false')

    $AstNodesAll = $Ast.FindAll({$true}, $true)

    foreach ($Node in $AstNodesAll) {

        $NodeTypeName = $Node.GetType().Name

        if ($NodeTypeName -notin $AllowedNodeTypes) {

            Write-Warning "Skipping transform property '$PropertyName': expression contains disallowed construct '$NodeTypeName'"
            return $false

        }

        # Layer 4: Variable restriction
        if ($Node -is [System.Management.Automation.Language.VariableExpressionAst]) {

            if ($Node.VariablePath.UserPath -notin $AllowedVariables) {

                Write-Warning "Skipping transform property '$PropertyName': expression references disallowed variable '`$$($Node.VariablePath.UserPath)'"
                return $false

            }
        }
    }

    Write-Debug "Expression validated for '$PropertyName': $Expression"
    return $true
    
}

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDkhLNfsQrWZls2
# qaOLvrg4tX8Eq3HXuwfiMRzDDYil+aCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIC7B4zswZGCAAaIb7a85okqHmfma
# lJSyKvno08WAfNPjMA0GCSqGSIb3DQEBAQUABIIBABDAchoGrEQ2jSmIEfUgv2BV
# nwD4MCnD8R2NrT9GQjWlUs5l3EsC75r2Qi2PEe8Si5Yr9koqju2By+il4CL/RKHs
# 9isJUkpVWFaSxAhrDdrXp8MJVoywafw6XccVJNX/ZWadC3sc1yTYJIyTcEAHd5ar
# rR3v4c2+51ZLVmvTUv9zKNBDw8fr5CGlTJ4jspR8+UkvlhNEFfv59zVg7M7S056h
# 6vRaLG3Dg7ua1GVZRC3nZ9oPIvf6RnkbtrnTGcO6MWwlGVKIWiItEpKF2PGG9XOi
# Y9iKEyFH9UP9IzH0zKuRwCQL8V40ib57Hv4zCY675zIa4WK6Ems1WIrkNEt60yo=
# SIG # End signature block
