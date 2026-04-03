using module '..\DRMMObject\DRMMObject.psm1'

<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Represents an account in the DRMM system, including its properties and related information.
.DESCRIPTION
    The DRMMAccount class models an account within the DRMM platform, encapsulating properties such as the account ID, unique identifier, name, currency, and related descriptors and device status. It provides a static method to create an instance of the class from a typical API response object that contains account information. The class also includes a method to generate a summary string that combines the account name with its device status for easy display. The DRMMAccountDescriptor and DRMMAccountDevicesStatus classes represent related information about the account, such as billing details and device status, respectively.
.LINK
    Get-RMMAccount
#>
class DRMMAccount : DRMMObject {

    # The unique identifier for the account.
    [int]$Id
    # The unique identifier string for the account.
    [string]$Uid
    # The name of the account.
    [string]$Name
    # The currency associated with the account, typically represented as a three-letter ISO currency code.
    [string]$Currency
    # An instance of the DRMMAccountDescriptor class that provides additional details about the account, such as billing email, device limit, and time zone.
    [DRMMAccountDescriptor]$Descriptor
    # An instance of the DRMMAccountDevicesStatus class that provides information about the number of devices associated with the account and their status (online, offline, on-demand, managed).
    [DRMMAccountDevicesStatus]$DevicesStatus

    DRMMAccount() : base() {

    }

    static [DRMMAccount] FromAPIMethod([pscustomobject]$Response) {

        $Account = [DRMMAccount]::new()

        $Account.Id = $Response.id
        $Account.Uid = $Response.uid
        $Account.Name = $Response.name
        $Account.Currency = $Response.currency

        # Parse descriptor
        $DescriptorData = $Response.descriptor

        if ($null -ne $DescriptorData) {

            $Account.Descriptor = [DRMMAccountDescriptor]::FromAPIMethod($DescriptorData)

        }

        # Parse devices status
        $DevicesStatusData = $Response.devicesStatus

        if ($null -ne $DevicesStatusData) {

            $Account.DevicesStatus = [DRMMAccountDevicesStatus]::FromAPIMethod($DevicesStatusData)

        }

        return $Account

    }

    <#
    .SYNOPSIS
        Generates a summary string for the account, including its name and device status.
    .DESCRIPTION
        The GetSummary method creates a concise summary of the account by combining its name with a summary of its device status. If device status information is available, it includes the number of online devices and the total number of devices. If device status information is not available, it indicates that there is no device status information. Used in TypeName properties and other display contexts to provide a quick overview of the account's status.
    .OUTPUTS
        A summary string combining the account name and device status.
    #>
    [string] GetSummary() {

        $DeviceInfo = if ($this.DevicesStatus) { $this.DevicesStatus.GetSummary() } else { 'No device status' }

        return "$($this.Name) - $DeviceInfo"

    }
}

<#
.SYNOPSIS
    Represents the descriptor information for a DRMM account, including billing and timezone details.
.DESCRIPTION
    The DRMMAccountDescriptor class encapsulates details about a DRMM account's billing email, device limit, and time zone. It provides a static method to create an instance of the class from a typical API response object that contains these descriptor details. This class is used as a property within the DRMMAccount class to provide additional information about the account's configuration and limitations.
.LINK
    Get-RMMAccount
#>
class DRMMAccountDescriptor : DRMMObject {

    # The billing email address associated with the account.
    [string]$BillingEmail
    # The maximum number of devices allowed for the account.
    [int]$DeviceLimit
    # The time zone setting for the account.
    [string]$TimeZone

    DRMMAccountDescriptor() : base() {

    }

    static [DRMMAccountDescriptor] FromAPIMethod([pscustomobject]$Response) {

        $Descriptor = [DRMMAccountDescriptor]::new()

        $Descriptor.BillingEmail = $Response.bilingEmail
        $Descriptor.DeviceLimit = $Response.deviceLimit
        $Descriptor.TimeZone = $Response.timeZone

        return $Descriptor

    }
}

<#
.SYNOPSIS
    Represents the device status information for a DRMM account, including counts of devices in various states.
.DESCRIPTION
    The DRMMAccountDevicesStatus class encapsulates information about the number of devices associated with a DRMM account, including the total number of devices, the number of online devices, offline devices, on-demand devices, and managed devices. It provides a static method to create an instance of the class from a typical API response object that contains these device status details. The class also includes methods to calculate the percentage of online devices and to generate a summary string that combines this information for easy display. This class is used as a property within the DRMMAccount class to provide insights into the account's device status.
.LINK
    Get-RMMAccount
#>
class DRMMAccountDevicesStatus : DRMMObject {

    # The total number of devices associated with the account.
    [int]$NumberOfDevices
    # The number of devices that are currently online.
    [int]$NumberOfOnlineDevices
    # The number of devices that are currently offline.
    [int]$NumberOfOfflineDevices
    # The number of devices that are on-demand.
    [int]$NumberOfOnDemandDevices
    # The number of devices that are managed within the account.
    [int]$NumberOfManagedDevices

    DRMMAccountDevicesStatus() : base() {

    }

    static [DRMMAccountDevicesStatus] FromAPIMethod([pscustomobject]$Response) {

        $Status = [DRMMAccountDevicesStatus]::new()

        $Status.NumberOfDevices = $Response.numberOfDevices
        $Status.NumberOfOnlineDevices = $Response.numberOfOnlineDevices
        $Status.NumberOfOfflineDevices = $Response.numberOfOfflineDevices
        $Status.NumberOfOnDemandDevices = $Response.numberOfOnDemandDevices
        $Status.NumberOfManagedDevices = $Response.numberOfManagedDevices

        return $Status

    }

    <#
    .SYNOPSIS
        Calculates the percentage of online devices for the account.
    .DESCRIPTION
        The GetOnlinePercentage method computes the percentage of devices that are currently online out of the total number of devices associated with the account. It handles cases where the total number of devices is zero to avoid division by zero errors, returning 0% in such cases. The result is rounded to two decimal places for readability. This method provides a quick metric for understanding the online status of the account's devices.
    .OUTPUTS
        The percentage of online devices as a double value.
    #>
    [double] GetOnlinePercentage() {

        if ($this.NumberOfDevices -eq 0) {

            return 0

        }

        return [Math]::Round(($this.NumberOfOnlineDevices / $this.NumberOfDevices) * 100, 2)

    }

    <#
    .SYNOPSIS
        Generates a summary string for the device status, including the count of online devices and total devices.
    .DESCRIPTION
        The GetSummary method creates a concise summary of the device status for the account by combining the number of online devices with the total number of devices. It also includes the percentage of online devices in parentheses for additional context. This summary is used in the GetSummary method of the DRMMAccount class to provide a quick overview of the account's device status.
    .OUTPUTS
        A summary string combining the count of online devices and total devices.
    #>
    [string] GetSummary() {

        return "$($this.NumberOfOnlineDevices)/$($this.NumberOfDevices) online ($($this.GetOnlinePercentage())%)"

    }
}