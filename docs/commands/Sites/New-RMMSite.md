# New-RMMSite

## SYNOPSIS
Creates a new site in the Datto RMM account.

## SYNTAX

```
New-RMMSite [-Name] <String> [[-Description] <String>] [[-Notes] <String>] [-OnDemand] [-SplashtopAutoInstall]
 [[-ProxyHost] <String>] [[-ProxyPort] <Int32>] [[-ProxyType] <String>] [[-ProxyUsername] <String>]
 [[-ProxyPassword] <SecureString>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The New-RMMSite creates a new site in the authenticated user's account.
A site represents a customer location or organisational unit within Datto RMM.

Supports creating sites with proxy settings in a single operation,
or proxy settings can be configured later using Set-RMMSiteProxy.

## EXAMPLES

EXAMPLE 1
```
New-RMMSite -Name "Contoso Main Office"
```

Creates a new site with the specified name.

EXAMPLE 2
```
New-RMMSite -Name "Branch Office" -Description "West Coast Branch" -OnDemand
```

Creates an on-demand site with a description.

EXAMPLE 3
```
$ProxyPass = Read-Host -Prompt "Enter proxy password" -AsSecureString
New-RMMSite -Name "Remote Site" -ProxyHost "proxy.contoso.com" -ProxyPort 8080 -ProxyType http -ProxyUsername "proxyuser" -ProxyPassword $ProxyPass
```

Creates a site with HTTP proxy settings configured.

EXAMPLE 4
```
New-RMMSite -Name "Test Site" -SplashtopAutoInstall -Notes "Testing environment"
```

Creates a site with Splashtop auto-install enabled and notes.

## PARAMETERS

### -Name
The name of the site to create.
This parameter is required.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
A description of the site.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Notes
Additional notes about the site.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OnDemand
Whether the site should be configured as an on-demand site.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SplashtopAutoInstall
Whether Splashtop should be automatically installed on devices at this site.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProxyHost
The hostname or IP address of the proxy server.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProxyPort
The port number of the proxy server.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProxyType
The type of proxy server.
Valid values: 'http', 'socks4', 'socks5'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProxyUsername
The username for proxy authentication.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProxyPassword
The password for proxy authentication (as a SecureString).

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

None. You cannot pipe objects to New-RMMSite.
## OUTPUTS

DRMMSite. Returns the newly created site object.
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

Proxy settings can be configured during site creation or added later using Set-RMMSiteProxy.

## RELATED LINKS
