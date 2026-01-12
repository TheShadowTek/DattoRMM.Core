using module '.\DRMMObject.psm1'
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
class DRMMNetworkInterface : DRMMObject {

    [string]$Instance
    [string]$Ipv4
    [string]$Ipv6
    [string]$MacAddress
    [string]$Type

    DRMMNetworkInterface() : base() {

    }

    static [DRMMNetworkInterface] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Nic = [DRMMNetworkInterface]::new()
        $Nic.Instance = $Response.instance
        $Nic.Ipv4 = $Response.ipv4
        $Nic.Ipv6 = $Response.ipv6
        $Nic.MacAddress = $Response.macAddress
        $Nic.Type = $Response.type

        return $Nic

    }
}

class DRMMEsxiDatastore : DRMMObject {

    [string]$DatastoreName
    [Nullable[int]]$SubscriptionPercent
    [Nullable[long]]$FreeSpace
    [Nullable[long]]$Size
    [string]$FileSystem
    [string]$Status

    DRMMEsxiDatastore() : base() {

    }

    static [DRMMEsxiDatastore] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Datastore = [DRMMEsxiDatastore]::new()
        $Datastore.DatastoreName = [DRMMObject]::GetValue($Response, 'datastoreName')
        $Datastore.SubscriptionPercent = [DRMMObject]::GetValue($Response, 'subscriptionPercent')
        $Datastore.FreeSpace = [DRMMObject]::GetValue($Response, 'freeSpace')
        $Datastore.Size = [DRMMObject]::GetValue($Response, 'size')
        $Datastore.FileSystem = [DRMMObject]::GetValue($Response, 'fileSystem')
        $Datastore.Status = [DRMMObject]::GetValue($Response, 'status')

        return $Datastore

    }
}

class DRMMEsxiGuest : DRMMObject {

    [string]$GuestName
    [Nullable[int]]$ProcessorSpeedTotal
    [Nullable[long]]$MemorySizeTotal
    [Nullable[int]]$NumberOfSnapshots
    [string]$Datastores

    DRMMEsxiGuest() : base() {

    }

    static [DRMMEsxiGuest] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Guest = [DRMMEsxiGuest]::new()
        $Guest.GuestName = [DRMMObject]::GetValue($Response, 'guestName')
        $Guest.ProcessorSpeedTotal = [DRMMObject]::GetValue($Response, 'processorSpeedTotal')
        $Guest.MemorySizeTotal = [DRMMObject]::GetValue($Response, 'memorySizeTotal')
        $Guest.NumberOfSnapshots = [DRMMObject]::GetValue($Response, 'numberOfSnapshots')
        $Guest.Datastores = [DRMMObject]::GetValue($Response, 'datastores')

        return $Guest

    }
}

class DRMMEsxiHostAudit : DRMMObject {

    [guid]$DeviceUid
    [string]$PortalUrl
    [DRMMEsxiSystemInfo]$SystemInfo
    [DRMMEsxiGuest[]]$Guests
    [DRMMEsxiProcessor[]]$Processors
    [DRMMEsxiNic[]]$Nics
    [DRMMEsxiPhysicalMemory[]]$PhysicalMemory
    [DRMMEsxiDatastore[]]$Datastores

    DRMMEsxiHostAudit() : base() {

    }

    static [DRMMEsxiHostAudit] FromAPIMethod([pscustomobject]$Response, [guid]$DeviceUid) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Audit = [DRMMEsxiHostAudit]::new()
        $Audit.DeviceUid = $DeviceUid
        $Audit.PortalUrl = [DRMMObject]::GetValue($Response, 'portalUrl')

        # System info
        $SystemInfoData = [DRMMObject]::GetValue($Response, 'systemInfo')
        if ($null -ne $SystemInfoData) {

            $Audit.SystemInfo = [DRMMEsxiSystemInfo]::FromAPIMethod($SystemInfoData)

        }

        # Guests
        $GuestsData = [DRMMObject]::GetValue($Response, 'guests')
        if ($null -ne $GuestsData -and $GuestsData.Count -gt 0) {

            $Audit.Guests = @($GuestsData | ForEach-Object { [DRMMEsxiGuest]::FromAPIMethod($_) })

        }

        # Processors
        $ProcessorsData = [DRMMObject]::GetValue($Response, 'processors')
        if ($null -ne $ProcessorsData -and $ProcessorsData.Count -gt 0) {

            $Audit.Processors = @($ProcessorsData | ForEach-Object { [DRMMEsxiProcessor]::FromAPIMethod($_) })

        }

        # Nics
        $NicsData = [DRMMObject]::GetValue($Response, 'nics')
        if ($null -ne $NicsData -and $NicsData.Count -gt 0) {

            $Audit.Nics = @($NicsData | ForEach-Object { [DRMMEsxiNic]::FromAPIMethod($_) })

        }

