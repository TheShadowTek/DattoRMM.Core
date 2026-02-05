<#
.SYNOPSIS
    Shows completion status of class documentation content.

.DESCRIPTION
    Get-ClassDocStatus.ps1 analyzes the ClassDocContent.psd1 file and reports
    on documentation completion progress.
    
    Shows:
    - Overall completion percentage
    - Per-region completion
    - Per-class completion
    - List of TODO items (null or empty values)

.PARAMETER Region
    Filter to a specific region/folder.

.PARAMETER ClassName
    Filter to a specific class name.

.PARAMETER ShowTODOs
    Show detailed list of all TODO items (null/empty values).

.EXAMPLE
    .\Build\Get-ClassDocStatus.ps1
    Shows overall completion status.

.EXAMPLE
    .\Build\Get-ClassDocStatus.ps1 -Region DRMMDevice
    Shows completion status for DRMMDevice region only.

.EXAMPLE
    .\Build\Get-ClassDocStatus.ps1 -ShowTODOs
    Lists all incomplete documentation items.

.NOTES
    Author: Robert Faddes
    Helps track documentation completion progress.
#>
[CmdletBinding()]
param(
    [string]$Region,
    [string]$ClassName,
    [switch]$ShowTODOs
)

$ErrorActionPreference = 'Stop'

# Get module root
$ModuleRoot = Split-Path $PSScriptRoot -Parent
$ContentPsd1Path = Join-Path $PSScriptRoot 'ClassDocContent.psd1'

if (-not (Test-Path $ContentPsd1Path)) {
    Write-Error "ClassDocContent.psd1 not found. Run Build-ClassDocs.ps1 first."
    return
}

Write-Host "`n=== Class Documentation Status ===" -ForegroundColor Cyan
Write-Host "Loading ClassDocContent.psd1..." -ForegroundColor Yellow

$DocContent = Import-PowerShellDataFile -Path $ContentPsd1Path

# Function to count nulls/empties recursively
function Count-Completeness {
    param($Object, [ref]$Total, [ref]$Complete)
    
    if ($Object -is [hashtable]) {
        foreach ($Key in $Object.Keys) {
            if ($Key -like '_*') { continue }  # Skip metadata and deprecated
            Count-Completeness -Object $Object[$Key] -Total $Total -Complete $Complete
        }
    } elseif ($Object -is [array]) {
        foreach ($Item in $Object) {
            Count-Completeness -Object $Item -Total $Total -Complete $Complete
        }
    } else {
        $Total.Value++
        if ($null -ne $Object -and $Object -ne '') {
            $Complete.Value++
        }
    }
}

# Function to find TODOs
function Find-TODOs {
    param($Object, $Path = @())
    
    $TODOs = @()
    
    if ($Object -is [hashtable]) {
        foreach ($Key in $Object.Keys) {
            if ($Key -like '_*') { continue }
            $TODOs += Find-TODOs -Object $Object[$Key] -Path ($Path + $Key)
        }
    } elseif ($Object -is [array]) {
        for ($i = 0; $i -lt $Object.Count; $i++) {
            $TODOs += Find-TODOs -Object $Object[$i] -Path ($Path + "[$i]")
        }
    } else {
        if ($null -eq $Object -or $Object -eq '') {
            $TODOs += [PSCustomObject]@{
                Path = ($Path -join '.')
                Value = $Object
            }
        }
    }
    
    return $TODOs
}

# Filter by region/class if specified
$FilteredContent = @{}
foreach ($Key in $DocContent.Keys) {
    if ($Key -eq '_Metadata') { continue }
    
    if ($Region -and $Key -ne $Region) { continue }
    
    if ($ClassName) {
        if ($DocContent[$Key].ContainsKey($ClassName)) {
            $FilteredContent[$Key] = @{
                $ClassName = $DocContent[$Key][$ClassName]
            }
        }
    } else {
        $FilteredContent[$Key] = $DocContent[$Key]
    }
}

# Calculate overall stats
$OverallTotal = 0
$OverallComplete = 0
$RegionStats = @{}

