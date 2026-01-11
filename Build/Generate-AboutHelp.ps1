
<#
.SYNOPSIS
    Converts about_*.md files in docs/about/ to MAML XML files in en-US/ for PowerShell external help.
.DESCRIPTION
    This script parses markdown files, extracts key sections, and generates minimal MAML XML for use with Get-Help about_*. 
    Designed for maintainability: write help in markdown for GitHub, convert to MAML for the module.
.NOTES
    Only basic markdown features and sections are supported. Extend as needed for more advanced formatting.
#>

param(
    [string]$SourceFolder = "docs/about",
    [string]$OutputFolder = "en-US"
)

function Convert-MarkdownToMaml {
    param(
        [string]$MarkdownPath,
        [string]$XmlPath
    )
    $md = Get-Content $MarkdownPath -Raw
    $lines = $md -split "`r?`n"
    $short = ""
    $long = ""
    $examples = @()
    $currentSection = ""
    $exampleBlock = ""
    $customSections = @()
    $customSectionText = ""
    $customSectionTitle = ""
    foreach ($line in $lines) {
        # Heading detection
        if ($line -match "^(#+) (.+)") {
            $level = $matches[1].Length
            $title = $matches[2].Trim()
            $upperTitle = $title.ToUpper()
            if ($upperTitle -eq "SHORT DESCRIPTION") {
                $currentSection = "short"
                continue
            } elseif ($upperTitle -eq "LONG DESCRIPTION") {
                $currentSection = "long"
                continue
            } elseif ($upperTitle -like "EXAMPLES*") {
                $currentSection = "examples"
                continue
            } else {
                # Save previous custom section
                if ($customSectionTitle -and $customSectionText) {
                    $customSections += "`n$customSectionTitle`n$customSectionText"
                }
                # Start new custom section with readable heading formatting
                if ($level -eq 1) {
                    $customSectionTitle = "$upperTitle`n" + ('=' * $title.Length)
                } elseif ($level -eq 2) {
                    $customSectionTitle = "$title`n" + ('-' * $title.Length)
                } elseif ($level -eq 3) {
                    $customSectionTitle = "* $title *"
                } else {
                    $customSectionTitle = (' ' * ($level-3)*2) + "- $title -"
                }
                $customSectionText = ""
                $currentSection = "custom"
                continue
            }
        }
        if ($currentSection -eq "short") {
            $short += $line + " `n"
        } elseif ($currentSection -eq "long") {
            $long += $line + " `n"
        } elseif ($currentSection -eq "examples") {
            if ($line -match "^```powershell") {
                $exampleBlock = ""
                continue
            } elseif ($line -match "^```$") {
                $examples += $exampleBlock.Trim()
                $exampleBlock = ""
                continue
            } elseif ($exampleBlock -ne $null) {
                $exampleBlock += $line + "`n"
            }
        } elseif ($currentSection -eq "custom") {
            $customSectionText += $line + "`n"
        }
    }
    # Add last custom section if present
    if ($customSectionTitle -and $customSectionText) {
        $customSections += "`n$customSectionTitle`n$customSectionText"
    }
    $short = $short.Trim()
    $long = $long.Trim()
    # Append custom sections to longDescription
    if ($customSections.Count -gt 0) {
        $long += "`n" + ($customSections -join "`n")
    }
    # Build MAML XML
        $xml = @"
<?xml version="1.0" encoding="utf-8"?>
<helpItems schema="maml" xmlns="http://msh" xmlns:maml="http://schemas.microsoft.com/maml/2004/10">
    <maml:about>
        <maml:aboutName>$($MarkdownPath | Split-Path -Leaf | Split-Path -LeafBase)</maml:aboutName>
        <maml:shortDescription>
            <maml:para>$short</maml:para>
        </maml:shortDescription>
        <maml:longDescription>
            <maml:para>$long</maml:para>
        </maml:longDescription>
        <maml:relatedLinks />
        <maml:examples>
"@
        foreach ($ex in $examples) {
                $xml += @"
            <maml:example>
                <maml:title />
                <maml:introduction />
                <maml:code>$ex</maml:code>
                <maml:remarks />
            </maml:example>
"@
        }
        $xml += @"
        </maml:examples>
    </maml:about>
</helpItems>
"@
    Set-Content -Path $XmlPath -Value $xml
    if (Test-Path $XmlPath) {
        Write-Host "[DIAG] Confirmed file written: $XmlPath"

    } else {
        Write-Warning "[DIAG] File not found after write: $XmlPath"
    }
}

# Create output folder if missing
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

# Get all about_*.md files
$aboutFiles = Get-ChildItem -Path $SourceFolder -Filter "about_*.md" -File
if (-not $aboutFiles) {
    Write-Warning "No about_*.md files found in $SourceFolder."
    return
}


Write-Host "[DIAG] About files to process: $($aboutFiles.Count)"
foreach ($file in $aboutFiles) {
    Write-Host "[DIAG] Processing: $($file.FullName)"
    $xmlFile = Join-Path $OutputFolder ($file.BaseName + ".xml")
    Write-Host "[DIAG] Output XML path: $xmlFile"
    if (-not $file.FullName -or -not $xmlFile) {
        Write-Warning "[DIAG] Skipping file due to missing path: $($file.FullName) -> $xmlFile"
        continue
    }
    try {
        Convert-MarkdownToMaml -MarkdownPath $file.FullName -XmlPath $xmlFile
        Write-Host "Generated: $xmlFile"
    } catch {
        Write-Error "[DIAG] Failed to process $($file.FullName): $_"
    }
}

Write-Host "About MAML XML generation complete."
