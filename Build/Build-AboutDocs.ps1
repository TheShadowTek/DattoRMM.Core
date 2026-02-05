<#
.SYNOPSIS
    Generates and converts about_ documentation for classes and topics.

.DESCRIPTION
    Build-AboutDocs.ps1 handles two types of about documentation:
    
    1. AUTO-GENERATION (from Classes.psm1):
       - Scans Private/Classes/Classes.psm1 for class definitions
       - Uses PowerShell AST (Abstract Syntax Tree) parser for reliable parsing
       - Generates about_ClassName.md files in docs/about/classes/
       - Includes properties, methods, and basic structure
    
    2. CONVERSION (markdown to help text):
       - Reads all about_*.md files from docs/about/ and docs/about/classes/
       - Converts markdown to PowerShell help text format
       - Outputs to en-US/*.help.txt for shell help access
       - Injects class structure for class-based topics

    AST = Abstract Syntax Tree: PowerShell's built-in code parser that understands
    PowerShell syntax and structure, making it more reliable than regex patterns.

.PARAMETER GenerateClassDocs
    If specified, auto-generates about_ClassName.md files from Classes.psm1.

.PARAMETER ConvertToHelpText
    If specified, converts existing markdown files to .help.txt format.

.PARAMETER All
    Performs both operations: generate class docs, then convert to help text.

.PARAMETER Force
    Force regeneration of all files regardless of modification time.

.PARAMETER AboutFolder
    Root folder for about documentation. Defaults to .\docs\about

.PARAMETER OutputFolder
    Folder for .help.txt output. Defaults to .\en-US

.EXAMPLE
    .\Build\Build-AboutDocs.ps1 -All
    Generates class docs and converts all to help text.

.EXAMPLE
    .\Build\Build-AboutDocs.ps1 -GenerateClassDocs
    Only generates about_ClassName.md files from Classes.psm1.

.EXAMPLE
    .\Build\Build-AboutDocs.ps1 -ConvertToHelpText
    Only converts existing markdown to .help.txt files.

.NOTES
    Author: Robert Faddes
    Uses AST (Abstract Syntax Tree) parsing for reliable class extraction.
#>
[CmdletBinding(DefaultParameterSetName = 'All')]
param(
    [Parameter(ParameterSetName = 'Generate')]
    [switch]$GenerateClassDocs,
    
    [Parameter(ParameterSetName = 'Convert')]
    [switch]$ConvertToHelpText,
    
    [Parameter(ParameterSetName = 'All')]
    [switch]$All,
    
    [switch]$Force = $true,
    
    [string]$AboutFolder = ".\docs\about",
    [string]$OutputFolder = ".\en-US"
)

$ErrorActionPreference = 'Continue'

# Helper function to format markdown tables with proper spacing
function Format-MarkdownTable {
    param(
        [string]$TableText
    )
    
    $Lines = $TableText -split "\r?\n" | Where-Object { $_.Trim() -match '^\|' }
    if ($Lines.Count -lt 2) { return $TableText }
    
    # Parse table - ensure each row is an array of cells
    $Rows = @()
    foreach ($Line in $Lines) {
        $Cells = @($Line -split '\|' | Select-Object -Skip 1 | Select-Object -SkipLast 1 | ForEach-Object { $_.Trim() })
        $Rows += ,$Cells  # Comma forces it to be added as a single array element
    }
    
    # Skip separator row (second row with dashes)
    $HeaderRow = $Rows[0]
    $DataRows = @($Rows | Select-Object -Skip 2)
    
    if ($DataRows.Count -eq 0) { return $TableText }
    
    # Calculate column widths (min 10, max 40 for readability)
    $ColumnCount = $HeaderRow.Count
    $ColumnWidths = for ($i = 0; $i -lt $ColumnCount; $i++) {
        $Widths = @($HeaderRow[$i].Length)
        foreach ($Row in $DataRows) {
            if ($i -lt $Row.Count) {
                $Widths += $Row[$i].Length
            }
        }
        $MaxWidth = ($Widths | Measure-Object -Maximum).Maximum
        [Math]::Min([Math]::Max($MaxWidth, 10), 40)
    }
    
    # Format as plain text with proper spacing
    $Output = @()
    $Output += "    " + (0..($ColumnCount-1) | ForEach-Object { $HeaderRow[$_].PadRight($ColumnWidths[$_]) }) -join '  '
    $Output += "    " + (0..($ColumnCount-1) | ForEach-Object { '-' * $ColumnWidths[$_] }) -join '  '
    foreach ($Row in $DataRows) {
        $RowText = "    " + (0..($ColumnCount-1) | ForEach-Object { 
            $Cell = if ($_ -lt $Row.Count) { $Row[$_] } else { "" }
            # Truncate if too long
            if ($Cell.Length -gt $ColumnWidths[$_]) {
                $Cell = $Cell.Substring(0, $ColumnWidths[$_] - 3) + '...'
            }
            $Cell.PadRight($ColumnWidths[$_])
        }) -join '  '
        $Output += $RowText
    }
    
    return ($Output -join "`n")
}

# Get module root
$ModuleRoot = Split-Path $PSScriptRoot -Parent
Push-Location $ModuleRoot

try {
    Write-Host "`n=== Build-AboutDocs.ps1 ===" -ForegroundColor Cyan
    
    # Read manifest for DocsBaseUrl
    Write-Host "`nReading module manifest..." -ForegroundColor Yellow
    $ManifestPath = Join-Path $ModuleRoot 'DattoRMM.Core.psd1'
    $Manifest = Import-PowerShellDataFile -Path $ManifestPath
    $DocsBaseUrl = $Manifest.PrivateData.PSData.DocsBaseUrl
    if (-not $DocsBaseUrl) {
        Write-Warning "DocsBaseUrl not found in manifest. Using default."
        $DocsBaseUrl = 'https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/'
    }
    Write-Host "  DocsBaseUrl: $DocsBaseUrl" -ForegroundColor Gray
    
    # Determine what to do
    $DoGenerate = $All -or $GenerateClassDocs
    $DoConvert = $All -or $ConvertToHelpText -or (-not $GenerateClassDocs)
    
    # ============================================================================
    # STEP 1: AUTO-GENERATE CLASS DOCUMENTATION
    # ============================================================================
    
    if ($DoGenerate) {
        Write-Host "`n=== Generating Class Documentation ===" -ForegroundColor Cyan
        Write-Host "Parsing Classes.psm1 using PowerShell AST..." -ForegroundColor Yellow
        
        $ClassesFile = Join-Path $ModuleRoot 'Private\Classes\Classes.psm1'
        if (-not (Test-Path $ClassesFile)) {
            Write-Warning "Classes.psm1 not found at: $ClassesFile"
            Write-Warning "Skipping class documentation generation."
        } else {
            # Parse using AST (Abstract Syntax Tree) - more reliable than regex
            Write-Host "  Reading file..." -ForegroundColor Gray
            $ClassesContent = Get-Content $ClassesFile -Raw
            $AST = [System.Management.Automation.Language.Parser]::ParseInput(
                $ClassesContent, 
                [ref]$null, 
                [ref]$null
            )
            
            # Find all class definitions using AST
            Write-Host "  Extracting class definitions..." -ForegroundColor Gray
            $ClassDefinitions = $AST.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.TypeDefinitionAst] -and
                $node.IsClass
            }, $true)
            
            Write-Host "  Found $($ClassDefinitions.Count) class definitions" -ForegroundColor Gray
            
            $ClassInfo = @{}
            
            foreach ($ClassDef in $ClassDefinitions) {
                $ClassName = $ClassDef.Name
                Write-Host "`n    Processing: $ClassName" -ForegroundColor Green
                
                # Extract properties
                $Properties = $ClassDef.Members | Where-Object { 
                    $_ -is [System.Management.Automation.Language.PropertyMemberAst] 
                }
                
                $PropList = foreach ($Prop in $Properties) {
                    $PropName = $Prop.Name
                    $PropType = $Prop.PropertyType.TypeName.FullName
                    Write-Host "      Property: $PropName [$PropType]" -ForegroundColor Gray
                    [PSCustomObject]@{
                        Name = $PropName
                        Type = $PropType
                    }
                }
                
                # Extract methods (excluding static FromAPIMethod)
                $Methods = $ClassDef.Members | Where-Object { 
                    $_ -is [System.Management.Automation.Language.FunctionMemberAst] 
                }
                
                $MethodList = foreach ($Method in $Methods) {
                    $MethodName = $Method.Name
                    $IsStatic = $Method.IsStatic
                    $ReturnType = if ($Method.ReturnType) { 
                        $Method.ReturnType.TypeName.FullName 
                    } else { 
                        'void' 
                    }
                    
                    # Skip static FromAPIMethod
                    if ($IsStatic -and $MethodName -eq 'FromAPIMethod') {
                        continue
                    }
                    
                    # Get parameters
                    $Params = $Method.Parameters | ForEach-Object {
                        $ParamType = if ($_.StaticType) { 
                            $_.StaticType.Name 
                        } else { 
                            'object' 
                        }
                        $ParamName = $_.Name.VariablePath.UserPath
                        "[$ParamType]`$$ParamName"
                    }
                    
                    $Signature = if ($IsStatic) {
                        "static $MethodName($($Params -join ', '))"
                    } else {
                        "$MethodName($($Params -join ', '))"
                    }
                    
                    Write-Host "      Method: $Signature : $ReturnType" -ForegroundColor Gray
                    
                    [PSCustomObject]@{
                        Name = $MethodName
                        Signature = $Signature
                        ReturnType = $ReturnType
                        IsStatic = $IsStatic
                    }
                }
                
                $ClassInfo[$ClassName] = @{
                    Properties = $PropList
                    Methods = $MethodList
                }
            }
            
            # Generate markdown files for each class
            Write-Host "`n  Generating markdown files..." -ForegroundColor Yellow
            $ClassDocsFolder = Join-Path $AboutFolder 'classes'
            if (-not (Test-Path $ClassDocsFolder)) {
                New-Item -Path $ClassDocsFolder -ItemType Directory -Force | Out-Null
            }
            
            $Generated = 0
            $Skipped = 0
            
            foreach ($ClassName in $ClassInfo.Keys | Sort-Object) {
                $AboutFile = Join-Path $ClassDocsFolder "about_$ClassName.md"
                
                # Check if regeneration needed
                $ShouldGenerate = $Force
                if (-not $ShouldGenerate) {
                    if (-not (Test-Path $AboutFile)) {
                        $ShouldGenerate = $true
                    } elseif ((Get-Item $ClassesFile).LastWriteTime -gt (Get-Item $AboutFile).LastWriteTime) {
                        $ShouldGenerate = $true
                    }
                }
                
                if ($ShouldGenerate) {
                    Write-Host "    Generating: about_$ClassName.md" -ForegroundColor Green
                    
                    $Info = $ClassInfo[$ClassName]
                    $Props = $Info.Properties
                    $Methods = $Info.Methods
                    
                    # Build markdown content
                    $Content = @"
# about_$ClassName

## SHORT DESCRIPTION

Describes the $ClassName class used in DattoRMM.Core module.

## LONG DESCRIPTION

The $ClassName class represents objects returned by various Get-RMM* cmdlets.
This class provides strongly-typed properties and methods for working with Datto RMM data.

For detailed usage examples and command reference, see the related cmdlets in the RELATED LINKS section below.

## PROPERTIES

The $ClassName class exposes the following properties:

"@
                    
                    if ($Props.Count -gt 0) {
                        $Content += @"

| Property | Type | Description |
|----------|------|-------------|

"@
                        foreach ($Prop in $Props) {
                            $Content += "| $($Prop.Name) | $($Prop.Type) | TODO: Add description |`n"
                        }
                    } else {
                        $Content += "`nNo public properties defined.`n"
                    }
                    
                    $Content += @"

## METHODS

The $ClassName class provides the following methods:

"@
                    
                    if ($Methods.Count -gt 0) {
                        foreach ($Method in $Methods) {
                            $Content += @"

### $($Method.Signature)

Returns: ``$($Method.ReturnType)``

TODO: Add method description and usage example.

``````powershell
# Example usage
# TODO: Add example
``````

"@
                        }
                    } else {
                        $Content += "`nNo public methods defined.`n"
                    }
                    
                    $Content += @"

## RELATED LINKS

- [Online Documentation]($DocsBaseUrl/about/classes/about_$ClassName.md)

"@
                    
                    # Save file
                    Set-Content -Path $AboutFile -Value $Content -NoNewline
                    $Generated++
                    
                } else {
                    Write-Host "    Skipped: about_$ClassName.md (up to date)" -ForegroundColor Yellow
                    $Skipped++
                }
            }
            
            Write-Host "`n  Generated: $Generated" -ForegroundColor Green
            Write-Host "  Skipped:   $Skipped" -ForegroundColor Yellow
        }
    }
    
    # ============================================================================
    # STEP 2: CONVERT MARKDOWN TO HELP TEXT
    # ============================================================================
    
    if ($DoConvert) {
        Write-Host "`n=== Converting Markdown to Help Text ===" -ForegroundColor Cyan
        
        # Re-parse class info for injection into help text
        Write-Host "Parsing Classes.psm1 for help text injection..." -ForegroundColor Yellow
        
        $ClassesFile = Join-Path $ModuleRoot 'Private\Classes\Classes.psm1'
        $ClassDefs = @{}
        
        if (Test-Path $ClassesFile) {
            $ClassesContent = Get-Content $ClassesFile -Raw
            $AST = [System.Management.Automation.Language.Parser]::ParseInput(
                $ClassesContent, 
                [ref]$null, 
                [ref]$null
            )
            
            $ClassDefinitions = $AST.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.TypeDefinitionAst] -and
                $node.IsClass
            }, $true)
            
            foreach ($ClassDef in $ClassDefinitions) {
                $ClassName = $ClassDef.Name
                
                # Properties
                $Properties = $ClassDef.Members | Where-Object { 
                    $_ -is [System.Management.Automation.Language.PropertyMemberAst] 
                }
                $PropStrings = foreach ($Prop in $Properties) {
                    "    $($Prop.Name) [$($Prop.PropertyType.TypeName.FullName)]"
                }
                
                # Methods (excluding static FromAPIMethod)
                $Methods = $ClassDef.Members | Where-Object { 
                    $_ -is [System.Management.Automation.Language.FunctionMemberAst] 
                }
                $MethodStrings = foreach ($Method in $Methods) {
                    if ($Method.IsStatic -and $Method.Name -eq 'FromAPIMethod') {
                        continue
                    }
                    $Params = $Method.Parameters | ForEach-Object {
                        $ParamType = if ($_.StaticType) { $_.StaticType.Name } else { 'object' }
                        $ParamName = $_.Name.VariablePath.UserPath
                        "[$ParamType]`$$ParamName"
                    }
                    $RetType = if ($Method.ReturnType) { 
                        $Method.ReturnType.TypeName.FullName 
                    } else { 
                        'void' 
                    }
                    $Signature = if ($Method.IsStatic) {
                        "static $($Method.Name)($($Params -join ', '))"
                    } else {
                        "$($Method.Name)($($Params -join ', '))"
                    }
                    "    $Signature : $RetType"
                }
                
                $ClassDefs[$ClassName] = @{
                    Properties = $PropStrings
                    Methods = $MethodStrings
                }
            }
            
            Write-Host "  Loaded $($ClassDefs.Count) class definitions" -ForegroundColor Gray
        }
        
        # Get all about_*.md files
        Write-Host "`nScanning for about_*.md files..." -ForegroundColor Yellow
        $AboutFiles = @(
            Get-ChildItem -Path $AboutFolder -Filter "about_*.md" -File -ErrorAction SilentlyContinue
            Get-ChildItem -Path (Join-Path $AboutFolder 'classes') -Filter "about_*.md" -File -ErrorAction SilentlyContinue
        )
        
        Write-Host "  Found $($AboutFiles.Count) about files" -ForegroundColor Gray
        
        # Ensure output folder exists
        if (-not (Test-Path $OutputFolder)) {
            New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
        }
        
        $Converted = 0
        $SkippedConvert = 0
        $Failed = 0
        
        foreach ($MdFile in $AboutFiles) {
            $AboutName = $MdFile.BaseName
            $ClassName = $AboutName -replace '^about_', ''
            $IsClass = $ClassDefs.ContainsKey($ClassName)
            
            $HelpFile = Join-Path $OutputFolder "$AboutName.help.txt"
            
            # Check if conversion needed
            $ShouldConvert = $Force
            if (-not $ShouldConvert) {
                if (-not (Test-Path $HelpFile)) {
                    $ShouldConvert = $true
                } elseif ($MdFile.LastWriteTime -gt (Get-Item $HelpFile).LastWriteTime) {
                    $ShouldConvert = $true
                }
            }
            
            if ($ShouldConvert) {
                Write-Host "`n  Converting: $AboutName" -ForegroundColor Green
                Write-Host "    Source: $($MdFile.FullName.Replace($ModuleRoot + '\', ''))" -ForegroundColor Gray
                Write-Host "    Output: $($HelpFile.Replace($ModuleRoot + '\', ''))" -ForegroundColor Gray
                Write-Host "    Type: $(if ($IsClass) { 'Class' } else { 'Topic' })" -ForegroundColor Gray
                
                try {
                    $Markdown = Get-Content $MdFile.FullName -Raw
                    
                    # Parse markdown sections
                    $ShortDesc = ""
                    $LongDesc = ""
                    $SeeAlso = @()
                    
                    $Lines = $Markdown -split "`r?`n"
                    $CurrentSection = ""
                    $InSeeAlso = $false
                    
                    for ($i = 0; $i -lt $Lines.Count; $i++) {
                        $Line = $Lines[$i]
                        
                        # Detect sections
                        if ($Line -match "^##?\s*SHORT DESCRIPTION") {
                            $CurrentSection = "short"
                            continue
                        } elseif ($Line -match "^##?\s*LONG DESCRIPTION") {
                            $CurrentSection = "long"
                            continue
                        } elseif ($Line -match "^##?\s*RELATED LINKS") {
                            $InSeeAlso = $true
                            $CurrentSection = "see-also"
                            continue
                        } elseif ($Line -match "^##?\s+" -and $CurrentSection -eq "see-also") {
                            # Next section starts, exit see-also
                            $InSeeAlso = $false
                            continue
                        }
                        
                        # Parse content
                        if ($CurrentSection -eq "short") {
                            # Strip markdown links
                            $Line = $Line -replace '\[([^\]]+)\]\([^\)]*\)', '$1'
                            if ($Line.Trim()) {
                                $ShortDesc += $Line.Trim() + " "
                            }
                        } elseif ($CurrentSection -eq "long") {
                            # Strip markdown links
                            $Line = $Line -replace '\[([^\]]+)\]\([^\)]*\)', '$1'
                            if ($Line.Trim() -or $LongDesc) {
                                $LongDesc += $Line + "`n"
                            }
                        } elseif ($InSeeAlso) {
                            # Extract link text (strip markdown)
                            if ($Line -match '^\s*-\s*\[([^\]]+)\]') {
                                $SeeAlso += $matches[1].Trim()
                            } elseif ($Line -match '^\s*-\s*(.+)') {
                                $SeeAlso += $matches[1].Trim()
                            } elseif ($Line -match '^\[([^\]]+)\]') {
                                $SeeAlso += $matches[1].Trim()
                            }
                        }
                    }
                    
                    $ShortDesc = $ShortDesc.Trim()
                    $LongDesc = $LongDesc.Trim()
                    
                    # Convert markdown tables to formatted plain text
                    Write-Host "    Formatting tables..." -ForegroundColor Gray
                    $LongDesc = [regex]::Replace($LongDesc, '(?ms)(\|[^\r\n]+\|\r?\n)+', {
                        param($match)
                        Format-MarkdownTable -TableText $match.Value
                    })
                    
                    # If class, inject class structure
                    if ($IsClass -and $ClassDefs.ContainsKey($ClassName)) {
                        Write-Host "    Injecting class structure..." -ForegroundColor Gray
                        $ClassInfo = $ClassDefs[$ClassName]
                        
                        $LongDesc += "`n`n"
                        $LongDesc += "PROPERTIES`n"
                        if ($ClassInfo.Properties.Count -gt 0) {
                            $LongDesc += ($ClassInfo.Properties -join "`n") + "`n"
                        } else {
                            $LongDesc += "    No public properties.`n"
                        }
                        
                        $LongDesc += "`nMETHODS`n"
                        if ($ClassInfo.Methods.Count -gt 0) {
                            $LongDesc += ($ClassInfo.Methods -join "`n") + "`n"
                        } else {
                            $LongDesc += "    No public methods.`n"
                        }
                    }
                    
                    # Build help text format
                    $HelpText = @"
TOPIC
    $AboutName

SHORT DESCRIPTION
    $ShortDesc

LONG DESCRIPTION
$LongDesc

"@
                    
                    if ($SeeAlso.Count -gt 0) {
                        $HelpText += "SEE ALSO`n"
                        foreach ($Link in $SeeAlso) {
                            $HelpText += "    $Link`n"
                        }
                    } else {
                        # Default to online docs
                        $OnlineUrl = "$DocsBaseUrl/about/$AboutName.md"
                        $HelpText += "SEE ALSO`n    $OnlineUrl`n"
                    }
                    
                    # Save help file
                    Set-Content -Path $HelpFile -Value $HelpText -NoNewline
                    Write-Host "    ✓ Converted successfully" -ForegroundColor Green
                    $Converted++
                    
                } catch {
                    Write-Warning "    Failed to convert $AboutName : $_"
                    $Failed++
                }
            } else {
                $SkippedConvert++
            }
        }
        
        Write-Host "`n  Converted: $Converted" -ForegroundColor Green
        Write-Host "  Skipped:   $SkippedConvert" -ForegroundColor Yellow
        Write-Host "  Failed:    $Failed" -ForegroundColor $(if ($Failed -gt 0) { 'Red' } else { 'Gray' })
    }
    
    Write-Host "`n=== Complete ===" -ForegroundColor Cyan
    
} finally {
    Pop-Location
}
