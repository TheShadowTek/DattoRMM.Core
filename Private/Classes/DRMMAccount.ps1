<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '.\DRMMObject.psm1'

class DRMMAccount : DRMMObject {

    [int]$Id
    [string]$Uid
    [string]$Name
    [string]$Currency
    [DRMMAccountDescriptor]$Descriptor
    [DRMMAccountDevicesStatus]$DevicesStatus

    DRMMAccount() : base() {

    }

    static [DRMMAccount] FromAPIMethod([pscustomobject]$Response) {

        $Account = [DRMMAccount]::new()

        $Account.Id = [DRMMObject]::GetValue($Response, 'id')
        $Account.Uid = [DRMMObject]::GetValue($Response, 'uid')
        $Account.Name = [DRMMObject]::GetValue($Response, 'name')
        $Account.Currency = [DRMMObject]::GetValue($Response, 'currency')

        # Parse descriptor
        $DescriptorData = [DRMMObject]::GetValue($Response, 'descriptor')

        if ($null -ne $DescriptorData) {

            $Account.Descriptor = [DRMMAccountDescriptor]::FromAPIMethod($DescriptorData)

        }

        # Parse devices status
        $DevicesStatusData = [DRMMObject]::GetValue($Response, 'devicesStatus')

        if ($null -ne $DevicesStatusData) {

            $Account.DevicesStatus = [DRMMAccountDevicesStatus]::FromAPIMethod($DevicesStatusData)

        }

        return $Account

    }

    [string] GetSummary() {

        $DeviceInfo = if ($this.DevicesStatus) { $this.DevicesStatus.GetSummary() } else { 'No device status' }

        return "$($this.Name) - $DeviceInfo"

    }
}

class DRMMAccountDescriptor : DRMMObject {

    [string]$BillingEmail
    [int]$DeviceLimit
    [string]$TimeZone

    DRMMAccountDescriptor() : base() {

    }

    static [DRMMAccountDescriptor] FromAPIMethod([pscustomobject]$Response) {

        $Descriptor = [DRMMAccountDescriptor]::new()

        $Descriptor.BillingEmail = [DRMMObject]::GetValue($Response, 'bilingEmail')
        $Descriptor.DeviceLimit = [DRMMObject]::GetValue($Response, 'deviceLimit')
        $Descriptor.TimeZone = [DRMMObject]::GetValue($Response, 'timeZone')

        return $Descriptor

    }
}

class DRMMAccountDevicesStatus : DRMMObject {

    [int]$NumberOfDevices
    [int]$NumberOfOnlineDevices
    [int]$NumberOfOfflineDevices
    [int]$NumberOfOnDemandDevices
    [int]$NumberOfManagedDevices

    DRMMAccountDevicesStatus() : base() {

    }

    static [DRMMAccountDevicesStatus] FromAPIMethod([pscustomobject]$Response) {

        $Status = [DRMMAccountDevicesStatus]::new()

        $Status.NumberOfDevices = [DRMMObject]::GetValue($Response, 'numberOfDevices')
        $Status.NumberOfOnlineDevices = [DRMMObject]::GetValue($Response, 'numberOfOnlineDevices')
        $Status.NumberOfOfflineDevices = [DRMMObject]::GetValue($Response, 'numberOfOfflineDevices')
        $Status.NumberOfOnDemandDevices = [DRMMObject]::GetValue($Response, 'numberOfOnDemandDevices')
        $Status.NumberOfManagedDevices = [DRMMObject]::GetValue($Response, 'numberOfManagedDevices')

        return $Status

    }

    [double] GetOnlinePercentage() {

        if ($this.NumberOfDevices -eq 0) {

            return 0

        }

        return [Math]::Round(($this.NumberOfOnlineDevices / $this.NumberOfDevices) * 100, 2)

    }

    [string] GetSummary() {

        return "$($this.NumberOfOnlineDevices)/$($this.NumberOfDevices) online ($($this.GetOnlinePercentage())%)"

    }
}
