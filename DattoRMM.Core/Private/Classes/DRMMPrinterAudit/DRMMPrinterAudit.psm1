using module '..\DRMMNetworkInterface\DRMMNetworkInterface.psm1'
<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '..\DRMMObject\DRMMObject.psm1'
<#
.SYNOPSIS
    Represents the audit information of a printer, including SNMP info, marker supplies, printer details, system info, and network interfaces.
.DESCRIPTION
    The DRMMPrinterAudit class encapsulates detailed information about a printer, such as its unique identifier, portal URL, SNMP information, marker supplies, printer details, system information, and network interfaces. This class is typically used to represent the results of a printer audit operation within the DRMM system.
#>
class DRMMPrinter : DRMMObject {

    # The total number of pages printed by the printer.
    [Nullable[long]]$PrintedPageCount

    DRMMPrinter() : base() {

    }

    static [DRMMPrinter] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Printer = [DRMMPrinter]::new()
        $Printer.PrintedPageCount = $Response.printedPageCount

        return $Printer

    }
}

<#
.SYNOPSIS
    Represents the audit information of a printer, including SNMP info, marker supplies, printer details, system info, and network interfaces.
.DESCRIPTION
    The DRMMPrinterAudit class encapsulates detailed information about a printer, such as its unique identifier, portal URL, SNMP information, marker supplies, printer details, system information, and network interfaces. This class is typically used to represent the results of a printer audit operation within the DRMM system.
#>
class DRMMPrinterAudit : DRMMObject {

    # The unique identifier (UID) of the device.
    [guid]$DeviceUid
    # The URL of the portal.
    [string]$PortalUrl
    # The SNMP information of the printer.
    [DRMMPrinterSnmpInfo]$SnmpInfo
    # The marker supplies of the printer.
    [DRMMPrinterMarkerSupply[]]$PrinterMarkerSupplies
    # The printer associated with the audit.
    [DRMMPrinter]$Printer
    # The system information of the printer.
    [DRMMPrinterSystemInfo]$SystemInfo
    # The network interfaces of the printer.
    [DRMMNetworkInterface[]]$Nics

    DRMMPrinterAudit() : base() {

    }

    static [DRMMPrinterAudit] FromAPIMethod([pscustomobject]$Response, [guid]$DeviceUid) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Audit = [DRMMPrinterAudit]::new()
        $Audit.DeviceUid = $DeviceUid
        $Audit.PortalUrl = $Response.portalUrl

        # SNMP info
        $SnmpInfoData = $Response.snmpInfo
        if ($null -ne $SnmpInfoData) {

            $Audit.SnmpInfo = [DRMMPrinterSnmpInfo]::FromAPIMethod($SnmpInfoData)

        }

        # Printer marker supplies
        $SuppliesData = $Response.printerMarkerSupplies
        if ($null -ne $SuppliesData -and $SuppliesData.Count -gt 0) {

            $Audit.PrinterMarkerSupplies = @($SuppliesData | ForEach-Object { [DRMMPrinterMarkerSupply]::FromAPIMethod($_) })

        }

        # Printer
        $PrinterData = $Response.printer
        if ($null -ne $PrinterData) {

            $Audit.Printer = [DRMMPrinter]::FromAPIMethod($PrinterData)

        }

        # System info
        $SystemInfoData = $Response.systemInfo
        if ($null -ne $SystemInfoData) {

            $Audit.SystemInfo = [DRMMPrinterSystemInfo]::FromAPIMethod($SystemInfoData)

        }

        # Network interfaces
        $NicsData = $Response.nics
        if ($null -ne $NicsData -and $NicsData.Count -gt 0) {

            $Audit.Nics = @($NicsData | ForEach-Object { [DRMMNetworkInterface]::FromAPIMethod($_) })

        }

        return $Audit

    }
}

<#
.SYNOPSIS
    Represents the marker supply information of a printer, including description, maximum capacity, and supply level.
