<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '.\DRMMObject.psm1'
using module '.\DRMMNetworkInterface.psm1'
class DRMMDeviceAudit : DRMMObject {

    [guid]$DeviceUid
    [string]$PortalUrl
    [string]$WebRemoteUrl
    [DRMMDeviceAuditSystemInfo]$SystemInfo
    [DRMMNetworkInterface[]]$Nics
    [DRMMDeviceAuditBios]$Bios
    [DRMMDeviceAuditBaseBoard]$BaseBoard
    [DRMMDeviceAuditDisplay[]]$Displays
    [DRMMDeviceAuditLogicalDisk[]]$LogicalDisks
    [DRMMDeviceAuditMobileInfo[]]$MobileInfo
    [DRMMDeviceAuditProcessor[]]$Processors
    [DRMMDeviceAuditVideoBoard[]]$VideoBoards
    [DRMMDeviceAuditAttachedDevice[]]$AttachedDevices
    [DRMMDeviceAuditSnmpInfo]$SnmpInfo
    [DRMMDeviceAuditPhysicalMemory[]]$PhysicalMemory
    [DRMMDeviceAuditSoftware[]]$Software

    DRMMDeviceAudit() : base() {

    }

    static [DRMMDeviceAudit] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Audit = [DRMMDeviceAudit]::new()
        $Audit.PortalUrl = [DRMMObject]::GetValue($Response, 'portalUrl')
        $Audit.WebRemoteUrl = [DRMMObject]::GetValue($Response, 'webRemoteUrl')
        
        # System info
        $SystemInfoData = [DRMMObject]::GetValue($Response, 'systemInfo')
        if ($null -ne $SystemInfoData) {

            $Audit.SystemInfo = [DRMMDeviceAuditSystemInfo]::FromAPIMethod($SystemInfoData)

        }

        # BIOS
        $BiosData = [DRMMObject]::GetValue($Response, 'bios')
        if ($null -ne $BiosData) {

            $Audit.Bios = [DRMMDeviceAuditBios]::FromAPIMethod($BiosData)

        }

        # Base board
        $BaseBoardData = [DRMMObject]::GetValue($Response, 'baseBoard')
        if ($null -ne $BaseBoardData) {

            $Audit.BaseBoard = [DRMMDeviceAuditBaseBoard]::FromAPIMethod($BaseBoardData)

        }

        # SNMP info
        $SnmpData = [DRMMObject]::GetValue($Response, 'snmpInfo')
        if ($null -ne $SnmpData) {

            $Audit.SnmpInfo = [DRMMDeviceAuditSnmpInfo]::FromAPIMethod($SnmpData)

        }

        # Network interfaces
        $NicsData = [DRMMObject]::GetValue($Response, 'nics')
        if ($null -ne $NicsData -and $NicsData.Count -gt 0) {

            $Audit.Nics = @($NicsData | ForEach-Object { [DRMMNetworkInterface]::FromAPIMethod($_) })

        }

        # Displays
        $DisplaysData = [DRMMObject]::GetValue($Response, 'displays')
        if ($null -ne $DisplaysData -and $DisplaysData.Count -gt 0) {

            $Audit.Displays = @($DisplaysData | ForEach-Object { [DRMMDeviceAuditDisplay]::FromAPIMethod($_) })

        }

        # Logical disks
        $DisksData = [DRMMObject]::GetValue($Response, 'logicalDisks')
        if ($null -ne $DisksData -and $DisksData.Count -gt 0) {

            $Audit.LogicalDisks = @($DisksData | ForEach-Object { [DRMMDeviceAuditLogicalDisk]::FromAPIMethod($_) })

        }

        # Mobile info
        $MobileData = [DRMMObject]::GetValue($Response, 'mobileInfo')
        if ($null -ne $MobileData -and $MobileData.Count -gt 0) {

            $Audit.MobileInfo = @($MobileData | ForEach-Object { [DRMMDeviceAuditMobileInfo]::FromAPIMethod($_) })

        }

        # Processors
        $ProcessorsData = [DRMMObject]::GetValue($Response, 'processors')
        if ($null -ne $ProcessorsData -and $ProcessorsData.Count -gt 0) {

            $Audit.Processors = @($ProcessorsData | ForEach-Object { [DRMMDeviceAuditProcessor]::FromAPIMethod($_) })

        }

        # Video boards
        $VideoData = [DRMMObject]::GetValue($Response, 'videoBoards')
        if ($null -ne $VideoData -and $VideoData.Count -gt 0) {

            $Audit.VideoBoards = @($VideoData | ForEach-Object { [DRMMDeviceAuditVideoBoard]::FromAPIMethod($_) })

        }

