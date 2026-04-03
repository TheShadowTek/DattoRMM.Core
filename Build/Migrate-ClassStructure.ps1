<#
.SYNOPSIS
    Migrates Classes.psm1, Format.ps1xml, and Types.ps1xml into per-domain split files.

.DESCRIPTION
    Migrate-ClassStructure.ps1 is a one-shot migration script that transforms the monolithic
    class, format, and type files into a per-domain folder structure under
    Private/Classes/[Domain]/, with each domain containing:

        [Domain].psm1           - PowerShell class/enum definitions
        [Domain].Format.ps1xml  - Format view definitions (List/Table)
        [Domain].Types.ps1xml   - Type extension definitions (ToString, etc.)

    During migration the script also splices PSD1 content (PropertyDescriptions,
    MethodDescriptions, Notes, RelatedLinks) into the class file as comment-based
    help blocks, enriching each class .SYNOPSIS/.DESCRIPTION with property-level
    single-line comments and method-level help comment blocks.

    After generating all domain files the script rewrites DattoRMM.Core.psm1 to
    load classes via 'using module' statements in correct inheritance order, and
    updates DattoRMM.Core.psd1 to list all the new Format and Types files.

    The original monolithic files are NOT deleted - they are archived to
    Private/Classes/_Archive/ for safety.

.PARAMETER ModuleRoot
    Root of the module workspace. Defaults to the parent of the Build folder.

.PARAMETER DryRun
    When set, prints what would be done but writes no files.

.PARAMETER SkipPsd1Merge
    When set, skips splicing PSD1 documentation content into the class files.
    Use this if you only want the structural split without documentation enrichment.

.EXAMPLE
    .\Build\Migrate-ClassStructure.ps1
    Performs the full migration.

.EXAMPLE
    .\Build\Migrate-ClassStructure.ps1 -DryRun
    Previews actions without writing files.

.EXAMPLE
    .\Build\Migrate-ClassStructure.ps1 -SkipPsd1Merge
    Splits files structurally without enriching class comments from PSD1.

.NOTES
    Author: Robert Faddes
    This is a one-shot migration script. Run once, validate, then update Build-ClassDocs.ps1.
    Inheritance order is resolved automatically - base classes always precede derived classes
    within a domain file.
#>
[CmdletBinding()]
param(

    [string]$ModuleRoot = (Split-Path $PSScriptRoot -Parent),

    [switch]$DryRun,

    [switch]$SkipPsd1Merge

)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ─────────────────────────────────────────────────────────────────────────────
# Paths
# ─────────────────────────────────────────────────────────────────────────────

$ClassesFile    = Join-Path $ModuleRoot 'DattoRMM.Core\Private\Classes\Classes.psm1'
$FormatFile     = Join-Path $ModuleRoot 'DattoRMM.Core\DattoRMM.Core.Format.ps1xml'
$TypesFile      = Join-Path $ModuleRoot 'DattoRMM.Core\DattoRMM.Core.Types.ps1xml'
$PsdFile        = Join-Path $ModuleRoot 'Build\ClassDocContent.psd1'
$ManifestFile   = Join-Path $ModuleRoot 'DattoRMM.Core\DattoRMM.Core.psd1'
$ModuleFile     = Join-Path $ModuleRoot 'DattoRMM.Core\DattoRMM.Core.psm1'
$ClassesDir     = Join-Path $ModuleRoot 'DattoRMM.Core\Private\Classes'
$ArchiveDir     = Join-Path $ClassesDir '_Archive'

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

function Write-Step {

    param([string]$Message, [string]$Color = 'Cyan')
    Write-Host "`n=== $Message ===" -ForegroundColor $Color

}

function Write-Detail {

    param([string]$Message, [string]$Color = 'Gray')
    Write-Host "  $Message" -ForegroundColor $Color

}

function Write-FileAction {

    param([string]$Action, [string]$Path, [string]$Color = 'Yellow')
    $Rel = $Path.Replace($ModuleRoot, '').TrimStart('\','/')
    Write-Host "  [$Action] $Rel" -ForegroundColor $Color

}

function Save-File {

    param([string]$Path, [string]$Content)

    if ($DryRun) {

        Write-FileAction 'DRY-RUN' $Path 'DarkGray'
        return

    }

    $Dir = Split-Path $Path -Parent
    if (-not (Test-Path $Dir)) {

        $null = New-Item -ItemType Directory -Path $Dir -Force

    }

    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::UTF8)
    Write-FileAction 'WROTE' $Path 'Green'

}

# ─────────────────────────────────────────────────────────────────────────────
# Step 1 - Load source files
# ─────────────────────────────────────────────────────────────────────────────

Write-Step 'Loading source files'

foreach ($F in @($ClassesFile, $FormatFile, $TypesFile)) {

    if (-not (Test-Path $F)) {

        throw "Required file not found: $F"

    }

}

$ClassesContent = [System.IO.File]::ReadAllText($ClassesFile, [System.Text.Encoding]::UTF8)
$FormatContent  = [System.IO.File]::ReadAllText($FormatFile,  [System.Text.Encoding]::UTF8)
$TypesContent   = [System.IO.File]::ReadAllText($TypesFile,   [System.Text.Encoding]::UTF8)

Write-Detail "Classes.psm1   : $([math]::Round($ClassesContent.Length / 1KB, 1)) KB"
Write-Detail "Format.ps1xml  : $([math]::Round($FormatContent.Length / 1KB, 1)) KB"
Write-Detail "Types.ps1xml   : $([math]::Round($TypesContent.Length / 1KB, 1)) KB"

# ─────────────────────────────────────────────────────────────────────────────
# Step 2 - Load PSD1 documentation content
# ─────────────────────────────────────────────────────────────────────────────

