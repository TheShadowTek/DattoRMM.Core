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

# Alert Times - done
Alert date time parsing currently commented and returning raw

# Hardening - done
Username exposed by activity log 'job' User, and details. Limited documentation as to what will be returned by activitylog details,
Review add confirm acceptable, or full PII masking on top for known entities?
Confirm on execution - site level confirmation, or All

# ActivityLog Job HasStdOut - done
Job has standard out, object reports false, not verified StdErr - possible omcponent issue not API, other test have been accurate.
Result - Reviewing wrong activity log :-|

# Review Activity Log Usage - done
no parameters should return all activity - done, end up full refactor for improvments

# doc valudation
- verify all links, especially feature request

# Community issues - done
Review Datto rMM commnuity for API issues and solutions and verify any known solutions are covered.
Nothing jumped out

# ALPHA READY
Test udf csv and json methods

# Alpha test plan
Devices - ESXi, printers, switches, what about datto backup devices (do they appear) - am I missing any datto product integration stuff?
Would it help workflow migration to return raw object for users?

# Beta test plan

# Bug Review
AlertContext srvc_resource_usage_ctx ResponseActions, the WEBHOOK_EXECUTED title and description impacts the UI too

# Module Name - done
Review module name given similarity with existing module

# Document DRMMObject and helper methods
like the heading says

# Throttle Control Improvment - done
Read account delay limit 0.9 default, from get account. Implment into throttle with variable overheadoverhead variable.
Result allows control of buffer, do not util to get above 50% with pause (overhead would be 0.4 for default). This 
allows control for concurrancy with other lighter workloads that are not throttled by backing off earlier. This should be a 
value relative to the account back off limit.
Mor ereliable than current hard 0.85.

# Throttle Class - done
Throttle could possibly get a class given it returns a psobject - no, internal except debug

# Config functions - done
Set and Get need refactor

# Throttle!!! - Fixed
Pause didn't kick in when expected above 85% util - modified last throttle refactor
havne't been band tho, throttle kept 3 x medium, 1 x aggressive, 1 x cautious concurrent sustained
maxing at 87% - wireless connection

# Get Device PII
Better message

# Was it my WiFi? ONCE - make that twice - is the API/AWS having a bad night 20/1/24 22:30-00:00

DEBUG: Uri: https://pinotage-api.centrastage.net/api/v2/site/3498e5a1-40ba-4bef-bbd9-4f4721c7bd8f/alerts/resolved?max=250
Invoke-RestMethod: C:\Users\..\DattoRMM.Core\Private\Invoke-APIMethod.ps1:141
Line |
 141 |              $Result = Invoke-RestMethod @RequestParams
     |                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Unable to read data from the transport connection: An
     | existing connection was forcibly closed by the remote host..

4 concurrent session, only impacted one session, last debug was 72%, 540ms delay, throttle medium

## 4 concurrent session - all four had same errer 21/1/2026 ~19:30
no indication in debug logs approaching acount cut-off, it doesn't look like rate limit, feels more AWS.
more reasearch required

All sessions start again without issue (infinite loop stress testing throttle) - so not banned.
Retry I think would workaround, but would rather understand issue better...

# Add retry - done
Doh, I need a retry on failure! Not had an error till now see above
Leaving it out for now to ensure catch errors in long running concurrent jobs.

retry working errors being caught in warning stream

# comment/remove class using - done
need to comment or remove scriptanlyser friendly using in class ps1 files, verbose shows drmmobject being repeatidly loaded
need to test module load without
resolved with updated module load process

# Rename Get-RMMDeviceFilter - done
Should noun be -RMMFilter, how it was originally?
Filter is site and global scope, not device - it identifies devices

# Update Build Help scripts
Scripts need some refinment, and new docs structure