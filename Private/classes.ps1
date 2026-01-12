using module '.\Classes\DRMMObject.psm1'



class DRMMDevice : DRMMObject {

    [long]$Id
    [guid]$Uid
    [long]$SiteId
    [guid]$SiteUid
    [string]$SiteName
    [DRMMDeviceType]$DeviceType
    [string]$Hostname
    [string]$IntIpAddress
    [string]$OperatingSystem
    [string]$LastLoggedInUser
    [string]$Domain
    [string]$CagVersion
    [string]$DisplayVersion
    [string]$ExtIpAddress
    [string]$Description
    [bool]$A64Bit
    [bool]$RebootRequired
    [bool]$Online
    [bool]$Suspended
    [bool]$Deleted
    [Nullable[datetime]]$LastSeen
    [Nullable[datetime]]$LastReboot
    [Nullable[datetime]]$LastAuditDate
    [Nullable[datetime]]$CreationDate
    [DRMMDeviceUdfs]$Udfs
    [bool]$SnmpEnabled
    [string]$DeviceClass
    [string]$PortalUrl
    [string]$WarrantyDate
    [DRMMDeviceAntivirusInfo]$Antivirus
    [DRMMDevicePatchManagement]$PatchManagement
    [string]$SoftwareStatus
    [string]$WebRemoteUrl
    [bool]$NetworkProbe
    [bool]$OnboardedViaNetworkMonitor
    [bool]$RevealLastLoggedInUser

    DRMMDevice() : base() {

        $this.RevealLastLoggedInUser = $false

    }

    static [DRMMDevice] FromAPIMethod([pscustomobject]$Response) {

        return [DRMMDevice]::FromAPIMethod($Response, $false)

    }

    static [DRMMDevice] FromAPIMethod([pscustomobject]$Response, [bool]$RevealLastLoggedInUser) {

        if ($null -eq $Response) {

            return $null

        }

        $Device = [DRMMDevice]::new()
        $Device.Id = $Response.id
        $Device.Uid = $Response.uid
        $Device.SiteId = $Response.siteId
        $Device.SiteUid = $Response.siteUid
        $Device.SiteName = $Response.siteName
        $Device.Hostname = $Response.hostname
        $Device.IntIpAddress = $Response.intIpAddress
        $Device.OperatingSystem = $Response.operatingSystem
        $Device.RevealLastLoggedInUser = $RevealLastLoggedInUser

        if ($RevealLastLoggedInUser) {

            $Device.LastLoggedInUser = $Response.lastLoggedInUser

        } else {

            $Device.LastLoggedInUser = [DRMMObject]::MaskString([string]$Response.lastLoggedInUser, 2, '*')

        }

        $Device.Domain = $Response.domain
        $Device.CagVersion = $Response.cagVersion
        $Device.DisplayVersion = $Response.displayVersion
        $Device.ExtIpAddress = $Response.extIpAddress
        $Device.Description = $Response.description
        $Device.A64Bit = $Response.a64Bit
        $Device.RebootRequired = $Response.rebootRequired
        $Device.Online = $Response.online
        $Device.Suspended = $Response.suspended
        $Device.Deleted = $Response.deleted
        $Device.SnmpEnabled = $Response.snmpEnabled
        $Device.DeviceClass = $Response.deviceClass
        $Device.PortalUrl = $Response.portalUrl
        $Device.WarrantyDate = $Response.warrantyDate
        $Device.SoftwareStatus = $Response.softwareStatus
        $Device.WebRemoteUrl = $Response.webRemoteUrl
        $Device.NetworkProbe = $Response.networkProbe
        $Device.OnboardedViaNetworkMonitor = $Response.onboardedViaNetworkMonitor
        $Device.DeviceType = [DRMMDeviceType]::FromAPIMethod($Response.deviceType)
        $Device.Udfs = [DRMMDeviceUdfs]::FromAPIMethod($Response.udf)
        $Device.Antivirus = [DRMMDeviceAntivirusInfo]::FromAPIMethod($Response.antivirus)
        $Device.PatchManagement = [DRMMDevicePatchManagement]::FromAPIMethod($Response.patchManagement)
        $Device.LastSeen = ([DRMMObject]::ParseApiDate($Response.lastSeen)).DateTime
        $Device.LastReboot = ([DRMMObject]::ParseApiDate($Response.lastReboot)).DateTime
        $Device.LastAuditDate = ([DRMMObject]::ParseApiDate($Response.lastAuditDate)).DateTime
        $Device.CreationDate = ([DRMMObject]::ParseApiDate($Response.creationDate)).DateTime

        return $Device

    }

