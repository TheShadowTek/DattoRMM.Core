<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '..\DRMMAlert\DRMMAlert.psm1'
using module '..\DRMMDevice\DRMMDevice.psm1'
using module '..\DRMMObject\DRMMObject.psm1'
<#
.SYNOPSIS
    Represents a filter in the DRMM system, including its name, description, type, and scope.
.DESCRIPTION
    The DRMMFilter class models a filter within the DRMM platform, encapsulating properties such as Id, FilterId, Name, Description, Type, Scope, SiteUid, DateCreate, LastUpdated, and PortalUrl. It provides a constructor and a static method to create an instance from API response data. The class also includes methods to determine if the filter is global or site-specific, as well as a method to generate a summary string of the filter's information. Additionally, it includes methods to retrieve devices and alerts associated with the filter.
    
    For site-scoped filters, the DRMMSiteFilter subclass extends this class with a Site property that provides full context about the associated site.
#>
class DRMMFilter : DRMMObject {

    # The identifier of the filter.
    [long]$Id
    # The unique identifier of the filter.
    [long]$FilterId
    # The name of the filter.
    [string]$Name
    # A brief description of the filter's purpose or criteria.
    [string]$Description
    # The type or category of the filter.
    [string]$Type
    # The scope or context in which the filter is applied.
    [string]$Scope
    # The unique identifier of the site associated with the filter.
    [Nullable[guid]]$SiteUid
    # The date and time when the filter was created.
    [Nullable[datetime]]$DateCreate
    # The date and time when the filter was last updated.
    [Nullable[datetime]]$LastUpdated
    # The URL to access the filter results in the Datto RMM web portal.
    [string]$PortalUrl

    DRMMFilter() : base() {

    }

    static [DRMMFilter] FromAPIMethod([pscustomobject]$Response, [string]$Scope, [string]$Platform) {

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
        $Filter.PortalUrl = "https://$($Platform.ToLower()).rmm.datto.com/device-filter-results/$($Filter.Id)"

        $CreateDate = [DRMMObject]::ParseApiDate($Response.dateCreate)
        $Filter.DateCreate = $CreateDate.DateTime

        $UpdatedDate = [DRMMObject]::ParseApiDate($Response.lastUpdated)
        $Filter.LastUpdated = $UpdatedDate.DateTime

        return $Filter

    }

    <#
    .SYNOPSIS
        Determines if the variable is global in scope.
    .DESCRIPTION
        The IsGlobal method checks the Scope property of the variable to determine if it is global in scope. It returns true if the Scope is equal to 'Global', and false otherwise.
    .OUTPUTS
        A boolean value indicating whether the filter is global in scope.
    #>
    [bool] IsGlobal() {
        
        return ($this.Scope -eq 'Global')
    
    }

    <#
    .SYNOPSIS
        Determines if the variable is site-specific in scope.
    .DESCRIPTION
        The IsSite method checks the Scope property of the variable to determine if it is site-specific in scope. It returns true if the Scope is equal to 'Site', and false otherwise.
    .OUTPUTS
        A boolean value indicating whether the filter is site-specific in scope.
    #>
    [bool] IsSite() {
        
        return ($this.Scope -eq 'Site')
    
    }

    <#
    .SYNOPSIS
        Determines if the filter is the default type.
    .DESCRIPTION
        The IsDefault method checks the Type property of the filter to determine if it is the default type. It returns true if the Type is equal to 'rmm_default', and false otherwise.
    .OUTPUTS
        A boolean value indicating whether the filter is the default type.
    #>
    [bool] IsDefault() {
        
        return ($this.Type -eq 'rmm_default')
    
    }

    <#
    .SYNOPSIS
        Determines if the filter is a custom type.
    .DESCRIPTION
        The IsCustom method checks the Type property of the filter to determine if it is a custom type. It returns true if the Type is equal to 'custom', and false otherwise.
    .OUTPUTS
        A boolean value indicating whether the filter is a custom type.
    #>
    [bool] IsCustom() {
        
        return ($this.Type -eq 'custom')
    
    }

    <#
    .SYNOPSIS
        Opens the portal URL associated with the filter in the default web browser.
    .DESCRIPTION
        The OpenPortal method launches the portal URL associated with the filter using the default web browser. If the portal URL is not available, a warning is displayed.
    .OUTPUTS
        This method does not return a value. It performs an action to open the portal URL in the default web browser.
    #>
    [void] OpenPortal() {

        if ($this.PortalUrl) {

            Start-Process $this.PortalUrl

        } else {

            Write-Warning "Portal URL is not available for filter $($this.Name)"

        }
    }

