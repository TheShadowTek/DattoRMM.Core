# Remove-RMMSiteProxy

## SYNOPSIS
Removes proxy settings from a Datto RMM site.

## SYNTAX

BySiteObject
```
Remove-RMMSiteProxy -Site <DRMMSite> [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

ByUid
```
Remove-RMMSiteProxy -SiteUid <Guid> [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The Remove-RMMSiteProxy function deletes the proxy server configuration from a
specified site.
After removal, devices at the site will connect directly to the
Datto RMM service without going through a proxy.

The site can be specified by passing a DRMMSite object from the pipeline or by
providing the SiteUid parameter directly.

## EXAMPLES

EXAMPLE 1
```powershell
Remove-RMMSiteProxy -SiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
```

Removes proxy settings from the specified site (with confirmation prompt).

EXAMPLE 2
```powershell
Get-RMMSite -Name "Branch Office" | Remove-RMMSiteProxy -Force
```

Removes proxy settings from the site via pipeline without confirmation.

EXAMPLE 3
```powershell
Get-RMMSite | Where-Object {$_.Name -like "Test*"} | Remove-RMMSiteProxy
```

Removes proxy settings from all sites with names starting with "Test".

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
The unique identifier (GUID) of the site from which to remove proxy settings.

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

After removing proxy settings, devices will need to be able to connect directly
to the Datto RMM service.
Ensure network connectivity is available before removing
proxy configuration.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Sites/Remove-RMMSiteProxy.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Sites/Remove-RMMSiteProxy.md))
- [about_DRMMSite](../../about/classes/DRMMSite/about_DRMMSite.md)
- [Get-RMMSite](./Get-RMMSite.md)
- [Set-RMMSiteProxy](./Set-RMMSiteProxy.md)
