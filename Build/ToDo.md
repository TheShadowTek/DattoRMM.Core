# PS 7 justification - not API
From log file seems agent might already be running .Net Core

|INFO|4|MonitoringAgentHandler: Is Windows: True. Currently running NetCore: False. Can run NetCore: True|{  }

# Alert Context Class Definitions Verification
Analyse alert context class, no reference, command builds class properties list from known alerts
```powershell
(Get-RMMAlert -Status All -Debug).AlertContext | where {$_.Class -notin 'comp_script_ctx', 'online_offline_status_ctx'} | sort Class -Unique | select Class, @{n='Properties';e={$_.Properties.Keys -join ';'}} | Export-Csv <path>.csv
```
| Class | Properties
| ----- | ----------
| fs_object_ctx | threshold, sample, condition, objectType, path |
| perf_disk_usage_ctx | diskNameDesignation, freeSpace, unitOfMeasure, diskName, totalVolume |
| perf_resource_usage_ctx | percentage, type |
| process_resource_usage_ctx | processName, sample, type |
| process_status_ctx | processName, status |
| srvc_resource_usage_ctx | sample, serviceName, type |
| srvc_status_ctx | serviceName, status |

# doc valudation
- verify all links, especially feature request

# ALPHA (extended)/BETA Ready
Quick start guides
- Connect
- Get sites/devices/filters/alerts with pipeing
- Actions, job start/monitor/result/Out, resolve alerts
- Data extract
- Azure runbook setup/batching conceptual
- Class methods review

# Alpha test plan
Devices - ESXi, printers, switches, what about datto backup devices (do they appear) - am I missing any datto product integration stuff?
Would it help workflow migration to return raw object for users?

# Document DRMMObject and helper methods
like the heading says

# Get Device PII
Better message

# Extend Config Options
* Retry parameters

# Update Build Help scripts
Scripts need some refinment, and new docs structure

# DELETED DEVICES
Get site needs a switch to get deleted devices, currently excluded....

# Class Methods review
DRMMFilter - done

# Token Security
Can token security be improved?

# Custom Type/Format
Extensibility with type and format ps1xml files for bespoke environment implementation

# Variable Hardening
Update get and set to better handle masked variables, and secure update,... and new variable too!!

# Add Filters to Site
Add filters logic to get site expanded properties

# BUG RETrY on 400 error
Retry counter not working on 400 error
observed whilst testing set rmm variable 

[!IMPORTANT]
# Invoke Rest Method Exceptions
Allow pipeline to continue
Handle:
- 4xx something went wrong
- 5xx service errors, retry

# DRMMObject::GetValue
Remove from all but edge case safety coverage