<#
.SYNOPSIS
    Converts PowerShell function help to Markdown documentation for all public module functions.

.DESCRIPTION
    ConvertTo-MdFunctionDocs.ps1 generates Markdown documentation for all public functions in the DattoRMM.Core module.
    It uses PlatyPS to extract help, handles enum loading issues, and post-processes the output to clean up formatting (such as removing 'PS >' prompts from examples).
    Only regenerates help files if the source function has been modified more recently than the existing Markdown file, unless -Force is specified.

.PARAMETER Force
    If specified, regenerates all function help files regardless of modification time.

.PARAMETER OutputFolder
    The folder to output Markdown files to. Defaults to .\docs

.EXAMPLE
    .\Build\ConvertTo-MdFunctionDocs.ps1
    Generates Markdown help for any functions that have been modified.

.EXAMPLE
    .\Build\ConvertTo-MdFunctionDocs.ps1 -Force
    Regenerates all Markdown help files.

.NOTES
    Script: ConvertTo-MdFunctionDocs.ps1
    Uses PlatyPS for help extraction and custom post-processing for formatting consistency.
#>
[CmdletBinding()]
param(
    [bool]$Force  =$true,
    
    [string]$OutputFolder = ".\docs\commands"
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
    # Load DRMMObject.psm1 first
    $objectModule = Join-Path $ModuleRoot "Private/Classes/DRMMObject.psm1"
    if (Test-Path $objectModule) {
        . $objectModule
        Write-Host "  Loaded DRMMObject.psm1"
    } else {
        Write-Warning "DRMMObject.psm1 not found: $objectModule"
    }
    # Load classes in module order
    $ClassFiles = @(
        'DRMMNetworkInterface.ps1',
        'DRMMEnums.ps1',
        'DRMMAccount.ps1',
        'DRMMActivityLog.ps1',
        'DRMMAlert.ps1',
        'DRMMComponent.ps1',
        'DRMMDeviceAudit.ps1',
        'DRMMJob.ps1',
        'DRMMDevice.ps1',
        'DRMMVariable.ps1',
        'DRMMFilter.ps1',
        'DRMMSite.ps1',
        'DRMMNetMapping.ps1',
        'DRMMStatus.ps1',
        'DRMMUser.ps1'
    )
    foreach ($file in $ClassFiles) {
        $path = Join-Path $ModuleRoot "Private/Classes/$file"
        if (Test-Path $path) {
            . $path
        } else {
            Write-Warning "Class file not found: $path"
        }
    }
    
    # Import module
    Write-Host "  Importing module..."
    Import-Module .\DattoRMM.Core.psd1 -Force

    # Read DocsBaseUrl from manifest
    $Manifest = Import-PowerShellDataFile -Path .\DattoRMM.Core.psd1
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
            New-MarkdownHelp -Command $FunctionName -OutputFolder $OutputFolder -Force -NoMetadata -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
            
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



            # --- Improved: Convert RELATED LINKS to markdown links with doc path (handles multi-line and .LINK tags) ---
            $Content = [regex]::Replace($Content, '(?ms)(^## RELATED LINKS\s*)([\s\S]*?)(?=^## |\z)', {
                param($match)
                $header = $match.Groups[1].Value
                $block = $match.Groups[2].Value
                # Extract all possible link names from the block
                $names = @()
                foreach ($line in $block -split "`n") {
                    $line = $line.Trim()
                    if ($line -match '^[\-\*]\s*\[([^\]]+)\]') { $names += $matches[1] }
                    elseif ($line -match '^\[([^\]]+)\]') { $names += $matches[1] }
                    elseif ($line -match '^([A-Za-z0-9\-_]+)$') { $names += $matches[1] }
                }
                if ($names.Count -eq 0) { return $match.Value }
                $links = $names | ForEach-Object { "- [$_]({docpath}/$_.md)" }
                return "$header`n$($links -join "`n")`n"
            })
            # Replace {docpath} with DocsBaseUrl
            $Content = $Content -replace '\{docpath\}', $DocsBaseUrl.TrimEnd('/')

            # Write back (markdown expects newlines)
            Set-Content -Path $MarkdownFile -Value $Content
            write-host "Iut path: $MarkdownFile"

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
