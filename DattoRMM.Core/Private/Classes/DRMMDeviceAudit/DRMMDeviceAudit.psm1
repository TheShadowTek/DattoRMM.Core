using module '..\DRMMNetworkInterface\DRMMNetworkInterface.psm1'
using module '..\DRMMObject\DRMMObject.psm1'

<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Represents a comprehensive audit of a device, including hardware, software, and network information.
.DESCRIPTION
    The DRMMDeviceAudit class encapsulates detailed information about a device, such as its unique identifier, portal URL, system information, network interfaces, BIOS details, baseboard information, display configurations, logical disks, mobile information, processors, video boards, attached devices, SNMP information, physical memory, and installed software. This class is typically used to represent the results of a device audit operation within the DRMM system.
#>
class DRMMDeviceAudit : DRMMObject {

    # The unique identifier of the audited device.
    [guid]$DeviceUid
    # The portal URL associated with the audited device.
    [string]$PortalUrl
    # The web remote URL associated with the audited device.
    [string]$WebRemoteUrl
    # Information about the system of the audited device.
    [DRMMDeviceAuditSystemInfo]$SystemInfo
    # Information about the network interfaces of the audited device.
    [DRMMNetworkInterface[]]$Nics
    # Information about the BIOS of the audited device.
    [DRMMDeviceAuditBios]$Bios
    # Information about the baseboard (motherboard) of the audited device.
    [DRMMDeviceAuditBaseBoard]$BaseBoard
    # Information about the display configurations of the audited device.
    [DRMMDeviceAuditDisplay[]]$Displays
    # Information about the logical disks of the audited device.
    [DRMMDeviceAuditLogicalDisk[]]$LogicalDisks
    # Information about the mobile aspects of the audited device.
    [DRMMDeviceAuditMobileInfo[]]$MobileInfo
    # Information about the processors of the audited device.
    [DRMMDeviceAuditProcessor[]]$Processors
    # Information about the video boards of the audited device.
    [DRMMDeviceAuditVideoBoard[]]$VideoBoards
    # Information about devices attached to the audited device.
    [DRMMDeviceAuditAttachedDevice[]]$AttachedDevices
    # Information about the SNMP configuration of the audited device.
    [DRMMDeviceAuditSnmpInfo]$SnmpInfo
    # Information about the physical memory of the audited device.
    [DRMMDeviceAuditPhysicalMemory[]]$PhysicalMemory
    # Information about the software installed on the audited device.
    [DRMMDeviceAuditSoftware[]]$Software

    DRMMDeviceAudit() : base() {

    }

    static [DRMMDeviceAudit] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Audit = [DRMMDeviceAudit]::new()
        $Audit.PortalUrl = $Response.portalUrl
        $Audit.WebRemoteUrl = $Response.webRemoteUrl
        
        # System info
        $SystemInfoData = $Response.systemInfo
        if ($null -ne $SystemInfoData) {

            $Audit.SystemInfo = [DRMMDeviceAuditSystemInfo]::FromAPIMethod($SystemInfoData)

        }

        # BIOS
        $BiosData = $Response.bios
        if ($null -ne $BiosData) {

            $Audit.Bios = [DRMMDeviceAuditBios]::FromAPIMethod($BiosData)

        }

        # Base board
        $BaseBoardData = $Response.baseBoard
        if ($null -ne $BaseBoardData) {

            $Audit.BaseBoard = [DRMMDeviceAuditBaseBoard]::FromAPIMethod($BaseBoardData)

        }

        # SNMP info
        $SnmpData = $Response.snmpInfo
        if ($null -ne $SnmpData) {

            $Audit.SnmpInfo = [DRMMDeviceAuditSnmpInfo]::FromAPIMethod($SnmpData)

        }

        # Network interfaces
        $NicsData = $Response.nics
        if ($null -ne $NicsData -and $NicsData.Count -gt 0) {

            $Audit.Nics = @($NicsData | ForEach-Object { [DRMMNetworkInterface]::FromAPIMethod($_) })

        }

        # Displays
        $DisplaysData = $Response.displays
        if ($null -ne $DisplaysData -and $DisplaysData.Count -gt 0) {

            $Audit.Displays = @($DisplaysData | ForEach-Object { [DRMMDeviceAuditDisplay]::FromAPIMethod($_) })

        }

        # Logical disks
        $DisksData = $Response.logicalDisks
        if ($null -ne $DisksData -and $DisksData.Count -gt 0) {

            $Audit.LogicalDisks = @($DisksData | ForEach-Object { [DRMMDeviceAuditLogicalDisk]::FromAPIMethod($_) })

        }

