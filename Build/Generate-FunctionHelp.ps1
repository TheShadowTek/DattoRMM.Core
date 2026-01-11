<#
.SYNOPSIS
    Generates markdown help files for module functions using PlatyPS.

.DESCRIPTION
    This script generates markdown documentation for all public functions in the module.
    It handles the enum loading issue with PlatyPS and post-processes the output to
    clean up formatting (removes PS > prompts for cleaner examples).
    
    Only regenerates help files if the source function has been modified more recently
    than the existing markdown file.

.PARAMETER Force
    Force regeneration of all help files regardless of modification time.

.PARAMETER OutputFolder
    The folder to output markdown files to. Defaults to .\docs

.EXAMPLE
    .\Build\Generate-FunctionHelp.ps1
    
    Generates markdown help for any functions that have been modified.

.EXAMPLE
    .\Build\Generate-FunctionHelp.ps1 -Force
    
    Regenerates all markdown help files.
#>
[CmdletBinding()]
param(
    [switch]$Force,
    
    [string]$OutputFolder = ".\docs"
)

$ErrorActionPreference = 'Stop'

# Get module root (parent of Build folder)
$ModuleRoot = Split-Path $PSScriptRoot -Parent
Push-Location $ModuleRoot

try {

    Write-Host "Generating function help documentation..." -ForegroundColor Cyan
    
    # Ensure output folder exists
    if (-not (Test-Path $OutputFolder)) {

        New-Item -Path $OutputFolder -ItemType Directory | Out-Null
        Write-Host "  Created output folder: $OutputFolder"

    }
    
    # Load types into session (required for PlatyPS to resolve types)
    # Classes and enums must be loaded in the current scope, not just imported via module
    Write-Host "  Loading types into session..."
    . .\Private\classes.ps1
    
    # Import module
    Write-Host "  Importing module..."
    Import-Module .\Datto-RMM.psd1 -Force

    # Read DocsBaseUrl from manifest
    $Manifest = Import-PowerShellDataFile -Path .\Datto-RMM.psd1
    $DocsBaseUrl = $Manifest.PrivateData.PSData.DocsBaseUrl
    if (-not $DocsBaseUrl) {
        Write-Warning "DocsBaseUrl not found in manifest. Using './docs/' as fallback."
        $DocsBaseUrl = './docs/'
    }
    
    # Import PlatyPS
    if (-not (Get-Module -ListAvailable -Name PlatyPS)) {

        Write-Error "PlatyPS module not found. Install with: Install-Module PlatyPS"

    }

    Import-Module PlatyPS -ErrorAction Stop
    
    # Get all public functions
    $PublicFunctions = Get-ChildItem -Path .\Public -Filter *.ps1 -Recurse | Where-Object { $_.Name -notlike '*.Tests.ps1' }
    
    Write-Host "  Found $($PublicFunctions.Count) public functions"
    
    $Generated = 0
    $Skipped = 0
    
    foreach ($FunctionFile in $PublicFunctions) {

        $FunctionName = $FunctionFile.BaseName
        $MarkdownFile = Join-Path $OutputFolder "$FunctionName.md"
        
        # Check if regeneration is needed
        $ShouldGenerate = $Force

        if (-not $ShouldGenerate) {

            if (-not (Test-Path $MarkdownFile)) {

                $ShouldGenerate = $true

            } else {

                $SourceModified = $FunctionFile.LastWriteTime
                $MarkdownModified = (Get-Item $MarkdownFile).LastWriteTime

                if ($SourceModified -gt $MarkdownModified) {

                    $ShouldGenerate = $true

                }
            }
        }
        
        if ($ShouldGenerate) {

            Write-Host "  Generating: $FunctionName" -ForegroundColor Green
            
            # Generate markdown (suppress Get-Help type resolution warnings)
            $null = New-MarkdownHelp -Command $FunctionName -OutputFolder $OutputFolder -Force -NoMetadata -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            
            # Check if file was created
            if (-not (Test-Path $MarkdownFile)) {

                Write-Host "    WARNING: Failed to generate $FunctionName" -ForegroundColor Yellow
                continue

            }
            
            # Post-process: Clean up formatting

            $Content = Get-Content $MarkdownFile -Raw
            if ($null -eq $Content) {
                $Content = ''
            }

            # Remove "PS > " and ">> " from code blocks for cleaner examples
            $Content = $Content -replace '(?m)^PS > ', ''
            $Content = $Content -replace '(?m)^>> ', ''

            # Fix OUTPUTS and INPUTS sections: Remove ### from descriptive text lines
            $Content = $Content -replace '(?m)^### (?!-\S)', ''

            # Remove ProgressAction parameter (PowerShell 7.4+ common parameter noise)
            $Content = $Content -replace '(?ms)### -ProgressAction.*?(?=###|^##|\z)', ''


            # --- New: Ensure all code blocks are closed ---
            $openCodeBlocks = [regex]::Matches($Content, '```')
            $openCodeBlockCount = if ($openCodeBlocks) { $openCodeBlocks.Count } else { 0 }
            if ($openCodeBlockCount % 2 -ne 0) {
                Write-Host "    DEBUG: Unclosed code block detected in $FunctionName.md, auto-closing..." -ForegroundColor Yellow
                $Content = $Content + "`n$('```')"
            }


            # --- Improved: Convert RELATED LINKS to markdown links with doc path ---
            # Replace lines like [Get-RMMDevice]() or Get-RMMDevice with [Get-RMMDevice]({docpath}/Get-RMMDevice.md)
            $Content = [regex]::Replace($Content, '(?m)^\[([A-Za-z0-9\-_]+)\]\(\)|^([A-Za-z0-9\-_]+)$', {
                param($match)
                $name = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[2].Value }
                if ($null -eq $name -or $name -eq '') { return $match.Value }
                return "[$name]({docpath}/$name.md)"
            })

            # Replace {docpath} with DocsBaseUrl
            $Content = $Content -replace '\{docpath\}', $DocsBaseUrl.TrimEnd('/')

            # Write back (markdown expects newlines)
            Set-Content -Path $MarkdownFile -Value $Content

            $Generated++

        } else {

            Write-Host "  Skipped: $FunctionName (up to date)" -ForegroundColor Gray
            $Skipped++

        }
    }
    
    Write-Host ""
    Write-Host "Generation complete!" -ForegroundColor Cyan
    Write-Host "  Generated: $Generated" -ForegroundColor Green
    Write-Host "  Skipped: $Skipped" -ForegroundColor Gray
    Write-Host "  Output: $OutputFolder"
    
} finally {

    Pop-Location

}