$DocContent = $null
if (-not $SkipPsd1Merge) {

    Write-Step 'Loading PSD1 documentation content'

    if (Test-Path $PsdFile) {

        $DocContent = Import-PowerShellDataFile -Path $PsdFile
        Write-Detail "Loaded ClassDocContent.psd1 with $($DocContent.Keys.Count - 1) domain entries"

    } else {

        Write-Warning "ClassDocContent.psd1 not found - skipping PSD1 merge"
        $SkipPsd1Merge = $true

    }

}

# ─────────────────────────────────────────────────────────────────────────────
# Step 3 - Parse Classes.psm1: extract regions → classes
# ─────────────────────────────────────────────────────────────────────────────

Write-Step 'Parsing Classes.psm1'

# Strip the signature block before parsing
$SignatureStart = $ClassesContent.IndexOf('# SIG # Begin signature block')
$CleanContent   = if ($SignatureStart -gt 0) {
    $ClassesContent.Substring(0, $SignatureStart).TrimEnd()
} else {
    $ClassesContent
}

$Lines = $CleanContent -split "`r?`n"

# Build region map: FolderName -> @{ StartLine, EndLine, RawLines }
$RegionStack  = [System.Collections.Generic.Stack[hashtable]]::new()
$Regions      = [System.Collections.Generic.List[hashtable]]::new()

for ($i = 0; $i -lt $Lines.Count; $i++) {

    $Line = $Lines[$i]

    if ($Line -match '^\s*#region\s+(.+)') {

        $RegionText  = $matches[1].Trim()
        $FolderName  = ($RegionText -split '\s+')[0]
        $RegionStack.Push(@{
            Name       = $RegionText
            FolderName = $FolderName
            StartLine  = $i
            Lines      = [System.Collections.Generic.List[string]]::new()
        })

    } elseif ($Line -match '^\s*#endregion') {

        if ($RegionStack.Count -gt 0) {

            $Region          = $RegionStack.Pop()
            $Region.EndLine  = $i
            $Regions.Add($Region)

        }

    } elseif ($RegionStack.Count -gt 0) {

        $RegionStack.Peek().Lines.Add($Line)

    }

}

Write-Detail "Found $($Regions.Count) top-level regions"

# ─────────────────────────────────────────────────────────────────────────────
# Step 4 - Parse each region with the AST to get class/enum definitions
#          and extract property + method comment blocks via PSParser
# ─────────────────────────────────────────────────────────────────────────────

Write-Step 'Extracting class/enum definitions via AST'

# For each region we need the raw source slice so we can extract clean class blocks.
# We reconstruct the slice from the original lines (not $Region.Lines, which excludes
# the #region/#endregion markers) so that line numbers inside the AST are correct
# relative to the slice.

function Get-LineSlice {

    param([string[]]$AllLines, [int]$From, [int]$To)
    # $From and $To are 0-based indices (inclusive)
    $AllLines[$From..$To] -join "`n"

}

function Get-PSParserCommentBefore {

    # Returns the comment text (stripped of markers) immediately preceding $TargetLine (1-based)
    param([object[]]$Tokens, [int]$TargetLine)

    $Preceding = $Tokens | Where-Object {
        $_.Type -eq 'Comment' -and $_.StartLine -lt $TargetLine
    } | Sort-Object StartLine -Descending | Select-Object -First 1

    if (-not $Preceding) { return $null }

    # Must be within 3 lines of the target (allow blank lines between comment and declaration)
    if (($TargetLine - $Preceding.EndLine) -gt 3) { return $null }

    return $Preceding.Content

}

function Parse-HelpComment {

    param([string]$CommentText)

    if ([string]::IsNullOrWhiteSpace($CommentText)) { return $null }

    $Result = @{ Synopsis = $null; Description = $null; Notes = $null; Links = @(); Examples = @() }

    if ($CommentText -match '(?s)<#(.*?)#>') {

        $Body = $matches[1]

        if ($Body -match '(?s)\.SYNOPSIS\s+(.*?)(?=\s*\.[A-Z]|\s*$)') {
            $Result.Synopsis = ($matches[1].Trim() -replace '\s+', ' ')
        }

        if ($Body -match '(?s)\.DESCRIPTION\s+(.*?)(?=\s*\.[A-Z]|\s*$)') {
            $Result.Description = ($matches[1].Trim() -replace '[ \t]+', ' ')
        }

        if ($Body -match '(?s)\.NOTES\s+(.*?)(?=\s*\.[A-Z]|\s*$)') {
            $Result.Notes = ($matches[1].Trim() -replace '\s+', ' ')
        }

        $LinkMatches = [regex]::Matches($Body, '\.LINK\s+(\S+)')
        foreach ($M in $LinkMatches) {
            $Result.Links += $M.Groups[1].Value.Trim()
        }

    } elseif ($CommentText -match '^#\s*(.+)') {

        $Result.Synopsis = $matches[1].Trim()

    }

    return $Result

}

# Domain map: FolderName -> @{ Region; TypeDefs: list of PSCustomObject }
$DomainMap = [System.Collections.Specialized.OrderedDictionary]::new()