        # Physical memory
        $MemoryData = [DRMMObject]::GetValue($Response, 'physicalMemory')
        if ($null -ne $MemoryData -and $MemoryData.Count -gt 0) {

            $Audit.PhysicalMemory = @($MemoryData | ForEach-Object { [DRMMEsxiPhysicalMemory]::FromAPIMethod($_) })

        }

        # Datastores
        $DatastoresData = [DRMMObject]::GetValue($Response, 'datastores')
        if ($null -ne $DatastoresData -and $DatastoresData.Count -gt 0) {

            $Audit.Datastores = @($DatastoresData | ForEach-Object { [DRMMEsxiDatastore]::FromAPIMethod($_) })

        }

        return $Audit

    }
}

class DRMMEsxiNic : DRMMObject {

    [string]$Name
    [string]$Ipv4
    [string]$Ipv6
    [string]$MacAddress
    [string]$Speed
    [string]$Type

    DRMMEsxiNic() : base() {

    }

    static [DRMMEsxiNic] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Nic = [DRMMEsxiNic]::new()
        $Nic.Name = [DRMMObject]::GetValue($Response, 'name')
        $Nic.Ipv4 = [DRMMObject]::GetValue($Response, 'ipv4')
        $Nic.Ipv6 = [DRMMObject]::GetValue($Response, 'ipv6')
        $Nic.MacAddress = [DRMMObject]::GetValue($Response, 'macAddress')
        $Nic.Speed = [DRMMObject]::GetValue($Response, 'speed')
        $Nic.Type = [DRMMObject]::GetValue($Response, 'type')

        return $Nic

    }
}

class DRMMEsxiPhysicalMemory : DRMMObject {

    [string]$Module
    [Nullable[long]]$Size
    [string]$Type
    [string]$Speed
    [string]$SerialNumber
    [string]$PartNumber
    [string]$Bank

    DRMMEsxiPhysicalMemory() : base() {

    }

    static [DRMMEsxiPhysicalMemory] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Memory = [DRMMEsxiPhysicalMemory]::new()
        $Memory.Module = [DRMMObject]::GetValue($Response, 'module')
        $Memory.Size = [DRMMObject]::GetValue($Response, 'size')
        $Memory.Type = [DRMMObject]::GetValue($Response, 'type')
        $Memory.Speed = [DRMMObject]::GetValue($Response, 'speed')
        $Memory.SerialNumber = [DRMMObject]::GetValue($Response, 'serialNumber')
        $Memory.PartNumber = [DRMMObject]::GetValue($Response, 'partNumber')
        $Memory.Bank = [DRMMObject]::GetValue($Response, 'bank')

        return $Memory

    }
}

class DRMMEsxiProcessor : DRMMObject {

    [Nullable[double]]$Frequency
    [string]$Name
    [Nullable[int]]$NumberOfCores

    DRMMEsxiProcessor() : base() {

    }

    static [DRMMEsxiProcessor] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Processor = [DRMMEsxiProcessor]::new()
        $Processor.Frequency = [DRMMObject]::GetValue($Response, 'frequency')
        $Processor.Name = [DRMMObject]::GetValue($Response, 'name')
        $Processor.NumberOfCores = [DRMMObject]::GetValue($Response, 'numberOfCores')

        return $Processor

    }
}

class DRMMEsxiSystemInfo : DRMMObject {

    [string]$Manufacturer
    [string]$Model
    [string]$Name
    [Nullable[int]]$NumberOfSnapshots
    [string]$ServiceTag

    DRMMEsxiSystemInfo() : base() {

    }

    static [DRMMEsxiSystemInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $SystemInfo = [DRMMEsxiSystemInfo]::new()
        $SystemInfo.Manufacturer = [DRMMObject]::GetValue($Response, 'manufacturer')
        $SystemInfo.Model = [DRMMObject]::GetValue($Response, 'model')
        $SystemInfo.Name = [DRMMObject]::GetValue($Response, 'name')
        $SystemInfo.NumberOfSnapshots = [DRMMObject]::GetValue($Response, 'numberOfSnapshots')
        $SystemInfo.ServiceTag = [DRMMObject]::GetValue($Response, 'serviceTag')

        return $SystemInfo

    }
}

class DRMMPrinter : DRMMObject {

    [Nullable[long]]$PrintedPageCount

    DRMMPrinter() : base() {

    }

    static [DRMMPrinter] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Printer = [DRMMPrinter]::new()
        $Printer.PrintedPageCount = [DRMMObject]::GetValue($Response, 'printedPageCount')

        return $Printer

    }
}

class DRMMPrinterAudit : DRMMObject {

