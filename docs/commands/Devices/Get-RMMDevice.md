# Get-RMMDevice

## SYNOPSIS
Retrieves device information from the Datto RMM API.

## SYNTAX

Global (Default)
```
Get-RMMDevice [-FilterId <Int64>] [-Hostname <String>] [-DeviceType <String>] [-OperatingSystem <String>]
 [-SiteName <String>] [-IncludeLastLoggedInUser] [-Force] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

SiteNetSummary
```
Get-RMMDevice -Site <DRMMSite> [-NetSummary] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

Site
```
Get-RMMDevice -Site <DRMMSite> [-FilterId <Int64>] [-IncludeLastLoggedInUser] [-Force]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

SiteUidNetSummary
```
Get-RMMDevice -SiteUid <Guid> [-NetSummary] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

SiteUid
```
Get-RMMDevice -SiteUid <Guid> [-FilterId <Int64>] [-IncludeLastLoggedInUser] [-Force]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

Device
```
Get-RMMDevice -Device <DRMMDevice> [-IncludeLastLoggedInUser] [-Force] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

DeviceUid
```
Get-RMMDevice -DeviceUid <Guid> [-IncludeLastLoggedInUser] [-Force] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

DeviceId
```
Get-RMMDevice -DeviceId <Int32> [-IncludeLastLoggedInUser] [-Force] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

DeviceMac
```
Get-RMMDevice -MacAddress <String> [-IncludeLastLoggedInUser] [-Force] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

Filter
```
Get-RMMDevice -Filter <DRMMFilter> [-IncludeLastLoggedInUser] [-Force] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMDevice function retrieves managed device information at different scopes:
global (account-level), site-level, filter-based, or for specific devices.
Devices can
be filtered by hostname, device type, operating system, or site name at the global scope.

The function supports pipeline input from Get-RMMSite, Get-RMMDevice, and Get-RMMFilter,
making it easy to retrieve devices for filtered sets of sites or filter definitions.

When specifying a Filter, site-scoped filters automatically route to the appropriate site
endpoint.
Global-scoped filters route to the account endpoint.

When using -IncludeLastLoggedInUser, the function will prompt for confirmation due to
privacy implications unless -Force is specified.

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMDevice
```

Retrieves all devices in the account.

EXAMPLE 2
```powershell
Get-RMMDevice -Hostname "SERVER01"
```

Retrieves devices with hostname containing "SERVER01".

EXAMPLE 3
```powershell
Get-RMMSite -Name "Main Office" | Get-RMMDevice
```

Gets all devices for the "Main Office" site.

EXAMPLE 4
```powershell
Get-RMMFilter -Name "Production Servers" | Get-RMMDevice
```

Gets all devices matching the "Production Servers" filter.
Site-scoped filters automatically
route to the correct site endpoint.

EXAMPLE 5
```powershell
Get-RMMDevice -DeviceUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
```

Retrieves a specific device by its unique identifier.

EXAMPLE 6
```powershell
Get-RMMDevice -MacAddress "00:11:22:33:44:55"
```

Retrieves a device by its MAC address.

EXAMPLE 7
```powershell
Get-RMMDevice -FilterId 12345
```

Retrieves all devices matching filter 12345 at the account level.

EXAMPLE 8
```powershell
Get-RMMSite -Name "Main Office" | Get-RMMDevice -FilterId 12345
```

Retrieves devices matching filter 12345 scoped to the "Main Office" site.

EXAMPLE 9
```powershell
Get-RMMDevice -DeviceType "Server" -OperatingSystem "Windows Server 2022"
```

Retrieves all Windows Server 2022 devices.

EXAMPLE 10
```powershell
Get-RMMSite | Get-RMMDevice -NetSummary
```

Gets network interface information for devices at all sites.

EXAMPLE 11
```powershell
Get-RMMDevice -DeviceUid $guid -IncludeLastLoggedInUser -Force
```

Retrieves a device with last logged in user information without confirmation prompt.

## PARAMETERS

### -Site
A DRMMSite object to retrieve devices for.
Accepts pipeline input from Get-RMMSite.

```yaml
Type: DRMMSite
Parameter Sets: SiteNetSummary, Site
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -SiteUid
The unique identifier (GUID) of a site to retrieve devices for.

```yaml
Type: Guid
Parameter Sets: SiteUidNetSummary, SiteUid
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Device
A DRMMDevice object to re-retrieve from the API.
Accepts pipeline input from Get-RMMDevice.
Useful for refreshing stale device data.

```yaml
Type: DRMMDevice
Parameter Sets: Device
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
Parameter Sets: DeviceUid
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeviceId
The numeric ID of a specific device to retrieve.

```yaml
Type: Int32
Parameter Sets: DeviceId
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -MacAddress
The MAC address of a device to retrieve.
Accepts formats: 001122334455, 00:11:22:33:44:55,
or 00-11-22-33-44-55.

```yaml
Type: String
Parameter Sets: DeviceMac
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
A DRMMFilter object to retrieve matching devices for.
Accepts pipeline input from Get-RMMFilter.
Site-scoped filters automatically route to the appropriate site endpoint.

```yaml
Type: DRMMFilter
Parameter Sets: Filter
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -FilterId
Apply a device filter by its numeric ID.
When used alone, queries at the global (account) scope.
When combined with Site or SiteUid, queries at the site scope.

```yaml
Type: Int64
Parameter Sets: Global, Site, SiteUid
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Hostname
Filter devices by hostname (partial match supported).
Only available at global scope.

```yaml
Type: String
Parameter Sets: Global
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeviceType
Filter devices by device type category (e.g., "Desktop", "Laptop", "Server").
Only available at global scope.

```yaml
Type: String
Parameter Sets: Global
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OperatingSystem
Filter devices by operating system (partial match supported).
Only available at global scope.

```yaml
Type: String
Parameter Sets: Global
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SiteName
Filter devices by site name (partial match supported).
Only available at global scope.

```yaml
Type: String
Parameter Sets: Global
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
Parameter Sets: Global, Site, SiteUid, Device, DeviceUid, DeviceId, DeviceMac, Filter
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
Parameter Sets: Global, Site, SiteUid, Device, DeviceUid, DeviceId, DeviceMac, Filter
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
DRMMDevice. You can pipe device objects from Get-RMMDevice.
DRMMFilter. You can pipe filter objects from Get-RMMFilter.
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

When piping sites or filters, the IncludeLastLoggedInUser parameter applies to all
objects in the pipeline.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Get-RMMDevice.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Devices/Get-RMMDevice.md))
- [about_DRMMDevice](../../about/classes/DRMMDevice/about_DRMMDevice.md)
- [about_DRMMFilter](../../about/classes/DRMMFilter/about_DRMMFilter.md)
- [Get-RMMFilter](../Filter/Get-RMMFilter.md)
- [Get-RMMSite](../Sites/Get-RMMSite.md)