        # Mobile info
        $MobileData = $Response.mobileInfo
        if ($null -ne $MobileData -and $MobileData.Count -gt 0) {

            $Audit.MobileInfo = @($MobileData | ForEach-Object { [DRMMDeviceAuditMobileInfo]::FromAPIMethod($_) })

        }

        # Processors
        $ProcessorsData = $Response.processors
        if ($null -ne $ProcessorsData -and $ProcessorsData.Count -gt 0) {

            $Audit.Processors = @($ProcessorsData | ForEach-Object { [DRMMDeviceAuditProcessor]::FromAPIMethod($_) })

        }

        # Video boards
        $VideoData = $Response.videoBoards
        if ($null -ne $VideoData -and $VideoData.Count -gt 0) {

            $Audit.VideoBoards = @($VideoData | ForEach-Object { [DRMMDeviceAuditVideoBoard]::FromAPIMethod($_) })

        }

        # Attached devices
        $AttachedData = $Response.attachedDevices
        if ($null -ne $AttachedData -and $AttachedData.Count -gt 0) {

            $Audit.AttachedDevices = @($AttachedData | ForEach-Object { [DRMMDeviceAuditAttachedDevice]::FromAPIMethod($_) })

        }

        # Physical memory
        $MemoryData = $Response.physicalMemory
        if ($null -ne $MemoryData -and $MemoryData.Count -gt 0) {

            $Audit.PhysicalMemory = @($MemoryData | ForEach-Object { [DRMMDeviceAuditPhysicalMemory]::FromAPIMethod($_) })

        }

        return $Audit

    }
}

<#
.SYNOPSIS
    Represents an attached device in a device audit, including its description and instance information.
.DESCRIPTION
    The DRMMDeviceAuditAttachedDevice class models the information about a device that is attached to the audited system. It includes properties such as Description and Instance, which provide details about the attached device. This class is typically used as part of the DRMMDeviceAudit to represent the various devices connected to the system being audited.
#>
class DRMMDeviceAuditAttachedDevice : DRMMObject {

    # A description of the attached device.
    [string]$Description
    # The instance identifier of the attached device.
    [string]$Instance

    DRMMDeviceAuditAttachedDevice() : base() {

    }

    static [DRMMDeviceAuditAttachedDevice] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Device = [DRMMDeviceAuditAttachedDevice]::new()
        $Device.Description = $Response.description
        $Device.Instance = $Response.instance

        return $Device

    }
}

<#
.SYNOPSIS
    Represents the baseboard information of a device in a device audit, including manufacturer, product, and serial number.
.DESCRIPTION
    The DRMMDeviceAuditBaseBoard class models the information about the baseboard (motherboard) of the audited system. It includes properties such as Manufacturer, Product, and SerialNumber, which provide details about the baseboard. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.
#>
class DRMMDeviceAuditBaseBoard : DRMMObject {

    # The manufacturer of the baseboard.
    [string]$Manufacturer
    # The product name or model of the baseboard.
    [string]$Product
    # The serial number of the baseboard.
    [string]$SerialNumber

    DRMMDeviceAuditBaseBoard() : base() {

    }

    static [DRMMDeviceAuditBaseBoard] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $BaseBoard = [DRMMDeviceAuditBaseBoard]::new()
        $BaseBoard.Manufacturer = $Response.manufacturer
        $BaseBoard.Product = $Response.product
        $BaseBoard.SerialNumber = $Response.serialNumber

        return $BaseBoard

    }
}

<#
.SYNOPSIS
    Represents the BIOS information of a device in a device audit, including manufacturer, name, serial number, and SMBIOS BIOS version.
.DESCRIPTION
    The DRMMDeviceAuditBios class models the information about the BIOS of the audited system. It includes properties such as Manufacturer, Name, SerialNumber, and SmbiosBiosVersion, which provide details about the BIOS. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.
#>
class DRMMDeviceAuditBios : DRMMObject {

    # The manufacturer of the BIOS.
    [string]$Manufacturer
    # The name of the BIOS.
    [string]$Name
    # The serial number of the BIOS.
    [string]$SerialNumber
    # The SMBIOS BIOS version.
    [string]$SmbiosBiosVersion

    DRMMDeviceAuditBios() : base() {

    }

    static [DRMMDeviceAuditBios] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Bios = [DRMMDeviceAuditBios]::new()
        $Bios.Manufacturer = $Response.manufacturer
        $Bios.Name = $Response.name
        $Bios.SerialNumber = $Response.serialNumber
        $Bios.SmbiosBiosVersion = $Response.smbiosBiosVersion

        return $Bios

    }
}

<#
.SYNOPSIS
    Represents the display information of a device in a device audit, including instance, screen height, and screen width.
