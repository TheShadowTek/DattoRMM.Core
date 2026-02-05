# Get-RMMEsxiHostAudit

## SYNOPSIS
Retrieves ESXi host audit data for a specific device.

## SYNTAX

```
Get-RMMEsxiHostAudit [-DeviceUid] <Guid> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMEsxiHostAudit function retrieves detailed VMware ESXi host information,
including host configuration, virtual machines, storage, and hardware details.

This audit data is collected by the Datto RMM agent from ESXi hosts and provides
comprehensive information about the virtualization environment, including:
- Host system information and configuration
- Virtual machines and their status
- Processor and memory details
- Network adapters and configuration
- Datastore information and capacity

## EXAMPLES

EXAMPLE 1
```
Get-RMMDevice -Name "ESXI-HOST-01" | Get-RMMEsxiHostAudit
```

Retrieves ESXi audit data for an ESXi host by name.

EXAMPLE 2
```
Get-RMMEsxiHostAudit -DeviceUid "12067610-8504-48e3-b5de-60e48416aaad"
```

Retrieves ESXi audit data using a specific device UID.

EXAMPLE 3
```
$Audit = Get-RMMDevice -DeviceId 12345 | Get-RMMEsxiHostAudit
$Audit.Guests | Select-Object Name, PowerState, GuestOS
```

Retrieves ESXi audit data and displays virtual machine information.

EXAMPLE 4
```
$EsxiAudit = Get-RMMEsxiHostAudit -DeviceUid $DeviceUid
$EsxiAudit.Datastores | Where-Object {$_.FreeSpaceGB -lt 100}
```

Retrieves ESXi audit data and finds datastores with less than 100GB free.

EXAMPLE 5
```
Get-RMMDevice -FilterId 300 | Get-RMMEsxiHostAudit | 
    ForEach-Object {
        [PSCustomObject]@{
            HostName = $_.SystemInfo.Hostname
            TotalVMs = $_.Guests.Count
            RunningVMs = ($_.Guests | Where-Object PowerState -eq 'poweredOn').Count
        }
    }
```

Gets ESXi hosts and creates a summary showing host names and VM counts.

## PARAMETERS

### -DeviceUid
The unique identifier (GUID) of the ESXi host device to retrieve audit data for.
Accepts pipeline input from Get-RMMDevice.

```yaml
Type: Guid
Parameter Sets: (All)
Aliases: Uid

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

## INPUTS

System.Guid. You can pipe DeviceUid from Get-RMMDevice.
DRMMDevice. You can pipe device objects from Get-RMMDevice.
## OUTPUTS

DRMMEsxiHostAudit. Returns ESXi audit objects with the following properties:
- DeviceUid: Device unique identifier
- SystemInfo: ESXi host system information (version, build, hostname)
- Guests: Array of virtual machine objects with status and configuration
- Processors: Processor information and specifications
- Nics: Network adapter configuration
- PhysicalMemory: Memory modules and capacity
- Datastores: Storage datastore information and capacity
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

ESXi audit data is only available for devices identified as VMware ESXi hosts.
The Datto RMM agent must have appropriate permissions to query the ESXi host.

## RELATED LINKS
