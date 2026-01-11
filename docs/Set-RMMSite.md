# Set-RMMSite

## SYNOPSIS
Updates an existing site in the Datto RMM account.

## SYNTAX

BySiteObject
```
Set-RMMSite -Site <DRMMSite> [-Name <String>] [-Description <String>] [-Notes <String>] [-OnDemand]
 [-SplashtopAutoInstall] [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

ByUid
```
Set-RMMSite -SiteUid <Guid> -Name <String> [-Description <String>] [-Notes <String>] [-OnDemand]
 [-SplashtopAutoInstall] [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The Set-RMMSite function updates properties of an existing site in the authenticated
user's account.
The site can be specified by passing a DRMMSite object from the pipeline
or by providing the SiteUid parameter directly.

Note: Proxy settings cannot be updated using this function.
Use Set-RMMSiteProxy or
Remove-RMMSiteProxy to manage proxy settings.

## EXAMPLES

EXAMPLE 1
```
Set-RMMSite -SiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -Name "Updated Site Name"
```

Updates the name of the specified site.

EXAMPLE 2
```
Get-RMMSite -Name "Old Name" | Set-RMMSite -Name "New Name" -Description "Updated description"
```

Updates the name and description of a site via pipeline.

EXAMPLE 3
```
$Site = Get-RMMSite -Name "Test Site"
Set-RMMSite -Site $Site -Name "Test Site" -OnDemand -Force
```

Enables on-demand for a site without confirmation prompt.

EXAMPLE 4
```
Get-RMMSite | Where-Object {$_.Name -like "Branch*"} | Set-RMMSite -SplashtopAutoInstall
```

Enables Splashtop auto-install for all sites with names starting with "Branch".

## PARAMETERS

### -Site
A DRMMSite object to update.
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
The unique identifier (GUID) of the site to update.

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

### -Name
The new name for the site.
This parameter is required.

```yaml
Type: String
Parameter Sets: BySiteObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: ByUid
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
The new description for the site.

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

### -Notes
The new notes for the site.

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

DRMMSite. Returns the updated site object.
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

This function does not support updating proxy settings.
Use Set-RMMSiteProxy or
Remove-RMMSiteProxy for proxy configuration changes.

## RELATED LINKS

[about_DRMMSite](https://github.com/boabf/Datto-RMM/blob/main/docs/about_DRMMSite.md)

[Get-RMMSite](https://github.com/boabf/Datto-RMM/blob/main/docs/Get-RMMSite.md)

[Set-RMMSiteProxy](https://github.com/boabf/Datto-RMM/blob/main/docs/Set-RMMSiteProxy.md)


