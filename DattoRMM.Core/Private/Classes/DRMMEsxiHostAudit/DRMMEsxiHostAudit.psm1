using module '..\DRMMObject\DRMMObject.psm1'

<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Represents the audit information of an ESXi host, including system info, guests, processors, network interfaces, physical memory, and datastores.
.DESCRIPTION
    The DRMMEsxiHostAudit class encapsulates detailed information about an ESXi host, such as its unique identifier, portal URL, system information, guest virtual machines, processors, network interfaces, physical memory modules, and datastores. This class is typically used to represent the results of an ESXi host audit operation within the DRMM system.
#>
class DRMMEsxiDatastore : DRMMObject {

    # The name of the datastore.
    [string]$DatastoreName
    # The percentage of subscription used in the datastore.
    [Nullable[int]]$SubscriptionPercent
    # The amount of free space available in the datastore.
    [Nullable[long]]$FreeSpace
    # The total size of the datastore.
    [Nullable[long]]$Size
    # The file system type of the datastore.
    [string]$FileSystem
    # The current status of the datastore.
    [string]$Status

    DRMMEsxiDatastore() : base() {

    }

    static [DRMMEsxiDatastore] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Datastore = [DRMMEsxiDatastore]::new()
        $Datastore.DatastoreName = $Response.datastoreName
        $Datastore.SubscriptionPercent = $Response.subscriptionPercent
        $Datastore.FreeSpace = $Response.freeSpace
        $Datastore.Size = $Response.size
        $Datastore.FileSystem = $Response.fileSystem
        $Datastore.Status = $Response.status

        return $Datastore

    }
}

<#
.SYNOPSIS
    Represents a guest virtual machine on an ESXi host, including its name, processor speed, memory size, number of snapshots, and datastores.
.DESCRIPTION
    The DRMMEsxiGuest class models the information about a guest virtual machine running on an ESXi host. It includes properties such as GuestName, ProcessorSpeedTotal, MemorySizeTotal, NumberOfSnapshots, and Datastores, which provide details about the virtual machine's configuration and resource usage. This class is typically used as part of the DRMMEsxiHostAudit to represent the virtual machines running on the ESXi host being audited.
#>
class DRMMEsxiGuest : DRMMObject {

    # The name of the guest virtual machine.
    [string]$GuestName
    # The total processor speed allocated to the guest virtual machine.
    [Nullable[int]]$ProcessorSpeedTotal
    # The total memory size allocated to the guest virtual machine.
    [Nullable[long]]$MemorySizeTotal
    # The number of snapshots taken for the guest virtual machine.
    [Nullable[int]]$NumberOfSnapshots
    # The datastores associated with the guest virtual machine.
    [string]$Datastores

    DRMMEsxiGuest() : base() {

    }

    static [DRMMEsxiGuest] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Guest = [DRMMEsxiGuest]::new()
        $Guest.GuestName = $Response.guestName
        $Guest.ProcessorSpeedTotal = $Response.processorSpeedTotal
        $Guest.MemorySizeTotal = $Response.memorySizeTotal
        $Guest.NumberOfSnapshots = $Response.numberOfSnapshots
        $Guest.Datastores = $Response.datastores

        return $Guest

    }
}

<#
.SYNOPSIS
    Represents the audit information of an ESXi host, including system info, guests, processors, network interfaces, physical memory, and datastores.
.DESCRIPTION
    The DRMMEsxiHostAudit class encapsulates detailed information about an ESXi host, such as its unique identifier, portal URL, system information, guest virtual machines, processors, network interfaces, physical memory modules, and datastores. This class is typically used to represent the results of an ESXi host audit operation within the DRMM system.
#>
class DRMMEsxiHostAudit : DRMMObject {

