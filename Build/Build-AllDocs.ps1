<#
.SYNOPSIS
    Orchestrates the complete documentation generation workflow for DattoRMM.Core.

.DESCRIPTION
    Build-AllDocs.ps1 coordinates the full documentation build process:
    
    1. FUNCTION DOCUMENTATION (Build-FunctionDocs.ps1)
       - Generates markdown from comment-based help for all Public/**/*.ps1 files
       - Outputs to docs/commands/
       - PowerShell handles help for these automatically (no .help.txt conversion)
    
    2. CLASS DOCUMENTATION (Build-ClassDocs.ps1)
       - Parses per-domain class .psm1 files using AST
       - Generates class reference markdown from inline documentation
       - Outputs markdown to docs/about/classes/
    
    3. HELP TEXT CONVERSION
       - Converts docs/about/*.md (manual topic docs) to en-US/*.help.txt
       - Converts docs/about/classes/*.md (generated class docs) to en-US/*.help.txt
       - Does NOT convert docs/commands/*.md (function docs)

.PARAMETER FunctionDocs
    Generate function documentation only.

.PARAMETER ClassDocs
    Generate class documentation only.

.PARAMETER ConvertToHelpText
    Convert markdown to .help.txt files only.

.PARAMETER All
    Run all steps: function docs, class docs, and help text conversion.

.PARAMETER Force
    Force regeneration of all files regardless of modification time.

.PARAMETER OutputFolder
    Root folder for en-US help text output. Defaults to .\DattoRMM.Core\en-US

.EXAMPLE
    .\Build\Build-AllDocs.ps1 -All
    Runs complete documentation generation workflow.

.EXAMPLE
    .\Build\Build-AllDocs.ps1 -FunctionDocs
    Generates function documentation only.

.EXAMPLE
    .\Build\Build-AllDocs.ps1 -ClassDocs -ConvertToHelpText
    Generates class docs and converts to help text.

.EXAMPLE
    .\Build\Build-AllDocs.ps1 -All -Force
    Regenerates all documentation from scratch.

.NOTES
    Author: Robert Faddes
    This script coordinates Build-FunctionDocs.ps1 and Build-ClassDocs.ps1.
#>
[CmdletBinding(DefaultParameterSetName = 'All')]
param(
    [Parameter(ParameterSetName = 'FunctionDocs')]
    [switch]$FunctionDocs,
    
    [Parameter(ParameterSetName = 'ClassDocs')]
    [switch]$ClassDocs,
    
    [Parameter(ParameterSetName = 'ConvertToHelpText')]
    [switch]$ConvertToHelpText,
    
    [Parameter(ParameterSetName = 'All')]
    [switch]$All,
    
    [switch]$Force,
    
    [string]$OutputFolder = "$PSScriptRoot\..\DattoRMM.Core\en-US"
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
# Resolve OutputFolder to absolute path
$OutputFolder = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFolder)
try {
    Write-Host "`n=== Build-AllDocs.ps1 ===" -ForegroundColor Cyan
    Write-Host "Orchestrating documentation generation workflow..." -ForegroundColor Cyan
    
    # Determine what to run
    $RunFunctionDocs = $All -or $FunctionDocs
    $RunClassDocs = $All -or $ClassDocs
    $RunConvertToHelpText = $All -or $ConvertToHelpText -or (-not ($FunctionDocs -or $ClassDocs))
    
    # Read manifest for DocsBaseUrl (used in help text conversion)
    Write-Host "`nReading module manifest..." -ForegroundColor Yellow
    $ManifestPath = Join-Path $ModuleRoot 'DattoRMM.Core\DattoRMM.Core.psd1'
    $Manifest = Import-PowerShellDataFile -Path $ManifestPath
    $DocsBaseUrl = $Manifest.PrivateData.PSData.DocsBaseUrl
    if (-not $DocsBaseUrl) {
        Write-Warning "DocsBaseUrl not found in manifest. Using default."
        $DocsBaseUrl = 'https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/'
    }
    Write-Host "  DocsBaseUrl: $DocsBaseUrl" -ForegroundColor Gray
    
    # ============================================================================
    # STEP 1: GENERATE FUNCTION DOCUMENTATION
    # ============================================================================
    
    if ($RunFunctionDocs) {
        Write-Host "`n=== STEP 1: Generating Function Documentation ===" -ForegroundColor Cyan
        
        $FunctionDocsScript = Join-Path $PSScriptRoot 'Build-FunctionDocs.ps1'
        if (Test-Path $FunctionDocsScript) {
            $ScriptParams = @{}
            if ($Force) { $ScriptParams['Force'] = $true }
            
            Write-Host "  Invoking: Build-FunctionDocs.ps1 $(if($Force){'-Force'})" -ForegroundColor Gray
            & $FunctionDocsScript @ScriptParams
            
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Build-FunctionDocs.ps1 reported errors."
            } else {
                Write-Host "`n  ✓ Function documentation complete" -ForegroundColor Green
            }
        } else {
            Write-Error "Build-FunctionDocs.ps1 not found at: $FunctionDocsScript"
        }
    }
    
    # ============================================================================
    # STEP 2: GENERATE CLASS DOCUMENTATION
    # ============================================================================
    
    if ($RunClassDocs) {
        Write-Host "`n=== STEP 2: Generating Class Documentation ===" -ForegroundColor Cyan
        
        $ClassDocsScript = Join-Path $PSScriptRoot 'Build-ClassDocs.ps1'
        if (Test-Path $ClassDocsScript) {
            $ScriptParams = @{}
            if ($Force) { $ScriptParams['Force'] = $true }
            
            Write-Host "  Invoking: Build-ClassDocs.ps1 $(if($Force){'-Force'})" -ForegroundColor Gray
            & $ClassDocsScript @ScriptParams
            
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Build-ClassDocs.ps1 reported errors."
            } else {
                Write-Host "`n  ✓ Class documentation complete" -ForegroundColor Green
            }
        } else {
            Write-Error "Build-ClassDocs.ps1 not found at: $ClassDocsScript"
        }
    }
    
    # ============================================================================
    # STEP 3: CONVERT MARKDOWN TO HELP TEXT
    # ============================================================================
    
    if ($RunConvertToHelpText) {
        Write-Host "`n=== STEP 3: Converting Markdown to Help Text ===" -ForegroundColor Cyan
        Write-Host "Converting docs/about/ markdown to en-US/*.help.txt..." -ForegroundColor Yellow
        Write-Host "Note: docs/commands/ is NOT converted (PowerShell handles function help automatically)" -ForegroundColor Gray
        
        # Get all about_*.md files from docs/about/ and docs/about/classes/ ONLY
        Write-Host "`nScanning for about_*.md files..." -ForegroundColor Yellow
        $AboutFiles = @(
            Get-ChildItem -Path (Join-Path $ModuleRoot 'docs\about') -Filter "about_*.md" -File -ErrorAction SilentlyContinue
            Get-ChildItem -Path (Join-Path $ModuleRoot 'docs\about\classes') -Filter "about_*.md" -File -Recurse -ErrorAction SilentlyContinue
        )
        
        Write-Host "  Found $($AboutFiles.Count) about topic files" -ForegroundColor Gray
        
        # Ensure output folder exists
        if (-not (Test-Path $OutputFolder)) {
            New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
        }
        
        $Converted = 0
        $Skipped = 0
        $Failed = 0
        
        foreach ($MdFile in $AboutFiles) {
            $AboutName = $MdFile.BaseName
            $ClassName = $AboutName -replace '^about_', ''
            
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
                            # HTTP links: emit label then URL on separate lines so Get-Help can show both
                            if ($Line -match '^\s*-\s*\[([^\]]+)\]\((https?://[^\)]+)\)') {
                                $SeeAlso += $matches[1].Trim()
                                $SeeAlso += $matches[2].Trim()
                            } elseif ($Line -match '^\s*-\s*\[([^\]]+)\]\([^\)]*\)') {
                                # Relative link — emit label only (URL not useful in shell)
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
                $Skipped++
            }
        }
        
        Write-Host "`n  Converted: $Converted" -ForegroundColor Green
        Write-Host "  Skipped:   $Skipped" -ForegroundColor Yellow
        Write-Host "  Failed:    $Failed" -ForegroundColor $(if ($Failed -gt 0) { 'Red' } else { 'Gray' })
    }
    
    # ============================================================================
    # SUMMARY
    # ============================================================================
    
    Write-Host "`n=== Documentation Generation Complete ===" -ForegroundColor Cyan
    Write-Host "Steps completed:" -ForegroundColor Yellow
    if ($RunFunctionDocs) { Write-Host "  ✓ Function documentation (docs/commands/)" -ForegroundColor Green }
    if ($RunClassDocs) { Write-Host "  ✓ Class documentation (docs/about/classes/)" -ForegroundColor Green }
    if ($RunConvertToHelpText) { Write-Host "  ✓ Help text conversion (en-US/*.help.txt)" -ForegroundColor Green }
    Write-Host ""
    
} finally {
    Pop-Location
}