foreach ($Region in $Regions) {

    $FolderName = $Region.FolderName
    $Slice      = Get-LineSlice $Lines $Region.StartLine $Region.EndLine

    $ParseErrors = $null
    $AST         = [System.Management.Automation.Language.Parser]::ParseInput($Slice, [ref]$null, [ref]$ParseErrors)

    if ($ParseErrors.Count -gt 0) {

        Write-Warning "Parse errors in region '$($Region.Name)': $($ParseErrors[0].Message)"

    }

    $Tokens = [System.Management.Automation.PSParser]::Tokenize($Slice, [ref]$null)

    $TypeDefs = $AST.FindAll({
        param($n)
        $n -is [System.Management.Automation.Language.TypeDefinitionAst]
    }, $true)

    if (-not $DomainMap.Contains($FolderName)) {

        $DomainMap[$FolderName] = @{
            FolderName = $FolderName
            Region     = $Region
            TypeDefs   = [System.Collections.Generic.List[object]]::new()
        }

    }

    foreach ($TypeDef in $TypeDefs) {

        $TypeName = $TypeDef.Name
        $IsEnum   = $TypeDef.IsEnum

        # Class-level comment
        $ClassComment = Parse-HelpComment (Get-PSParserCommentBefore $Tokens $TypeDef.Extent.StartLineNumber)

        # Base type
        $BaseType = if ($TypeDef.BaseTypes.Count -gt 0) { $TypeDef.BaseTypes[0].TypeName.Name } else { $null }

        # Enum values
        $EnumValues = if ($IsEnum) { $TypeDef.Members | ForEach-Object { $_.Name } } else { @() }

        # Properties
        $Properties = if (-not $IsEnum) {

            $TypeDef.Members | Where-Object {
                $_ -is [System.Management.Automation.Language.PropertyMemberAst]
            } | ForEach-Object {

                $PropComment = Get-PSParserCommentBefore $Tokens $_.Extent.StartLineNumber
                [PSCustomObject]@{
                    Name     = $_.Name
                    Type     = if ($_.PropertyType) { $_.PropertyType.TypeName.FullName } else { 'object' }
                    IsHidden = $_.IsHidden
                    IsStatic = $_.IsStatic
                    Comment  = if ($PropComment) { ($PropComment -replace '^#\s*','').Trim() } else { $null }
                }

            }

        } else { @() }

        # Methods
        $Methods = if (-not $IsEnum) {

            $TypeDef.Members | Where-Object {
                $_ -is [System.Management.Automation.Language.FunctionMemberAst]
            } | ForEach-Object {

                $MethComment = Parse-HelpComment (Get-PSParserCommentBefore $Tokens $_.Extent.StartLineNumber)
                $ReturnType  = if ($_.ReturnType) { $_.ReturnType.TypeName.FullName } else { 'void' }

                $Params = $_.Parameters | ForEach-Object {
                    [PSCustomObject]@{
                        Name = $_.Name.VariablePath.UserPath
                        Type = if ($_.StaticType) { $_.StaticType.Name } else { 'object' }
                    }
                }

                [PSCustomObject]@{
                    Name        = $_.Name
                    IsStatic    = $_.IsStatic
                    IsHidden    = $_.IsHidden
                    ReturnType  = $ReturnType
                    Parameters  = $Params
                    Comment     = $MethComment
                }

            }

        } else { @() }

        $DomainMap[$FolderName].TypeDefs.Add([PSCustomObject]@{
            Name         = $TypeName
            IsEnum       = $IsEnum
            IsClass      = (-not $IsEnum)
            BaseType     = $BaseType
            EnumValues   = $EnumValues
            Properties   = $Properties
            Methods      = $Methods
            ClassComment = $ClassComment
            FolderName   = $FolderName
            # Raw source block for this type (extracted from the slice)
            RawSource    = $null  # populated below
        })

        Write-Detail "$TypeName ($(if ($IsEnum) {'enum'} else {'class'})) -> $FolderName"

    }

}

Write-Detail "Total domains  : $($DomainMap.Count)"
Write-Detail "Total types    : $(($DomainMap.Values | ForEach-Object { $_.TypeDefs.Count } | Measure-Object -Sum).Sum)"

# ─────────────────────────────────────────────────────────────────────────────
# Step 5 - Extract raw source blocks for each class/enum
#          Uses AST extents to slice lines; walks backwards to capture the
#          preceding comment block using a pre-sorted token index for O(log n).
# ─────────────────────────────────────────────────────────────────────────────

Write-Step 'Extracting raw class source blocks'

# Parse the full clean content once
$FullAST         = [System.Management.Automation.Language.Parser]::ParseInput($CleanContent, [ref]$null, [ref]$null)
$FullLines       = $CleanContent -split "`r?`n"

# Tokenize once; build an array sorted by StartLine for binary-search
$FullTokens      = [System.Management.Automation.PSParser]::Tokenize($CleanContent, [ref]$null)
$CommentTokens   = @($FullTokens | Where-Object { $_.Type -eq 'Comment' } | Sort-Object StartLine)
$CommentStarts   = $CommentTokens | ForEach-Object { $_.StartLine }

function Find-PrecedingComment {

    param([int]$TargetLine)

    # Binary search for the last comment token whose StartLine < TargetLine
    $Lo  = 0
    $Hi  = $CommentStarts.Count - 1
    $Idx = -1

    while ($Lo -le $Hi) {

        $Mid = [int](($Lo + $Hi) / 2)
        if ($CommentStarts[$Mid] -lt $TargetLine) {
            $Idx = $Mid
            $Lo  = $Mid + 1
        } else {
            $Hi  = $Mid - 1
        }

    }

    if ($Idx -lt 0) { return $null }

    $Token = $CommentTokens[$Idx]
    # Must be within 3 lines of target
    if (($TargetLine - $Token.EndLine) -gt 3) { return $null }

    return $Token

}

$AllTypeDefs = $FullAST.FindAll({
    param($n)
    $n -is [System.Management.Automation.Language.TypeDefinitionAst]
}, $true)

$RawBlockMap = @{}

foreach ($TypeDef in $AllTypeDefs) {

    $TypeName   = $TypeDef.Name
    $ClassStart = $TypeDef.Extent.StartLineNumber  # 1-based
    $ClassEnd   = $TypeDef.Extent.EndLineNumber    # 1-based

    # Find the preceding comment (opening of <# #> block or # line)
    $CommentToken = Find-PrecedingComment $ClassStart

    $BlockStartLine0 = if ($CommentToken) {
        $CommentToken.StartLine - 1  # convert 1-based to 0-based
    } else {
        $ClassStart - 1              # 0-based, no comment
    }

    $BlockEndLine0 = $ClassEnd - 1   # convert 1-based to 0-based

    $RawBlock = ($FullLines[$BlockStartLine0..$BlockEndLine0]) -join "`n"
    $RawBlockMap[$TypeName] = $RawBlock.TrimEnd()

}

