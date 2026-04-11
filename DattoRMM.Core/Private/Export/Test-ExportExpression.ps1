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
