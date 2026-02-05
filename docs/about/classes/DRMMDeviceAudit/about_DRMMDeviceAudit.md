# about_DRMMDeviceAudit

## SHORT DESCRIPTION

Represents a comprehensive audit of a device, including hardware, software, and network information.

## LONG DESCRIPTION

The DRMMDeviceAudit class encapsulates detailed information about a device, such as its unique identifier, portal URL, system information, network interfaces, BIOS details, baseboard information, display configurations, logical disks, mobile information, processors, video boards, attached devices, SNMP information, physical memory, and installed software. This class is typically used to represent the results of a device audit operation within the DRMM system.

This class inherits from [DRMMObject](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMDeviceAudit class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DeviceUid       | guid                            | Add description |
| PortalUrl       | string                          | Add description |
| WebRemoteUrl    | string                          | Add description |
| SystemInfo      | DRMMDeviceAuditSystemInfo       | Add description |
| Nics            | DRMMNetworkInterface[]          | Add description |
| Bios            | DRMMDeviceAuditBios             | Add description |
| BaseBoard       | DRMMDeviceAuditBaseBoard        | Add description |
| Displays        | DRMMDeviceAuditDisplay[]        | Add description |
| LogicalDisks    | DRMMDeviceAuditLogicalDisk[]    | Add description |
| MobileInfo      | DRMMDeviceAuditMobileInfo[]     | Add description |
| Processors      | DRMMDeviceAuditProcessor[]      | Add description |
| VideoBoards     | DRMMDeviceAuditVideoBoard[]     | Add description |
| AttachedDevices | DRMMDeviceAuditAttachedDevice[] | Add description |
| SnmpInfo        | DRMMDeviceAuditSnmpInfo         | Add description |
| PhysicalMemory  | DRMMDeviceAuditPhysicalMemory[] | Add description |
| Software        | DRMMDeviceAuditSoftware[]       | Add description |

## METHODS

The DRMMDeviceAudit class provides the following methods:

### DRMMDeviceAudit()

Add method description explaining what this method does

**Returns:** `void` - Describe what this method returns

**Example:**

```powershell
# TODO: Add usage example for this method
```


## USAGE EXAMPLES

### Example 1: Basic usage

```powershell
# TODO: Add comprehensive usage example
```

### Example 2: Advanced usage

```powershell
# TODO: Add advanced usage example
```

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

TODO: Add any additional notes about this class.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMDeviceAudit/about_DRMMDeviceAudit.md)
