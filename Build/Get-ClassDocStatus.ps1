<#
.SYNOPSIS
    Reports documentation coverage status across all class domain files.

.DESCRIPTION
    Get-ClassDocStatus.ps1 scans the per-domain .psm1 class files under
    DattoRMM.Core\Private\Classes\ and reports documentation coverage:

    - Classes / enums missing .SYNOPSIS or .DESCRIPTION
    - Properties missing an inline # comment
    - Methods missing a .SYNOPSIS comment block

    Outputs a summary by domain with counts and per-item detail.

.PARAMETER Domain
    Filter to a specific domain folder name (e.g. DRMMDevice).

.PARAMETER ClassName
    Filter to a specific class or enum name.

.PARAMETER ShowMissing
    Show the full list of missing items.

.EXAMPLE
    .\Build\Get-ClassDocStatus.ps1
    Shows overall and per-domain coverage summary.

.EXAMPLE
    .\Build\Get-ClassDocStatus.ps1 -ShowMissing
    Lists every property/method/class that is missing documentation.

.EXAMPLE
    .\Build\Get-ClassDocStatus.ps1 -Domain DRMMDevice -ShowMissing
    Shows missing documentation items for the DRMMDevice domain only.

.NOTES
    Author: Robert Faddes
#>
[CmdletBinding()]
param(
    [string]$Domain,
    [string]$ClassName,
    [switch]$ShowMissing
)

$ErrorActionPreference = 'Continue'

# Get module root
$ModuleRoot = Split-Path $PSScriptRoot -Parent

