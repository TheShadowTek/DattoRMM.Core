<#
.SYNOPSIS
    Generates Markdown documentation from comment-based help for all public module functions.

.DESCRIPTION
    Build-FunctionDocs.ps1 generates comprehensive Markdown documentation by:
    - Scanning all Public/**/*.ps1 files for functions
    - Using PlatyPS to extract comment-based help
    - Post-processing output to clean up formatting issues
    - Preserving folder structure from Public/ in docs/commands/
    - Only regenerating files when source has been modified (unless -Force)

    Post-processing includes:
    - Removing 'PS >' and '>>' prompts from examples
    - Fixing unclosed code blocks
    - Converting RELATED LINKS to proper markdown links
    - Removing noise parameters (ProgressAction, etc.)

.PARAMETER Force
    If specified, regenerates all function documentation regardless of modification time.

.PARAMETER OutputFolder
    The root folder for command documentation. Defaults to .\docs\commands
    Subfolders will mirror the Public/ folder structure.

.EXAMPLE
    .\Build\Build-FunctionDocs.ps1
    Generates Markdown documentation for modified functions only.

.EXAMPLE
    .\Build\Build-FunctionDocs.ps1 -Force
    Regenerates all function documentation.

.NOTES
    Author: Robert Faddes
    Requires: PlatyPS module
    Uses PowerShell AST (Abstract Syntax Tree) parsing for reliable type loading.
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [string]$OutputFolder = "$PSScriptRoot\..\docs\commands"
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'Continue'

# Get module root (parent of Build folder)
$ModuleRoot = Split-Path $PSScriptRoot -Parent
Push-Location $ModuleRoot

# Resolve OutputFolder to absolute path
$OutputFolder = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFolder)

