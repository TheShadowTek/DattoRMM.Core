<#
.SYNOPSIS
    Converts Markdown about_*.md files to PowerShell about help text, with class-aware enhancements.

.DESCRIPTION
    ConvertFrom-MdAboutDocs.ps1 reads all about_*.md files in the docs folder and generates PowerShell about help .txt files in en-US/.
    If an about topic matches a class, it includes class properties and methods in the output, and links to online documentation if available.
    Otherwise, it processes the file as a standard about_ topic.
    This script is intended to be used as part of the build process for the DattoRMM.Core module.

.PARAMETER AboutFolder
    The folder containing about_*.md files. Defaults to 'docs'.

.PARAMETER OutputFolder
    The folder to output .help.txt files. Defaults to 'en-US'.

.NOTES
    Script: ConvertFrom-MdAboutDocs.ps1
    Online doc links are constructed from DocsBaseUrl in the module manifest.
#>

param(
    [string]$AboutFolder = "docs",
    [string]$OutputFolder = "en-US"
)

# Load DocsBaseUrl from manifest
$manifestPath = Join-Path $PSScriptRoot '..\DattoRMM.Core.psd1'
$manifest = Import-PowerShellDataFile -Path $manifestPath
$DocsBaseUrl = $manifest.DocsBaseUrl

### Parse class names, properties, and methods from modular class files in Private/Classes
$classDefs = @{}
$classTextParts = @()
if (Test-Path 'Private/Classes') {
    $classFiles = Get-ChildItem 'Private/Classes' -Filter '*.ps*' -File | Sort-Object Name
    foreach ($file in $classFiles) {
        if (Test-Path $file.FullName) {
            $content = Get-Content $file.FullName -Raw
            # Exclude 'using' lines
            $content = ($content -split "`n") | Where-Object { $_ -notmatch '^\s*using\s' } | Out-String
            $classTextParts += $content
        }
    }
}
$classText = $classTextParts -join "`n"

# Parse class names, properties, and methods from the concatenated class text
$classDecls = [regex]::Matches($classText, 'class (\w+)[^{]*{', 'IgnoreCase')
$classInfos = @()
foreach ($decl in $classDecls) {
    $className = $decl.Groups[1].Value
    $startIdx = $decl.Index + $decl.Length
    $classInfos += [PSCustomObject]@{ Name = $className; Start = $startIdx; DeclIdx = $decl.Index }
}
for ($i = 0; $i -lt $classInfos.Count; $i++) {
    $className = $classInfos[$i].Name
    $bodyStart = $classInfos[$i].Start
    $bodyEnd = if ($i -lt $classInfos.Count - 1) { $classInfos[$i+1].DeclIdx } else { $classText.Length }
    $classBlock = $classText.Substring($bodyStart, $bodyEnd - $bodyStart)
    # Now extract the full class body using brace counting
    $braceCount = 1
    $body = ''
    for ($j = 0; $j -lt $classBlock.Length; $j++) {
        $c = $classBlock[$j]
        if ($c -eq '{') { $braceCount++ }
        elseif ($c -eq '}') { $braceCount-- }
        if ($braceCount -eq 0) { $body = $classBlock.Substring(0, $j); break }
    }
    # Properties: [Type]$Name
    # Improved regex: match nested brackets and array types
    $propMatches = [regex]::Matches($body, '^[ \t]*\[([\w\[\]]+)\]\s*\$(\w+)', 'Multiline')
    $props = @()
    foreach ($p in $propMatches) {
        $ptype = $p.Groups[1].Value
        $pname = $p.Groups[2].Value
        $props += "$pname [$ptype]"
    }
    Write-Host ("Class: {0} - Properties found: {1}" -f $className, ($props -join ', '))
    # Methods: static/instance
    $methodMatches = [regex]::Matches($body, '^[ \t]*(static\s+)?\[([^\]]+)\]\s+(\w+)\s*\(([^)]*)\)\s*\{', 'Multiline')
    $methods = @()
    foreach ($m in $methodMatches) {
        $isStatic = $m.Groups[1].Value
        $retType = $m.Groups[2].Value
        $methName = $m.Groups[3].Value
        $params = $m.Groups[4].Value
        # Exclude static FromAPIMethod methods
        if ($isStatic -and $methName -eq 'FromAPIMethod') { continue }
        # PowerShell style: static MethodName(params) Type
        $sig = ("$isStatic$methName($params) $retType").Trim()
        $methods += $sig
    }
    $classDefs[$className] = @{ Properties = $props; Methods = $methods }
}

