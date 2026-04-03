<#
.SYNOPSIS
    Signs the DattoRMM.Core module files with an Authenticode signature.
.DESCRIPTION
    This script signs the module manifest (.psd1) and root module (.psm1) files
    using a code signing certificate stored in the local machine certificate store.
    
    The certificate must be imported to Cert:\CurrentUser\TrustedPublisher\ before running this script.
    
    Signing ensures:
    - File integrity (detect tampering)
    - Module authenticity (prove it came from you)
    - Execution policy compliance (signed scripts can run under restricted policies)
    
    IMPORTANT: Any edits to signed files invalidate the signature. You must re-sign
    after making changes. This is a security feature.
.PARAMETER CertThumbprint
    Thumbprint of the code signing certificate in the local machine store.
    If not provided, the script will search for a certificate with "DattoRMM" in the subject.
.PARAMETER ModulePath
    Path to the DattoRMM.Core module folder. Defaults to the module in the workspace.
.PARAMETER Force
    If $true, signs files even if they already have a valid signature.
.EXAMPLE
    .\Sign-Module.ps1
    
    Searches for a certificate with "DattoRMM" in the subject and signs the module.
.EXAMPLE
    .\Sign-Module.ps1 -CertThumbprint "ABC123DEF456..."
    
    Signs the module using the specified certificate thumbprint.
.EXAMPLE
    .\Sign-Module.ps1 -Force $true
    
    Forces re-signing of all module files (useful after editing signed files).
#>
param(
	[string]$CertThumbprint,
	[string]$ModulePath = "$PSScriptRoot\..\DattoRMM.Core",
	[bool]$Force = $false
)

# Ensure the module path exists
if (-not (Test-Path $ModulePath)) {
	Write-Error "Module path not found: $ModulePath"
	exit 1
}

Write-Host "=== DattoRMM.Core Code Signing ===" -ForegroundColor Cyan
Write-Host "Module path: $ModulePath"
Write-Host ""

# ============================================================================
# 1. Find or validate the code signing certificate
# ============================================================================

Write-Host "Step 1: Locating code signing certificate..." -ForegroundColor Yellow

$cert = $null
$certStores = @(
	'Cert:\CurrentUser\My',
	'Cert:\LocalMachine\My'
)

if ($CertThumbprint) {
	Write-Host "  Searching for certificate with thumbprint: $CertThumbprint"
	foreach ($store in $certStores) {
		$cert = Get-ChildItem -Path $store -Recurse -ErrorAction SilentlyContinue | 
			Where-Object { $_.Thumbprint -eq $CertThumbprint }
		if ($cert) { break }
	}
} else {
	Write-Host "  Searching for certificate with 'DattoRMM' in subject..."
	foreach ($store in $certStores) {
		$cert = Get-ChildItem -Path $store -Recurse -ErrorAction SilentlyContinue | 
			Where-Object { $_.Subject -like "*DattoRMM.Core*" }
		if ($cert) { break }
	}
	
	if (-not $cert) {
		Write-Host "  No certificate found with 'DattoRMM.Core' in subject."
		Write-Host "  Searching for any available code signing certificates..."
		
		foreach ($store in $certStores) {
			$certs = Get-ChildItem -Path $store -Recurse -ErrorAction SilentlyContinue | Where-Object {
				$_.Extensions | Where-Object { $_.Oid.FriendlyName -eq "Enhanced Key Usage" } | 
				Where-Object { $_.Format($false) -like "*Code Signing*" }
			}
			
			if ($certs) {
				Write-Host ""
				Write-Host "  Found $(($certs | Measure-Object).Count) code signing certificate(s) in $store :"
				$certs | ForEach-Object { 
					Write-Host "    ✓ Subject: $($_.Subject)"
					Write-Host "      Thumbprint: $($_.Thumbprint)"
					Write-Host "      Valid: $($_.NotBefore) to $($_.NotAfter)"
					Write-Host ""
				}
				if ($certs -is [array]) {
					$cert = $certs[0]
					Write-Host "  Using first certificate."
				} else {
					$cert = $certs
				}
				break
			}
		}
	}
}

