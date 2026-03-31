# Security Policy

## Supported Versions

DattoRMM.Core is currently in public beta. Only the latest release receives security fixes.

| Version | Supported |
|---|---|
| 0.5.x (beta) | Yes — latest release only |
| Earlier versions | No |

## Reporting a Vulnerability

Please **do not** report security vulnerabilities via public GitHub Issues.

To report a vulnerability, open a [GitHub Issue](../../issues/new) and mark it with the **security** label. If you would prefer to report privately, you can use GitHub's [Private Vulnerability Reporting](../../security/advisories/new) feature.

**Please include:**
- A clear description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested remediation if known

You can expect an initial response within **5 business days**. If the issue is confirmed, a fix will be prioritised for the next release.

## Security Design Notes

DattoRMM.Core was designed with credential security as a first-class concern. The following behaviours are intentional:

- API credentials are accepted as `SecureString` and never stored in plain text
- Session tokens are held in module-scope memory only and are cleared by `Disconnect-DattoRMM`
- No credentials, tokens, or keys are written to disk, logs, or verbose output
- `Connect-DattoRMM` supports multiple authentication patterns including Azure Key Vault and PowerShell SecretStore

See [about_DattoRMM.CoreSecurity](./docs/about/about_DattoRMM.CoreSecurity.md) for full details on credential lifecycle and SecureString behaviour.

## Code Signing Certificate

All module files are signed with an Authenticode code signing certificate and timestamped via DigiCert.

### Current Certificate

| Field | Value |
|---|---|
| **Subject** | CN=DattoRMM.Core Code Signing, O=Robert Faddes |
| **Type** | Self-signed (beta only) |
| **Thumbprint** | `AC6E298DC3D620910439643D646253469971BB10` |
| **Valid From** | 31 March 2026 |
| **Expires** | 31 March 2028 |
| **Hash Algorithm** | SHA256 |
| **Timestamp** | DigiCert SHA256 RSA4096 |

### What Happens When the Certificate Expires

- **Already-signed files remain valid** — the DigiCert timestamp proves the files were signed while the certificate was active. Signature verification will continue to pass indefinitely.
- **New releases cannot be signed** with an expired certificate — a new certificate must be issued first.

### Certificate Roadmap

| Milestone | Certificate |
|---|---|
| Beta (current) | Self-signed, 2-year validity |
| v1.0 | CA-issued code signing certificate (e.g. DigiCert, Sectigo) |

When the CA certificate is issued for v1.0, all module files will be re-signed and a new `.cer` will be published. The self-signed certificate will be retired.

### Verifying Signatures

Users can verify that module files are correctly signed:

```powershell
Get-ChildItem -Path ".\DattoRMM.Core" -Recurse -Include "*.psm1","*.psd1","*.ps1","*.ps1xml" |
    Get-AuthenticodeSignature |
    Select-Object Path, Status
```

All files should show `Valid` after trusting the certificate (see [INSTALL.md](INSTALL.md) for trust instructions).