.DESCRIPTION
    The DRMMDeviceAuditDisplay class models the information about the display of the audited system. It includes properties such as Instance, ScreenHeight, and ScreenWidth, which provide details about the display. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.
#>
class DRMMDeviceAuditDisplay : DRMMObject {

    # The instance identifier of the display.
    [string]$Instance
    # The height of the display screen in pixels.
    [int]$ScreenHeight
    # The width of the display screen in pixels.
    [int]$ScreenWidth

    DRMMDeviceAuditDisplay() : base() {

    }

    static [DRMMDeviceAuditDisplay] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Display = [DRMMDeviceAuditDisplay]::new()
        $Display.Instance = $Response.instance
        $Display.ScreenHeight = $Response.screenHeight
        $Display.ScreenWidth = $Response.screenWidth

        return $Display

    }
}

<#
.SYNOPSIS
    Represents the logical disk information of a device in a device audit, including description, disk identifier, free space, and size.
.DESCRIPTION
    The DRMMDeviceAuditLogicalDisk class models the information about the logical disks of the audited system. It includes properties such as Description, DiskIdentifier, Freespace, and Size, which provide details about each logical disk. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.
#>
class DRMMDeviceAuditLogicalDisk : DRMMObject {

    # A description of the logical disk.
    [string]$Description
    # The identifier of the logical disk.
    [string]$DiskIdentifier
    # The free space available on the logical disk.
    [long]$Freespace
    # The total size of the logical disk.
    [long]$Size

    DRMMDeviceAuditLogicalDisk() : base() {

    }

    static [DRMMDeviceAuditLogicalDisk] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Disk = [DRMMDeviceAuditLogicalDisk]::new()
        $Disk.Description = $Response.description
        $Disk.DiskIdentifier = $Response.diskIdentifier
        $Disk.Freespace = $Response.freespace
        $Disk.Size = $Response.size

        return $Disk

    }
}

<#
.SYNOPSIS
    Represents the mobile information of a device in a device audit, including ICCID, IMEI, number, and operator.
.DESCRIPTION
    The DRMMDeviceAuditMobileInfo class models the information about the mobile connectivity of the audited system. It includes properties such as Iccid, Imei, Number, and Operator, which provide details about the mobile network information of the device. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.
#>
class DRMMDeviceAuditMobileInfo : DRMMObject {

    # The ICCID (Integrated Circuit Card Identifier) of the mobile device.
    [string]$Iccid
    # The IMEI (International Mobile Equipment Identity) of the mobile device.
    [string]$Imei
    # The phone number associated with the mobile device.
    [string]$Number
    # The mobile network operator of the device.
    [string]$Operator

    DRMMDeviceAuditMobileInfo() : base() {

    }

    static [DRMMDeviceAuditMobileInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Mobile = [DRMMDeviceAuditMobileInfo]::new()
        $Mobile.Iccid = $Response.iccid
        $Mobile.Imei = $Response.imei
        $Mobile.Number = $Response.number
        $Mobile.Operator = $Response.operator

        return $Mobile

    }
}

<#
.SYNOPSIS
    Represents the physical memory information of a device in a device audit, including bank label, capacity, manufacturer, part number, serial number, and speed.
.DESCRIPTION
    The DRMMDeviceAuditPhysicalMemory class models the information about the physical memory modules of the audited system. It includes properties such as BankLabel, Capacity, Manufacturer, PartNumber, SerialNumber, and Speed, which provide details about each physical memory module. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.
#>
class DRMMDeviceAuditPhysicalMemory : DRMMObject {

    # The label of the memory bank.
    [string]$BankLabel
    # The capacity of the physical memory module.
    [long]$Capacity
    # The manufacturer of the physical memory module.
    [string]$Manufacturer
    # The part number of the physical memory module.
    [string]$PartNumber
    # The serial number of the physical memory module.
    [string]$SerialNumber
    # The speed of the physical memory module.
    [int]$Speed

    DRMMDeviceAuditPhysicalMemory() : base() {

    }

    static [DRMMDeviceAuditPhysicalMemory] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Memory = [DRMMDeviceAuditPhysicalMemory]::new()
        $Memory.BankLabel = $Response.bankLabel
        $Memory.Capacity = $Response.capacity
        $Memory.Manufacturer = $Response.manufacturer
        $Memory.PartNumber = $Response.partNumber
        $Memory.SerialNumber = $Response.serialNumber
        $Memory.Speed = $Response.speed

        return $Memory

    }
}

<#
.SYNOPSIS
    Represents the processor information of a device in a device audit, including its name.
.DESCRIPTION
    The DRMMDeviceAuditProcessor class models the information about the processor(s) of the audited system. It includes a property for the Name of the processor, which provides details about the CPU. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.
