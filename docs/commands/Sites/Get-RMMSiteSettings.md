# Get-RMMSiteSettings

## SYNOPSIS
Retrieves site settings from the Datto RMM API.

## SYNTAX

Site (Default)
```
Get-RMMSiteSettings -Site <DRMMSite> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

Uid
```
Get-RMMSiteSettings -SiteUid <Guid> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMSiteSettings function retrieves configuration settings for a specific site.
Site settings include general settings, proxy configuration, mail settings, notification
settings, and other site-specific configurations.

This function can accept either a site object from Get-RMMSite or a site UID directly.

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMSite -Name "Contoso" | Get-RMMSiteSettings
```

Retrieves settings for the "Contoso" site.

EXAMPLE 2
```powershell
Get-RMMSiteSettings -SiteUid "12067610-8504-48e3-b5de-60e48416aaad"
```

Retrieves settings for a site by its unique identifier.

EXAMPLE 3
```powershell
$Settings = Get-RMMSite -SiteUid $SiteUid | Get-RMMSiteSettings
$Settings.GeneralSettings
```

Retrieves site settings and displays the general settings section.

EXAMPLE 4
```powershell
Get-RMMSite | Get-RMMSiteSettings | Select-Object Name, @{N='Timezone';E={$_.GeneralSettings.Timezone}}
```

Retrieves settings for all sites and displays site name and timezone.

EXAMPLE 5
```powershell
$Settings = Get-RMMSiteSettings -SiteUid $SiteUid
$Settings.MailSettings
```

Retrieves site settings and displays the mail recipients configuration.

## PARAMETERS

### -Site
A DRMMSite object to retrieve settings for.
Accepts pipeline input from Get-RMMSite.

```yaml
Type: DRMMSite
Parameter Sets: Site
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -SiteUid
The unique identifier (GUID) of the site to retrieve settings for.

```yaml
Type: Guid
Parameter Sets: Uid
Aliases: Uid

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

## INPUTS

DRMMSite. You can pipe site objects from Get-RMMSite.
System.Guid. You can pipe SiteUid values.
## OUTPUTS

DRMMSiteSettings. Returns settings objects with the following properties:
- SiteUid: Site unique identifier
- GeneralSettings: General site configuration (timezone, locale, etc.)
- ProxySettings: Proxy server configuration
- MailSettings: Email notification settings
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

Site settings control how the Datto RMM agent behaves for devices in that site.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Sites/Get-RMMSiteSettings.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Sites/Get-RMMSiteSettings.md))
- [about_DRMMSite](../../about/classes/DRMMSite/about_DRMMSite.md)
- [Get-RMMSite](./Get-RMMSite.md)
- [Set-RMMSiteProxy](./Set-RMMSiteProxy.md)
