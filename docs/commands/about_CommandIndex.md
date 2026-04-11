# DattoRMM.Core Command Reference

A reference index of all public functions in the DattoRMM.Core module, organised by domain.

## Contents

- [Account](#account)
- [ActivityLog](#activitylog)
- [Alerts](#alerts)
- [Auth](#auth)
- [Component](#component)
- [Config](#config)
- [Devices](#devices)
- [Export](#export)
- [Filter](#filter)
- [Jobs](#jobs)
- [Sites](#sites)
- [Variables](#variables)

## Account

| Command | Synopsis |
| ------- | -------- |
| [`Get-RMMAccount`](Account/Get-RMMAccount.md) | Retrieves information about the authenticated Datto RMM account. |
| [`Get-RMMNetMapping`](Account/Get-RMMNetMapping.md) | Retrieves Datto Networking site mappings. |
| [`Get-RMMRequestRate`](Account/Get-RMMRequestRate.md) | Retrieves the current API request rate information for the Datto RMM account. |
| [`Get-RMMStatus`](Account/Get-RMMStatus.md) | Retrieves the current status of the Datto RMM system. |
| [`Get-RMMThrottleStatus`](Account/Get-RMMThrottleStatus.md) | Retrieves a detailed snapshot of the current API rate limits, counts, and local throttle state. |
| [`Get-RMMUser`](Account/Get-RMMUser.md) | Retrieves user accounts from the Datto RMM API. |
| [`Invoke-RMMApiMethod`](Account/Invoke-RMMApiMethod.md) | Invokes an arbitrary Datto RMM API endpoint and returns the untyped response as a PSObject. |

## ActivityLog

| Command | Synopsis |
| ------- | -------- |
| [`Get-RMMActivityLog`](ActivityLog/Get-RMMActivityLog.md) | Retrieves activity logs from the Datto RMM API. |

## Alerts

| Command | Synopsis |
| ------- | -------- |
| [`Get-RMMAlert`](Alerts/Get-RMMAlert.md) | Retrieves alerts from the Datto RMM API. |
| [`Resolve-RMMAlert`](Alerts/Resolve-RMMAlert.md) | Resolves a Datto RMM alert. |

## Auth

| Command | Synopsis |
| ------- | -------- |
| [`Connect-DattoRMM`](Auth/Connect-DattoRMM.md) | Connects to the Datto RMM API and authenticates using API credentials. |
| [`Disconnect-DattoRMM`](Auth/Disconnect-DattoRMM.md) | Disconnects from the Datto RMM API and clears authentication information. |
| [`Request-RMMToken`](Auth/Request-RMMToken.md) | Requests a new Datto RMM API access token and returns a DRMMToken object. |
| [`Reset-RMMApiKeys`](Auth/Reset-RMMApiKeys.md) | Resets the authenticated user's API access and secret keys in Datto RMM. |
| [`Show-RMMToken`](Auth/Show-RMMToken.md) | Displays the current Datto RMM API token and authentication details. |

## Component

| Command | Synopsis |
| ------- | -------- |
| [`Get-RMMComponent`](Component/Get-RMMComponent.md) | Retrieves all components (scripts/jobs) from the Datto RMM account. |

## Config

| Command | Synopsis |
| ------- | -------- |
| [`Get-RMMConfig`](Config/Get-RMMConfig.md) | Retrieves the current DattoRMM.Core module configuration. |
| [`Remove-RMMConfig`](Config/Remove-RMMConfig.md) | Deletes the persistent DattoRMM.Core configuration file (factory reset for future sessions). |
| [`Save-RMMConfig`](Config/Save-RMMConfig.md) | Saves the current in-memory DattoRMM.Core configuration to disk. |
| [`Set-RMMConfig`](Config/Set-RMMConfig.md) | Configures the current DattoRMM.Core session and optionally saves settings persistently. |

## Devices

| Command | Synopsis |
| ------- | -------- |
| [`Get-RMMDevice`](Devices/Get-RMMDevice.md) | Retrieves device information from the Datto RMM API. |
| [`Get-RMMDeviceAudit`](Devices/Get-RMMDeviceAudit.md) | Retrieves detailed audit information for a device. |
| [`Get-RMMDeviceSoftware`](Devices/Get-RMMDeviceSoftware.md) | Retrieves installed software for a specific device. |
| [`Get-RMMEsxiHostAudit`](Devices/Get-RMMEsxiHostAudit.md) | Retrieves ESXi host audit data for a specific device. |
| [`Get-RMMPrinterAudit`](Devices/Get-RMMPrinterAudit.md) | Retrieves printer audit data for a specific device. |
| [`Move-RMMDevice`](Devices/Move-RMMDevice.md) | Moves a device from one site to another site. |
| [`Set-RMMDeviceUDF`](Devices/Set-RMMDeviceUDF.md) | Sets user-defined fields on a device in Datto RMM. |
| [`Set-RMMDeviceWarranty`](Devices/Set-RMMDeviceWarranty.md) | Sets the warranty expiration date on a device in Datto RMM. |

## Export

| Command | Synopsis |
| ------- | -------- |
| [`Export-RMMObjectCsv`](Export/Export-RMMObjectCsv.md) | Exports DattoRMM.Core objects to a flattened CSV file using named transforms. |

See [about_DattoRMM.CoreExport](../about/about_DattoRMM.CoreExport.md) for details on transform authoring and custom transforms.

## Filter

| Command | Synopsis |
| ------- | -------- |
| [`Get-RMMFilter`](Filter/Get-RMMFilter.md) | Retrieves filters from the Datto RMM API. |

## Jobs

| Command | Synopsis |
| ------- | -------- |
| [`Get-RMMJob`](Jobs/Get-RMMJob.md) | Retrieves job information from the Datto RMM API by JobUid or from an ActivityLog object. |
| [`Get-RMMJobResult`](Jobs/Get-RMMJobResult.md) | Retrieves job execution results and output for a specific device from the Datto RMM API. |
| [`New-RMMQuickJob`](Jobs/New-RMMQuickJob.md) | Creates a quick job on a device in Datto RMM. |

## Sites

| Command | Synopsis |
| ------- | -------- |
| [`Get-RMMSite`](Sites/Get-RMMSite.md) | Retrieves sites from the Datto RMM API. |
| [`Get-RMMSiteSettings`](Sites/Get-RMMSiteSettings.md) | Retrieves site settings from the Datto RMM API. |
| [`New-RMMSite`](Sites/New-RMMSite.md) | Creates a new site in the Datto RMM account. |
| [`Remove-RMMSiteProxy`](Sites/Remove-RMMSiteProxy.md) | Removes proxy settings from a Datto RMM site. |
| [`Set-RMMSite`](Sites/Set-RMMSite.md) | Updates an existing site in the Datto RMM account. |
| [`Set-RMMSiteProxy`](Sites/Set-RMMSiteProxy.md) | Creates or updates proxy settings for a Datto RMM site. |

## Variables

| Command | Synopsis |
| ------- | -------- |
| [`Get-RMMVariable`](Variables/Get-RMMVariable.md) | Retrieves variables from the Datto RMM API. |
| [`New-RMMVariable`](Variables/New-RMMVariable.md) | Creates a new variable in the Datto RMM account or site. |
| [`Remove-RMMVariable`](Variables/Remove-RMMVariable.md) | Deletes a variable from the Datto RMM account or site. |
| [`Set-RMMVariable`](Variables/Set-RMMVariable.md) | Updates an existing variable in the Datto RMM account or site. |