.DESCRIPTION
    The DRMMPrinterMarkerSupply class models the information about the marker supplies of a printer. It includes properties such as Description, MaxCapacity, and SuppliesLevel, which provide details about the printer's consumable supplies (e.g., ink or toner levels). This class is typically used as part of the DRMMPrinterAudit to represent the status of the printer's marker supplies.
#>
class DRMMPrinterMarkerSupply : DRMMObject {

    # The description of the printer's marker supply.
    [string]$Description
    # The maximum capacity of the printer's marker supply.
    [string]$MaxCapacity
    # The current supply level of the printer's marker supply.
    [string]$SuppliesLevel

    DRMMPrinterMarkerSupply() : base() {

    }

    static [DRMMPrinterMarkerSupply] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Supply = [DRMMPrinterMarkerSupply]::new()
        $Supply.Description = $Response.description
        $Supply.MaxCapacity = $Response.maxCapacity
        $Supply.SuppliesLevel = $Response.suppliesLevel

        return $Supply

    }
}

<#
.SYNOPSIS
    Represents the SNMP information of a printer, including SNMP name, contact, description, location, uptime, NIC manufacturer, object ID, and serial number.
.DESCRIPTION
    The DRMMPrinterSnmpInfo class models the SNMP-related information of a printer. It includes properties such as SnmpName, SnmpContact, SnmpDescription, SnmpLocation, SnmpUptime, NicManufacturer, ObjectId, and SnmpSerial. This class is typically used as part of the DRMMPrinterAudit to represent the SNMP details of the printer.
#>
class DRMMPrinterSnmpInfo : DRMMObject {

    # The name of the printer as reported by SNMP.
    [string]$SnmpName
    # The contact information for SNMP communication with the printer.
    [string]$SnmpContact
    # The description of the SNMP configuration for the printer.
    [string]$SnmpDescription
    # The physical location of the printer as reported by SNMP.
    [string]$SnmpLocation
    # The uptime of the printer as reported by SNMP.
    [string]$SnmpUptime
    # The manufacturer of the network interface card (NIC) used for SNMP communication.
    [string]$NicManufacturer
    # The SNMP object identifier (OID) associated with the printer.
    [string]$ObjectId
    # The serial number of the printer as reported by SNMP.
    [string]$SnmpSerial

    DRMMPrinterSnmpInfo() : base() {

    }

    static [DRMMPrinterSnmpInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Snmp = [DRMMPrinterSnmpInfo]::new()
        $Snmp.SnmpName = $Response.snmpName
        $Snmp.SnmpContact = $Response.snmpContact
        $Snmp.SnmpDescription = $Response.snmpDescription
        $Snmp.SnmpLocation = $Response.snmpLocation
        $Snmp.SnmpUptime = $Response.snmpUptime
        $Snmp.NicManufacturer = $Response.nicManufacturer
        $Snmp.ObjectId = $Response.objectId
        $Snmp.SnmpSerial = $Response.snmpSerial

        return $Snmp

    }
}

<#
.SYNOPSIS
    Represents the system information of a printer, including manufacturer and model.
.DESCRIPTION
    The DRMMPrinterSystemInfo class models the system-related information of a printer. It includes properties such as Manufacturer and Model. This class is typically used as part of the DRMMPrinterAudit to represent the system details of the printer.
#>
class DRMMPrinterSystemInfo : DRMMObject {

    # The manufacturer of the printer.
    [string]$Manufacturer
    # The model of the printer.
    [string]$Model

    DRMMPrinterSystemInfo() : base() {

    }

    static [DRMMPrinterSystemInfo] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $SystemInfo = [DRMMPrinterSystemInfo]::new()
        $SystemInfo.Manufacturer = $Response.manufacturer
        $SystemInfo.Model = $Response.model