# Populate RawSource on each TypeDef in the DomainMap
foreach ($Domain in $DomainMap.Values) {

    foreach ($TypeInfo in $Domain.TypeDefs) {

        if ($RawBlockMap.ContainsKey($TypeInfo.Name)) {

            $TypeInfo.RawSource = $RawBlockMap[$TypeInfo.Name]

        } else {

            Write-Warning "No raw source block found for: $($TypeInfo.Name)"

        }

    }

}

# ─────────────────────────────────────────────────────────────────────────────
# Step 6 - Splice PSD1 documentation into class source blocks
#          Merges PropertyDescriptions, MethodDescriptions, Notes, RelatedLinks
#          into the comment-based help in the raw source.
# ─────────────────────────────────────────────────────────────────────────────

if (-not $SkipPsd1Merge) {

    Write-Step 'Splicing PSD1 documentation into class source blocks'

    foreach ($Domain in $DomainMap.Values) {

        $FolderName = $Domain.FolderName

        foreach ($TypeInfo in $Domain.TypeDefs) {

            $TypeName = $TypeInfo.Name

            # Find PSD1 entry: search all domain keys for this class name
            $PsdEntry = $null
            foreach ($DomainKey in $DocContent.Keys) {

                if ($DomainKey -eq '_Metadata') { continue }
                if ($DocContent[$DomainKey].ContainsKey($TypeName)) {
                    $PsdEntry = $DocContent[$DomainKey][$TypeName]
                    break
                }

            }

            if (-not $PsdEntry) {

                Write-Detail "No PSD1 entry for $TypeName - skipping merge"
                continue

            }

            $Source = $TypeInfo.RawSource
            if (-not $Source) { continue }

            # ── 1. Enrich class-level <# #> with .NOTES and .LINK ───────────

            $HasClassBlock = $Source -match '(?s)^<#.*?#>'

            if ($HasClassBlock) {

                $ExistingBlock = $matches[0]
                $NewBlock      = $ExistingBlock

                # Add .NOTES if PSD1 has notes and block doesn't already have one
                $Notes = if ($PsdEntry -is [hashtable] -and $PsdEntry.ContainsKey('Notes')) { $PsdEntry.Notes | Where-Object { $_ } } else { @() }
                if ($Notes -and $Notes.Count -gt 0 -and $NewBlock -notmatch '\.NOTES') {

                    $NoteText = ($Notes -join "`n") -replace "`r`n", "`n"
                    $NewBlock  = $NewBlock -replace '#>\s*$', ".NOTES`n    $NoteText`n#>"

                }

                # Add .LINK for each related link not already in the block
                $Links = if ($PsdEntry -is [hashtable] -and $PsdEntry.ContainsKey('RelatedLinks')) { $PsdEntry.RelatedLinks | Where-Object { $_ } } else { @() }
                foreach ($Link in $Links) {

                    if ($NewBlock -notmatch [regex]::Escape($Link)) {

                        $NewBlock = $NewBlock -replace '#>\s*$', ".LINK`n    $Link`n#>"

                    }

                }

                if ($NewBlock -ne $ExistingBlock) {

                    $Source = $Source.Replace($ExistingBlock, $NewBlock)
                    Write-Detail "  Enriched class block: $TypeName"

                }

            }

            # ── 2. Enrich property comments ──────────────────────────────────

            $PropDescs = if ($PsdEntry -is [hashtable] -and $PsdEntry.ContainsKey('PropertyDescriptions')) { $PsdEntry.PropertyDescriptions } else { $null }
            if ($PropDescs -and $PropDescs.Count -gt 0) {

                foreach ($PropName in $PropDescs.Keys) {

                    $PsdPropDesc = $PropDescs[$PropName]
                    if ([string]::IsNullOrWhiteSpace($PsdPropDesc)) { continue }

                    # Match a property declaration line (with or without existing comment)
                    # Pattern: optional leading whitespace, optional type, $PropName
                    $PropPattern  = "(?m)([ \t]*(?:\[[\w\[\]]+\][ \t]+)?\`$$PropName\b)"
                    $PropMatch    = [regex]::Match($Source, $PropPattern)

                    if ($PropMatch.Success) {

                        $PropLine    = $PropMatch.Value
                        $Indent      = [regex]::Match($PropLine, '^([ \t]*)').Groups[1].Value
                        $CommentLine = "$Indent# $PsdPropDesc"

                        # Only inject if there isn't already a comment on the preceding line
                        $PropIndex = $Source.IndexOf($PropLine)
                        $Before    = $Source.Substring(0, $PropIndex)
                        $LastNl    = $Before.LastIndexOf("`n")
                        $PrevLine  = if ($LastNl -ge 0) { $Before.Substring($LastNl + 1).TrimEnd() } else { '' }

                        if ($PrevLine -notmatch '^\s*#') {

                            $Source = $Source.Insert($PropIndex, "$CommentLine`n")
                            Write-Detail "  Added property comment: $TypeName.$PropName"

                        }

                    }

                }

            }

            # ── 3. Enrich method comments ────────────────────────────────────

            $MethDescs = if ($PsdEntry -is [hashtable] -and $PsdEntry.ContainsKey('MethodDescriptions')) { $PsdEntry.MethodDescriptions } else { $null }
            if ($MethDescs -and $MethDescs.Count -gt 0) {

                foreach ($MethName in $MethDescs.Keys) {

                    $MethEntry = $MethDescs[$MethName]
                    if (-not $MethEntry) { continue }

                    $MethDesc   = $MethEntry.Description
                    $MethReturn = $MethEntry.ReturnValue
                    if ([string]::IsNullOrWhiteSpace($MethDesc)) { continue }

                    # Build help block
                    $HelpLines = @('<#')
                    $HelpLines += ".SYNOPSIS"
                    $HelpLines += "    $MethDesc"

                    if (-not [string]::IsNullOrWhiteSpace($MethReturn)) {

                        $HelpLines += ".OUTPUTS"
                        $HelpLines += "    $MethReturn"

                    }

                    $HelpLines += '#>'
                    $HelpBlock  = $HelpLines -join "`n    "

                    # Find the method declaration - match [returntype] MethodName( or just MethodName(
                    $MethPattern = "(?m)([ \t]*(?:\[[\w\[\]]+\][ \t]+)?$([regex]::Escape($MethName))\s*\()"
                    $MethMatch   = [regex]::Match($Source, $MethPattern)

                    if ($MethMatch.Success) {

                        $MethLine  = $MethMatch.Value
                        $Indent    = [regex]::Match($MethLine, '^([ \t]*)').Groups[1].Value
                        $MethIndex = $Source.IndexOf($MethLine)
                        $Before    = $Source.Substring(0, $MethIndex)
                        $LastNl    = $Before.LastIndexOf("`n")
                        $PrevLine  = if ($LastNl -ge 0) { $Before.Substring($LastNl + 1).TrimEnd() } else { '' }

                        if ($PrevLine -notmatch '^\s*(?:#|<#)') {

                            $IndentedBlock = ($HelpBlock -split "`n" | ForEach-Object { "$Indent$_" }) -join "`n"
                            $Source = $Source.Insert($MethIndex, "$IndentedBlock`n")
                            Write-Detail "  Added method comment: $TypeName.$MethName"

                        }

                    }

                }

            }

            $TypeInfo.RawSource = $Source

        }

    }

}

