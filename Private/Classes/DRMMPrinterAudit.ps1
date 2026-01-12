using module '.\DRMMObject.psm1'
. $PSScriptRoot/DRMMNetworkInterface.ps1

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
