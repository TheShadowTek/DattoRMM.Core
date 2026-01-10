# New-RMMVariable

## SYNOPSIS
Creates a new variable in the Datto RMM account or site.

## SYNTAX

Global (Default)
```
New-RMMVariable -Name <String> [-Value <String>] [-Masked] [-Force] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

BySiteObject
```
New-RMMVariable -Site <DRMMSite> -Name <String> [-Value <String>] [-Masked] [-Force]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

BySiteUid
```
New-RMMVariable -SiteUid <Guid> -Name <String> [-Value <String>] [-Masked] [-Force]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The New-RMMVariable function creates a new variable at either the account (global) level
or at a specific site level.
Variables can store configuration data that can be referenced
in scripts and automation.

Variables can optionally be masked to hide sensitive values in the Datto RMM UI.

## EXAMPLES

EXAMPLE 1
```
New-RMMVariable -Name "CompanyName" -Value "Contoso Ltd"
```

Creates an account-level variable named "CompanyName".

EXAMPLE 2
```
New-RMMVariable -Name "APIKey" -Value "secret123" -Masked
```

Creates a masked account-level variable for sensitive data.

EXAMPLE 3
```
Get-RMMSite -Name "Main Office" | New-RMMVariable -Name "SiteCode" -Value "MO001"
```

Creates a site-level variable via pipeline.

EXAMPLE 4
```
New-RMMVariable -SiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -Name "BackupPath" -Value "\\server\backup"
```

Creates a site-level variable by specifying the site UID.

## PARAMETERS

### -Site
A DRMMSite object to create the variable in.
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
The unique identifier (GUID) of a site to create the variable in.

```yaml
Type: Guid
Parameter Sets: BySiteUid
Aliases: Uid

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name
The name of the variable to create.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value
The value to assign to the variable.

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

### -Masked
Whether the variable value should be masked (hidden) in the Datto RMM UI.
Use this for
sensitive values like passwords or API keys.

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
Bypasses the confirmation prompt.

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

DRMMVariable. Returns the newly created variable object (fetched via Get-RMMVariable).
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

Variable names must be unique within their scope (account or site).
The Masked property can only be set during creation and cannot be changed later.

API Behavior: The Datto API does not return the created variable object, so this
function fetches it using Get-RMMVariable by name.

## RELATED LINKS