    # The unique identifier of the ESXi host.
    [guid]$DeviceUid
    # The portal URL of the ESXi host.
    [string]$PortalUrl
    # The system information of the ESXi host.
    [DRMMEsxiSystemInfo]$SystemInfo
    # The guest virtual machines running on the ESXi host.
    [DRMMEsxiGuest[]]$Guests
    # The processors of the ESXi host.
    [DRMMEsxiProcessor[]]$Processors
    # The network interface cards (NICs) of the ESXi host.
    [DRMMEsxiNic[]]$Nics
    # The physical memory modules of the ESXi host.
    [DRMMEsxiPhysicalMemory[]]$PhysicalMemory
    # The datastores associated with the ESXi host.
    [DRMMEsxiDatastore[]]$Datastores

    DRMMEsxiHostAudit() : base() {

    }

    static [DRMMEsxiHostAudit] FromAPIMethod([pscustomobject]$Response, [guid]$DeviceUid) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Audit = [DRMMEsxiHostAudit]::new()
        $Audit.DeviceUid = $DeviceUid
        $Audit.PortalUrl = $Response.portalUrl

        # System info
        $SystemInfoData = $Response.systemInfo
        if ($null -ne $SystemInfoData) {

            $Audit.SystemInfo = [DRMMEsxiSystemInfo]::FromAPIMethod($SystemInfoData)

        }

        # Guests
        $GuestsData = $Response.guests
        if ($null -ne $GuestsData -and $GuestsData.Count -gt 0) {

            $Audit.Guests = @($GuestsData | ForEach-Object { [DRMMEsxiGuest]::FromAPIMethod($_) })

        }

        # Processors
        $ProcessorsData = $Response.processors
        if ($null -ne $ProcessorsData -and $ProcessorsData.Count -gt 0) {

            $Audit.Processors = @($ProcessorsData | ForEach-Object { [DRMMEsxiProcessor]::FromAPIMethod($_) })

        }

        # Nics
        $NicsData = $Response.nics
        if ($null -ne $NicsData -and $NicsData.Count -gt 0) {

            $Audit.Nics = @($NicsData | ForEach-Object { [DRMMEsxiNic]::FromAPIMethod($_) })

        }

        # Physical memory
        $MemoryData = $Response.physicalMemory
        if ($null -ne $MemoryData -and $MemoryData.Count -gt 0) {

            $Audit.PhysicalMemory = @($MemoryData | ForEach-Object { [DRMMEsxiPhysicalMemory]::FromAPIMethod($_) })

        }

        # Datastores
        $DatastoresData = $Response.datastores
        if ($null -ne $DatastoresData -and $DatastoresData.Count -gt 0) {

            $Audit.Datastores = @($DatastoresData | ForEach-Object { [DRMMEsxiDatastore]::FromAPIMethod($_) })

        }

        return $Audit

    }
}

<#
.SYNOPSIS
    Represents a network interface card (NIC) on an ESXi host, including its name, IP addresses, MAC address, speed, and type.
.DESCRIPTION
    The DRMMEsxiNic class models the information about a network interface card (NIC) on an ESXi host. It includes properties such as Name, Ipv4, Ipv6, MacAddress, Speed, and Type, which provide details about the NIC's configuration and capabilities. This class is typically used as part of the DRMMEsxiHostAudit to represent the network interfaces of the ESXi host being audited.
#>
class DRMMEsxiNic : DRMMObject {

    # The name of the network interface card (NIC).
    [string]$Name
    # The IPv4 address of the network interface card (NIC).
    [string]$Ipv4
    # The IPv6 address of the network interface card (NIC).
    [string]$Ipv6
    # The MAC address of the network interface card (NIC).
    [string]$MacAddress
    # The speed of the network interface card (NIC).
    [string]$Speed
    # The type of the network interface card (NIC).
    [string]$Type

    DRMMEsxiNic() : base() {

    }

    static [DRMMEsxiNic] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Nic = [DRMMEsxiNic]::new()
        $Nic.Name = $Response.name
        $Nic.Ipv4 = $Response.ipv4
        $Nic.Ipv6 = $Response.ipv6
        $Nic.MacAddress = $Response.macAddress
        $Nic.Speed = $Response.speed
        $Nic.Type = $Response.type

        return $Nic

    }
}

