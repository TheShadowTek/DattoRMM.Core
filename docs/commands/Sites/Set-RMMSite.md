# Set-RMMSite

## SYNOPSIS
Updates an existing site in the Datto RMM account.

## SYNTAX

BySiteObject (Default)
```
Set-RMMSite -Site <DRMMSite> [-Name <String>] [-Description <String>] [-Notes <String>] [-OnDemand]
 [-SplashtopAutoInstall] [-AppendNotes] [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

ByUidOverwrite
```
Set-RMMSite -SiteUid <Guid> -Name <String> [-Description <String>] [-Notes <String>] [-OnDemand]
 [-SplashtopAutoInstall] [-OverwriteAll] [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

ByUid
```
Set-RMMSite -SiteUid <Guid> [-Name <String>] [-Description <String>] [-Notes <String>] [-OnDemand]
 [-SplashtopAutoInstall] [-AppendNotes] [-Force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The Set-RMMSite function updates properties of an existing site in the authenticated
user's account.

Due to an API limitation, omitted properties are wiped when updating a site.
To prevent
unintended data loss, this function preserves existing property values by default:

- Pipeline input: When a DRMMSite object is piped, its current properties are used as
  defaults for any parameters not explicitly specified.
- SiteUid input: When a site UID is provided, the function fetches the current site
  state from the API and uses those values as defaults.

To bypass property preservation and send only explicitly specified parameters, use the
-OverwriteAll switch.
When OverwriteAll is used, Name becomes mandatory and any omitted
properties will be reset to their API default values.

Note: Proxy settings cannot be updated using this function.
Use Set-RMMSiteProxy or
Remove-RMMSiteProxy to manage proxy settings.

## EXAMPLES

EXAMPLE 1
```powershell
Set-RMMSite -SiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -Name "Updated Site Name"
```

Updates the site name.
Other existing properties are preserved by fetching the current
site state from the API before updating.

EXAMPLE 2
```powershell
Set-RMMSite -SiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -Name "Clean Site" -OverwriteAll
```

Updates the site with only the specified name.
All other properties are reset to their
API default values because OverwriteAll bypasses property preservation.

EXAMPLE 3
```powershell
Get-RMMSite -SiteName "Old Name" | Set-RMMSite -Name "New Name" -Description "Updated description"
```

Updates the name and description of a site via pipeline.

EXAMPLE 4
```powershell
$Site = Get-RMMSite -SiteName "Test Site"
Set-RMMSite -Site $Site -Name "Test Site" -OnDemand -Force
```

Enables on-demand for a site without confirmation prompt.

EXAMPLE 5
```powershell
Get-RMMSite | Where-Object {$_.Name -like "Branch*"} | Set-RMMSite -SplashtopAutoInstall
```

Enables Splashtop auto-install for all sites with names starting with "Branch".

EXAMPLE 6
```powershell
Get-RMMSite -SiteUid $SiteUid | Set-RMMSite -Notes "Reviewed April 2026" -AppendNotes
```

Appends a note to the site's existing notes, preserving the original content.

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
Parameter Sets: ByUidOverwrite, ByUid
Aliases: Uid

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The new name for the site.
Required when using -OverwriteAll.
When a reference site
is available (pipeline or fetched), defaults to the existing site name.

```yaml
Type: String
Parameter Sets: BySiteObject, ByUid
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: ByUidOverwrite
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

### -AppendNotes
Append the value supplied to -Notes to the site's existing notes, separated by a blank
line.
Requires -Notes to be specified.
Has no effect if -Notes is not provided.

Not available with -OverwriteAll because the current site state is unknown in that
parameter set.

```yaml
Type: SwitchParameter
Parameter Sets: BySiteObject, ByUid
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -OverwriteAll
Bypass property preservation and send only explicitly specified parameters to the API.
When this switch is used, Name becomes mandatory.
Properties not explicitly specified
will be reset to their API default values.

Use this when you intentionally want to clear or reset site properties.

```yaml
Type: SwitchParameter
Parameter Sets: ByUidOverwrite
Aliases:

Required: True
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


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Sites/Set-RMMSite.md)
- [about_DRMMSite](../../about/classes/DRMMSite/about_DRMMSite.md)
- [Get-RMMSite](./Get-RMMSite.md)
- [Set-RMMSiteProxy](./Set-RMMSiteProxy.md)
