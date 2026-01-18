# Get-RMMDevice

## SYNOPSIS
Retrieves device information from the Datto RMM API.

## SYNTAX

GlobalAll (Default)
```
Get-RMMDevice [-Hostname <String>] [-FilterId <Int64>] [-DeviceType <String>] [-OperatingSystem <String>]
 [-SiteName <String>] [-IncludeLastLoggedInUser] [-Force] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

SiteNetSummary
```
Get-RMMDevice -Site <DRMMSite> [-NetSummary] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

SiteAll
```
Get-RMMDevice -Site <DRMMSite> [-FilterId <Int64>] [-IncludeLastLoggedInUser] [-Force]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

DeviceByUid
```
Get-RMMDevice -DeviceUid <Guid> [-IncludeLastLoggedInUser] [-Force] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

DeviceById
```
Get-RMMDevice -DeviceId <Int32> [-IncludeLastLoggedInUser] [-Force] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

SiteUidNetSummary
```
Get-RMMDevice -SiteUid <Guid> [-NetSummary] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

SiteAllUid
```
Get-RMMDevice -SiteUid <Guid> [-FilterId <Int64>] [-IncludeLastLoggedInUser] [-Force]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

DeviceByMacAddress
```
Get-RMMDevice -MacAddress <String> [-IncludeLastLoggedInUser] [-Force] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMDevice function retrieves managed device information at different scopes:
global (account-level), site-level, or for specific devices.
Devices can be filtered
by hostname, device type, operating system, site name, or retrieved using specific
identifiers (UID, ID, or MAC address).

The function supports pipeline input from Get-RMMSite to easily retrieve all devices
for specific sites.

When using -IncludeLastLoggedInUser, the function will prompt for confirmation due to
privacy implications unless -Force is specified.

## EXAMPLES

EXAMPLE 1
```
Get-RMMDevice
```

Retrieves all devices in the account.

EXAMPLE 2
```
Get-RMMDevice -Hostname "SERVER01"
```

Retrieves devices with hostname containing "SERVER01".

EXAMPLE 3
```
Get-RMMSite -Name "Main Office" | Get-RMMDevice
```

Gets all devices for the "Main Office" site.

EXAMPLE 4
```
Get-RMMDevice -DeviceUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
```

Retrieves a specific device by its unique identifier.

EXAMPLE 5
```
Get-RMMDevice -MacAddress "00:11:22:33:44:55"
```

Retrieves a device by its MAC address.

EXAMPLE 6
```
Get-RMMDevice -FilterId 12345
```

Retrieves all devices matching the specified filter.

EXAMPLE 7
```
Get-RMMDevice -DeviceType "Server" -OperatingSystem "Windows Server 2022"
```

Retrieves all Windows Server 2022 devices.

EXAMPLE 8
```
Get-RMMSite | Get-RMMDevice -NetSummary
```

Gets network interface information for devices at all sites.

EXAMPLE 9
```
Get-RMMDevice -DeviceUid $guid -IncludeLastLoggedInUser -Force
```

Retrieves a device with last logged in user information without confirmation prompt.

## PARAMETERS

### -Site
A DRMMSite object to retrieve devices for.
Accepts pipeline input from Get-RMMSite.

```yaml
Type: DRMMSite
Parameter Sets: SiteNetSummary, SiteAll
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -DeviceUid
The unique identifier (GUID) of a specific device to retrieve.

```yaml
Type: Guid
Parameter Sets: DeviceByUid
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -DeviceId
The numeric ID of a specific device to retrieve.

```yaml
Type: Int32
Parameter Sets: DeviceById
Aliases: Id

Required: True
Position: Named
Default value: 0
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SiteUid
The unique identifier (GUID) of a site to retrieve devices for.

```yaml
Type: Guid
Parameter Sets: SiteUidNetSummary, SiteAllUid
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -MacAddress
The MAC address of a device to retrieve.
Accepts formats: 001122334455, 00:11:22:33:44:55, or 00-11-22-33-44-55.

```yaml
Type: String
Parameter Sets: DeviceByMacAddress
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Hostname
Filter devices by hostname (partial match supported).

```yaml
Type: String
Parameter Sets: GlobalAll
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilterId
Apply a device filter by its ID.
Can be used at global or site scope.

```yaml
Type: Int64
Parameter Sets: GlobalAll, SiteAll, SiteAllUid
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -DeviceType
Filter devices by device type category (e.g., "Desktop", "Laptop", "Server").

```yaml
Type: String
Parameter Sets: GlobalAll
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OperatingSystem
Filter devices by operating system (partial match supported).

```yaml
Type: String
Parameter Sets: GlobalAll
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SiteName
Filter devices by site name (partial match supported).

```yaml
Type: String
Parameter Sets: GlobalAll
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeLastLoggedInUser
Include the last logged in user information.
Requires confirmation unless -Force is specified.

```yaml
Type: SwitchParameter
Parameter Sets: GlobalAll, SiteAll, DeviceByUid, DeviceById, SiteAllUid, DeviceByMacAddress
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Suppress the confirmation prompt when using -IncludeLastLoggedInUser.

```yaml
Type: SwitchParameter
Parameter Sets: GlobalAll, SiteAll, DeviceByUid, DeviceById, SiteAllUid, DeviceByMacAddress
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NetSummary
Retrieve network interface summary for devices at a site.
Returns DRMMDeviceNetworkInterface objects.

```yaml
Type: SwitchParameter
Parameter Sets: SiteNetSummary, SiteUidNetSummary
Aliases:

Required: True
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
You can also pipe objects with DeviceUid, DeviceId, SiteUid, or MacAddress properties.
## OUTPUTS

DRMMDevice. Returns device objects with comprehensive information including:
- Device identification (Uid, Id, Hostname)
- Network information (IntIpAddress, ExtIpAddress)
- Status (Online, Suspended, Deleted, RebootRequired)
- Software information (OperatingSystem, CagVersion)
- Dates (LastSeen, LastReboot, LastAuditDate)
- UDFs, Antivirus, Patch Management information
When -NetSummary is specified, returns DRMMDeviceNetworkInterface objects with network card details.
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

The -IncludeLastLoggedInUser parameter requires explicit confirmation due to privacy
implications.
Use -Force to bypass the confirmation prompt.

## RELATED LINKS


- [about_DRMMDevice](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about_DRMMDevice.md)
- [about_DRMMFilter](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about_DRMMFilter.md)
- [Get-RMMDeviceFilter](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/Get-RMMDeviceFilter.md)
- [Get-RMMSite](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/Get-RMMSite.md)