# ─────────────────────────────────────────────────────────────────────────────
# Step 7 - Parse Format.ps1xml: split <View> blocks by TypeName
# ─────────────────────────────────────────────────────────────────────────────

Write-Step 'Parsing Format.ps1xml view blocks'

# Strip sig block
$FormatSigStart = $FormatContent.IndexOf('<!-- SIG # Begin signature block -->')
$CleanFormat    = if ($FormatSigStart -gt 0) {
    $FormatContent.Substring(0, $FormatSigStart).TrimEnd()
} else {
    $FormatContent
}

# Parse with XmlDocument - strip the outer <Configuration><ViewDefinitions> wrapper
[xml]$FormatXml = $CleanFormat

# Map TypeName prefix -> list of <View> XML strings
$FormatViewMap  = [System.Collections.Specialized.OrderedDictionary]::new()

foreach ($View in $FormatXml.Configuration.ViewDefinitions.View) {

    # Extract the TypeName from ViewSelectedBy
    $TypeName = $View.ViewSelectedBy.TypeName

    if (-not $TypeName) { continue }

    # Determine which domain this TypeName belongs to
    # We find the class entry in DomainMap
    $OwningDomain = $null
    foreach ($Domain in $DomainMap.Values) {

        $Match = $Domain.TypeDefs | Where-Object { $_.Name -eq $TypeName }
        if ($Match) {
            $OwningDomain = $Domain.FolderName
            break
        }

    }

    if (-not $OwningDomain) {

        # Fallback: use the type name prefix to find likely domain
        foreach ($Domain in $DomainMap.Values) {

            $DomainPrefix = $Domain.FolderName -replace '^DRMM', 'DRMM'
            if ($TypeName.StartsWith($DomainPrefix)) {
                $OwningDomain = $Domain.FolderName
                break
            }

        }

    }

    if (-not $OwningDomain) {

        Write-Warning "Cannot determine domain for Format view TypeName: $TypeName"
        $OwningDomain = 'Misc'

    }

    if (-not $FormatViewMap.Contains($OwningDomain)) {

        $FormatViewMap[$OwningDomain] = [System.Collections.Generic.List[string]]::new()

    }

    # Serialize the <View> node back to indented XML string
    $Sw       = [System.IO.StringWriter]::new()
    $XmlSettings = [System.Xml.XmlWriterSettings]::new()
    $XmlSettings.Indent = $true
    $XmlSettings.IndentChars = '  '
    $XmlSettings.OmitXmlDeclaration = $true
    $XmlSettings.NewLineOnAttributes = $false
    $Xw       = [System.Xml.XmlWriter]::Create($Sw, $XmlSettings)
    $View.WriteTo($Xw)
    $Xw.Flush()
    $ViewXml  = $Sw.ToString()
    $Xw.Dispose()
    $Sw.Dispose()

    $FormatViewMap[$OwningDomain].Add($ViewXml)

}

Write-Detail "Format views mapped across $($FormatViewMap.Count) domains"

# ─────────────────────────────────────────────────────────────────────────────
# Step 8 - Parse Types.ps1xml: split <Type> blocks by TypeName
# ─────────────────────────────────────────────────────────────────────────────

Write-Step 'Parsing Types.ps1xml type blocks'

$TypesSigStart = $TypesContent.IndexOf('<!-- SIG # Begin signature block -->')
$CleanTypes    = if ($TypesSigStart -gt 0) {
    $TypesContent.Substring(0, $TypesSigStart).TrimEnd()
} else {
    $TypesContent
}

[xml]$TypesXml   = $CleanTypes
$TypesEntryMap   = [System.Collections.Specialized.OrderedDictionary]::new()