#>
class DRMMDeviceAuditProcessor : DRMMObject {

    # The name of the processor.
    [string]$Name

    DRMMDeviceAuditProcessor() : base() {

    }

    static [DRMMDeviceAuditProcessor] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Processor = [DRMMDeviceAuditProcessor]::new()
        $Processor.Name = $Response.name

        return $Processor

    }
}

<#
.SYNOPSIS
    Represents the SNMP information of a device in a device audit, including contact, description, location, and name.
.DESCRIPTION
    The DRMMDeviceAuditSnmpInfo class models the information about the SNMP configuration of the audited system. It includes properties such as Contact, Description, Location, and Name, which provide details about the SNMP settings of the device. This class is typically used as part of the DRMMDeviceAudit to represent the network information of the system being audited.
#>
class DRMMDeviceAuditSnmpInfo : DRMMObject {

    # The contact information for SNMP.
    [string]$Contact
    # A description of the SNMP configuration.
    [string]$Description
    # The physical location of the SNMP device.
    [string]$Location
    # The name of the SNMP device.
    [string]$Name

    DRMMDeviceAuditSnmpInfo() : base() {

    }

    static [DRMMDeviceAuditSnmpInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Snmp = [DRMMDeviceAuditSnmpInfo]::new()
        $Snmp.Contact = $Response.contact
        $Snmp.Description = $Response.description
        $Snmp.Location = $Response.location
        $Snmp.Name = $Response.name

        return $Snmp

    }
}

<#
.SYNOPSIS
    Represents the software information of a device in a device audit, including its name and version.
.DESCRIPTION
    The DRMMDeviceAuditSoftware class models the information about the software installed on the audited system. It includes properties such as Name and Version, which provide details about each software application. This class is typically used as part of the DRMMDeviceAudit to represent the software inventory of the system being audited.
#>
class DRMMDeviceAuditSoftware : DRMMObject {

    # The name of the software.
    [string]$Name
    # The version of the software.
    [string]$Version

    DRMMDeviceAuditSoftware() : base() {

    }

    static [DRMMDeviceAuditSoftware] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Software = [DRMMDeviceAuditSoftware]::new()
        $Software.Name = $Response.name
        $Software.Version = $Response.version

        return $Software

    }
}

<#
.SYNOPSIS
    Represents the system information of a device in a device audit, including manufacturer, model, total physical memory, username, .NET version, and total CPU cores.
.DESCRIPTION
    The DRMMDeviceAuditSystemInfo class models the information about the system of the audited device. It includes properties such as Manufacturer, Model, TotalPhysicalMemory, Username, DotNetVersion, and TotalCpuCores, which provide detailed information about the system's hardware and software environment. This class is typically used as part of the DRMMDeviceAudit to represent the overall system information of the device being audited.
#>
class DRMMDeviceAuditSystemInfo : DRMMObject {

    # The manufacturer of the system.
    [string]$Manufacturer
    # The model of the system.
    [string]$Model
    # The total physical memory (RAM) of the system.
    [long]$TotalPhysicalMemory
    # The username of the currently logged-in user.
    [string]$Username
    # The version of the .NET framework installed on the system.
    [string]$DotNetVersion
    # The total number of CPU cores in the system.
    [int]$TotalCpuCores

    DRMMDeviceAuditSystemInfo() : base() {

    }

    static [DRMMDeviceAuditSystemInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $SystemInfo = [DRMMDeviceAuditSystemInfo]::new()
        $SystemInfo.Manufacturer = $Response.manufacturer
        $SystemInfo.Model = $Response.model
        $SystemInfo.TotalPhysicalMemory = $Response.totalPhysicalMemory
        $SystemInfo.Username = $Response.username
        $SystemInfo.DotNetVersion = $Response.dotNetVersion
        $SystemInfo.TotalCpuCores = $Response.totalCpuCores

        return $SystemInfo

    }
}

<#
.SYNOPSIS
    Represents the video board information of a device in a device audit, including its display adapter name.
.DESCRIPTION
    The DRMMDeviceAuditVideoBoard class models the information about the video board (graphics card) of the audited system. It includes a property for the DisplayAdapter, which provides details about the graphics hardware. This class is typically used as part of the DRMMDeviceAudit to represent the hardware information of the system being audited.
#>
class DRMMDeviceAuditVideoBoard : DRMMObject {

    # The name of the display adapter (video board) in the system.
    [string]$DisplayAdapter

    DRMMDeviceAuditVideoBoard() : base() {

    }

    static [DRMMDeviceAuditVideoBoard] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $VideoBoard = [DRMMDeviceAuditVideoBoard]::new()
        $VideoBoard.DisplayAdapter = $Response.displayAdapter

        return $VideoBoard

    }
}