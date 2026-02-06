# Determine paths
$CurrentFolder = Split-Path -Path $PSCommandPath -Parent
$RootFolder    = Split-Path -Path $CurrentFolder -Parent

# Hardcoded SPDX header (block comment)
$Header = @"
<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>

"@

# File to exclude
$ExcludedFile = Join-Path -Path $RootFolder -ChildPath "DattoRMM.Core\Private\howtothrottle.ps1"

# Allowed file extensions
$AllowedExtensions = @(
    '.ps1',
    '.psm1',
    '.psd1',
    '.psrc',
    '.pssc'
)

Write-Host "Root folder: $RootFolder"
Write-Host "Excluding current folder: $CurrentFolder"
Write-Host "Excluding easter egg: $ExcludedFile"
Write-Host "Allowed extensions: $($AllowedExtensions -join ', ')"

# Get only allowed file types, excluding build folder + easter egg
$Files = Get-ChildItem -Path $RootFolder -Recurse -File |
    Where-Object {
        $_.DirectoryName -ne $CurrentFolder -and
        $_.FullName -ne $ExcludedFile -and
        $AllowedExtensions -contains $_.Extension
    }

foreach ($File in $Files) {

    $Content = Get-Content -Path $File.FullName -Raw

    # Skip if SPDX already present
    if ($Content -match 'SPDX-License-Identifier') {
        Write-Host "Skipping (already has SPDX): $($File.FullName)"
        continue
    }

    Write-Host "======================" -ForegroundColor Magenta
    Write-Host "Adding SPDX header to: $($File.FullName)"

    # Prepend header directly
    $NewContent = $Header + $Content

    Set-Content -Path $File.FullName -Value $NewContent -Encoding UTF8
}