foreach ($TypeEntry in $TypesXml.Types.Type) {

    $TypeName = $TypeEntry.Name
    if (-not $TypeName) { continue }

    $OwningDomain = $null
    foreach ($Domain in $DomainMap.Values) {

        $Match = $Domain.TypeDefs | Where-Object { $_.Name -eq $TypeName }
        if ($Match) {
            $OwningDomain = $Domain.FolderName
            break
        }

    }

    if (-not $OwningDomain) {

        foreach ($Domain in $DomainMap.Values) {

            if ($TypeName.StartsWith($Domain.FolderName)) {
                $OwningDomain = $Domain.FolderName
                break
            }

        }

    }

    if (-not $OwningDomain) {

        Write-Warning "Cannot determine domain for Types entry TypeName: $TypeName"
        $OwningDomain = 'Misc'

    }

    if (-not $TypesEntryMap.Contains($OwningDomain)) {

        $TypesEntryMap[$OwningDomain] = [System.Collections.Generic.List[string]]::new()

    }

    $Sw          = [System.IO.StringWriter]::new()
    $XmlSettings = [System.Xml.XmlWriterSettings]::new()
    $XmlSettings.Indent = $true
    $XmlSettings.IndentChars = '  '
    $XmlSettings.OmitXmlDeclaration = $true
    $XmlSettings.NewLineOnAttributes = $false
    $Xw          = [System.Xml.XmlWriter]::Create($Sw, $XmlSettings)
    $TypeEntry.WriteTo($Xw)
    $Xw.Flush()
    $EntryXml    = $Sw.ToString()
    $Xw.Dispose()
    $Sw.Dispose()

    $TypesEntryMap[$OwningDomain].Add($EntryXml)

}

Write-Detail "Types entries mapped across $($TypesEntryMap.Count) domains"

# ─────────────────────────────────────────────────────────────────────────────
# Step 9 - Resolve inheritance order within each domain
#          Base classes must be defined before derived classes in the same file.
#          Cross-domain dependencies are handled by 'using module' load order.
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────
# Step 8.5 - Compute cross-domain dependency graph
#            Must run before file writing so domain files get correct
#            'using module' headers for cross-domain base class resolution.
# ─────────────────────────────────────────────────────────────────────────────

Write-Step 'Computing cross-domain dependency graph'

# ClassName -> DomainFolderName
$ClassDomainMap = @{}
foreach ($FolderName in $DomainMap.Keys) {

    foreach ($TypeInfo in $DomainMap[$FolderName].TypeDefs) {

        $ClassDomainMap[$TypeInfo.Name] = $FolderName

    }

}

# DomainFolderName -> HashSet of domain folder names it depends on
$DomainDeps = @{}
foreach ($FolderName in $DomainMap.Keys) {

    $DomainDeps[$FolderName] = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($TypeInfo in $DomainMap[$FolderName].TypeDefs) {

        if ($TypeInfo.BaseType -and $ClassDomainMap.ContainsKey($TypeInfo.BaseType)) {

            $BaseDomain = $ClassDomainMap[$TypeInfo.BaseType]
            if ($BaseDomain -ne $FolderName) {

                $null = $DomainDeps[$FolderName].Add($BaseDomain)

            }

        }

    }

}

# Topological sort of domains - determines 'using module' load order
$LoadOrder    = [System.Collections.Generic.List[string]]::new()
$EmittedDoms  = [System.Collections.Generic.HashSet[string]]::new()
$Pending      = [System.Collections.Generic.List[string]]::new()
foreach ($K in $DomainMap.Keys) { $Pending.Add($K) }
$MaxDomPasses = $Pending.Count + 1
$DomPass      = 0

while ($Pending.Count -gt 0 -and $DomPass -lt $MaxDomPasses) {

    $DomPass++
    $EmittedThisPass = $false
    $StillPending    = [System.Collections.Generic.List[string]]::new()

    foreach ($Dom in $Pending) {

        $Deps       = $DomainDeps[$Dom]
        $AllDepsMet = $true

        foreach ($Dep in $Deps) {

            if (-not $EmittedDoms.Contains($Dep)) {
                $AllDepsMet = $false
                break
            }

        }

        if ($AllDepsMet) {

            $LoadOrder.Add($Dom)
            $null = $EmittedDoms.Add($Dom)
            $EmittedThisPass = $true

        } else {

            $StillPending.Add($Dom)

        }

    }

    $Pending = $StillPending

    if (-not $EmittedThisPass -and $Pending.Count -gt 0) {

        Write-Warning "Unresolvable cross-domain dependency - appending remaining domains in declaration order"
        foreach ($Dom in $Pending) { $LoadOrder.Add($Dom) }
        break

    }

}

Write-Detail "Load order: $($LoadOrder -join ' -> ')"

# ─────────────────────────────────────────────────────────────────────────────
# Step 9 - Resolve inheritance order within each domain
#          Base classes must be defined before derived classes in the same file.
#          Cross-domain dependencies are handled by 'using module' load order.
# ─────────────────────────────────────────────────────────────────────────────

Write-Step 'Resolving inheritance order within domains'

function Get-SortedTypeDefs {

    # $TypeDefs: any enumerable of PSCustomObject representing parsed class/enum info
    param($TypeDefs)

    $Sorted    = [System.Collections.Generic.List[object]]::new()
    $Emitted   = [System.Collections.Generic.HashSet[string]]::new()
    # Materialise into a plain array first to avoid scalar-collapse from Where-Object
    # and to sidestep List[T] constructor overload resolution issues
    $AllItems  = @($TypeDefs)
    $Remaining = [System.Collections.Generic.List[object]]::new()
    foreach ($Item in $AllItems) { $Remaining.Add($Item) }

    # Enums first - they have no inheritance
    foreach ($T in @($Remaining | Where-Object { $_.IsEnum })) {

        $Sorted.Add($T)
        $null = $Emitted.Add($T.Name)

    }

    $NextRemaining = [System.Collections.Generic.List[object]]::new()
    foreach ($T in @($Remaining | Where-Object { -not $_.IsEnum })) { $NextRemaining.Add($T) }
    $Remaining = $NextRemaining

    # Topological sort for classes
    $MaxPasses = $Remaining.Count + 1
    $Pass      = 0

    while ($Remaining.Count -gt 0 -and $Pass -lt $MaxPasses) {

        $Pass++
        $EmittedThisPass = $false

        $StillRemaining = [System.Collections.Generic.List[object]]::new()

        foreach ($T in $Remaining) {

            $Base = $T.BaseType
            # Emit if: no base type, base is not in this domain, or base already emitted
            $BaseInDomain = @($Remaining | Where-Object { $_.Name -eq $Base })
            if (-not $Base -or -not $BaseInDomain -or $Emitted.Contains($Base)) {

                $Sorted.Add($T)
                $null = $Emitted.Add($T.Name)
                $EmittedThisPass = $true

            } else {

                $StillRemaining.Add($T)

            }

        }

        $Remaining = $StillRemaining

        if (-not $EmittedThisPass -and $Remaining.Count -gt 0) {

            Write-Warning "Circular dependency or unresolvable inheritance in domain - emitting remaining in declaration order"
            foreach ($T in $Remaining) {
                $Sorted.Add($T)
            }
            break

        }

    }

    return $Sorted

}