        # Attached devices
        $AttachedData = [DRMMObject]::GetValue($Response, 'attachedDevices')
        if ($null -ne $AttachedData -and $AttachedData.Count -gt 0) {

            $Audit.AttachedDevices = @($AttachedData | ForEach-Object { [DRMMDeviceAuditAttachedDevice]::FromAPIMethod($_) })

        }

        # Physical memory
        $MemoryData = [DRMMObject]::GetValue($Response, 'physicalMemory')
        if ($null -ne $MemoryData -and $MemoryData.Count -gt 0) {

            $Audit.PhysicalMemory = @($MemoryData | ForEach-Object { [DRMMDeviceAuditPhysicalMemory]::FromAPIMethod($_) })

        }

        return $Audit

    }
}

class DRMMDeviceAuditAttachedDevice : DRMMObject {

    [string]$Description
    [string]$Instance

    DRMMDeviceAuditAttachedDevice() : base() {

    }

    static [DRMMDeviceAuditAttachedDevice] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Device = [DRMMDeviceAuditAttachedDevice]::new()
        $Device.Description = [DRMMObject]::GetValue($Response, 'description')
        $Device.Instance = [DRMMObject]::GetValue($Response, 'instance')

        return $Device

    }
}

class DRMMDeviceAuditBaseBoard : DRMMObject {

    [string]$Manufacturer
    [string]$Product
    [string]$SerialNumber

    DRMMDeviceAuditBaseBoard() : base() {

    }

    static [DRMMDeviceAuditBaseBoard] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $BaseBoard = [DRMMDeviceAuditBaseBoard]::new()
        $BaseBoard.Manufacturer = [DRMMObject]::GetValue($Response, 'manufacturer')
        $BaseBoard.Product = [DRMMObject]::GetValue($Response, 'product')
        $BaseBoard.SerialNumber = [DRMMObject]::GetValue($Response, 'serialNumber')

        return $BaseBoard

    }
}

class DRMMDeviceAuditBios : DRMMObject {

    [string]$Manufacturer
    [string]$Name
    [string]$SerialNumber
    [string]$SmbiosBiosVersion

    DRMMDeviceAuditBios() : base() {

    }

    static [DRMMDeviceAuditBios] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Bios = [DRMMDeviceAuditBios]::new()
        $Bios.Manufacturer = [DRMMObject]::GetValue($Response, 'manufacturer')
        $Bios.Name = [DRMMObject]::GetValue($Response, 'name')
        $Bios.SerialNumber = [DRMMObject]::GetValue($Response, 'serialNumber')
        $Bios.SmbiosBiosVersion = [DRMMObject]::GetValue($Response, 'smbiosBiosVersion')

        return $Bios

    }
}

class DRMMDeviceAuditDisplay : DRMMObject {

    [string]$Instance
    [int]$ScreenHeight
    [int]$ScreenWidth

    DRMMDeviceAuditDisplay() : base() {

    }

    static [DRMMDeviceAuditDisplay] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Display = [DRMMDeviceAuditDisplay]::new()
        $Display.Instance = [DRMMObject]::GetValue($Response, 'instance')
        $Display.ScreenHeight = [DRMMObject]::GetValue($Response, 'screenHeight')
        $Display.ScreenWidth = [DRMMObject]::GetValue($Response, 'screenWidth')

        return $Display

    }
}

class DRMMDeviceAuditLogicalDisk : DRMMObject {

    [string]$Description
    [string]$DiskIdentifier
    [long]$Freespace
    [long]$Size

    DRMMDeviceAuditLogicalDisk() : base() {

    }

    static [DRMMDeviceAuditLogicalDisk] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Disk = [DRMMDeviceAuditLogicalDisk]::new()
        $Disk.Description = [DRMMObject]::GetValue($Response, 'description')
        $Disk.DiskIdentifier = [DRMMObject]::GetValue($Response, 'diskIdentifier')
        $Disk.Freespace = [DRMMObject]::GetValue($Response, 'freespace')
        $Disk.Size = [DRMMObject]::GetValue($Response, 'size')

        return $Disk

    }
}

class DRMMDeviceAuditMobileInfo : DRMMObject {

    [string]$Iccid
    [string]$Imei
    [string]$Number
    [string]$Operator

    DRMMDeviceAuditMobileInfo() : base() {

    }

    static [DRMMDeviceAuditMobileInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Mobile = [DRMMDeviceAuditMobileInfo]::new()
        $Mobile.Iccid = [DRMMObject]::GetValue($Response, 'iccid')
        $Mobile.Imei = [DRMMObject]::GetValue($Response, 'imei')
        $Mobile.Number = [DRMMObject]::GetValue($Response, 'number')
        $Mobile.Operator = [DRMMObject]::GetValue($Response, 'operator')

        return $Mobile

    }
}

class DRMMDeviceAuditPhysicalMemory : DRMMObject {

    [string]$BankLabel
    [long]$Capacity
    [string]$Manufacturer
    [string]$PartNumber
    [string]$SerialNumber
    [int]$Speed

    DRMMDeviceAuditPhysicalMemory() : base() {

    }

    static [DRMMDeviceAuditPhysicalMemory] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Memory = [DRMMDeviceAuditPhysicalMemory]::new()
        $Memory.BankLabel = [DRMMObject]::GetValue($Response, 'bankLabel')
        $Memory.Capacity = [DRMMObject]::GetValue($Response, 'capacity')
        $Memory.Manufacturer = [DRMMObject]::GetValue($Response, 'manufacturer')
        $Memory.PartNumber = [DRMMObject]::GetValue($Response, 'partNumber')
        $Memory.SerialNumber = [DRMMObject]::GetValue($Response, 'serialNumber')
        $Memory.Speed = [DRMMObject]::GetValue($Response, 'speed')

        return $Memory

    }
}

class DRMMDeviceAuditProcessor : DRMMObject {

    [string]$Name

    DRMMDeviceAuditProcessor() : base() {

    }

    static [DRMMDeviceAuditProcessor] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Processor = [DRMMDeviceAuditProcessor]::new()
        $Processor.Name = [DRMMObject]::GetValue($Response, 'name')

        return $Processor

    }
}

class DRMMDeviceAuditSnmpInfo : DRMMObject {

    [string]$Contact
    [string]$Description
    [string]$Location
    [string]$Name

    DRMMDeviceAuditSnmpInfo() : base() {

    }

    static [DRMMDeviceAuditSnmpInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Snmp = [DRMMDeviceAuditSnmpInfo]::new()
        $Snmp.Contact = [DRMMObject]::GetValue($Response, 'contact')
        $Snmp.Description = [DRMMObject]::GetValue($Response, 'description')
        $Snmp.Location = [DRMMObject]::GetValue($Response, 'location')
        $Snmp.Name = [DRMMObject]::GetValue($Response, 'name')

        return $Snmp

    }
}

class DRMMDeviceAuditSoftware : DRMMObject {

    [string]$Name
    [string]$Version

    DRMMDeviceAuditSoftware() : base() {

    }

    static [DRMMDeviceAuditSoftware] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Software = [DRMMDeviceAuditSoftware]::new()
        $Software.Name = [DRMMObject]::GetValue($Response, 'name')
        $Software.Version = [DRMMObject]::GetValue($Response, 'version')

        return $Software

    }
}

class DRMMDeviceAuditSystemInfo : DRMMObject {

    [string]$Manufacturer
    [string]$Model
    [long]$TotalPhysicalMemory
    [string]$Username
    [string]$DotNetVersion
    [int]$TotalCpuCores

    DRMMDeviceAuditSystemInfo() : base() {

    }

    static [DRMMDeviceAuditSystemInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $SystemInfo = [DRMMDeviceAuditSystemInfo]::new()
        $SystemInfo.Manufacturer = [DRMMObject]::GetValue($Response, 'manufacturer')
        $SystemInfo.Model = [DRMMObject]::GetValue($Response, 'model')
        $SystemInfo.TotalPhysicalMemory = [DRMMObject]::GetValue($Response, 'totalPhysicalMemory')
        $SystemInfo.Username = [DRMMObject]::GetValue($Response, 'username')
        $SystemInfo.DotNetVersion = [DRMMObject]::GetValue($Response, 'dotNetVersion')
        $SystemInfo.TotalCpuCores = [DRMMObject]::GetValue($Response, 'totalCpuCores')

        return $SystemInfo

    }
}

class DRMMDeviceAuditVideoBoard : DRMMObject {

    [string]$DisplayAdapter

    DRMMDeviceAuditVideoBoard() : base() {

    }

    static [DRMMDeviceAuditVideoBoard] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $VideoBoard = [DRMMDeviceAuditVideoBoard]::new()
        $VideoBoard.DisplayAdapter = [DRMMObject]::GetValue($Response, 'displayAdapter')

        return $VideoBoard

    }
}


