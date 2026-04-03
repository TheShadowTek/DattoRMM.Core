# Code Signing Guide for DattoRMM.Core

## Overview

Code signing adds a digital signature to PowerShell files (.ps1, .psm1, .psd1) to ensure:
- **Integrity**: The file hasn't been modified since signing
- **Authenticity**: Proves the file came from you (certificate holder)
- **Trust**: Allows execution under restricted execution policies

## Key Concepts

### What Gets Signed?

For comprehensive security, we sign **all** PowerShell files:

**Always signed:**
- `DattoRMM.Core.psm1` — Root module file
- `DattoRMM.Core.psd1` — Module manifest
- `DattoRMM.Core.ps1xml` — Format/type definitions
- `DattoRMM.Core.Types.ps1xml` — Type accelerator definitions

**Recursively signed:**
- `Public/**/*.ps1` — All public functions (Account, Alerts, Devices, etc.)
- `Private/Classes/**/*.psm1` — All class definition modules
- Any other `.ps1xml` files in the module

This approach ensures:
- **Complete integrity** — Every file in the module is verifiable
- **Tamper detection** — Any modification is detectable
- **Distribution security** — Users can trust the entire package
- **Best practice** — Comprehensive signing is the industry standard

### What Doesn't Get Signed?

- Archived files (`Private/Classes/_Archive/*`)
- Build scripts (development-only, like this signing script)
- Documentation and markdown files
- Configuration files (.gitignore, test fixtures, etc.)
- Generated output (releases, build artifacts)

### Signing vs Execution Policy

| Execution Policy | Requires Signature | Notes |
|---|---|---|
| Unrestricted | No | Scripts run regardless of signature |
| RemoteSigned | Only for downloaded scripts | Local scripts run unsigned |
| AllSigned | Yes | All scripts must be signed |
| Restricted | N/A | No scripts can run |

## Prerequisites

### 1. Certificate in Local Machine Store

Your code signing certificate must be installed in:
```
Cert:\LocalMachine\My\
```

If you have a `.pfx` or `.p12` file:

```powershell
$pfxPath = 'C:\path\to\cert.pfx'
$password = ConvertTo-SecureString 'your-password' -AsPlainText -Force

Import-PfxCertificate `
    -FilePath $pfxPath `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $password
```

### 2. Verify the Certificate

```powershell
# List all certificates in Local Machine store
Get-ChildItem -Path Cert:\LocalMachine\My

# Find certificates with code signing capability
Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {
    $_.Extensions | Where-Object { 
        $_.Oid.FriendlyName -eq 'Enhanced Key Usage' 
    } | Where-Object { 
        $_.Format($false) -like '*Code Signing*' 
    }
}
```

## Signing the Module

Run the signing script:

```powershell
cd DattoRMM.Core\Build
.\Sign-Module.ps1
```

The script will:
1. Search for your code signing certificate
2. Sign the manifest (.psd1)
3. Sign the root module (.psm1)
4. Verify both signatures are valid

### With a Specific Certificate

If you have multiple certificates, specify the thumbprint:

```powershell
.\Sign-Module.ps1 -CertThumbprint 'ABC123DEF456...'
```

### Force Re-signing

After editing signed files, re-sign them:

```powershell
.\Sign-Module.ps1 -Force $true
```

## Important: Re-sign ALL Files After ANY Edit

**Any change to the module requires re-signing every file.**

Since all module files are signed, modifying any single file invalidates signatures across the board. This is by design for maximum security:

Examples that require re-signing:
- Add a new public function → Re-sign everything
- Fix a bug in a class → Re-sign everything
- Update documentation → Re-sign everything
- Change the manifest version → Re-sign everything
- Modify any .ps1xml format file → Re-sign everything

Use `-Force $true` to re-sign all files at once:

```powershell
.\Sign-Module.ps1 -Force $true
```

This ensures:
- All signatures stay in sync
- Users get one coherent, verifiable package
- No partial/inconsistent signatures in distribution

## Workflow Example

```powershell
# 1. Edit a public function
# ... modify Public/Account/Get-RMMAccount.ps1

# 2. Update the manifest version
# ... edit DattoRMM.Core.psd1, bump to 0.5.52

# 3. Re-sign ALL files (one command)
cd Build
.\Sign-Module.ps1 -Force $true

# 4. Test the module
Import-Module ..\DattoRMM.Core\DattoRMM.Core.psd1 -Force
Get-Module DattoRMM.Core

# 5. Verify all signatures are valid
Get-ChildItem '..\DattoRMM.Core' -Include '*.ps1', '*.psm1', '*.psd1', '*.ps1xml' -Recurse | 
    Get-AuthenticodeSignature | 
    Where-Object { $_.Status -ne 'Valid' }
# Should return nothing if all signatures are valid

# 6. Commit and push
git add -A
git commit -m "feat: Add new Get-RMMAccount feature"
git push
```

## Distributing Your Module

Include the public certificate with your release:

```
Release/
├── DattoRMM.Core/
│   ├── DattoRMM.Core.psd1
│   ├── DattoRMM.Core.psm1
│   ├── Public/
│   ├── Private/
│   └── en-US/
└── DattoRMM.Core-CodeSigning.cer  ← Public cert for verification
```

Users can verify signatures:

```powershell
Get-AuthenticodeSignature -FilePath 'DattoRMM.Core.psm1' | Format-List

# Output:
# SignerCertificate      : [Thumbprint, Subject]
# SignatureType          : Authenticode
# HashAlgorithm          : sha256
# Status                 : Valid
# StatusMessage          : Signature verified.
```

## Troubleshooting

### Certificate Not Found

```
Error: Could not find a code signing certificate.
```

**Solution:**
1. Verify your .pfx/.p12 file path
2. Check the certificate password
3. Re-import: `Import-PfxCertificate ...`

### Signature Invalid After Importing

```
Status: UnknownError
StatusMessage: The signature is not valid.
```

**Causes:**
- File was edited after signing → Re-sign with `-Force $true`
- Certificate expired → Get a new certificate
- Signature corrupted → Re-sign

### "Could Not Establish Secure Channel"

```
Error: Could not establish a secure channel
```

This typically occurs during signing when the Windows Update CRL can't be reached. **This is a signing warning, not an error**—the file is still signed. To bypass:

```powershell
# Add to your signing script:
$signParams = @{
    FilePath        = $path
    Certificate     = $cert
    IncludeChain    = 'All'
    ErrorAction     = 'SilentlyContinue'  # Ignore the warning
}
```

## Next Steps

1. **Immediate**: Run `.\Sign-Module.ps1` to sign your module
2. **Verify**: `Get-AuthenticodeSignature -FilePath 'DattoRMM.Core\DattoRMM.Core.psm1'`
3. **Update**: Consider adding `CertificateThumbprint` to your .psd1 manifest
4. **Document**: Add release notes indicating the module is signed

## References

- [Set-AuthenticodeSignature](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-authenticodeSignature)
- [Get-AuthenticodeSignature](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/get-authenticodeSignature)
- [About Execution Policies](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)
- [Certificate Best Practices](https://docs.microsoft.com/en-us/previous-versions/dotnet/articles/ms734791(v=msdn.10))
