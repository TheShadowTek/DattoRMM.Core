# about_DattoRMM.CoreAuthentication

## SHORT DESCRIPTION

Describes the authentication methods supported by the DattoRMM.Core module, including interactive, automated, and cloud-based credential storage options.

## LONG DESCRIPTION

The DattoRMM.Core module authenticates to the Datto RMM API v2 using one of three methods:

1. **API Key and Secret** — The module exchanges credentials for an access token via OAuth.
2. **PSCredential** — A credential object where the username is the API key and the password is the API secret.
3. **API Token** — A pre-existing access token supplied directly, bypassing OAuth token generation.

Methods 1 and 2 generate a new token and support automatic token refresh. Method 3 is a stateless "bring your own token" mode for scenarios where token lifecycle is managed externally.

Authentication is handled by `Connect-DattoRMM`. On success, a session token is stored in memory for the duration of the PowerShell session. Tokens are never written to disk.

### API Key and Secret

The most direct method. The API secret must be provided as a `SecureString`:

```powershell
$Secret = Read-Host -Prompt "Enter API Secret" -AsSecureString
Connect-DattoRMM -Key "your-api-key" -Secret $Secret
```

### PSCredential

Supply both the key and secret as a `PSCredential` object. The username field holds the API key; the password holds the API secret:

```powershell
$Cred = Get-Credential -Message "Enter API key as username, API secret as password"
Connect-DattoRMM -Credential $Cred
```

### PowerShell SecretStore

For persistent, secure credential storage between sessions, use the `Microsoft.PowerShell.SecretManagement` and `Microsoft.PowerShell.SecretStore` modules:

```powershell
# One-time setup: store your credential
Import-Module Microsoft.PowerShell.SecretManagement
$Cred = Get-Credential
Set-Secret -Name "DattoRMM-API" -Secret $Cred

# Future sessions: retrieve and connect
Connect-DattoRMM -Credential (Get-Secret -Name "DattoRMM-API")
```

> [!NOTE]
> If the vault is password-protected and used in a script, provide vault access via a `SecureString` parameter rather than interactive prompts.

SecretManagement supports multiple vault backends (SecretStore, KeePass, Azure Key Vault, etc.). Any vault that returns a `PSCredential` is compatible with `Connect-DattoRMM`.

### Azure Automation — Automation Account Credential

For unattended automation in Azure Automation Runbooks, credentials can be stored as Automation Account credential assets:

```powershell
Import-Module DattoRMM.Core

$Cred = Get-AutomationPSCredential -Name "DattoRMM-API"
Connect-DattoRMM -Credential $Cred
```

> [!NOTE]
> The credential asset must be created in the Automation Account before use. The username field holds the API key; the password field holds the API secret.

### Azure Automation — Azure Key Vault

Credentials can also be retrieved from Azure Key Vault, which is useful when secrets are managed centrally:

```powershell
Connect-AzAccount  # Managed Identity or Service Principal recommended

$ApiKey = Get-AzKeyVaultSecret -VaultName "MyKeyVault" -Name "DattoRMM-API-Key" -AsPlainText
$Secret = Get-AzKeyVaultSecret -VaultName "MyKeyVault" -Name "DattoRMM-API-Secret"

Connect-DattoRMM -Key $ApiKey -Secret $Secret
```

> [!NOTE]
> The Key Vault and secrets must be created and accessible to the automation context (Managed Identity, Service Principal, or user account).

### API Token (Bring Your Own Token)

For scenarios where token generation is managed externally — such as a shared token service, CI/CD pipeline, or central secret store — you can supply a pre-existing access token directly:

```powershell
$Token = Read-Host -AsSecureString -Prompt "Enter API Token"
Connect-DattoRMM -ApiToken $Token
```

Or retrieve the token from Azure Key Vault:

```powershell
$Token = (Get-AzKeyVaultSecret -VaultName 'MyVault' -Name 'DattoRMMToken').SecretValue
Connect-DattoRMM -ApiToken $Token -Platform Merlot
```

Key differences from key/secret authentication:

- The module does **not** generate a new token — it uses the one you provide.
- `-AutoRefresh` is **not available** in this mode. The token must be valid for the duration of your session.
- No credentials are stored in memory; only the token itself.
- The module does not track token expiry.

This mode is useful when you want full external control over token lifecycle, or when credentials should never be present in the automation context.

### Choosing a Method

| Scenario | Recommended Method |
|---|---|
| Interactive shell | `Get-Credential` or `Read-Host -AsSecureString` |
| Persistent local credentials | PowerShell SecretStore |
| Azure Automation Runbooks | Automation Account Credential or Azure Key Vault |
| CI/CD pipelines | `-ApiToken` with vault-managed token, or environment variables converted to `SecureString` |
| External token management | `-ApiToken` with `Request-RMMToken` or vault-stored token |

> [!NOTE]
> PowerShell SecretManagement vaults are primarily designed for local shell use. In Azure Automation, Automation Account Credentials and Azure Key Vault are the standard approaches. Other methods or third-party PAM modules may work, but compatibility is not verified.

## AUTOMATIC TOKEN REFRESH

