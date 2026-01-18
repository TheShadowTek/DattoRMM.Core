# about_DattoRMM.Core

## SHORT DESCRIPTION
A comprehensive PowerShell module for managing and automating tasks with the Datto RMM API v2.

## LONG DESCRIPTION
The DattoRMM.Core module provides an object-oriented interface for interacting with the Datto RMM API. It supports secure authentication, robust device and job management, advanced automation, and reporting scenarios. Key features include:

- Secure API authentication (API key/secret, PSCredential, SecretStore)
- Comprehensive device, job, account, and site management
- Advanced filtering, querying, and automation
- Built-in rate limiting and throttling for safe parallel workloads
- Extensible, scriptable, and designed for integration into larger PowerShell workflows

Security is a core focus: secrets are handled securely, tokens are never written to disk, and sensitive operations are PII-hardened. The module is suitable for both interactive and unattended automation, including Azure Automation and CI/CD pipelines.

## EXAMPLES
### Example 1: Connect and Get Devices
```powershell
$Secret = Read-Host -Prompt "Enter API Secret" -AsSecureString
Connect-DattoRMM -Key "your-api-key" -Secret $Secret
Get-RMMDevice
```

### Example 2: Run a Job on All Web Servers
```powershell
$Filter = Get-RMMDeviceFilter -Name "Web Servers" | Where-Object {$_.IsGlobal()}
$Component = Get-RMMComponent | Where-Object Name -eq "Patch WebServer - URGENT"
Get-RMMDevice -FilterId $Filter.Id | New-RMMQuickJob -JobName "Patch WebServer - URGENT" -Component $Component -Force
```

## SEE ALSO
[Project README](https://github.com/boabf/DattoRMM.Core)