foreach ($RegionKey in ($FilteredContent.Keys | Sort-Object)) {
    $RegionTotal = 0
    $RegionComplete = 0
    $ClassStats = @{}
    
    foreach ($ClassKey in ($FilteredContent[$RegionKey].Keys | Sort-Object)) {
        $ClassTotal = 0
        $ClassComplete = 0
        
        Count-Completeness -Object $FilteredContent[$RegionKey][$ClassKey] -Total ([ref]$ClassTotal) -Complete ([ref]$ClassComplete)
        
        $ClassStats[$ClassKey] = @{
            Total = $ClassTotal
            Complete = $ClassComplete
            Percentage = if ($ClassTotal -gt 0) { [math]::Round(($ClassComplete / $ClassTotal) * 100, 1) } else { 0 }
        }
        
        $RegionTotal += $ClassTotal
        $RegionComplete += $ClassComplete
    }
    
    $RegionStats[$RegionKey] = @{
        Total = $RegionTotal
        Complete = $RegionComplete
        Percentage = if ($RegionTotal -gt 0) { [math]::Round(($RegionComplete / $RegionTotal) * 100, 1) } else { 0 }
        Classes = $ClassStats
    }
    
    $OverallTotal += $RegionTotal
    $OverallComplete += $RegionComplete
}

# Display overall summary
Write-Host "`n=== Overall Summary ===" -ForegroundColor Cyan
$OverallPercentage = if ($OverallTotal -gt 0) { [math]::Round(($OverallComplete / $OverallTotal) * 100, 1) } else { 0 }
Write-Host "  Total fields:     $OverallTotal" -ForegroundColor Gray
Write-Host "  Completed:        $OverallComplete" -ForegroundColor Green
Write-Host "  Remaining:        $($OverallTotal - $OverallComplete)" -ForegroundColor Yellow
Write-Host "  Completion:       $OverallPercentage%" -ForegroundColor $(if ($OverallPercentage -ge 75) { 'Green' } elseif ($OverallPercentage -ge 50) { 'Yellow' } else { 'Red' })

# Display per-region breakdown
Write-Host "`n=== By Region ===" -ForegroundColor Cyan
foreach ($RegionKey in ($RegionStats.Keys | Sort-Object)) {
    $Stats = $RegionStats[$RegionKey]
    $Color = if ($Stats.Percentage -ge 75) { 'Green' } elseif ($Stats.Percentage -ge 50) { 'Yellow' } else { 'Red' }
    Write-Host "`n  $RegionKey`: $($Stats.Complete)/$($Stats.Total) ($($Stats.Percentage)%)" -ForegroundColor $Color
    
    foreach ($ClassKey in ($Stats.Classes.Keys | Sort-Object)) {
        $ClassStats = $Stats.Classes[$ClassKey]
        $ClassColor = if ($ClassStats.Percentage -ge 75) { 'Green' } elseif ($ClassStats.Percentage -ge 50) { 'Yellow' } else { 'Red' }
        Write-Host "    $ClassKey`: $($ClassStats.Complete)/$($ClassStats.Total) ($($ClassStats.Percentage)%)" -ForegroundColor $ClassColor
    }
}

# Show TODOs if requested
if ($ShowTODOs) {
    Write-Host "`n=== TODO Items ===" -ForegroundColor Cyan
    $AllTODOs = Find-TODOs -Object $FilteredContent
    
    if ($AllTODOs.Count -eq 0) {
        Write-Host "  No TODO items found! Documentation is complete." -ForegroundColor Green
    } else {
        Write-Host "  Found $($AllTODOs.Count) incomplete items:`n" -ForegroundColor Yellow
        foreach ($TODO in $AllTODOs) {
            Write-Host "    $($TODO.Path)" -ForegroundColor Gray
        }
    }
}

# Metadata info
if ($DocContent.ContainsKey('_Metadata')) {
    $Meta = $DocContent['_Metadata']
    Write-Host "`n=== Metadata ===" -ForegroundColor Cyan
    Write-Host "  Version:        $($Meta.Version)" -ForegroundColor Gray
    Write-Host "  Last Updated:   $($Meta.LastUpdated)" -ForegroundColor Gray
    Write-Host "  Auto Generated: $($Meta.AutoGenerated)" -ForegroundColor Gray
}

Write-Host "`n=== Complete ===" -ForegroundColor Cyan