    [DRMMAlert[]] GetAlerts() {

        if (-not (Get-Command -Name Get-RMMAlert -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Get-RMMAlert -DeviceUid $this.Uid -Status 'All'

    }

    [DRMMAlert[]] GetAlerts([string]$Status) {

        if (-not (Get-Command -Name Get-RMMAlert -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Get-RMMAlert -DeviceUid $this.Uid -Status $Status

    }

    [void] OpenPortal() {

        if ($this.PortalUrl) {

            Start-Process $this.PortalUrl

        } else {

            Write-Warning "Portal URL is not available for device $($this.Hostname)"

        }
    }

    [void] OpenWebRemote() {

        if ($this.WebRemoteUrl) {

            Start-Process $this.WebRemoteUrl

        } else {

            Write-Warning "Web Remote URL is not available for device $($this.Hostname)"

        }
    }

    [object] GetUdfAsJson([int]$UdfNumber) {

        if ($UdfNumber -lt 1 -or $UdfNumber -gt 30) {

            throw "UDF number must be between 1 and 30"

        }

        $UdfPropName = "Udf$UdfNumber"
        $UdfValue = $this.Udfs.$UdfPropName

        if ([string]::IsNullOrWhiteSpace($UdfValue)) {

            return $null

        }

        try {

            return $UdfValue | ConvertFrom-Json

        } catch {

            throw "Failed to parse UDF $UdfNumber as JSON: $_"

        }
    }

    [pscustomobject] GetUdfAsCsv([int]$UdfNumber, [string[]]$Headers) {

        # Default delimiter: comma
        return $this.GetUdfAsCsv($UdfNumber, ',', $Headers)

    }

    [pscustomobject] GetUdfAsCsv([int]$UdfNumber, [string]$Delimiter, [string[]]$Headers) {

        if ($UdfNumber -lt 1 -or $UdfNumber -gt 30) {

            throw "UDF number must be between 1 and 30"

        }

        if ([string]::IsNullOrEmpty($Delimiter)) {

            throw "Delimiter cannot be null or empty"

        }

        if ($null -eq $Headers -or $Headers.Count -eq 0) {

            throw "Headers must contain at least one column name"

        }

        $UdfPropName = "Udf$UdfNumber"
        $UdfValue = $this.Udfs.$UdfPropName

        if ([string]::IsNullOrWhiteSpace($UdfValue)) {
            
            return $null

        }

        try {

            # Parse single row of delimited data with custom headers
            $CsvText = $UdfValue
            return (ConvertFrom-Csv -InputObject $CsvText -Delimiter $Delimiter -Header $Headers)

        } catch {

            Write-Error "Failed to parse UDF $UdfNumber as delimited data: $_"
            return $null

        }

    }

    [string] GetSummary() {

        $DeviceTypeStr = if ($this.DeviceType) { "$($this.DeviceType.Category)" } else { 'Unknown' }
        return "$($this.Hostname)|$DeviceTypeStr"

    }

    # Alert Management Methods
    [void] ResolveAllAlerts() {

        if (-not (Get-Command -Name Resolve-RMMAlert -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        $alerts = $this.GetAlerts('Open')

        foreach ($alert in $alerts) {

            Resolve-RMMAlert -AlertUid $alert.Uid -Force

        }
    }

    # Data Retrieval Methods
    [DRMMDeviceAudit] GetAudit() {

        if (-not (Get-Command -Name Get-RMMDeviceAudit -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Get-RMMDeviceAudit -DeviceUid $this.Uid

    }

    [DRMMDeviceAuditSoftware[]] GetSoftware() {

        if (-not (Get-Command -Name Get-RMMDeviceSoftware -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Get-RMMDeviceSoftware -DeviceUid $this.Uid

    }

    # Device Management Methods
    [DRMMDevice] SetUDF([hashtable]$UDFFields) {

        if (-not (Get-Command -Name Set-RMMDeviceUDF -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Set-RMMDeviceUDF -DeviceUid $this.Uid @UDFFields -Force

    }

    [DRMMDevice] ClearUDF([int]$UdfNumber) {

        if (-not (Get-Command -Name Set-RMMDeviceUDF -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        if ($UdfNumber -lt 1 -or $UdfNumber -gt 30) {

            throw "UDF number must be between 1 and 30"

        }

        $udfParam = @{"UDF$UdfNumber" = ''}

        return Set-RMMDeviceUDF -DeviceUid $this.Uid @udfParam -Force

    }

    [DRMMDevice] ClearUDFs() {

        if (-not (Get-Command -Name Set-RMMDeviceUDF -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        $udfParams = @{}

        for ($i = 1; $i -le 30; $i++) {

            $udfParams["UDF$i"] = ''

        }

        return Set-RMMDeviceUDF -DeviceUid $this.Uid @udfParams -Force

    }

    [DRMMDevice] SetWarranty([datetime]$WarrantyDate) {

        if (-not (Get-Command -Name Set-RMMDeviceWarranty -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Set-RMMDeviceWarranty -DeviceUid $this.Uid -WarrantyDate $WarrantyDate -Force

    }

    [DRMMJob] RunQuickJob([guid]$ComponentUid, [hashtable]$Variables) {

        if (-not (Get-Command -Name New-RMMQuickJob -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return New-RMMQuickJob -DeviceUid $this.Uid -ComponentUid $ComponentUid -Variables $Variables -Force

    }

    [DRMMDevice] Move([guid]$TargetSiteUid) {

        if (-not (Get-Command -Name Move-RMMDevice -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Move-RMMDevice -DeviceUid $this.Uid -TargetSiteUid $TargetSiteUid -Force

    }
}

class DRMMDeviceAntivirusInfo : DRMMObject {

    [string]$AntivirusProduct
    [string]$AntivirusStatus

    DRMMDeviceAntivirusInfo() : base() {

    }

    static [DRMMDeviceAntivirusInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $AntivirusInfo = [DRMMDeviceAntivirusInfo]::new()
        $AntivirusInfo.AntivirusProduct = $Response.antivirusProduct
        $AntivirusInfo.AntivirusStatus = $Response.antivirusStatus

        return $AntivirusInfo

    }

    [bool] IsRunning() {

        return ($this.AntivirusStatus -match '^Running')

    }

    [bool] IsUpToDate() {

        return ($this.AntivirusStatus -eq 'RunningAndUpToDate')

    }

    [string] GetSummary() {

        return "$($this.AntivirusProduct) - $($this.AntivirusStatus)"

    }
}

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

class DRMMDeviceNetworkInterface : DRMMObject {

    [long]$Id
    [guid]$Uid
    [long]$SiteId
    [guid]$SiteUid
    [string]$SiteName
    [DRMMDeviceType]$DeviceType
    [string]$Hostname
    [string]$IntIpAddress
    [string]$ExtIpAddress
    [DRMMNetworkInterface[]]$Nics

    DRMMDeviceNetworkInterface() : base() {

        $this.Nics = @()

    }

    static [DRMMDeviceNetworkInterface] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Device = [DRMMDeviceNetworkInterface]::new()
        $Device.Id = $Response.id
        $Device.Uid = $Response.uid
        $Device.SiteId = $Response.siteId
        $Device.SiteUid = $Response.siteUid
        $Device.SiteName = $Response.siteName
        $Device.DeviceType = [DRMMDeviceType]::FromAPIMethod($Response.deviceType)
        $Device.Hostname = $Response.hostname
        $Device.IntIpAddress = $Response.intIpAddress
        $Device.ExtIpAddress = $Response.extIpAddress

        if ($Response.nics) {

            $Device.Nics = $Response.nics | ForEach-Object {

                [DRMMNetworkInterface]::FromAPIMethod($_)

            }
        }

        return $Device

    }
}

class DRMMDevicePatchManagement : DRMMObject {

    [string]$PatchStatus
    [Nullable[long]]$PatchesApprovedPending
    [Nullable[long]]$PatchesNotApproved
    [Nullable[long]]$PatchesInstalled

    DRMMDevicePatchManagement() : base() {

    }

    static [DRMMDevicePatchManagement] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $PatchMgmt = [DRMMDevicePatchManagement]::new()
        $PatchMgmt.PatchStatus = $Response.patchStatus
        $PatchMgmt.PatchesApprovedPending = $Response.patchesApprovedPending
        $PatchMgmt.PatchesNotApproved = $Response.patchesNotApproved
        $PatchMgmt.PatchesInstalled = $Response.patchesInstalled

        return $PatchMgmt

    }
}

class DRMMDevicesStatus : DRMMObject {

    [long]$NumberOfDevices
    [long]$NumberOfOnlineDevices
    [long]$NumberOfOfflineDevices

    DRMMDevicesStatus() : base() {

    }

    static [DRMMDevicesStatus] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

            $DevicesStatus = [DRMMDevicesStatus]::new()
            $DevicesStatus.NumberOfDevices = $Response.numberOfDevices
            $DevicesStatus.NumberOfOnlineDevices = $Response.numberOfOnlineDevices
            $DevicesStatus.NumberOfOfflineDevices = $Response.numberOfOfflineDevices

            return $DevicesStatus

    }

    [string] GetSummary() {

        return "Devices: $($this.NumberOfDevices), Online: $($this.NumberOfOnlineDevices), Offline: $($this.NumberOfOfflineDevices)"

    }
}

class DRMMDeviceType : DRMMObject {

    [string]$Category
    [string]$Type

    DRMMDeviceType() : base() {

    }

    static [DRMMDeviceType] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $DeviceType = [DRMMDeviceType]::new()
        $DeviceType.Category = $Response.category
        $DeviceType.Type = $Response.type

        return $DeviceType

    }
}

class DRMMDeviceUdfs : DRMMObject {

    [string]$Udf1
    [string]$Udf2
    [string]$Udf3
    [string]$Udf4
    [string]$Udf5
    [string]$Udf6
    [string]$Udf7
    [string]$Udf8
    [string]$Udf9
    [string]$Udf10
    [string]$Udf11
    [string]$Udf12
    [string]$Udf13
    [string]$Udf14
    [string]$Udf15
    [string]$Udf16
    [string]$Udf17
    [string]$Udf18
    [string]$Udf19
    [string]$Udf20
    [string]$Udf21
    [string]$Udf22
    [string]$Udf23
    [string]$Udf24
    [string]$Udf25
    [string]$Udf26
    [string]$Udf27
    [string]$Udf28
    [string]$Udf29
    [string]$Udf30

    DRMMDeviceUdfs() : base() {

    }

    static [DRMMDeviceUdfs] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $UdfEntries = [DRMMDeviceUdfs]::new()

        for ($i = 1; $i -le 30; $i++) {

            $PropName = "udf$i"
            $UdfPropName = "Udf$i"

            if ($Response.PSObject.Properties.Name -contains $PropName) {

                $Value = $Response.$PropName

                if ($null -ne $Value -and $Value -ne '') {

                    $UdfEntries.$UdfPropName = $Value

                }
            }
        }

        return $UdfEntries

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

class DRMMFilter : DRMMObject {

    [long]$Id
    [long]$FilterId
    [string]$Name
    [string]$Description
    [string]$Type
    [string]$Scope
    [Nullable[guid]]$SiteUid
    [Nullable[datetime]]$DateCreate
    [Nullable[datetime]]$LastUpdated

    DRMMFilter() : base() {

    }

    static [DRMMFilter] FromAPIMethod([pscustomobject]$Response, [string]$Scope, [Nullable[guid]]$SiteUid) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Filter = [DRMMFilter]::new()
        $Filter.Id = $Response.id
        $Filter.FilterId = $Response.id
        $Filter.Name = $Response.name
        $Filter.Description = $Response.description
        $Filter.Type = $Response.type
        $Filter.Scope = $Scope
        $Filter.SiteUid = $SiteUid

        $CreateDate = [DRMMObject]::ParseApiDate($Response.dateCreate)
        $Filter.DateCreate = $CreateDate.DateTime

        $UpdatedDate = [DRMMObject]::ParseApiDate($Response.lastUpdated)
        $Filter.LastUpdated = $UpdatedDate.DateTime

        return $Filter

    }

    [bool] IsGlobal() { return ($this.Scope -eq 'Global') }
    [bool] IsSite()   { return ($this.Scope -eq 'Site') }
    [bool] IsDefault() { return ($this.Type -eq 'rmm_default') }
    [bool] IsCustom()  { return ($this.Type -eq 'custom') }

    [string] GetSummary() {

        $ScopeValue = if ($this.Scope) { $this.Scope } else { 'Global' }
        $TypeValue = if ($this.Type) { " ($($this.Type))" } else { '' }

        return "$($this.Name) [$ScopeValue]$TypeValue"

    }

    # API Methods
    [DRMMDevice[]] GetDevices() {

        $result = if ($this.SiteUid) {

            Get-RMMDevice -SiteUid $this.SiteUid -FilterId $this.FilterId

        } else {

            Get-RMMDevice -FilterId $this.FilterId

        }

        if ($null -eq $result) {

            return @()

        }

        return $result

    }

    [int] GetDeviceCount() {

        $devices = $this.GetDevices()

        return $devices.Count

    }

    [DRMMAlert[]] GetAlerts() {

        if (-not (Get-Command -Name Get-RMMAlert -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        $devices = $this.GetDevices()
        $allAlerts = @()

        foreach ($device in $devices) {

            $alerts = Get-RMMAlert -DeviceUid $device.Uid -Status 'All'

            if ($alerts) {

                $allAlerts += $alerts

            }
        }

        return $allAlerts

    }

    [DRMMAlert[]] GetAlerts([string]$Status) {

        if (-not (Get-Command -Name Get-RMMAlert -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        $devices = $this.GetDevices()
        $allAlerts = @()

        foreach ($device in $devices) {

            $alerts = Get-RMMAlert -DeviceUid $device.Uid -Status $Status

            if ($alerts) {

                $allAlerts += $alerts

            }
        }

        return $allAlerts

    }
}

class DRMMJob : DRMMObject {

    [long]$Id
    [guid]$Uid
    [string]$Name
    [Nullable[datetime]]$DateCreated
    [string]$Status

    DRMMJob() : base() {

    }

    static [DRMMJob] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Job = [DRMMJob]::new()
        $Job.Id = [DRMMObject]::GetValue($Response, 'id')
        $Job.Uid = [DRMMObject]::GetValue($Response, 'uid')
        $Job.Name = [DRMMObject]::GetValue($Response, 'name')
        $Job.Status = [DRMMObject]::GetValue($Response, 'status')

        $DateCreatedValue = [DRMMObject]::GetValue($Response, 'dateCreated')

        if ($null -ne $DateCreatedValue) {

            try {

                $Job.DateCreated = [datetime]::Parse($DateCreatedValue)

            } catch {

                $Job.DateCreated = $null

            }
        }

        return $Job

    }

    # Status Check Methods
    [bool] IsActive() {

        return $this.Status -eq 'active'

    }

    [bool] IsCompleted() {

        return $this.Status -eq 'completed'

    }

    # Time-based Methods
    [timespan] GetAge() {

        if ($this.DateCreated) {

            return (Get-Date) - $this.DateCreated

        }

        return [timespan]::Zero

    }

    # API Wrapper Methods
    [DRMMJobComponent[]] GetComponents() {

        return (Get-RMMJob -JobUid $this.Uid -Components)

    }

    [DRMMJobResults] GetResults([guid]$DeviceUid) {

        return (Get-RMMJob -JobUid $this.Uid -DeviceUid $DeviceUid -Results)

    }

    [DRMMJobStdData[]] GetStdOut([guid]$DeviceUid) {

        return (Get-RMMJob -JobUid $this.Uid -DeviceUid $DeviceUid -StdOut)

    }

    [DRMMJobStdData[]] GetStdErr([guid]$DeviceUid) {

        return (Get-RMMJob -JobUid $this.Uid -DeviceUid $DeviceUid -StdErr)

    }

    # Refresh Method
    [void] Refresh() {

        $Updated = Get-RMMJob -JobUid $this.Uid

        if ($Updated) {

            $this.Status = $Updated.Status
            $this.Name = $Updated.Name
            $this.DateCreated = $Updated.DateCreated

        }

    }

    # Utility Methods
    [string] GetSummary() {

        $Age = ''

        if ($this.DateCreated) {

            $Span = $this.GetAge()

            if ($Span.TotalDays -ge 1) {

                $Age = " ($([int]$Span.TotalDays)d ago)"

            } elseif ($Span.TotalHours -ge 1) {

                $Age = " ($([int]$Span.TotalHours)h ago)"

            } else {

                $Age = " ($([int]$Span.TotalMinutes)m ago)"

            }

        }

        $JobName = if ($this.Name) {$this.Name} else {'Unknown Job'}

        return "$JobName - $($this.Status)$Age"

    }

    # Output Parsing Methods
    [pscustomobject[]] GetStdOutAsJson([guid]$DeviceUid) {

        $StdOutData = $this.GetStdOut($DeviceUid)

        if (-not $StdOutData -or $StdOutData.Count -eq 0) {

            return @()

        }

        # Combine all stdout lines into single string
        $JsonText = ($StdOutData | ForEach-Object {$_.StdData}) -join "`n"

        try {

            return (ConvertFrom-Json -InputObject $JsonText)

        } catch {

            Write-Error "Failed to parse stdout as JSON: $_"
            return @()

        }

    }

    [pscustomobject[]] GetStdOutAsCsv([guid]$DeviceUid) {

        # Default: treat first row as header
        return $this.GetStdOutAsCsv($DeviceUid, $true, $null)

    }

    [pscustomobject[]] GetStdOutAsCsv([guid]$DeviceUid, [bool]$FirstRowAsHeader) {

        return $this.GetStdOutAsCsv($DeviceUid, $FirstRowAsHeader, $null)

    }

    [pscustomobject[]] GetStdOutAsCsv([guid]$DeviceUid, [bool]$FirstRowAsHeader, [string[]]$Headers) {

        $StdOutData = $this.GetStdOut($DeviceUid)

        if (-not $StdOutData -or $StdOutData.Count -eq 0) {

            return @()

        }

        # Combine all stdout lines into single string
        $CsvText = ($StdOutData | ForEach-Object {$_.StdData}) -join "`n"

        try {

            if ($Headers -and $Headers.Count -gt 0) {

                # Custom headers provided
                if ($FirstRowAsHeader) {

                    # Original CSV has headers, skip that first line before parsing
                    $CsvText = ($CsvText -split "`n" | Select-Object -Skip 1) -join "`n"

                }

                # Parse with custom headers (all remaining rows are data)
                return (ConvertFrom-Csv -InputObject $CsvText -Header $Headers)

            } elseif ($FirstRowAsHeader) {

                # Standard CSV with header row
                return (ConvertFrom-Csv -InputObject $CsvText)

            } else {

                # FirstRowAsHeader = false but no custom headers provided
                throw "When FirstRowAsHeader is false, you must provide custom headers via the Headers parameter"

            }

        } catch {

            Write-Error "Failed to parse stdout as CSV: $_"
            return @()

        }

    }
}

class DRMMJobComponent : DRMMObject {

    [guid]$Uid
    [string]$Name
    [DRMMJobComponentVariable[]]$Variables

    DRMMJobComponent() : base() {

    }

    static [DRMMJobComponent] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Component = [DRMMJobComponent]::new()
        $Component.Uid = [DRMMObject]::GetValue($Response, 'uid')
        $Component.Name = [DRMMObject]::GetValue($Response, 'name')
        
        if ($Response.variables) {

            $Component.Variables = $Response.variables | ForEach-Object {

                [DRMMJobComponentVariable]::FromAPIMethod($_)

            }
        }

        return $Component

    }
}

class DRMMJobComponentResult : DRMMObject {

    [guid]$ComponentUid
    [string]$ComponentName
    [string]$ComponentStatus
    [int]$NumberOfWarnings
    [bool]$HasStdOut
    [bool]$HasStdErr

    DRMMJobComponentResult() : base() {

    }

    static [DRMMJobComponentResult] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Result = [DRMMJobComponentResult]::new()
        $Result.ComponentUid = [DRMMObject]::GetValue($Response, 'componentUid')
        $Result.ComponentName = [DRMMObject]::GetValue($Response, 'componentName')
        $Result.ComponentStatus = [DRMMObject]::GetValue($Response, 'componentStatus')
        $Result.NumberOfWarnings = [DRMMObject]::GetValue($Response, 'numberOfWarnings')
        $Result.HasStdOut = [DRMMObject]::GetValue($Response, 'hasStdOut')
        $Result.HasStdErr = [DRMMObject]::GetValue($Response, 'hasStdErr')

        return $Result

    }
}

class DRMMJobComponentVariable : DRMMObject {

    [string]$Name
    [string]$Value

    DRMMJobComponentVariable() : base() {

    }

    static [DRMMJobComponentVariable] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Variable = [DRMMJobComponentVariable]::new()
        $Variable.Name = [DRMMObject]::GetValue($Response, 'name')
        $Variable.Value = [DRMMObject]::GetValue($Response, 'value')

        return $Variable

    }
}

class DRMMJobResults : DRMMObject {

    [guid]$JobUid
    [guid]$DeviceUid
    [Nullable[datetime]]$RanOn
    [string]$JobDeploymentStatus
    [DRMMJobComponentResult[]]$ComponentResults

    DRMMJobResults() : base() {

    }

    static [DRMMJobResults] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Results = [DRMMJobResults]::new()
        $Results.JobUid = [DRMMObject]::GetValue($Response, 'jobUid')
        $Results.DeviceUid = [DRMMObject]::GetValue($Response, 'deviceUid')
        $Results.JobDeploymentStatus = [DRMMObject]::GetValue($Response, 'jobDeploymentStatus')

        $RanOnValue = [DRMMObject]::GetValue($Response, 'ranOn')
        $Results.RanOn = ([DRMMObject]::ParseApiDate($RanOnValue)).DateTime

        if ($Response.componentResults) {

            $Results.ComponentResults = $Response.componentResults | ForEach-Object {

                [DRMMJobComponentResult]::FromAPIMethod($_)

            }

        }

        return $Results

    }
}

class DRMMJobStdData : DRMMObject {

    [guid]$JobUid
    [guid]$DeviceUid
    [guid]$ComponentUid
    [string]$ComponentName
    [string]$StdData

    DRMMJobStdData() : base() {

    }

    static [DRMMJobStdData] FromAPIMethod([pscustomobject]$Response, [guid]$JobUid, [guid]$DeviceUid) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Result = [DRMMJobStdData]::new()
        $Result.JobUid = $JobUid
        $Result.DeviceUid = $DeviceUid
        $Result.ComponentUid = [DRMMObject]::GetValue($Response, 'componentUid')
        $Result.ComponentName = [DRMMObject]::GetValue($Response, 'componentName')
        $Result.StdData = [DRMMObject]::GetValue($Response, 'stdData')

        return $Result

    }
}

class DRMMNetMapping : DRMMObject {

    [long]$Id
    [guid]$Uid
    [string]$AccountUid
    [string]$Name
    [string]$Description
    [long[]]$DatatoNetworkingNetworkIds
    [string]$PortalUrl

    DRMMNetMapping() : base() {

        $this.DatatoNetworkingNetworkIds = @()

    }

    static [DRMMNetMapping] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $NetMapping = [DRMMNetMapping]::new()
        $NetMapping.Id = $Response.id
        $NetMapping.Uid = $Response.uid
        $NetMapping.AccountUid = $Response.accountUid
        $NetMapping.Name = $Response.name
        $NetMapping.Description = $Response.description
        $NetMapping.PortalUrl = $Response.portalUrl
        
        if ($Response.dattoNetworkingNetworkIds) {

            $NetMapping.DatatoNetworkingNetworkIds = $Response.dattoNetworkingNetworkIds

        }

        return $NetMapping

    }

    [void] OpenPortal() {

        if ($this.PortalUrl) {

            Start-Process $this.PortalUrl

        } else {

            Write-Warning "Portal URL is not available for site $($this.Name)"

        }
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

class DRMMSite : DRMMObject {

    [long]$Id
    [string]$Uid
    [string]$AccountUid
    [string]$Name
    [string]$Description
    [string]$Notes
    [bool]$OnDemand
    [bool]$SplashtopAutoInstall
    [DRMMSiteProxySettings]$ProxySettings
    [DRMMDevicesStatus]$DevicesStatus
    [DRMMSiteSettings]$SiteSettings
    [DRMMVariable[]]$Variables
    [object]$Filters  # Placeholder for filters data
    [string]$AutotaskCompanyName
    [string]$AutotaskCompanyId
    [string]$PortalUrl

    DRMMSite() : base() {

    }

    static [DRMMSite] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Site = [DRMMSite]::new()
        $Site.Id = $Response.id
        $Site.Uid = $Response.uid
        $Site.AccountUid = $Response.accountUid
        $Site.Name = $Response.name
        $Site.Description = $Response.description
        $Site.Notes = $Response.notes
        $Site.OnDemand = $Response.onDemand
        $Site.SplashtopAutoInstall = $Response.splashtopAutoInstall
        $Site.AutotaskCompanyName = $Response.autotaskCompanyName
        $Site.AutotaskCompanyId = $Response.autotaskCompanyId
        $Site.PortalUrl = $Response.portalUrl

        $ProxySettingsResponse = $Response.proxySettings

        if ($ProxySettingsResponse) {

            $Site.ProxySettings = [DRMMSiteProxySettings]::FromAPIMethod($ProxySettingsResponse)

        }

        $DevicesStatusResponse = $Response.devicesStatus

        if ($DevicesStatusResponse) {

            $Site.DevicesStatus = [DRMMDevicesStatus]::FromAPIMethod($DevicesStatusResponse)

        }

        $SiteSettingsResponse = $Response.siteSettings

        if ($SiteSettingsResponse) {

            $Site.SiteSettings = [DRMMSiteSettings]::FromAPIMethod($SiteSettingsResponse)

        }

        return $Site

    }

    [string] GetSummary() {

        $DeviceCount = if ($this.DevicesStatus -and $null -ne $this.DevicesStatus.NumberOfDevices) {"$($this.DevicesStatus.NumberOfDevices)"} else {'0'}

        return "$($this.Name) ($($this.Uid)) - Devices: $DeviceCount"

    }

    [DRMMSite] Set([hashtable]$Properties) {

        if (-not (Get-Command -Name Set-RMMSite -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        $params = @{
            Site = $this
            Force = $true
        }

        foreach ($key in $Properties.Keys) {

            $params[$key] = $Properties[$key]

        }

        return Set-RMMSite @params

    }

    [DRMMAlert[]] GetAlerts() {

        if (-not (Get-Command -Name Get-RMMAlert -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Get-RMMAlert -SiteUid $this.Uid -Status 'All'

    }

    [DRMMAlert[]] GetAlerts([string]$Status) {

        if (-not (Get-Command -Name Get-RMMAlert -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Get-RMMAlert -SiteUid $this.Uid -Status $Status

    }

    [void] OpenPortal() {

        if ($this.PortalUrl) {

            Start-Process $this.PortalUrl

        } else {

            Write-Warning "Portal URL is not available for site $($this.Name)"

        }
    }

    # Device Management Methods
    [DRMMDevice[]] GetDevices() {

        if (-not (Get-Command -Name Get-RMMDevice -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        $result = Get-RMMDevice -SiteUid $this.Uid

        if ($null -eq $result) {

            return @()

        }

        return $result

    }

    [DRMMDevice[]] GetDevices([long]$FilterId) {

        if (-not (Get-Command -Name Get-RMMDevice -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Get-RMMDevice -SiteUid $this.Uid -FilterId $FilterId

    }

    [int] GetDeviceCount() {

        if ($this.DevicesStatus -and $null -ne $this.DevicesStatus.NumberOfDevices) {

            return $this.DevicesStatus.NumberOfDevices

        }

        return 0

    }

    # Variable Management Methods
    [DRMMVariable[]] GetVariables() {

        if (-not (Get-Command -Name Get-RMMVariable -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Get-RMMVariable -SiteUid $this.Uid

    }

    [DRMMVariable] GetVariable([string]$Name) {

        if (-not (Get-Command -Name Get-RMMVariable -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Get-RMMVariable -SiteUid $this.Uid -Name $Name

    }

    [DRMMVariable] NewVariable([string]$Name, [string]$Value) {

        if (-not (Get-Command -Name New-RMMVariable -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return New-RMMVariable -SiteUid $this.Uid -Name $Name -Value $Value -Force

    }

    [DRMMVariable] NewVariable([string]$Name, [string]$Value, [bool]$Masked) {

        if (-not (Get-Command -Name New-RMMVariable -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return New-RMMVariable -SiteUid $this.Uid -Name $Name -Value $Value -Masked:$Masked -Force

    }

    # Filter Management Methods
    [DRMMFilter[]] GetFilters() {

        if (-not (Get-Command -Name Get-RMMDeviceFilter -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        $result = Get-RMMDeviceFilter -SiteUid $this.Uid

        if ($null -eq $result) {

            return @()

        }

        return $result

    }

    [DRMMFilter] GetFilter([string]$Name) {

        if (-not (Get-Command -Name Get-RMMDeviceFilter -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Get-RMMDeviceFilter -SiteUid $this.Uid -Name $Name

    }

    [DRMMSiteSettings] GetSettings() {

        if (-not (Get-Command -Name Get-RMMSiteSettings -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Get-RMMSiteSettings -SiteUid $this.Uid

    }

    [DRMMSiteSettings] SetProxy([string]$ProxyHost, [int]$Port, [string]$Type) {

        if (-not (Get-Command -Name Set-RMMSiteProxy -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Set-RMMSiteProxy -SiteUid $this.Uid -Host $ProxyHost -Port $Port -Type $Type -Force

    }

    [DRMMSiteSettings] SetProxy([string]$ProxyHost, [int]$Port, [string]$Type, [string]$Username, [SecureString]$Password) {

        if (-not (Get-Command -Name Set-RMMSiteProxy -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Set-RMMSiteProxy -SiteUid $this.Uid -Host $ProxyHost -Port $Port -Type $Type -Username $Username -Password $Password -Force

    }

    [DRMMSiteSettings] RemoveProxy() {

        if (-not (Get-Command -Name Remove-RMMSiteProxy -ErrorAction SilentlyContinue)) {

            [DRMMObject]::ThrowMissingHelperError()

        }

        return Remove-RMMSiteProxy -SiteUid $this.Uid -Force

    }
}

class DRMMSiteGeneralSettings : DRMMObject {

    [string]$Name
    [string]$Uid
    [string]$Description
    [bool]$OnDemand

    DRMMSiteGeneralSettings() : base() {}

    static [DRMMSiteGeneralSettings] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Settings = [DRMMSiteGeneralSettings]::new()
        $Settings.Name = $Response.name
        $Settings.Uid = $Response.uid
        $Settings.Description = $Response.description
        $Settings.OnDemand = $Response.onDemand

        return $Settings

    }

    [string] GetSummary() {

        return "OnDemand: $($this.OnDemand)"

    }
}

class DRMMSiteMailRecipient : DRMMObject {

    [string]$Name
    [string]$Email
    [string]$Type

    DRMMSiteMailRecipient() : base() {}

    static [DRMMSiteMailRecipient] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Recipient = [DRMMSiteMailRecipient]::new()
        $Recipient.Name = $Response.name
        $Recipient.Email = $Response.email
        $Recipient.Type = $Response.type

        return $Recipient

    }
}

class DRMMSiteProxySettings : DRMMObject {

    [string]$Host
    [string]$Username
    [securestring]$Password
    [int]$Port
    [string]$Type

    DRMMSiteProxySettings() : base() {

    }

    static [DRMMSiteProxySettings] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

            $ProxySettings = [DRMMSiteProxySettings]::new()
            $ProxySettings.Host = $Response.host
            $ProxySettings.Username = $Response.username
            $RawPassword = $Response.password

        if ($RawPassword -is [securestring]) {

            $ProxySettings.Password = $RawPassword

        } elseif ($RawPassword -is [string] -and $RawPassword.Length -gt 0) {

            $ProxySettings.Password = ConvertTo-SecureString -String $RawPassword -AsPlainText -Force

        } else {

            $ProxySettings.Password = $null

        }

        $ProxySettings.Port = $Response.port
        $ProxySettings.Type = $Response.type

        return $ProxySettings

    }

    [string] GetSummary() {

        $ProxyInfo = if ($this.Host) {"$($this.Type)://$($this.Host)$(if ($this.Port) {":$($this.Port)"})"} else {$null}
        return $ProxyInfo

    }
}

class DRMMSiteSettings : DRMMObject {

    [DRMMSiteGeneralSettings]$GeneralSettings
    [DRMMSiteProxySettings]$ProxySettings  # Reuse existing class
    [DRMMSiteMailRecipient[]]$MailRecipients
    [guid]$SiteUid

    DRMMSiteSettings() : base() {

    }

    static [DRMMSiteSettings] FromAPIMethod([pscustomobject]$Response, $SiteUid) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Settings = [DRMMSiteSettings]::new()

        if ($Response.generalSettings) {

            $Settings.GeneralSettings = [DRMMSiteGeneralSettings]::FromAPIMethod($Response.generalSettings)

        } else {

            $Settings.GeneralSettings = $null

        }

        if ($Response.proxySettings) {

            $Settings.ProxySettings = [DRMMSiteProxySettings]::FromAPIMethod($Response.proxySettings)
            
        } else {

            $Settings.ProxySettings = $null

        }

        $Settings.MailRecipients = $Response.mailRecipients | ForEach-Object {[DRMMSiteMailRecipient]::FromAPIMethod($_)}
        $Settings.SiteUid = $SiteUid
        
        return $Settings
    }

    [string] GetSummary() {

        $GeneralInfo = if ($this.GeneralSettings) { "OnDemand: $($this.GeneralSettings.OnDemand)" } else { "OnDemand: -" }
        $ProxyInfo = if ($this.ProxySettings) { " | Proxy: $($this.ProxySettings.GetSummary())" } else { " | Proxy: -" }
        $MailCount = if ($this.MailRecipients) { " | Mail Recipients: $($this.MailRecipients.Count)" } else { " | Mail Recipients: 0" }

        return "$GeneralInfo$ProxyInfo$MailCount"

    }    
}

class DRMMStatus : DRMMObject {

    [string]$Version
    [string]$Status
    [Nullable[datetime]]$Started

    DRMMStatus() : base() {

    }

    static [DRMMStatus] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Result = [DRMMStatus]::new()
        $Result.Version = [DRMMObject]::GetValue($Response, 'version')
        $Result.Status = [DRMMObject]::GetValue($Response, 'status')
        
        $StartedValue = [DRMMObject]::GetValue($Response, 'started')

        if ($null -ne $StartedValue) {
            
            try {

                $Result.Started = [datetime]::Parse($StartedValue)

            } catch {

                $Result.Started = $null

            }
        }

        return $Result

    }
}

class DRMMUser : DRMMObject {

    [string]$FirstName
    [string]$LastName
    [string]$Username
    [string]$Email
    [string]$Telephone
    [string]$Status
    [Nullable[datetime]]$Created
    [Nullable[datetime]]$LastAccess
    [bool]$Disabled

    DRMMUser() : base() {

    }

    static [DRMMUser] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $User = [DRMMUser]::new()
        $User.FirstName = $Response.firstName
        $User.LastName = $Response.lastName
        $User.Username = $Response.username
        $User.Email = $Response.email
        $User.Telephone = $Response.telephone
        $User.Status = $Response.status
        $User.Disabled = $Response.disabled

        $User.Created = ([DRMMObject]::ParseApiDate($Response.created)).DateTime
        $User.LastAccess = ([DRMMObject]::ParseApiDate($Response.lastAccess)).DateTime

        return $User

    }

    [string] GetFullName() {

        return "$($this.FirstName) $($this.LastName)".Trim()

    }

    [string] GetSummary() {

        $FullName = $this.GetFullName()
        $StatusText = if ($this.Disabled) {" (Disabled)"} else {""}

        return "$FullName ($($this.Username))$StatusText"

    }
}

class DRMMVariable : DRMMObject {

    [long]$Id
    [string]$Name
    [object]$Value
    [string]$Scope
    [Nullable[guid]]$SiteUid
    [bool]$IsSecret

    DRMMVariable() : base() {

    }

    static [DRMMVariable] FromAPIMethod([pscustomobject]$Response, [string]$Scope, [Nullable[guid]]$SiteUid) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Variable = [DRMMVariable]::new()
        $Variable.Id = $Response.id
        $Variable.Name = $Response.name
        $Variable.Value = $Response.value
        $Variable.IsSecret = $Response.masked
        $Variable.Scope = $Scope
        $Variable.SiteUid = $SiteUid

        return $Variable

    }

    [bool] IsGlobal() { return ($this.Scope -eq 'Global') }
    [bool] IsSite()   { return ($this.Scope -eq 'Site') }

    [string] GetSummary() {

        # API already returns masked values for secret variables
        $ScopeValue = if ($this.Scope) { $this.Scope } else { 'Global' }

        return "$($this.Name) [$ScopeValue] = $($this.Value)"

    }
}