# Get all about_*.md files
$aboutFiles = Get-ChildItem -Path $AboutFolder -Filter "about_*.md" -File
foreach ($file in $aboutFiles) {
    $aboutName = $file.BaseName
    $className = $aboutName -replace '^about_', ''
    $isClass = $classDefs.ContainsKey($className)
    $md = Get-Content $file.FullName -Raw
    $short = ""
    $long = ""
    $lines = $md -split "`r?`n"
    $currentSection = ""
    $properties = @()
    $inPropTable = $false
    $methodSections = @()
    $currentMethodCat = $null
    $seeAlsoItems = @()
    $inSeeAlso = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        # Section detection
        if ($line -match "^##? SHORT DESCRIPTION") { $currentSection = "short"; continue }
        elseif ($line -match "^##? LONG DESCRIPTION") { $currentSection = "long"; continue }
        elseif ($line -match "^##? PROPERTIES") { $currentSection = "properties"; $inPropTable = $false; continue }
        elseif ($line -match "^##? METHODS") { $currentSection = "methods"; $currentMethodCat = $null; continue }
        elseif ($line -match "^## SEE ALSO") {
            $inSeeAlso = $true
            continue
        }
        # Properties table parsing
        if ($currentSection -eq "properties") {
            if ($line -match '^\| *Property *\| *Type *\| *Description *\|') { $inPropTable = $true; continue }
            if ($inPropTable -and $line -match '^\|[- ]+\|') { continue } # skip table header separator
            if ($inPropTable -and $line -match '^\|') {
                $cols = $line -split '\|'; $cols = $cols | ForEach-Object { $_.Trim() } | Where-Object { $_ }
                if ($cols.Count -ge 3) {
                    $properties += @{ Name = $cols[0]; Type = $cols[1]; Desc = $cols[2] }
                }
                continue
            }
            if ($inPropTable -and !$line.Trim()) { $inPropTable = $false }
        }
        # Method parsing (just names)
        if ($currentSection -eq "methods" -and $currentMethodCat -and $methodSections.Count) {
            if ($line -match '^#### (.+)') {
                $methodSections[-1].Methods += $matches[1].Trim()
                continue
            }
        }
        # SEE ALSO parsing (plain text, ignore markdown links)
        if ($inSeeAlso) {
            # End SEE ALSO section if next heading or blank line after section found
            if ($line -match '^##? ' -and $seeAlsoSectionFound) { Write-Host ("    Exiting SEE ALSO section at heading line {0}: {1}" -f $i, $line); $inSeeAlso = $false; continue }
            if ($line.Trim() -eq "" -and $seeAlsoSectionFound) { Write-Host ("    Exiting SEE ALSO section at blank line {0}" -f $i); $inSeeAlso = $false; continue }
            if ($line -match '^\s*-\s*(.+)') {
                $item = $matches[1].Trim()

                # Remove markdown link if present
                if ($item -match '\[(.+?)\]\([^)]*\)') { $item = $matches[1] }
                Write-Host ("      Captured SEE ALSO item: {0}" -f $item)
                $seeAlsoItems += $item
                continue
            }
        }
        # Standard short/long
        if ($currentSection -eq "short") {
            # Strip markdown links in short description
            if ($line -match '\[(.+?)\]\([^)]*\)') { $line = $line -replace '\[(.+?)\]\([^)]*\)', '$1' }
            $short += $line + " `n"
        }
        elseif ($currentSection -eq "long") {
            # Strip markdown links in long description
            if ($line -match '\[(.+?)\]\([^)]*\)') { $line = $line -replace '\[(.+?)\]\([^)]*\)', '$1' }
            $long += $line + " `n"
        }
    }
    $short = $short.Trim()
    $long = $long.Trim()
    # If class, add parsed properties and methods
    if ($isClass) {
        Write-Host "  SEE ALSO items parsed: $($seeAlsoItems -join ', ')"
        $classProps = $classDefs[$className].Properties
        $classMethods = $classDefs[$className].Methods
        $long += "`n`n"
        $long += "PROPERTIES (from class)" + "`n" + ($classProps | ForEach-Object { "    $_" } | Out-String)
        $long += "`nMETHODS (from class)" + "`n" + ($classMethods | ForEach-Object { "    $_" } | Out-String)
        $long += "`nSEE ALSO"
        if ($seeAlsoItems.Count -gt 0) {
            Write-Host ("  Outputting SEE ALSO items for {0}: {1}" -f $aboutName, ($seeAlsoItems -join ', '))
            $long += "`n" + ($seeAlsoItems | ForEach-Object { "    $_" } | Out-String)
        } else {
            Write-Host ("  No SEE ALSO items found for {0}, using manifest URL" -f $aboutName)
            $long += "`n    $DocsBaseUrl$aboutName.md"
        }
    }
    # Output plain text about help file
    $txt = @()
    $txt += "TOPIC"
    $txt += "    $aboutName"
    $txt += ""
    $txt += "SHORT DESCRIPTION"
    $txt += "    $short"
    $txt += ""
    $txt += "LONG DESCRIPTION"
    $txt += "    $long"
    $txtFile = Join-Path $OutputFolder ($aboutName + ".help.txt")
    Set-Content -Path $txtFile -Value ($txt -join "`n")
    Write-Host "Generated: $txtFile (about help .txt)"
}
Write-Host "Class-aware about help generation complete."