try {

    # -------------------------------------------------------------------------
    # Helpers (mirrors Build-ClassDocs.ps1)
    # -------------------------------------------------------------------------

    function Get-ASTComment {
        param(
            [Parameter(Mandatory)] $MemberAst,
            [Parameter(Mandatory)] [string]$ScriptContent
        )

        $tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptContent, [ref]$null)
        $memberStartLine = $MemberAst.Extent.StartLineNumber
        $relevantTokens = $tokens | Where-Object { $_.StartLine -lt $memberStartLine } | Sort-Object StartLine -Descending

        foreach ($token in $relevantTokens) {
            if ($token.Type -eq 'Comment') {
                if (($memberStartLine - $token.EndLine) -le 2) {
                    $commentText = $token.Content
                    if ($commentText -match '(?s)<#(.*?)#>') {
                        $helpContent = $matches[1]
                        if ($helpContent -match '(?s)\.SYNOPSIS\s+(.*?)(?=\s*\.[A-Z]|\s*#>|$)') {
                            return ($matches[1].Trim() -replace '\s+', ' ')
                        }
                    } elseif ($commentText -match '^#\s*(.+)') {
                        return $matches[1].Trim()
                    }
                }
                break
            }
        }
        return $null
    }

    function Get-ASTHelpComment {
        param(
            [Parameter(Mandatory)] $MemberAst,
            [Parameter(Mandatory)] [string]$ScriptContent
        )

        $tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptContent, [ref]$null)
        $memberStartLine = $MemberAst.Extent.StartLineNumber
        $relevantTokens = $tokens | Where-Object { $_.StartLine -lt $memberStartLine } | Sort-Object StartLine -Descending

        $result = @{ Synopsis = $null; Description = $null }

        foreach ($token in $relevantTokens) {
            if ($token.Type -eq 'Comment') {
                if (($memberStartLine - $token.EndLine) -le 2) {
                    $commentText = $token.Content
                    if ($commentText -match '(?s)<#(.*?)#>') {
                        $helpContent = $matches[1]
                        if ($helpContent -match '(?s)\.SYNOPSIS\s+(.*?)(?=\s*\.[A-Z]|\s*#>|$)') {
                            $result.Synopsis = ($matches[1].Trim() -replace '\s+', ' ')
                        }
                        if ($helpContent -match '(?s)\.DESCRIPTION\s+(.*?)(?=\s*\.[A-Z]|\s*#>|$)') {
                            $result.Description = ($matches[1].Trim() -replace '\s+', ' ')
                        }
                    } elseif ($commentText -match '^#\s*(.+)') {
                        $result.Synopsis = $matches[1].Trim()
                    }
                }
                break
            }
        }
        return $result
    }

    # -------------------------------------------------------------------------
    # Scan domain files
    # -------------------------------------------------------------------------

    $ClassesRoot = Join-Path $ModuleRoot 'DattoRMM.Core\Private\Classes'
    $DomainFiles = Get-ChildItem -Path $ClassesRoot -Recurse -Filter '*.psm1' |
        Where-Object { $_.FullName -notmatch '_Archive' -and $_.Directory.FullName -ne $ClassesRoot } |
        Sort-Object FullName

    if ($DomainFiles.Count -eq 0) {
        Write-Error "No domain class files found under: $ClassesRoot"
        return
    }

    # -------------------------------------------------------------------------
    # Analyse each file
    # -------------------------------------------------------------------------

    # Each entry: { Domain, TypeName, Kind, Item, Issue }
    $Missing = [System.Collections.Generic.List[object]]::new()

    # Counters
    $TotalClasses    = 0
    $TotalProperties = 0
    $TotalMethods    = 0

    foreach ($DomainFile in $DomainFiles) {

        $DomainName = $DomainFile.Directory.Name

        if ($Domain -and $DomainName -ne $Domain) { continue }

        $Content = Get-Content $DomainFile.FullName -Raw
        $AST = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)
        $TypeDefs = $AST.FindAll({ param($n) $n -is [System.Management.Automation.Language.TypeDefinitionAst] }, $true)

        foreach ($TypeDef in $TypeDefs) {

            $TypeName = $TypeDef.Name
            if ($ClassName -and $TypeName -ne $ClassName) { continue }

            $TotalClasses++
            $Help = Get-ASTHelpComment $TypeDef $Content

            if (-not $Help.Synopsis) {
                $Missing.Add([PSCustomObject]@{ Domain = $DomainName; TypeName = $TypeName; Kind = 'Class'; Item = $TypeName; Issue = 'Missing .SYNOPSIS' })
            }
            if (-not $Help.Description) {
                $Missing.Add([PSCustomObject]@{ Domain = $DomainName; TypeName = $TypeName; Kind = 'Class'; Item = $TypeName; Issue = 'Missing .DESCRIPTION' })
            }

            if ($TypeDef.IsEnum) {
                # Enums: no per-value comment requirement
                continue
            }

            # Properties
            $Props = $TypeDef.Members | Where-Object {
                $_ -is [System.Management.Automation.Language.PropertyMemberAst] -and
                -not $_.IsHidden
            }
            foreach ($Prop in $Props) {
                $TotalProperties++
                $Comment = Get-ASTComment $Prop $Content
                if (-not $Comment) {
                    $Missing.Add([PSCustomObject]@{ Domain = $DomainName; TypeName = $TypeName; Kind = 'Property'; Item = $Prop.Name; Issue = 'Missing # comment' })
                }
            }

            # Methods (exclude constructors, hidden members, and internal static plumbing)
            $Methods = $TypeDef.Members | Where-Object {
                $_ -is [System.Management.Automation.Language.FunctionMemberAst] -and
                -not $_.IsHidden -and
                $_.Name -ne $TypeName -and
                -not ($_.IsStatic -and ($_.Name -like 'FromAPIMethod' -or $_.Name -like 'From*' -or $_.Name -like 'Populate*'))
            }
            foreach ($Method in $Methods) {
                $TotalMethods++
                $Comment = Get-ASTComment $Method $Content
                if (-not $Comment) {
                    $Sig = "$($Method.Name)($( ($Method.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }) -join ', ' ))"
                    $Missing.Add([PSCustomObject]@{ Domain = $DomainName; TypeName = $TypeName; Kind = 'Method'; Item = $Sig; Issue = 'Missing .SYNOPSIS' })
                }
            }
        }
    }

    # -------------------------------------------------------------------------
    # Summary
    # -------------------------------------------------------------------------

    $TotalItems   = $TotalClasses + $TotalProperties + $TotalMethods
    $MissingCount = $Missing.Count
    $CoveredCount = $TotalItems - $MissingCount
    # Note: a class with both missing Synopsis AND Description counts as 2 missing items
    # so coverage is calculated on unique items
    $UniqueItemsMissing = ($Missing | Select-Object Domain, TypeName, Kind, Item -Unique | Measure-Object).Count
    $Coverage = if ($TotalItems -gt 0) { [math]::Round((($TotalItems - $UniqueItemsMissing) / $TotalItems) * 100, 1) } else { 100 }

    Write-Host "`n=== Class Documentation Coverage ==="  -ForegroundColor Cyan
    Write-Host "  Classes:    $TotalClasses"           -ForegroundColor Gray
    Write-Host "  Properties: $TotalProperties"        -ForegroundColor Gray
    Write-Host "  Methods:    $TotalMethods"           -ForegroundColor Gray
    Write-Host "  Total items: $TotalItems"            -ForegroundColor Gray
    Write-Host "  Missing:    $MissingCount issue(s)" -ForegroundColor $(if ($MissingCount -gt 0) { 'Yellow' } else { 'Green' })
    $CoverageColor = if ($Coverage -ge 90) { 'Green' } elseif ($Coverage -ge 70) { 'Yellow' } else { 'Red' }
    Write-Host "  Coverage:   $Coverage%"             -ForegroundColor $CoverageColor

    # Per-domain breakdown
    Write-Host "`n=== By Domain ===" -ForegroundColor Cyan

    $DomainGroups = $Missing | Group-Object Domain | Sort-Object Name
    $AllDomains   = @($DomainFiles | Select-Object -ExpandProperty Directory | Select-Object -ExpandProperty Name -Unique | Sort-Object)
    if ($Domain) { $AllDomains = @($Domain) }

    foreach ($DomainName in $AllDomains) {
        $DomainMissing = @($Missing | Where-Object { $_.Domain -eq $DomainName })
        $IssueCount = $DomainMissing.Count
        $DomainColor = if ($IssueCount -eq 0) { 'Green' } elseif ($IssueCount -le 5) { 'Yellow' } else { 'Red' }
        Write-Host ("  {0,-30} {1} issue(s)" -f $DomainName, $IssueCount) -ForegroundColor $DomainColor
    }

    # Detailed missing items
    if ($ShowMissing) {

        if ($Missing.Count -eq 0) {
            Write-Host "`n  No missing documentation found." -ForegroundColor Green
        } else {
            Write-Host "`n=== Missing Documentation ===" -ForegroundColor Cyan

            $ByDomain = $Missing | Sort-Object Domain, TypeName, Kind, Item | Group-Object Domain

            foreach ($Group in $ByDomain) {
                Write-Host "`n  $($Group.Name)" -ForegroundColor Cyan

                $ByType = $Group.Group | Group-Object TypeName
                foreach ($TypeGroup in $ByType) {
                    Write-Host "    $($TypeGroup.Name)" -ForegroundColor White
                    foreach ($Item in $TypeGroup.Group) {
                        $KindColor = switch ($Item.Kind) {
                            'Class'    { 'Magenta' }
                            'Property' { 'Gray' }
                            'Method'   { 'Yellow' }
                        }
                        Write-Host ("      [{0,-8}] {1,-50} {2}" -f $Item.Kind, $Item.Item, $Item.Issue) -ForegroundColor $KindColor
                    }
                }
            }
        }
    }

    Write-Host "`n=== Complete ===" -ForegroundColor Cyan

} catch {
    Write-Error "Get-ClassDocStatus failed: $_"
}