    <#
    .SYNOPSIS
        Generates a summary string for the filter, including its name, scope, and type.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the filter's name, scope, and type. If the Scope property is not set, it defaults to 'Global'. If the Type property is not set, it defaults to '-'.
    .OUTPUTS
        A summary string that includes the filter's name, scope, and type.
    #>
    [string] GetSummary() {

        if ($this.Scope) {

            $ScopeValue = $this.Scope

        } else {

            $ScopeValue = 'Global'

        }

        if ($this.Type) {

            $TypeValue = $this.Type

        } else {

            $TypeValue = '-'

        }

        return "$($this.Name) [$ScopeValue]$TypeValue"

    }

    <#
    .SYNOPSIS
        Retrieves the devices associated with the filter.
    .DESCRIPTION
        The GetDevices method returns an array of DRMMDevice objects associated with the filter. If the filter is site-specific, it retrieves devices for the specified site UID and filter ID. Otherwise, it retrieves devices based on the filter ID alone.
    .OUTPUTS
        A list of devices associated with the filter.
    #>
    [DRMMDevice[]] GetDevices() {

        if ($this.IsSite()) {

            return Get-RMMDevice -SiteUid $this.SiteUid -FilterId $this.FilterId

        } else {

            return Get-RMMDevice -FilterId $this.FilterId

        }
    }

    <#
    .SYNOPSIS
        Retrieves the count of devices associated with the filter.
    .DESCRIPTION
        The GetDeviceCount method returns the number of DRMMDevice objects associated with the filter by calling the GetDevices method and counting the results.
    .OUTPUTS
        The count of devices associated with the filter.
    #>
    [int] GetDeviceCount() {

        return $this.GetDevices().Count

    }

    <#
    .SYNOPSIS
        Retrieves the alerts associated with the filter.
    .DESCRIPTION
        The GetAlerts method returns an array of DRMMAlert objects associated with the filter. It retrieves alerts for each device associated with the filter, defaulting to 'Open' status.
    .OUTPUTS
        A list of alerts associated with the filter, optionally filtered by status.
    #>
    [DRMMAlert[]] GetAlerts() {

        $Devices = $this.GetDevices()
        $AllAlerts = @()

        foreach ($Device in $Devices) {

            $Alerts = Get-RMMAlert -DeviceUid $Device.Uid -Status 'Open'

            if ($Alerts) {

                $AllAlerts += $Alerts
            }
        }

        return $AllAlerts

    }

    <#
    .SYNOPSIS
        Retrieves the alerts associated with the filter.
    .DESCRIPTION
        The GetAlerts method returns an array of DRMMAlert objects associated with the filter. It retrieves alerts for each device associated with the filter, optionally filtered by status. The status parameter allows filtering alerts by their status (e.g., 'Open', 'Resolved', 'All').
    #>
    [DRMMAlert[]] GetAlerts([string]$Status) {

        $Devices = $this.GetDevices()
        $AllAlerts = @()

        foreach ($Device in $Devices) {

            $Alerts = Get-RMMAlert -DeviceUid $Device.Uid -Status $Status

            if ($Alerts) {

                $AllAlerts += $Alerts

            }
        }

        return $AllAlerts

    }
}
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBtiPKdp40hldkB
# eoYPUUaMAo/GcfLPP7uFGXvwsr83k6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILknU3pePkdrQ1S1yZbkXFjn90Jy
# z88wCHpf2Vi6wmo8MA0GCSqGSIb3DQEBAQUABIIBAAy+ifDbr57yhbWhUg16cT3L
# h4nszmuVAcWXhxtlzulmZsMc0ZwNQkIzLshjHDS6YITi31gJW4df3wu+OmuHLwjI
# gFhgy9mvY/nFVHu7FU0OKvOAo0Tr7Um7vScCJtOrBvz9mBqnXlcixr8IQ86WFptR
# PzLMBvRdAx1c0eWq6OdkBiVu542QjB2fjrc6U+ZeCxIhXes4GN1aqV3cvi2ZztVf
# GZA+dS00zhkpmXlhBxWaZeEvAZpArKazGQYYbeWOp81sJxYAPi5Q/REBx7XhspK7
# BA0achcu0AB/rMaGw5RjDarHdOEuh1PNY2sg/HIl6aBlyZX+H4Fcoj+Rpe1uuow=
# SIG # End signature block