$Copyright = @"
<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
"@

# ─────────────────────────────────────────────────────────────────────────────
# Step 10 - Write domain .psm1 files
# ─────────────────────────────────────────────────────────────────────────────

Write-Step 'Writing domain .psm1 files'

$WrittenDomains = [System.Collections.Generic.List[string]]::new()

foreach ($FolderName in $DomainMap.Keys) {

    $Domain      = $DomainMap[$FolderName]
    $DomainDir   = Join-Path $ClassesDir $FolderName
    $OutFile     = Join-Path $DomainDir "$FolderName.psm1"

    $SortedTypes = Get-SortedTypeDefs $Domain.TypeDefs

    $Sb = [System.Text.StringBuilder]::new()

    # Add 'using module' statements for cross-domain base classes.
    # These MUST appear before any other executable content in the file.
    # Without them PowerShell cannot resolve inherited types at parse time,
    # producing 'Unexpected attribute' or 'Unable to find type' parse errors.
    $CrossDomainDeps = $DomainDeps[$FolderName]
    if ($CrossDomainDeps -and $CrossDomainDeps.Count -gt 0) {

        foreach ($DepDomain in ($CrossDomainDeps | Sort-Object)) {

            $null = $Sb.AppendLine("using module '..\..$DepDomain\$DepDomain.psm1'")

        }

        $null = $Sb.AppendLine()

    }

    $null = $Sb.AppendLine($Copyright)

    foreach ($TypeInfo in $SortedTypes) {

        if ($TypeInfo.RawSource) {

            $null = $Sb.AppendLine($TypeInfo.RawSource)
            $null = $Sb.AppendLine()

        } else {

            Write-Warning "No raw source for $($TypeInfo.Name) in domain $FolderName"

        }

    }

    Save-File $OutFile $Sb.ToString().TrimEnd()
    $WrittenDomains.Add($FolderName)

}

# ─────────────────────────────────────────────────────────────────────────────
# Step 11 - Write domain Format.ps1xml files
# ─────────────────────────────────────────────────────────────────────────────

Write-Step 'Writing domain Format.ps1xml files'

$WrittenFormatFiles = [System.Collections.Generic.List[string]]::new()

foreach ($FolderName in $WrittenDomains) {

    if (-not $FormatViewMap.Contains($FolderName)) {

        Write-Detail "No Format views for domain: $FolderName - skipping"
        continue

    }

    $DomainDir = Join-Path $ClassesDir $FolderName
    $OutFile   = Join-Path $DomainDir "$FolderName.Format.ps1xml"

    $Sb = [System.Text.StringBuilder]::new()
    $null = $Sb.AppendLine('<?xml version="1.0" encoding="utf-8"?>')
    $null = $Sb.AppendLine("<!-- SPDX-License-Identifier: MPL-2.0 -->")
    $null = $Sb.AppendLine("<!-- $FolderName domain Format views -->")
    $null = $Sb.AppendLine('<Configuration>')
    $null = $Sb.AppendLine('  <ViewDefinitions>')
    $null = $Sb.AppendLine()

    foreach ($ViewXml in $FormatViewMap[$FolderName]) {

        # Indent each line of the view block by 4 spaces to fit inside <ViewDefinitions>
        $Indented = ($ViewXml -split "`n" | ForEach-Object { "    $_" }) -join "`n"
        $null = $Sb.AppendLine($Indented)
        $null = $Sb.AppendLine()

    }

    $null = $Sb.AppendLine('  </ViewDefinitions>')
    $null = $Sb.AppendLine('</Configuration>')

    Save-File $OutFile $Sb.ToString().TrimEnd()
    $WrittenFormatFiles.Add("Private\Classes\$FolderName\$FolderName.Format.ps1xml")

}

# ─────────────────────────────────────────────────────────────────────────────
# Step 12 - Write domain Types.ps1xml files
# ─────────────────────────────────────────────────────────────────────────────

Write-Step 'Writing domain Types.ps1xml files'

$WrittenTypesFiles = [System.Collections.Generic.List[string]]::new()

foreach ($FolderName in $WrittenDomains) {

    if (-not $TypesEntryMap.Contains($FolderName)) {

        Write-Detail "No Types entries for domain: $FolderName - skipping"
        continue

    }

    $DomainDir = Join-Path $ClassesDir $FolderName
    $OutFile   = Join-Path $DomainDir "$FolderName.Types.ps1xml"

    $Sb = [System.Text.StringBuilder]::new()
    $null = $Sb.AppendLine('<?xml version="1.0" encoding="utf-8"?>')
    $null = $Sb.AppendLine("<!-- SPDX-License-Identifier: MPL-2.0 -->")
    $null = $Sb.AppendLine("<!-- $FolderName domain Type extensions -->")
    $null = $Sb.AppendLine('<Types>')
    $null = $Sb.AppendLine()

    foreach ($EntryXml in $TypesEntryMap[$FolderName]) {

        $Indented = ($EntryXml -split "`n" | ForEach-Object { "  $_" }) -join "`n"
        $null = $Sb.AppendLine($Indented)
        $null = $Sb.AppendLine()

    }

    $null = $Sb.AppendLine('</Types>')

    Save-File $OutFile $Sb.ToString().TrimEnd()
    $WrittenTypesFiles.Add("Private\Classes\$FolderName\$FolderName.Types.ps1xml")

}