if (-not $cert) {
	Write-Error "Could not find a code signing certificate in:"
	Write-Host "  - Cert:\CurrentUser\My"
	Write-Host "  - Cert:\LocalMachine\My"
	Write-Host ""
	Write-Host "Available certificates (all stores):"
	Get-ChildItem -Path Cert:\LocalMachine -Recurse -ErrorAction SilentlyContinue | 
		Where-Object { $_.HasPrivateKey } | 
		ForEach-Object { Write-Host "  Subject: $($_.Subject), Thumbprint: $($_.Thumbprint)" }
	Write-Host ""
	Write-Host "To resolve this:"
	Write-Host "1. Check if you have a .pfx or .p12 file (typically excluded from git)"
	Write-Host "2. Verify which certificate you used to sign before:"
	Write-Host "   Get-ChildItem -Path Cert:\CurrentUser\My | Format-List Subject, Thumbprint"
	Write-Host "   Get-ChildItem -Path Cert:\LocalMachine\My | Format-List Subject, Thumbprint"
	Write-Host "3. Import the .pfx file if needed:"
	Write-Host "   `$pfx = Get-Item 'path\to\cert.pfx'"
	Write-Host "   `$pfxPass = ConvertTo-SecureString 'password' -AsPlainText -Force"
	Write-Host "   Import-PfxCertificate -FilePath `$pfx.FullName -CertStoreLocation Cert:\CurrentUser\My -Password `$pfxPass"
	Write-Host "4. Run this script again with the certificate thumbprint"
	exit 1
}

Write-Host ""
Write-Host "  ✓ Certificate found: $($cert.Subject)" -ForegroundColor Green
Write-Host "  Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
Write-Host "  Valid: $($cert.NotBefore) to $($cert.NotAfter)"
Write-Host ""

# Verify the certificate has code signing capability
$hasCodeSigning = $cert.Extensions | Where-Object { $_.Oid.FriendlyName -eq "Enhanced Key Usage" } | 
					Where-Object { $_.Format($false) -like "*Code Signing*" }

if (-not $hasCodeSigning) {
	Write-Warning "Certificate does not have 'Code Signing' in its Enhanced Key Usage."
	Write-Host ""
	Write-Host "Available certificates with Code Signing capability:"
	foreach ($store in $certStores) {
		Get-ChildItem -Path $store -Recurse -ErrorAction SilentlyContinue | Where-Object {
			$_.Extensions | Where-Object { $_.Oid.FriendlyName -eq "Enhanced Key Usage" } | 
			Where-Object { $_.Format($false) -like "*Code Signing*" }
		} | ForEach-Object {
			Write-Host "  Subject: $($_.Subject)"
			Write-Host "  Thumbprint: $($_.Thumbprint)"
		}
	}
	Write-Host ""
	$confirm = Read-Host "Continue anyway? (y/n)"
	if ($confirm -ne 'y') {
		exit 0
	}
}

# ============================================================================
# 2. Collect all files to sign
# ============================================================================

Write-Host "Step 2: Collecting files to sign..." -ForegroundColor Yellow

$filesToSign = @()

# Manifest
$manifestPath = Join-Path $ModulePath "DattoRMM.Core.psd1"
if (Test-Path $manifestPath) {
	$filesToSign += $manifestPath
} else {
	Write-Error "Manifest file not found: $manifestPath"
	exit 1
}

# Root module
$rootModule = Join-Path $ModulePath "DattoRMM.Core.psm1"
if (Test-Path $rootModule) {
	$filesToSign += $rootModule
} else {
	Write-Error "Root module not found: $rootModule"
	exit 1
}

# All .psm1 files in Private/Classes (class definitions), excluding _Archive
$classModules = Get-ChildItem -Path $ModulePath -Include '*.psm1' -Recurse | 
	Where-Object { 
		($_.FullName -like "*Private\Classes*" -or $_.FullName -like "*Private/Classes*") -and
		$_.FullName -notlike "*_Archive*"
	}