The module can automatically refresh the API token before it expires, which is useful for long-running scripts and automation:

```powershell
Connect-DattoRMM -Key "your-api-key" -Secret $Secret -AutoRefresh
```

When `-AutoRefresh` is enabled, the module stores the supplied credentials in memory and uses them to request a new token before the current token expires. The default token lifetime is 100 hours and can be adjusted with `Set-RMMConfig -TokenExpireHours`.

> [!IMPORTANT]
> `-AutoRefresh` retains credentials in memory for the session. If this is not acceptable for your security posture, omit `-AutoRefresh` and re-authenticate manually when tokens expire.

## REQUESTING TOKENS WITHOUT CONNECTING

`Request-RMMToken` generates a new access token from the Datto RMM OAuth endpoint and returns a `DRMMToken` object — without storing the token in the module's authentication context.

This is useful for:

- **Testing and inspection** — Verify credentials are valid and inspect token properties before committing to a session.
- **External token management** — Generate a token, store it in a vault, and later use it with `Connect-DattoRMM -ApiToken`.
- **Token rotation pipelines** — Automate token generation in a separate process from the one consuming the API.

```powershell
$Secret = Read-Host -AsSecureString -Prompt "Enter API Secret"
$TokenResponse = Request-RMMToken -Key "your-api-key" -Secret $Secret
$TokenResponse | Format-List
```

The returned `DRMMToken` object contains:

| Property | Description |
|---|---|
| `AccessToken` | The access token as a `SecureString` |
| `TokenType` | Token type (typically "Bearer") |
| `ExpiresIn` | Token lifetime as a `TimeSpan` |
| `Scope` | OAuth scope granted |
| `Jti` | JWT identifier |

To use the generated token with the module:

```powershell
$TokenResponse = Request-RMMToken -Credential $Cred -Platform Merlot
Connect-DattoRMM -ApiToken $TokenResponse.AccessToken -Platform Merlot
```

> [!NOTE]
> `Request-RMMToken` does not store the token for authentication. To authenticate the module for API calls, pass the token to `Connect-DattoRMM -ApiToken` or use one of the credential-based methods.

## PROXY SUPPORT

`Connect-DattoRMM` supports connecting through an HTTP proxy:

```powershell
Connect-DattoRMM -Key "your-api-key" -Secret $Secret -Proxy "http://proxy.example.com:8080"
```

For authenticated proxies:

```powershell
$ProxyCred = Get-Credential -Message "Proxy credentials"
Connect-DattoRMM -Key "your-api-key" -Secret $Secret -Proxy "http://proxy.example.com:8080" -ProxyCredential $ProxyCred
```

## DISCONNECTING

To clear the session token and credentials from memory:

```powershell
Disconnect-DattoRMM
```

The module also clears authentication state automatically when removed from the session.

## API KEY MANAGEMENT

To regenerate API keys for the authenticated user:

```powershell
# Regenerate and return the new key/secret pair
$NewKeys = Reset-RMMAPIKeys -ReturnNewKey
```

> [!WARNING]
> This immediately invalidates the current session. Without `-ReturnNewKey`, the new keys are discarded and must be retrieved from the Datto RMM web portal.

## EXAMPLES

### Example 1: Interactive connection

```powershell
$Secret = Read-Host -Prompt "Enter API Secret" -AsSecureString
Connect-DattoRMM -Key "your-api-key" -Secret $Secret
```

### Example 2: Connect with SecretStore

```powershell
Connect-DattoRMM -Credential (Get-Secret -Name "DattoRMM-API")
```

### Example 3: Connect to a specific platform region

```powershell
Connect-DattoRMM -Credential $Cred -Platform Merlot
```

### Example 4: Long-running automation with auto-refresh

```powershell
Connect-DattoRMM -Credential $Cred -AutoRefresh
```

### Example 5: Connect with a pre-existing token

```powershell
$Token = (Get-AzKeyVaultSecret -VaultName 'MyVault' -Name 'DattoRMMToken').SecretValue
Connect-DattoRMM -ApiToken $Token -Platform Merlot
```

### Example 6: Generate and inspect a token

```powershell
$TokenResponse = Request-RMMToken -Key "your-api-key" -Secret $Secret
$TokenResponse.ExpiresIn
$TokenResponse.TokenType
```

### Example 7: Generate a token and use it to connect

```powershell
$TokenResponse = Request-RMMToken -Credential $Cred
Connect-DattoRMM -ApiToken $TokenResponse.AccessToken
```

## SEE ALSO

- [about_DattoRMM.Core](about_DattoRMM.Core.md)
- [about_DattoRMM.CoreConfiguration](about_DattoRMM.CoreConfiguration.md)
- [about_DattoRMM.CoreSecurity](about_DattoRMM.CoreSecurity.md)
- [Connect-DattoRMM](../commands/Auth/Connect-DattoRMM.md)
- [Request-RMMToken](../commands/Auth/Request-RMMToken.md)
- [Disconnect-DattoRMM](../commands/Auth/Disconnect-DattoRMM.md)
- [Reset-RMMAPIKeys](../commands/Auth/Reset-RMMAPIKeys.md)
