<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>

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

# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDugbgXPE/ipyNn
# 3LEn63JH7Vate/qxvieLoTlM8zSkF6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICOqir6zKRIro6gjRzatHZb/w752
# Z9mFm/ui06y0d9jpMA0GCSqGSIb3DQEBAQUABIIBAJ4ZuQSxxn8FYW+HYGCRmqVp
# zNV0Na2XXNg1y8xqwHLR3j5wWnLBbCtP3wQlhY58mQttRiGBYbsPUSuDJh9aei0c
# SY6UKzA8Pyek4KLi1Woe0fQ46dDILRW4cXpTCV+UsA+ARw/pQ1oxSRWib+PkZnHH
# qRHibWctRmfQM/5sNpmmg2F5qGKJkyHIwLz7Xm5/Je9TmKccmtIiDadAvPfMU2sf
# emUrFlYpP7b+MpVea+nEe+NG4pZh8Raw0mKIgYmNKF6qj1d/GJrWzfSHUEWVSHO0
# Vu8kztI/0NU6i70qb+SDEPYMAmmeYfcKp1Om7K223hqCzdHfi6LJL1W6eaX+PuY=
# SIG # End signature block
