# Connect-DattoRMM

## SYNOPSIS
Connects to the Datto RMM API and authenticates using API credentials.

## SYNTAX

Key (Default)
```
Connect-DattoRMM -Key <String> -Secret <SecureString> [-AutoRefresh] [-Platform <RMMPlatform>] [-Proxy <Uri>]
 [-ProxyCredential <PSCredential>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

Cred
```
Connect-DattoRMM -Credential <PSCredential> [-AutoRefresh] [-Platform <RMMPlatform>] [-Proxy <Uri>]
 [-ProxyCredential <PSCredential>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

ApiToken
```
Connect-DattoRMM -ApiToken <SecureString> [-Platform <RMMPlatform>] [-Proxy <Uri>]
 [-ProxyCredential <PSCredential>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Connect-DattoRMM function establishes a connection to the Datto RMM API using one of three
authentication methods:

1.
API Key and Secret: Generates a new access token via OAuth
2.
PSCredential: Uses username as key, password as secret to generate a new token
3.
API Token: Uses an existing access token (no token generation or refresh)

Methods 1 and 2 support automatic token refresh when enabled.
Method 3 is a stateless
"bring your own token" mode intended for scenarios where token lifecycle is managed externally
(e.g., Azure Key Vault, CI/CD pipelines).

The function allows selection of different Datto RMM platform regions.

## EXAMPLES

EXAMPLE 1
```powershell
$Secret = Read-Host -Prompt "Enter API Secret" -AsSecureString
Connect-DattoRMM -Key "your-api-key" -Secret $Secret
```

Connects to the Datto RMM API using an API key and securely prompted secret.

EXAMPLE 2
```powershell
$Secret = Read-Host -AsSecureString -Prompt "Enter API Secret"
Connect-DattoRMM -Key "your-api-key" -Secret $Secret -AutoRefresh
```

Connects to the API with automatic token refresh enabled.

EXAMPLE 3
```powershell
$Cred = Get-Credential -Message "Enter API Key as username and API Secret as password"
Connect-DattoRMM -Credential $Cred
```

Connects using a PSCredential object where the username is the API key and password is the secret.

EXAMPLE 4
```powershell
$Secret = Read-Host -AsSecureString -Prompt "Enter API Secret"
Connect-DattoRMM -Key "your-api-key" -Secret $Secret -Platform Merlot
```

Connects to the Merlot platform region.

EXAMPLE 5
```powershell
$Cred = Get-Credential -Message "Enter Datto RMM API credentials"
Connect-DattoRMM -Credential $Cred -AutoRefresh -Platform Pinotage
```

Creates a credential object using Get-Credential and connects with auto-refresh to the Pinotage platform.

EXAMPLE 6
```powershell
$Token = Read-Host -AsSecureString -Prompt "Enter API Token"
Connect-DattoRMM -ApiToken $Token
```

Connects using an existing API token.
The token will not be refreshed automatically.
Useful for automation scenarios where tokens are managed externally.

EXAMPLE 7
```powershell
# Retrieve token from Azure Key Vault
$Token = (Get-AzKeyVaultSecret -VaultName 'MyVault' -Name 'DattoRMMToken').SecretValue
Connect-DattoRMM -ApiToken $Token -Platform Merlot
```

Connects using a token retrieved from Azure Key Vault.

EXAMPLE 8
```powershell
$Secret = Read-Host -AsSecureString -Prompt "Enter API Secret"
$ProxyCred = Get-Credential -Message "Enter proxy credentials"
Connect-DattoRMM -Key "your-api-key" -Secret $Secret -Proxy "http://proxy.company.com:8080" -ProxyCredential $ProxyCred
```

Connects to the API through a proxy server with authentication.

## PARAMETERS

### -Key
The API key for authentication.
Used in conjunction with the Secret parameter.

```yaml
Type: String
Parameter Sets: Key
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Secret
The API secret as a SecureString.
Used in conjunction with the Key parameter.
Use Read-Host -AsSecureString to securely capture the secret.

```yaml
Type: SecureString
Parameter Sets: Key
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
A PSCredential object containing the API key as the username and the API secret as the password.
This provides an alternative authentication method to using Key and Secret parameters separately.

```yaml
Type: PSCredential
Parameter Sets: Cred
Aliases: Cred

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApiToken
An existing Datto RMM API access token as a SecureString.
When using this parameter, the function
will NOT generate a new token and will NOT refresh the token automatically.
This is intended for
scenarios where token lifecycle is managed externally (e.g., Azure Key Vault, CI/CD).

Cannot be used with AutoRefresh.
The token must be valid for the duration of your session.

```yaml
Type: SecureString
Parameter Sets: ApiToken
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AutoRefresh
When specified, the function will store credentials and automatically refresh the access token
when it expires during subsequent API calls.

Only valid with Key/Secret or Credential authentication.
Cannot be used with ApiToken.

```yaml
Type: SwitchParameter
Parameter Sets: Key, Cred
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Platform
Specifies the Datto RMM platform region to connect to.
Valid values: Pinotage, Concord, Vidal, Merlot, Zinfandel, Syrah

If not specified, uses the default platform configured via Save-RMMConfig.
If no default is configured, falls back to 'Pinotage'.

To set a persistent default platform: Save-RMMConfig -DefaultPlatform Merlot

```yaml
Type: RMMPlatform
Parameter Sets: (All)
Aliases:
Accepted values: Pinotage, Concord, Vidal, Merlot, Zinfandel, Syrah

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Proxy
Specifies a proxy server for the request, rather than connecting directly to the Datto RMM API.
Enter the URI of a network proxy server.
This parameter is optional and only needed if your
network requires proxy access.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProxyCredential
Specifies a user account that has permission to use the proxy server specified by the Proxy parameter.
This parameter is optional and can be used with or without the Proxy parameter (for transparent proxies
that still require authentication).

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

None. You cannot pipe objects to Connect-DattoRMM.
## OUTPUTS

None. This function does not generate output but stores authentication information in module scope.
## NOTES
The function stores the authentication token in the module's script scope.
This token is used by all
subsequent API calls made through the module.

Authentication Methods:
- Key/Secret and Credential methods generate new tokens and support AutoRefresh
- ApiToken method uses existing tokens and does NOT support AutoRefresh
- When AutoRefresh is enabled (Key/Secret or Credential only), credentials are stored securely
  and the token will be automatically refreshed when it expires
- ApiToken mode is stateless and does not store credentials or track token expiry

On module removal, the authentication information is cleared from memory.

Default Platform and Page Size:
You can configure persistent defaults using Save-RMMConfig to avoid specifying them each time:
- Save-RMMConfig -DefaultPlatform Merlot
- Save-RMMConfig -DefaultPageSize 100

The configured default page size will be used if it's within your account's maximum limit.
You can still override these defaults by explicitly specifying the -Platform parameter.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Connect-DattoRMM.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Connect-DattoRMM.md))
