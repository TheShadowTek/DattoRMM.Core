# about_DRMMDeviceAudit

## SHORT DESCRIPTION

Represents a comprehensive audit of a device, including hardware, software, and network information.

## LONG DESCRIPTION

The DRMMDeviceAudit class encapsulates detailed information about a device, such as its unique identifier, portal URL, system information, network interfaces, BIOS details, baseboard information, display configurations, logical disks, mobile information, processors, video boards, attached devices, SNMP information, physical memory, and installed software. This class is typically used to represent the results of a device audit operation within the DRMM system.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMDeviceAudit class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DeviceUid       | guid                            | The unique identifier of the audited device. |
| PortalUrl       | string                          | The portal URL associated with the audited device. |
| WebRemoteUrl    | string                          | The web remote URL associated with the audited device. |
| SystemInfo      | DRMMDeviceAuditSystemInfo       | Information about the system of the audited device. |
| Nics            | DRMMNetworkInterface[]          | Information about the network interfaces of the audited device. |
| Bios            | DRMMDeviceAuditBios             | Information about the BIOS of the audited device. |
| BaseBoard       | DRMMDeviceAuditBaseBoard        | Information about the baseboard (motherboard) of the audited device. |
| Displays        | DRMMDeviceAuditDisplay[]        | Information about the display configurations of the audited device. |
| LogicalDisks    | DRMMDeviceAuditLogicalDisk[]    | Information about the logical disks of the audited device. |
| MobileInfo      | DRMMDeviceAuditMobileInfo[]     | Information about the mobile aspects of the audited device. |
| Processors      | DRMMDeviceAuditProcessor[]      | Information about the processors of the audited device. |
| VideoBoards     | DRMMDeviceAuditVideoBoard[]     | Information about the video boards of the audited device. |
| AttachedDevices | DRMMDeviceAuditAttachedDevice[] | Information about devices attached to the audited device. |
| SnmpInfo        | DRMMDeviceAuditSnmpInfo         | Information about the SNMP configuration of the audited device. |
| PhysicalMemory  | DRMMDeviceAuditPhysicalMemory[] | Information about the physical memory of the audited device. |
| Software        | DRMMDeviceAuditSoftware[]       | Information about the software installed on the audited device. |

## METHODS

The DRMMDeviceAudit class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMDeviceAudit/about_DRMMDeviceAudit.md)