    [guid]$DeviceUid
    [string]$PortalUrl
    [DRMMPrinterSnmpInfo]$SnmpInfo
    [DRMMPrinterMarkerSupply[]]$PrinterMarkerSupplies
    [DRMMPrinter]$Printer
    [DRMMPrinterSystemInfo]$SystemInfo
    [DRMMNetworkInterface[]]$Nics

    DRMMPrinterAudit() : base() {

    }

    static [DRMMPrinterAudit] FromAPIMethod([pscustomobject]$Response, [guid]$DeviceUid) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Audit = [DRMMPrinterAudit]::new()
        $Audit.DeviceUid = $DeviceUid
        $Audit.PortalUrl = [DRMMObject]::GetValue($Response, 'portalUrl')

        # SNMP info
        $SnmpInfoData = [DRMMObject]::GetValue($Response, 'snmpInfo')
        if ($null -ne $SnmpInfoData) {

            $Audit.SnmpInfo = [DRMMPrinterSnmpInfo]::FromAPIMethod($SnmpInfoData)

        }

        # Printer marker supplies
        $SuppliesData = [DRMMObject]::GetValue($Response, 'printerMarkerSupplies')
        if ($null -ne $SuppliesData -and $SuppliesData.Count -gt 0) {

            $Audit.PrinterMarkerSupplies = @($SuppliesData | ForEach-Object { [DRMMPrinterMarkerSupply]::FromAPIMethod($_) })

        }

        # Printer
        $PrinterData = [DRMMObject]::GetValue($Response, 'printer')
        if ($null -ne $PrinterData) {

            $Audit.Printer = [DRMMPrinter]::FromAPIMethod($PrinterData)

        }

        # System info
        $SystemInfoData = [DRMMObject]::GetValue($Response, 'systemInfo')
        if ($null -ne $SystemInfoData) {

            $Audit.SystemInfo = [DRMMPrinterSystemInfo]::FromAPIMethod($SystemInfoData)

        }

        # Network interfaces
        $NicsData = [DRMMObject]::GetValue($Response, 'nics')
        if ($null -ne $NicsData -and $NicsData.Count -gt 0) {

            $Audit.Nics = @($NicsData | ForEach-Object { [DRMMNetworkInterface]::FromAPIMethod($_) })

        }

        return $Audit

    }
}

class DRMMPrinterMarkerSupply : DRMMObject {

    [string]$Description
    [string]$MaxCapacity
    [string]$SuppliesLevel

    DRMMPrinterMarkerSupply() : base() {

    }

    static [DRMMPrinterMarkerSupply] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Supply = [DRMMPrinterMarkerSupply]::new()
        $Supply.Description = [DRMMObject]::GetValue($Response, 'description')
        $Supply.MaxCapacity = [DRMMObject]::GetValue($Response, 'maxCapacity')
        $Supply.SuppliesLevel = [DRMMObject]::GetValue($Response, 'suppliesLevel')

        return $Supply

    }
}

class DRMMPrinterSnmpInfo : DRMMObject {

    [string]$SnmpName
    [string]$SnmpContact
    [string]$SnmpDescription
    [string]$SnmpLocation
    [string]$SnmpUptime
    [string]$NicManufacturer
    [string]$ObjectId
    [string]$SnmpSerial

    DRMMPrinterSnmpInfo() : base() {

    }

    static [DRMMPrinterSnmpInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Snmp = [DRMMPrinterSnmpInfo]::new()
        $Snmp.SnmpName = [DRMMObject]::GetValue($Response, 'snmpName')
        $Snmp.SnmpContact = [DRMMObject]::GetValue($Response, 'snmpContact')
        $Snmp.SnmpDescription = [DRMMObject]::GetValue($Response, 'snmpDescription')
        $Snmp.SnmpLocation = [DRMMObject]::GetValue($Response, 'snmpLocation')
        $Snmp.SnmpUptime = [DRMMObject]::GetValue($Response, 'snmpUptime')
        $Snmp.NicManufacturer = [DRMMObject]::GetValue($Response, 'nicManufacturer')
        $Snmp.ObjectId = [DRMMObject]::GetValue($Response, 'objectId')
        $Snmp.SnmpSerial = [DRMMObject]::GetValue($Response, 'snmpSerial')

        return $Snmp

    }
}

class DRMMPrinterSystemInfo : DRMMObject {

    [string]$Manufacturer
    [string]$Model

    DRMMPrinterSystemInfo() : base() {

    }

    static [DRMMPrinterSystemInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $SystemInfo = [DRMMPrinterSystemInfo]::new()
        $SystemInfo.Manufacturer = [DRMMObject]::GetValue($Response, 'manufacturer')
        $SystemInfo.Model = [DRMMObject]::GetValue($Response, 'model')

        return $SystemInfo

    }
}