# ─────────────────────────────────────────────────────────────────────────────
# Step 13 - Confirm load order (already computed in Step 8.5)
# ─────────────────────────────────────────────────────────────────────────────

Write-Step 'Cross-domain load order (already resolved in Step 8.5)'
Write-Detail "Load order: $($LoadOrder -join ' -> ')"

# ─────────────────────────────────────────────────────────────────────────────
# Step 14 - Rewrite DattoRMM.Core.psm1 using module statements
# ─────────────────────────────────────────────────────────────────────────────

Write-Step 'Rewriting DattoRMM.Core.psm1'

$OriginalPsm1 = [System.IO.File]::ReadAllText($ModuleFile, [System.Text.Encoding]::UTF8)

# Build the new 'using module' block
$UsingBlock = [System.Text.StringBuilder]::new()
$null = $UsingBlock.AppendLine("# Load class definitions - order is determined by cross-domain inheritance")
foreach ($Dom in $LoadOrder) {

    $RelPath = ".\Private\Classes\$Dom\$Dom.psm1"
    $null = $UsingBlock.AppendLine("using module '$RelPath'")

}

$NewUsingBlock = $UsingBlock.ToString().TrimEnd()

# Replace the existing single 'using module' line
$OldUsing = "using module '.\Private\Classes\Classes.psm1'"
$NewPsm1  = $OriginalPsm1.Replace($OldUsing, $NewUsingBlock)

if ($NewPsm1 -eq $OriginalPsm1) {

    Write-Warning "Could not find existing 'using module' line - manual update of DattoRMM.Core.psm1 required"

} else {

    Save-File $ModuleFile $NewPsm1

}

# ─────────────────────────────────────────────────────────────────────────────
# Step 15 - Rewrite DattoRMM.Core.psd1 with all Format and Types files
# ─────────────────────────────────────────────────────────────────────────────

Write-Step 'Rewriting DattoRMM.Core.psd1'

$OriginalPsd1 = [System.IO.File]::ReadAllText($ManifestFile, [System.Text.Encoding]::UTF8)

# Build new TypesToProcess array - relative to module root, with forward slashes
$TypesArray = $WrittenTypesFiles | ForEach-Object {
    "    '$($_ -replace '\\', '\\')'`n"
}
$NewTypesBlock = "TypesToProcess = @(`n$($TypesArray -join ''))"

# Build new FormatsToProcess array
$FormatArray = $WrittenFormatFiles | ForEach-Object {
    "    '$($_ -replace '\\', '\\')'`n"
}
$NewFormatsBlock = "FormatsToProcess = @(`n$($FormatArray -join ''))"

# Replace existing single-file declarations
$NewPsd1 = $OriginalPsd1 `
    -replace "TypesToProcess\s*=\s*@\([^)]*\)", $NewTypesBlock `
    -replace "FormatsToProcess\s*=\s*@\([^)]*\)", $NewFormatsBlock

if ($NewPsd1 -eq $OriginalPsd1) {

    Write-Warning "Could not update TypesToProcess/FormatsToProcess in psd1 - manual update required"

} else {

    Save-File $ManifestFile $NewPsd1

}

# ─────────────────────────────────────────────────────────────────────────────
# Step 16 - Archive originals
# ─────────────────────────────────────────────────────────────────────────────

Write-Step 'Archiving original monolithic files'

$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

foreach ($OrigFile in @($ClassesFile, $FormatFile, $TypesFile)) {

    $BaseName   = Split-Path $OrigFile -Leaf
    $ArchiveDst = Join-Path $ArchiveDir "$Timestamp-$BaseName"

    if (-not $DryRun) {

        if (-not (Test-Path $ArchiveDir)) {

            $null = New-Item -ItemType Directory -Path $ArchiveDir -Force

        }

        Copy-Item $OrigFile $ArchiveDst
        Write-FileAction 'ARCHIVED' $ArchiveDst 'DarkYellow'

    } else {

        Write-FileAction 'DRY-RUN ARCHIVE' $ArchiveDst 'DarkGray'

    }

}

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────

Write-Step 'Migration complete' 'Green'
Write-Host ""
Write-Host "  Domains processed    : $($WrittenDomains.Count)" -ForegroundColor White
Write-Host "  Format files written : $($WrittenFormatFiles.Count)" -ForegroundColor White
Write-Host "  Types files written  : $($WrittenTypesFiles.Count)" -ForegroundColor White
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host "  1. Import-Module .\DattoRMM.Core\DattoRMM.Core.psd1 -Force  (validate load)" -ForegroundColor Gray
Write-Host "  2. Run Invoke-ScriptAnalyzer on all new .psm1 files" -ForegroundColor Gray
Write-Host "  3. Update Build-ClassDocs.ps1 to scan Private\Classes\*\*.psm1 instead of Classes.psm1" -ForegroundColor Gray
Write-Host "  4. Delete the original Classes.psm1, Format.ps1xml, Types.ps1xml once validated" -ForegroundColor Gray
Write-Host "  5. Retire ClassDocContent.psd1 once all classes have inline documentation" -ForegroundColor Gray
Write-Host ""

if ($DryRun) {

    Write-Host "  DRY RUN - no files were written" -ForegroundColor DarkYellow

}
