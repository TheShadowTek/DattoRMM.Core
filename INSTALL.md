# Installing DattoRMM.Core

## Requirements

| Requirement | Details |
|---|---|
| **PowerShell** | 7.4 or later (PowerShell Core only — Windows PowerShell 5.1 is not supported) |
| **Platform** | Cross‑platform (PowerShell 7.4+) |
| **Execution Policy** | See [Code Signing](#code-signing-and-execution-policy) below |

---

## Install from PowerShell Gallery

**Prerelease (current):**

```powershell
Install-Module DattoRMM.Core -AllowPrerelease
```

**Stable release:**

```powershell
Install-Module DattoRMM.Core
```

After installing, import as normal:

```powershell
Import-Module DattoRMM.Core
```

---

## Code Signing and Execution Policy

The module is code-signed with a self-signed certificate. On Windows, if your execution policy is `RemoteSigned` or `AllSigned`, PowerShell requires the signing certificate to be trusted before the module can load.

> A CA-issued certificate will replace the self-signed certificate from v1.0 onwards. Once that is in place, no certificate installation is required.

### Trust the Signing Certificate

Download `DattoRMM.Core-CodeSigning.cer` from the [repository](https://github.com/TheShadowTek/DattoRMM.Core).

Run **as Administrator**:

```powershell
$CerPath = '<path to DattoRMM.Core-CodeSigning.cer>'
$Cer = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($CerPath)

$Store = [System.Security.Cryptography.X509Certificates.X509Store]::new('TrustedPublisher', 'LocalMachine')
$Store.Open('ReadWrite')
$Store.Add($Cer)
$Store.Close()
```

### Skip Signature Check (development only)

On machines where signature enforcement is not required:

```powershell
Import-Module DattoRMM.Core -SkipPublisherCheck
```

---

## Verify the Installation

```powershell
Get-Module DattoRMM.Core -ListAvailable
```

Expected output will show the module name, version, and path.

---

## Uninstalling

```powershell
Uninstall-Module DattoRMM.Core
```

---

## Azure Automation Runtime Environment

DattoRMM.Core requires PowerShell 7.4 or later. Ensure your Runtime Environment targets **PowerShell 7.4 or later** before installing.

### Stable Releases — Install from the Portal

1. Open your **Azure Automation Account** in the portal
2. Under **Process Automation**, select **Runtime Environments**
3. Select the Runtime Environment targeting **PowerShell 7.4 or later**
4. Select **Browse Gallery**, search for `DattoRMM.Core`, and install

### Prerelease — Runtime Environment Limitation

The Azure Automation portal does not support installing prerelease packages from the gallery, and there is no supported programmatic path for adding prerelease modules directly to a modern Runtime Environment.

For prerelease testing in Azure Automation, the following approaches are available:

**Wait for a stable release** — recommended for production runbooks.

**Zip upload (known to work from the repository folder):**

1. Zip the **contents** of the `DattoRMM.Core` module folder so that the module files (`DattoRMM.Core.psd1`, `DattoRMM.Core.psm1`, etc.) sit at the root of the archive — the zip must be named `DattoRMM.Core.zip`.
2. In the portal, open the Runtime Environment, select **Add a file**, and upload `DattoRMM.Core.zip`.

> **Note:** This has been tested using the module folder directly from the repository. It has not been tested against a module installed via PowerShellGet v3, which stores modules under a version-named subfolder (`DattoRMM.Core\<version>\`). If installing from a local PSModules path with that layout, zip the inner version subfolder's contents rather than the parent folder.

**Legacy account modules + Add from Library (unverified):** Some sources suggest using `New-AzAutomationModule -ContentLink` to load a module into the legacy account-level module store, after which it may appear as an option when adding modules to a Runtime Environment. This has not been confirmed — the portal's "Add from Library" option likely refers only to the PSGallery browse, not the legacy module store.

---

## Getting Started

Once installed, see the [README](README.md) for connection and usage instructions.