        return $SystemInfo

    }
}
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBBrNDAEhPgNC6X
# bH8Knnk0ZCGK6kAVGLuLerk0aGaUwqCCA04wggNKMIICMqADAgECAhB464iXHfI6
# gksEkDDTyrNsMA0GCSqGSIb3DQEBCwUAMD0xFjAUBgNVBAoMDVJvYmVydCBGYWRk
# ZXMxIzAhBgNVBAMMGkRhdHRvUk1NLkNvcmUgQ29kZSBTaWduaW5nMB4XDTI2MDMz
# MTAwMTMzMFoXDTI4MDMzMTAwMjMzMFowPTEWMBQGA1UECgwNUm9iZXJ0IEZhZGRl
# czEjMCEGA1UEAwwaRGF0dG9STU0uQ29yZSBDb2RlIFNpZ25pbmcwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQChn1EpMYQgl1RgWzQj2+wp2mvdfb3UsaBS
# nxEVGoQ0gj96tJ2MHAF7zsITdUjwaflKS1vE6wAlOg5EI1V79tJCMxzM0bFpOdR1
# L5F2HE/ovIAKNkHxFUF5qWU8vVeAsOViFQ4yhHpzLen0WLF6vhmc9eH23dLQy5fy
# tELZQEc2WbQFa4HMAitP/P9kHAu6CUx5s4woLIOyyR06jkr3l9vk0sxcbCxx7+dF
# RrsSLyPYPH+bUAB8+a0hs+6qCeteBuUfLvGzpMhpzKAsY82WZ3Rd9X38i32dYj+y
# dYx+nx+UEMDLjDJrZgnVa8as4RojqVLcEns5yb/XTjLxDc58VatdAgMBAAGjRjBE
# MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU
# H+B0vf97dYXqdUX1YMcWhFsY6fcwDQYJKoZIhvcNAQELBQADggEBAJmD4EEGNmcD
# 1JtFoRGxuLJaTHxDwBsjqcRQRE1VPZNGaiwIm8oSQdHVjQg0oIyK7SEb02cs6n6Y
# NZbwf7B7WZJ4aKYbcoLug1k1x9SoqwBmfElECeJTKXf6dkRRNmrAodpGCixR4wMH
# KXqwqP5F+5j7bdnQPiIVXuMesxc4tktz362ysph1bqKjDQSCBpwi0glEIH7bv5Ms
# Ey9Gl3fe+vYC5W06d2LYVebEfm9+7766hsOgpdDVgdtnN+e6uwIJjG/6PTG6TMDP
# y+pr5K6LyUVYJYcWWUTZRBqqwBHiLGekPbxrjEVfxUY32Pq4QfLzUH5hhUCAk4HN
# XpF9pOzFLMUxggIDMIIB/wIBATBRMD0xFjAUBgNVBAoMDVJvYmVydCBGYWRkZXMx
# IzAhBgNVBAMMGkRhdHRvUk1NLkNvcmUgQ29kZSBTaWduaW5nAhB464iXHfI6gksE
# kDDTyrNsMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKEC
# gAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwG
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMVCfe4H6MumHCiG3QNvujAn86N0
# ZH3j4kkjbLYqmvyNMA0GCSqGSIb3DQEBAQUABIIBACCtE3JpuxunkCS+tovIL3pd
# OkDzxQ+/r0/ABBz0a1tTV+XslWNCrp5ESth9WNFNGsIzVaWqfUVrtwHv6xCp8BtG
# 1R5S58w2MppF9i7rzJRnYi+vSrFpS0ZgtTUj/HEG+dHqtex4NQmHETDVMCKw6ox9
# k7b/YNnHvkIAYI2AjhwNwm17pC6QSi5/OPbB0nIgwa2T8jPQvNchbtVboFgJ/wb+
# oSgSBEUpClLQSl5BpEpZSXi04WGBFVTZEGCHgktI7OiDmFcnoQNSd/cIBbQr9YMR
# HXJiSpxi8Keh6uQgcq6DWMHvp+VaG3k3K7e0F6yGWNFT5azkzMreww0tBz2WHJY=
# SIG # End signature block
