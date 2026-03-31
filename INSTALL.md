# Installing DattoRMM.Core

## Requirements

| Requirement | Details |
|---|---|
| **PowerShell** | 7.4 or later (PowerShell Core only — Windows PowerShell 5.1 is not supported) |
| **Platform** | Windows |
| **Execution Policy** | See [Step 2](#step-2--execution-policy) below |

---

## Step 1 — Download and Unblock the Package

Download the latest `DattoRMM.Core-<version>.zip` from the [Releases](../../releases) page.

**Unblock the zip file before extracting it.** Windows marks files downloaded from the internet as untrusted. Unblocking the zip before extraction prevents that mark from being applied to every extracted file individually.

You can do this in one of two ways:

**Option A — File Explorer (easiest):**
1. Right-click `DattoRMM.Core-<version>.zip`
2. Select **Properties**
3. At the bottom of the General tab, tick **Unblock**
4. Click **OK**

**Option B — PowerShell:**
```powershell
Unblock-File -Path ".\DattoRMM.Core-<version>.zip"
```

Once unblocked, extract the zip. You should see the following structure:

```
DattoRMM.Core-<version>/
├── DattoRMM.Core/              ← the module (used in Steps 2 and 3)
├── docs/                       ← full documentation
├── DattoRMM.Core-CodeSigning.cer
├── CHANGELOG.md
├── INSTALL.md
├── LICENSE
├── README.md
└── SECURITY.md
```

All commands below assume you are running from inside the extracted folder.

---

## Step 2 — Execution Policy

PowerShell's execution policy controls whether signed scripts are required to run. Choose **one** of the options below.

### Option A — Recommended: Trust the Code Signing Certificate

This is the most secure option. It trusts only this module's signing certificate without relaxing your execution policy globally.

> This beta release is signed with a self-signed certificate. A CA-issued certificate will be used from v1.0 onwards.

Run **as Administrator**:

```powershell
$CerPath = Resolve-Path ".\DattoRMM.Core-CodeSigning.cer"
$Cer = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($CerPath)

$Store = [System.Security.Cryptography.X509Certificates.X509Store]::new("TrustedPublisher", "LocalMachine")
$Store.Open("ReadWrite")
$Store.Add($Cer)
$Store.Close()
```

Then ensure your execution policy permits signed scripts (this is the default on most systems):

```powershell
# Check current policy
Get-ExecutionPolicy -List

# Set if required (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

### Option B — Quick Start: Bypass Execution Policy for the Session

If you want to evaluate the module without importing a certificate, you can load it in a session-scoped bypass. **This does not change your system policy permanently.**

```powershell
pwsh -ExecutionPolicy Bypass -NoLogo
```

Or within an existing session, import the module directly:

```powershell
Import-Module ".\DattoRMM.Core\DattoRMM.Core.psd1" -Force
```

> Note: Session-scoped bypass (`Bypass`) only affects the current PowerShell window. Your system execution policy is unchanged.

---

## Step 3 — Install the Module

The commands below copy the `DattoRMM.Core` subfolder from the extracted package to a PowerShell module path. Run them from inside the extracted zip folder (the one containing `INSTALL.md`, `README.md`, etc.) — not from inside the `DattoRMM.Core` subfolder itself.

### Install for the current user only (no Administrator required)

```powershell
$Destination = "$env:USERPROFILE\Documents\PowerShell\Modules\DattoRMM.Core"
Copy-Item -Path ".\DattoRMM.Core" -Destination $Destination -Recurse -Force
```

After installing, import as normal:

```powershell
Import-Module DattoRMM.Core
```

### Install for all users on the machine (requires Administrator)

```powershell
$Destination = "C:\Program Files\PowerShell\Modules\DattoRMM.Core"
Copy-Item -Path ".\DattoRMM.Core" -Destination $Destination -Recurse -Force
```

### Run from a folder without installing

If you prefer not to install to a module path, import directly from the extracted folder:

```powershell
Import-Module ".\DattoRMM.Core\DattoRMM.Core.psd1"
```

> This is useful for testing or running from a script directory. The module will not be available in new sessions unless the `Import-Module` call is added to your PowerShell profile.

---

## Verify the Installation

```powershell
Get-Module DattoRMM.Core -ListAvailable
```

Expected output will show the module name, version, and path.

---

## Uninstalling

Remove the module folder from the path where it was installed:

```powershell
# User scope
Remove-Item "$env:USERPROFILE\Documents\PowerShell\Modules\DattoRMM.Core" -Recurse -Force

# System scope (requires Administrator)
Remove-Item "C:\Program Files\PowerShell\Modules\DattoRMM.Core" -Recurse -Force
```

---

## Azure Automation Runtime Environment

DattoRMM.Core requires PowerShell 7.4. Ensure your Runtime Environment targets **PowerShell 7.4** before importing the module.

### Prepare the Package

Azure Automation expects the zip to contain the module folder at the root of the archive. The release zip (`DattoRMM.Core-<version>.zip`) is already structured correctly — `DattoRMM.Core/` sits at the zip root. The additional documentation files included in the package (README, CHANGELOG, etc.) do not affect the import. Use the zip as downloaded — do **not** extract it first.

### Upload via the Azure Portal

1. Rename zip from `DattoRMM.Core-<version>.zip` to `DattoRMM.Core.zip`
2. Open your **Azure Automation Account** in the portal
3. Under **Process Automation**, select **Runtime Environments**
4. Select the Runtime Environment that targets **PowerShell 7.4**
5. Select **Add a file**
6. Browse to and select `DattoRMM.Core.zip`
7. Click **Save**

Allow a few minutes for the import to complete. Status will show as **Available** when ready.

---

## Getting Started

Once installed, see the [README](README.md) for connection and usage instructions.
