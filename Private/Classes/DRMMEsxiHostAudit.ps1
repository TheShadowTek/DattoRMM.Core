using module '.\DRMMObject.psm1'
. $PSScriptRoot/DRMMNetworkInterface.ps1

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
