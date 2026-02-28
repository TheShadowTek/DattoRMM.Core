# Request-RMMToken

## SYNOPSIS
Requests a new Datto RMM API access token and returns a DRMMToken object.

## SYNTAX

Key (Default)
```
Request-RMMToken -Key <String> -Secret <SecureString> [-Platform <RMMPlatform>] [-Proxy <Uri>]
 [-ProxyCredential <PSCredential>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

Cred
```
Request-RMMToken -Credential <PSCredential> [-Platform <RMMPlatform>] [-Proxy <Uri>]
 [-ProxyCredential <PSCredential>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Request-RMMToken function generates a new access token from the Datto RMM OAuth
endpoint and returns a strongly-typed DRMMToken object with the token information.

Unlike Connect-DattoRMM, this function does NOT store the token in the module's
authentication context.
It is intended for testing, inspection, or scenarios where
you need direct access to the token object.

## EXAMPLES

EXAMPLE 1
```powershell
$Secret = Read-Host -AsSecureString -Prompt "Enter API Secret"
$TokenResponse = Request-RMMToken -Key "your-api-key" -Secret $Secret
$TokenResponse
```

Requests a new token and displays the DRMMToken object.

EXAMPLE 2
```powershell
$Cred = Get-Credential -Message "Enter API credentials"
$Token = Request-RMMToken -Credential $Cred -Platform Merlot
$Token | Format-List
```

Requests a token using credentials and formats the output for inspection.

EXAMPLE 3
```powershell
$Secret = Read-Host -AsSecureString -Prompt "Enter API Secret"
$TokenResponse = Request-RMMToken -Key "your-api-key" -Secret $Secret
$TokenResponse.TokenType
$TokenResponse.ExpiresIn
```

Retrieves a token and accesses specific properties of the DRMMToken object.

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

### -Platform
Specifies the Datto RMM platform region to connect to.
Valid values: Pinotage, Concord, Vidal, Merlot, Zinfandel, Syrah

If not specified, uses the default platform configured via Save-RMMConfig.
If no default is configured, falls back to 'Pinotage'.

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

None. You cannot pipe objects to Request-RMMToken.
## OUTPUTS

DRMMToken object containing:
- AccessToken: The access token as a SecureString
- TokenType: Type of token (typically "Bearer")
- ExpiresIn: Token lifetime as a TimeSpan
- Scope: OAuth scope granted
- Jti: JWT identifier
## NOTES
This function does NOT store the token in $Script:RMMAuth.
It is designed for testing
and inspection purposes.
To authenticate the module for API calls, use Connect-DattoRMM.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Request-RMMToken.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Request-RMMToken.md))
- [Connect-DattoRMM](./Connect-DattoRMM.md)
