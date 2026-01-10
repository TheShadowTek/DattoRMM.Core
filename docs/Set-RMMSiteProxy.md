# Set-RMMSiteProxy

## SYNOPSIS
Creates or updates proxy settings for a Datto RMM site.

## SYNTAX

BySiteObject
```
Set-RMMSiteProxy -Site <DRMMSite> [-ProxyHost <String>] [-Port <Int32>] [-Type <String>] [-Username <String>]
 [-Password <SecureString>] [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

ByUid
```
Set-RMMSiteProxy -SiteUid <Guid> [-ProxyHost <String>] [-Port <Int32>] [-Type <String>] [-Username <String>]
 [-Password <SecureString>] [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The Set-RMMSiteProxy function creates or updates the proxy server configuration for
a specified site.
The site can be specified by passing a DRMMSite object from the
pipeline or by providing the SiteUid parameter directly.

Proxy settings control how devices at the site connect through a proxy server to
reach the Datto RMM service.

## EXAMPLES

EXAMPLE 1
```
Set-RMMSiteProxy -SiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -ProxyHost "proxy.contoso.com" -Port 8080 -Type http
```

Configures an HTTP proxy without authentication for the specified site.

EXAMPLE 2
```
$ProxyPass = Read-Host -Prompt "Enter proxy password" -AsSecureString
Get-RMMSite -Name "Branch Office" | Set-RMMSiteProxy -ProxyHost "proxy.branch.com" -Port 3128 -Type http -Username "proxyuser" -Password $ProxyPass
```

Configures an HTTP proxy with authentication via pipeline.

EXAMPLE 3
```
Get-RMMSite | Where-Object {$_.Name -like "Remote*"} | Set-RMMSiteProxy -ProxyHost "proxy.corp.com" -Port 1080 -Type socks5 -Force
```

Configures a SOCKS5 proxy for all sites with names starting with "Remote" without confirmation.

## PARAMETERS

### -Site
A DRMMSite object to configure.
Accepts pipeline input from Get-RMMSite.

```yaml
Type: DRMMSite
Parameter Sets: BySiteObject
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -SiteUid
The unique identifier (GUID) of the site to configure.

```yaml
Type: Guid
Parameter Sets: ByUid
Aliases: Uid

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ProxyHost
The hostname or IP address of the proxy server.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Port
The port number of the proxy server (1-65535).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Type
The type of proxy server.
Valid values: 'http', 'socks4', 'socks5'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Username
The username for proxy authentication.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Password
The password for proxy authentication (as a SecureString).

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Suppress the confirmation prompt.

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

DRMMSite. You can pipe site objects from Get-RMMSite.
You can also pipe objects with SiteUid or Uid properties.
## OUTPUTS

None. This function does not return any output.
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

All proxy parameters are optional.
You can update individual proxy settings by
specifying only the parameters you want to change.

Use Remove-RMMSiteProxy to delete proxy settings entirely.

## RELATED LINKS

[about_DRMMSite]()

[Get-RMMSite]()

[Remove-RMMSiteProxy]()