try {
    Write-Host "`n=== Build-FunctionDocs.ps1 ===" -ForegroundColor Cyan
    Write-Host "Generating function documentation from comment-based help..." -ForegroundColor Cyan
    
    # Ensure PlatyPS is available
    Write-Host "`nChecking for PlatyPS module..." -ForegroundColor Yellow
    if (-not (Get-Module -ListAvailable -Name PlatyPS)) {
        Write-Error "PlatyPS module not found. Install with: Install-Module PlatyPS"
        return
    }
    Import-Module PlatyPS -ErrorAction Stop
    Write-Host "  ✓ PlatyPS loaded" -ForegroundColor Green
    
    # Load types into session (required for PlatyPS to resolve custom types)
    Write-Host "`nLoading module types and classes..." -ForegroundColor Yellow
    
    # Load consolidated Classes.psm1
    $ClassesModule = Join-Path $ModuleRoot "DattoRMM.Core\Private\Classes\Classes.psm1"
    if (Test-Path $ClassesModule) {
        try {
            . $ClassesModule
            Write-Host "  ✓ Loaded Classes.psm1" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to load Classes.psm1: $_"
        }
    } else {
        Write-Warning "Classes.psm1 not found at: $ClassesModule"
    }
    
    # Import the module to get functions loaded
    Write-Host "`nImporting module..." -ForegroundColor Yellow
    try {
        $ModulePath = Join-Path $ModuleRoot 'DattoRMM.Core\DattoRMM.Core.psd1'
        Import-Module $ModulePath -Force -ErrorAction Stop
        Write-Host "  ✓ Module imported successfully" -ForegroundColor Green
    } catch {
        Write-Error "Failed to import module: $_"
        return
    }

    # Read DocsBaseUrl from manifest for RELATED LINKS
    Write-Host "\nReading module manifest..." -ForegroundColor Yellow
    $ManifestPath = Join-Path $ModuleRoot 'DattoRMM.Core\DattoRMM.Core.psd1'
    $Manifest = Import-PowerShellDataFile -Path $ManifestPath
    $DocsBaseUrl = $Manifest.PrivateData.PSData.DocsBaseUrl
    if (-not $DocsBaseUrl) {
        Write-Warning "DocsBaseUrl not found in manifest. Using default './docs/'"
        $DocsBaseUrl = './docs/'
    }
    Write-Host "  DocsBaseUrl: $DocsBaseUrl" -ForegroundColor Gray
    
    # Get all public function files
    Write-Host "`nScanning for public functions..." -ForegroundColor Yellow
    $PublicPath = Join-Path $ModuleRoot 'DattoRMM.Core\Public'
    $PublicFunctions = Get-ChildItem -Path $PublicPath -Filter *.ps1 -Recurse | 
        Where-Object { $_.Name -notlike '*.Tests.ps1' }
    
    Write-Host "  Found $($PublicFunctions.Count) public function files" -ForegroundColor Gray
        # Build lookup for function -> relative path in docs/commands
    Write-Host "\nBuilding documentation lookup tables..." -ForegroundColor Yellow
    $FunctionLookup = @{}
    foreach ($FuncFile in $PublicFunctions) {
        $FuncName = $FuncFile.BaseName
        $RelPath = $FuncFile.DirectoryName.Replace((Join-Path $ModuleRoot 'DattoRMM.Core\Public'), '').TrimStart('\','/')
        $FunctionLookup[$FuncName] = if ($RelPath) { $RelPath } else { '' }
    }
    
    # Build lookup for about docs -> relative path in docs/about
    $AboutLookup = @{}
    $AboutDocsPath = Join-Path $ModuleRoot 'docs\about'
    if (Test-Path $AboutDocsPath) {
        $AboutFiles = Get-ChildItem -Path $AboutDocsPath -Filter 'about_*.md' -Recurse
        foreach ($AboutFile in $AboutFiles) {
            $AboutName = $AboutFile.BaseName
            $RelPath = $AboutFile.DirectoryName.Replace($AboutDocsPath, '').TrimStart('\','/')
            $AboutLookup[$AboutName] = if ($RelPath) { $RelPath } else { '' }
        }
    }
    Write-Host "  Found $($FunctionLookup.Count) functions and $($AboutLookup.Count) about docs" -ForegroundColor Gray
        $Generated = 0
    $Skipped = 0
    $Failed = 0
    
    foreach ($FunctionFile in $PublicFunctions) {
        $FunctionName = $FunctionFile.BaseName
        
        # Calculate relative path from Public folder to preserve structure
        $RelativePath = $FunctionFile.DirectoryName.Replace((Join-Path $ModuleRoot 'DattoRMM.Core\Public'), '').TrimStart('\','/')
        
        # Create output path preserving folder structure
        $OutputSubFolder = if ($RelativePath) {
            Join-Path $OutputFolder $RelativePath
        } else {
            $OutputFolder
        }
        
        # Ensure output subfolder exists
        if (-not (Test-Path $OutputSubFolder)) {
            New-Item -Path $OutputSubFolder -ItemType Directory -Force | Out-Null
            Write-Host "`n  Created folder: $OutputSubFolder" -ForegroundColor Gray
        }
        
        $MarkdownFile = Join-Path $OutputSubFolder "$FunctionName.md"
        
        # Check if regeneration is needed
        $ShouldGenerate = $Force
        if (-not $ShouldGenerate) {
            if (-not (Test-Path $MarkdownFile)) {
                $ShouldGenerate = $true
                $Reason = "new file"
            } else {
                $SourceModified = $FunctionFile.LastWriteTime
                $MarkdownModified = (Get-Item $MarkdownFile).LastWriteTime
                if ($SourceModified -gt $MarkdownModified) {
                    $ShouldGenerate = $true
                    $Reason = "source modified"
                } elseif (Select-String -Path $MarkdownFile -Pattern '\{\{ Fill' -Quiet) {
                    $ShouldGenerate = $true
                    $Reason = "placeholder content detected"
                }
            }
        } else {
            $Reason = "forced"
        }
        
        if ($ShouldGenerate) {
            Write-Host "`n  Processing: $FunctionName" -ForegroundColor Green
            Write-Host "    Source: $($FunctionFile.FullName.Replace($ModuleRoot + '\', ''))" -ForegroundColor Gray
            Write-Host "    Output: $($MarkdownFile.Replace($ModuleRoot + '\', ''))" -ForegroundColor Gray
            Write-Host "    Reason: $Reason" -ForegroundColor Gray
            
            try {
                # Generate markdown (suppress warnings about type resolution)
                Write-Host "    Generating with PlatyPS..." -ForegroundColor Gray
                $Result = New-MarkdownHelp -Command $FunctionName -OutputFolder $OutputSubFolder -Force -NoMetadata -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                
                if (-not $Result) {
                    Write-Warning "    PlatyPS did not generate output for $FunctionName"
                    $Failed++
                    continue
                }
                
                # Check if file was created
                if (-not (Test-Path $MarkdownFile)) {
                    Write-Warning "    Markdown file not created: $MarkdownFile"
                    $Failed++
                    continue
                }
                
                # Post-process: Clean up formatting
                Write-Host "    Post-processing markdown..." -ForegroundColor Gray
                $Content = Get-Content $MarkdownFile -Raw
                
                if ($null -eq $Content) {
                    Write-Warning "    Markdown file is empty: $MarkdownFile"
                    $Failed++
                    continue
                }
                
                # Track changes for logging
                $Changes = @()
                
                # Remove "PS > " and ">> " from code blocks for cleaner examples
                if ($Content -match '(?m)^PS > ' -or $Content -match '(?m)^>> ') {
                    $Content = $Content -replace '(?m)^PS > ', ''
                    $Content = $Content -replace '(?m)^>> ', ''
                    $Changes += "Removed PS > prompts"
                }
                
                # Fix OUTPUTS and INPUTS sections: Remove ### from descriptive text
                if ($Content -match '(?m)^### (?!-\S)') {
                    $Content = $Content -replace '(?m)^### (?!-\S)', ''
                    $Changes += "Fixed heading levels"
                }
                
                # Remove ProgressAction parameter (PowerShell 7.4+ noise)
                if ($Content -match '(?ms)### -ProgressAction') {
                    $Content = $Content -replace '(?ms)### -ProgressAction.*?(?=###|^##|\z)', ''
                    $Changes += "Removed ProgressAction parameter"
                }
                
                # Update example script blocks to use 'powershell' language identifier
                # Replace only opening code blocks that follow EXAMPLE headings
                $Content = [regex]::Replace($Content, '(?ms)(^## EXAMPLES\r?\n)(.*?)(?=^## |\z)', {
                    param($match)
                    $header = $match.Groups[1].Value
                    $examplesSection = $match.Groups[2].Value
                    # Replace code blocks that immediately follow EXAMPLE N headings
                    $examplesSection = $examplesSection -replace '(?m)(^EXAMPLE \d+\r?\n)```\r?\n', "`$1``````powershell`n"
                    return $header + $examplesSection
                })
                
                # Ensure all code blocks are closed
                $CodeBlockCount = ([regex]::Matches($Content, '```')).Count
                if ($CodeBlockCount % 2 -ne 0) {
                    $Content = $Content.TrimEnd() + "`n``````n"
                    $Changes += "Closed unclosed code block"
                }
                
                # Convert RELATED LINKS to markdown links with relative paths
                $Content = [regex]::Replace($Content, '(?ms)(^## RELATED LINKS\s*)([\s\S]*?)(?=^## |\z)', {
                    param($match)
                    $header = $match.Groups[1].Value
                    $block = $match.Groups[2].Value
                    
                    # Extract GitHub URL for "Online Documentation" link
                    $OnlineDocUrl = $null
                    foreach ($line in $block -split "`n") {
                        $line = $line.Trim()
                        if ($line -match '(https?://[^\s]+)') {
                            $OnlineDocUrl = $matches[1]
                            break
                        }
                    }
                    
                    # Extract link names from the block (skip URLs)
                    $names = @()
                    foreach ($line in $block -split "`n") {
                        $line = $line.Trim()
                        # Skip empty lines
                        if ([string]::IsNullOrWhiteSpace($line)) {
                            continue
                        }
                        # Skip full URLs
                        if ($line -match 'https?://') {
                            continue
                        }
                        # Match various formats: [Name], - Name, Name
                        if ($line -match '^\[([^\]]+)\]') { 
                            $names += $matches[1] 
                        } elseif ($line -match '^[\-\*]\s*(.+)') { 
                            $names += $matches[1].Trim() 
                        } elseif ($line -match '^([A-Za-z0-9\-_]+)$') { 
                            $names += $matches[1] 
                        }
                    }
                    
                    # Calculate relative path from current function location
                    $CurrentRelPath = if ($RelativePath) { $RelativePath } else { '' }
                    $DepthFromCommands = if ($CurrentRelPath) { ($CurrentRelPath -split '[\\\\/]').Count } else { 0 }
                    $BackToCommands = if ($DepthFromCommands -gt 0) { ('../' * $DepthFromCommands) } else { './' }
                    
                    $linkLines = @()
                    
                    # Add Online Documentation link first if found
                    if ($OnlineDocUrl) {
                        $linkLines += "- [Online Documentation]($OnlineDocUrl)"
                    }
                    
                    # Add relative links for other docs
                    if ($names.Count -gt 0) {
                        foreach ($name in $names) {
                            if ($name -match '^about_') {
                                # About topics - need to go up to docs root, then into about
                                if ($AboutLookup.ContainsKey($name)) {
                                    $AboutSubPath = $AboutLookup[$name] -replace '\\', '/'  # Normalize to forward slashes
                                    $AboutPath = if ($AboutSubPath) { "about/$AboutSubPath/$name.md" } else { "about/$name.md" }
                                    $RelPath = "$BackToCommands../$AboutPath"
                                } else {
                                    # Fallback if not found in lookup
                                    $RelPath = "$BackToCommands../about/$name.md"
                                }
                                $linkLines += "- [$name]($RelPath)"
                            } else {
                                # Commands - calculate relative path from current function to linked function
                                if ($FunctionLookup.ContainsKey($name)) {
                                    $TargetSubPath = $FunctionLookup[$name] -replace '\\', '/'  # Normalize to forward slashes
                                    if ($CurrentRelPath -eq $TargetSubPath) {
                                        # Same subfolder
                                        $RelPath = "./$name.md"
                                    } elseif ($TargetSubPath) {
                                        # Different subfolder
                                        $RelPath = "$BackToCommands$TargetSubPath/$name.md"
                                    } else {
                                        # Target is in root commands folder
                                        $RelPath = "$BackToCommands$name.md"
                                    }
                                } else {
                                    # Fallback if not found in lookup
                                    $RelPath = "$BackToCommands$name.md"
                                }
                                $linkLines += "- [$name]($RelPath)"
                            }
                        }
                    }
                    
                    if ($linkLines.Count -gt 0) {
                        return $header + "`n" + ($linkLines -join "`n") + "`n"
                    } else {
                        # No links at all - remove the entire RELATED LINKS section
                        return ""
                    }
                })
                
                # Save cleaned content
                Set-Content -Path $MarkdownFile -Value $Content -NoNewline
                
                if ($Changes.Count -gt 0) {
                    Write-Host "    Changes: $($Changes -join ', ')" -ForegroundColor Gray
                }
                Write-Host "    ✓ Generated successfully" -ForegroundColor Green
                $Generated++
                
            } catch {
                Write-Warning "    Failed to process $FunctionName : $_"
                $Failed++
            }
        } else {
            $Skipped++
        }
    }
    
    # Summary
    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "  Generated: $Generated" -ForegroundColor Green
    Write-Host "  Skipped:   $Skipped" -ForegroundColor Yellow
    Write-Host "  Failed:    $Failed" -ForegroundColor $(if ($Failed -gt 0) { 'Red' } else { 'Gray' })
    Write-Host "  Total:     $($PublicFunctions.Count)`n" -ForegroundColor Gray
    
} finally {
    Pop-Location
}
