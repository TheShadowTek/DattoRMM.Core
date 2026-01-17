# PS 7 justification
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

# Alert Times
Alert date time parsing currently commented and returning raw

# Hardening
Username exposed by activity log 'job' User, and details. Limited documentation as to what will be returned by activitylog details,
Review add confirm acceptable, or full PII masking on top for known entities?

# ActivityLog Jog HasStdOut
Job has standard out, object reports false, not verified StdErr

# Review Activity Log Usage
no parameters should return all activity

# doc valudation
- verify all links, especially feature request

# Community issues
Review Datto rMM commnuity for API issues and solutions and verify any known solutions are covered.