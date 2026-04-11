@{

    'DRMMSite' = @{

        'Default' = @(
            'Id'
            'Uid'
            'Name'
            'Description'
            'OnDemand'
            @{Name = 'TotalDevices'; Path = 'DevicesStatus.NumberOfDevices'}
            @{Name = 'OnlineDevices'; Path = 'DevicesStatus.NumberOfOnlineDevices'}
            @{Name = 'OfflineDevices'; Path = 'DevicesStatus.NumberOfOfflineDevices'}
            'AutotaskCompanyName'
            'AutotaskCompanyId'
            'PortalUrl'
        )

        'Summary' = @(
            'Id'
            'Name'
            'Description'
            @{Name = 'TotalDevices'; Path = 'DevicesStatus.NumberOfDevices'}
            @{Name = 'OnlineDevices'; Path = 'DevicesStatus.NumberOfOnlineDevices'}
            @{Name = 'OfflineDevices'; Path = 'DevicesStatus.NumberOfOfflineDevices'}
        )
    }

    'DRMMDevice' = @{

        'Default' = @(
            'Id'
            'Uid'
            'SiteId'
            'SiteName'
            'Hostname'
            @{Name = 'DeviceCategory'; Path = 'DeviceType.Category'}
            @{Name = 'DeviceTypeName'; Path = 'DeviceType.Type'}
            'IntIpAddress'
            'ExtIpAddress'
            'OperatingSystem'
            'Domain'
            'LastLoggedInUser'
            'Online'
            'LastSeen'
            'RebootRequired'
            'Suspended'
            'Deleted'
            'WarrantyDate'
            @{Name = 'AntivirusProduct'; Path = 'Antivirus.AntivirusProduct'}
            @{Name = 'AntivirusStatus'; Path = 'Antivirus.AntivirusStatus'}
            @{Name = 'PatchStatus'; Path = 'PatchManagement.PatchStatus'}
            'PortalUrl'
        )

        'Summary' = @(
            'Id'
            'Hostname'
            'SiteName'
            'OperatingSystem'
            'Online'
            'LastSeen'
            'IntIpAddress'
        )
    }

    'DRMMAlert' = @{

        'Default' = @(
            'AlertUid'
            'Priority'
            'Diagnostics'
            'Resolved'
            'ResolvedBy'
            'ResolvedOn'
            'Muted'
            'TicketNumber'
            'Timestamp'
            @{Name = 'AlertContextClass'; Path = 'AlertContext.Class'}
            @{Name = 'MonitorSendsEmails'; Path = 'AlertMonitorInfo.SendsEmails'}
            @{Name = 'MonitorCreatesTicket'; Path = 'AlertMonitorInfo.CreatesTicket'}
            @{Name = 'DeviceName'; Path = 'AlertSourceInfo.DeviceName'}
            @{Name = 'DeviceUid'; Path = 'AlertSourceInfo.DeviceUid'}
            @{Name = 'SiteName'; Path = 'AlertSourceInfo.SiteName'}
            @{Name = 'SiteUid'; Path = 'AlertSourceInfo.SiteUid'}
            'AutoresolveMins'
            'PortalUrl'
        )

        'Summary' = @(
            'AlertUid'
            'Priority'
            'Resolved'
            'Timestamp'
            @{Name = 'DeviceName'; Path = 'AlertSourceInfo.DeviceName'}
            @{Name = 'SiteName'; Path = 'AlertSourceInfo.SiteName'}
            'Diagnostics'
        )
    }
}
