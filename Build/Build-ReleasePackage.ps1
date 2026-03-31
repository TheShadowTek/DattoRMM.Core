<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>

<#
.SYNOPSIS
    Builds a release package zip for DattoRMM.Core.

.DESCRIPTION
    Creates a clean release zip containing:
      - DattoRMM.Core/ (the module folder — signed files, help, classes, everything)
      - DattoRMM.Core-CodeSigning.cer (public certificate for signature trust)
      - docs/ (full documentation)
      - INSTALL.md
      - CHANGELOG.md
      - SECURITY.md
      - README.md
      - LICENSE

    The zip is structured so that DattoRMM.Core/ is at the root of the archive,
    making it directly importable by PowerShell and compatible with Azure Automation.

    The script reads the version and prerelease tag from the module manifest to
    name the output file automatically.

.PARAMETER OutputPath
    Directory where the release zip will be created. Defaults to .\Release.

.PARAMETER SkipSignatureCheck
    Skip the pre-build signature validation. Use only during development.

.EXAMPLE
    .\Build-ReleasePackage.ps1

    Builds the release zip to .\Release\ using the version from the module manifest.

.EXAMPLE
    .\Build-ReleasePackage.ps1 -OutputPath C:\Releases

    Builds the release zip to C:\Releases\.
#>

[CmdletBinding()]
param(

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\Release'),

    [Parameter()]
    [switch]$SkipSignatureCheck

)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path $PSScriptRoot -Parent

# ---------------------------------------------------------------------------
# Read version from module manifest
# ---------------------------------------------------------------------------

$ManifestPath = Join-Path $RepoRoot 'DattoRMM.Core\DattoRMM.Core.psd1'

if (-not (Test-Path $ManifestPath)) {

    throw "Module manifest not found at: $ManifestPath"

}

$Manifest = Import-PowerShellDataFile -Path $ManifestPath
$Version  = $Manifest.ModuleVersion

$Prerelease = $null
if ($Manifest.PrivateData.PSData.Prerelease) {

    $Prerelease = $Manifest.PrivateData.PSData.Prerelease

}

if ($Prerelease) {

    $FullVersion = "$Version-$Prerelease"

} else {

    $FullVersion = $Version

}

Write-Verbose "Module version: $FullVersion"

# ---------------------------------------------------------------------------
# Validate signatures (unless skipped)
# ---------------------------------------------------------------------------

if (-not $SkipSignatureCheck) {

    Write-Host 'Validating code signatures...' -ForegroundColor Cyan

    $SignedFiles = Get-ChildItem -Path (Join-Path $RepoRoot 'DattoRMM.Core') -Recurse -Include '*.psm1','*.psd1','*.ps1','*.ps1xml'
    $InvalidSigs = @()

    foreach ($File in $SignedFiles) {

        $Sig = Get-AuthenticodeSignature -FilePath $File.FullName

        if ($Sig.Status -ne 'Valid') {

            $InvalidSigs += [PSCustomObject]@{
                File   = $File.Name
                Status = $Sig.Status
            }

        }

    }

    if ($InvalidSigs.Count -gt 0) {

        Write-Warning "$($InvalidSigs.Count) file(s) have invalid or missing signatures:"
        $InvalidSigs | Format-Table -AutoSize | Out-String | Write-Warning
        throw 'Signature validation failed. Sign all files before building a release package.'

    }

    Write-Host "  $($SignedFiles.Count) files validated — all signatures OK" -ForegroundColor Green

}

# ---------------------------------------------------------------------------
# Stage the release content
# ---------------------------------------------------------------------------

$StagingDir = Join-Path ([System.IO.Path]::GetTempPath()) "DattoRMM.Core-Release-$([guid]::NewGuid().ToString('N').Substring(0,8))"

Write-Verbose "Staging directory: $StagingDir"

try {

    New-Item -ItemType Directory -Path $StagingDir -Force | Out-Null

    # Module folder (the main payload)
    Copy-Item -Path (Join-Path $RepoRoot 'DattoRMM.Core') -Destination (Join-Path $StagingDir 'DattoRMM.Core') -Recurse

    # Documentation
    Copy-Item -Path (Join-Path $RepoRoot 'docs') -Destination (Join-Path $StagingDir 'docs') -Recurse

    # Root-level files
    $RootFiles = @(
        'DattoRMM.Core-CodeSigning.cer'
        'INSTALL.md'
        'CHANGELOG.md'
        'SECURITY.md'
        'README.md'
        'LICENSE'
    )

    foreach ($FileName in $RootFiles) {

        $SourceFile = Join-Path $RepoRoot $FileName

        if (Test-Path $SourceFile) {

            Copy-Item -Path $SourceFile -Destination (Join-Path $StagingDir $FileName)

        } else {

            Write-Warning "Expected file not found, skipping: $FileName"

        }

    }

    # ---------------------------------------------------------------------------
    # Build the zip
    # ---------------------------------------------------------------------------

    $OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

    $ZipName = "DattoRMM.Core-$FullVersion.zip"
    $ZipPath = Join-Path $OutputPath $ZipName

    if (Test-Path $ZipPath) {

        Remove-Item $ZipPath -Force
        Write-Verbose "Removed existing zip: $ZipPath"

    }

    Write-Host "Building release package..." -ForegroundColor Cyan

    Compress-Archive -Path (Join-Path $StagingDir '*') -DestinationPath $ZipPath -CompressionLevel Optimal

    $ZipSize = [math]::Round((Get-Item $ZipPath).Length / 1MB, 2)

    Write-Host ''
    Write-Host "  Release package created:" -ForegroundColor Green
    Write-Host "    File:    $ZipPath" -ForegroundColor Green
    Write-Host "    Version: $FullVersion" -ForegroundColor Green
    Write-Host "    Size:    $ZipSize MB" -ForegroundColor Green
    Write-Host ''

} finally {

    # Clean up staging directory
    if (Test-Path $StagingDir) {

        Remove-Item $StagingDir -Recurse -Force
        Write-Verbose "Cleaned up staging directory"

    }

}