<#
.SYNOPSIS
    Represents the physical memory information of an ESXi host, including module, size, type, speed, serial number, part number, and bank.
.DESCRIPTION
    The DRMMEsxiPhysicalMemory class models the information about the physical memory modules of an ESXi host. It includes properties such as Module, Size, Type, Speed, SerialNumber, PartNumber, and Bank, which provide details about each physical memory module installed on the ESXi host. This class is typically used as part of the DRMMEsxiHostAudit to represent the memory configuration of the ESXi host being audited.
#>
class DRMMEsxiPhysicalMemory : DRMMObject {

    # The identifier or name of the physical memory module.
    [string]$Module
    # The size of the physical memory module.
    [Nullable[long]]$Size
    # The type of the physical memory module.
    [string]$Type
    # The speed of the physical memory module.
    [string]$Speed
    # The serial number of the physical memory module.
    [string]$SerialNumber
    # The part number of the physical memory module.
    [string]$PartNumber
    # The bank location of the physical memory module.
    [string]$Bank

    DRMMEsxiPhysicalMemory() : base() {

    }

    static [DRMMEsxiPhysicalMemory] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Memory = [DRMMEsxiPhysicalMemory]::new()
        $Memory.Module = $Response.module
        $Memory.Size = $Response.size
        $Memory.Type = $Response.type
        $Memory.Speed = $Response.speed
        $Memory.SerialNumber = $Response.serialNumber
        $Memory.PartNumber = $Response.partNumber
        $Memory.Bank = $Response.bank

        return $Memory

    }
}

<#
.SYNOPSIS
    Represents the processor information of an ESXi host, including its frequency, name, and number of cores.
.DESCRIPTION
    The DRMMEsxiProcessor class models the information about the processor(s) of an ESXi host. It includes properties such as Frequency, Name, and NumberOfCores, which provide details about the CPU configuration of the ESXi host. This class is typically used as part of the DRMMEsxiHostAudit to represent the processor information of the ESXi host being audited.
#>
class DRMMEsxiProcessor : DRMMObject {

    # The frequency of the processor.
    [Nullable[double]]$Frequency
    # The name of the processor.
    [string]$Name
    # The number of cores in the processor.
    [Nullable[int]]$NumberOfCores

    DRMMEsxiProcessor() : base() {

    }

    static [DRMMEsxiProcessor] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Processor = [DRMMEsxiProcessor]::new()
        $Processor.Frequency = $Response.frequency
        $Processor.Name = $Response.name
        $Processor.NumberOfCores = $Response.numberOfCores

        return $Processor

    }
}

<#
.SYNOPSIS
    Represents the system information of an ESXi host, including manufacturer, model, name, number of snapshots, and service tag.
.DESCRIPTION
    The DRMMEsxiSystemInfo class models the information about the ESXi host system. It includes properties such as Manufacturer, Model, Name, NumberOfSnapshots, and ServiceTag, which provide details about the ESXi host's hardware and configuration. This class is typically used as part of the DRMMEsxiHostAudit to represent the overall system information of the ESXi host being audited.
#>
class DRMMEsxiSystemInfo : DRMMObject {

    # The manufacturer of the ESXi host.
    [string]$Manufacturer
    # The model of the ESXi host.
    [string]$Model
    # The name of the ESXi host.
    [string]$Name
    # The number of snapshots on the ESXi host.
    [Nullable[int]]$NumberOfSnapshots
    # The service tag of the ESXi host.
    [string]$ServiceTag

    DRMMEsxiSystemInfo() : base() {

    }

    static [DRMMEsxiSystemInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $SystemInfo = [DRMMEsxiSystemInfo]::new()
        $SystemInfo.Manufacturer = $Response.manufacturer
        $SystemInfo.Model = $Response.model
        $SystemInfo.Name = $Response.name
        $SystemInfo.NumberOfSnapshots = $Response.numberOfSnapshots
        $SystemInfo.ServiceTag = $Response.serviceTag

        return $SystemInfo

    }
}