$filesToSign += $classModules.FullName

# All .ps1 files in Public (public functions)
$publicFunctions = Get-ChildItem -Path $ModulePath -Include '*.ps1' -Recurse | 
	Where-Object { $_.FullName -like "*Public*" }
$filesToSign += $publicFunctions.FullName

# All .psd1 files in Private/Data (static data files)
$dataFiles = Get-ChildItem -Path $ModulePath -Include '*.psd1' -Recurse |
	Where-Object { $_.FullName -like "*Private\Data*" -or $_.FullName -like "*Private/Data*" }
$filesToSign += $dataFiles.FullName

# All .ps1xml files (format and type definitions)
$xmlFiles = Get-ChildItem -Path $ModulePath -Include '*.ps1xml' -Recurse
$filesToSign += $xmlFiles.FullName

# Remove duplicates and nulls
$filesToSign = $filesToSign | Where-Object { $_ } | Select-Object -Unique | Sort-Object

Write-Host "  Found $(($filesToSign | Measure-Object).Count) file(s) to sign:"
$filesToSign | ForEach-Object {
	Write-Host "    - $(Split-Path -Leaf $_)" -ForegroundColor Gray
}
Write-Host ""

# ============================================================================
# 3. Sign all collected files
# ============================================================================

Write-Host "Step 3: Signing files..." -ForegroundColor Yellow

$signedCount = 0
$failedCount = 0
$failedFiles = @()

foreach ($file in $filesToSign) {
	try {
		$signParams = @{
			FilePath		= $file
			Certificate		= $cert
			IncludeChain	= 'All'
			ErrorAction		= 'Stop'
		}
		
		if ($Force) {
			$signParams['Force'] = $true
		}
		
		Set-AuthenticodeSignature @signParams | Out-Null
		Write-Host "  ✓ $(Split-Path -Leaf $file)" -ForegroundColor Green
		$signedCount++
	} catch {
		Write-Host "  ✗ $(Split-Path -Leaf $file) - $_" -ForegroundColor Red
		$failedCount++
		$failedFiles += $file
	}
}

Write-Host ""

# ============================================================================
# 4. Verify signatures
# ============================================================================

Write-Host "Step 4: Verifying signatures..." -ForegroundColor Yellow

$validCount = 0
$invalidCount = 0

foreach ($file in $filesToSign) {
	$sig = Get-AuthenticodeSignature -FilePath $file
	
	if ($sig.Status -eq 'Valid') {
		$validCount++
	} else {
		$invalidCount++
		Write-Host "  ⚠ $(Split-Path -Leaf $file): $($sig.Status)" -ForegroundColor Yellow
	}
}

Write-Host "  Valid signatures: $validCount / $(($filesToSign | Measure-Object).Count)"
Write-Host ""

# ============================================================================
# 5. Summary
# ============================================================================

Write-Host "=== Signing Summary ===" -ForegroundColor Cyan
Write-Host "Total files signed:   $signedCount"
Write-Host "Total files verified: $validCount / $(($filesToSign | Measure-Object).Count)"

if ($failedCount -gt 0) {
	Write-Host "Failed files:         $failedCount" -ForegroundColor Red
	$failedFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

Write-Host ""

if ($invalidCount -eq 0 -and $failedCount -eq 0) {
	Write-Host "=== All files signed successfully ===" -ForegroundColor Green
	Write-Host ""
	Write-Host "Next steps:"
	Write-Host "1. Test the signed module:"
	Write-Host "   Import-Module '$manifestPath' -Force"
	Write-Host "2. Verify execution policy:"
	Write-Host "   Get-ExecutionPolicy"
	Write-Host "3. After editing files, re-sign:"
	Write-Host "   .\Sign-Module.ps1 -Force `$true"
	Write-Host ""
	exit 0
} else {
	Write-Host "=== Signing Incomplete ===" -ForegroundColor Red
	Write-Host "Please check the errors above and try again."
	Write-Host ""
	exit 1
}
