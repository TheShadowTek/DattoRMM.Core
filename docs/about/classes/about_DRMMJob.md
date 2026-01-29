# about_DRMMJob

## SHORT DESCRIPTION

Describes the DRMMJob class for querying job execution information in Datto RMM.

## LONG DESCRIPTION

The DRMMJob class represents a job (component execution) in Datto RMM. Jobs are created when components are executed on devices through quick jobs or scheduled tasks. The DRMMJob class provides basic job information including status, creation time, and unique identifiers.

DRMMJob objects are returned by [Get-RMMJob](Get-RMMJob.md) and New-RMMQuickJob. Use Get-RMMJob with additional parameters to retrieve detailed execution results, output logs, and component information.

## PROPERTIES

The DRMMJob class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id | long | Numeric job identifier |
| Uid | guid | Job unique identifier (GUID) |
| Name | string | Job name |
| DateCreated | datetime | Job creation timestamp |
| Status | string | Job execution status (active, completed) |

## METHODS

### Status Check Methods

#### IsActive()

Returns true if the job status is 'active' (executing or queued).

**Returns:** `[bool]`

```powershell
$job = Get-RMMJob -JobUid $JobUid
if ($job.IsActive()) {
    Write-Host "Job is still running"
}
```

#### IsCompleted()

Returns true if the job status is 'completed' (finished execution).

**Returns:** `[bool]`

```powershell
while (-not $job.IsCompleted()) {
    Start-Sleep -Seconds 60
    $job.Refresh()
}
```

### Time-Based Methods

#### GetAge()

Returns the time elapsed since the job was created.

**Returns:** `[timespan]`

```powershell
$job = Get-RMMJob -JobUid $JobUid
$age = $job.GetAge()
Write-Host "Job created $($age.TotalMinutes) minutes ago"
```

### API Wrapper Methods

#### GetComponents()

Retrieves all components associated with the job, including variable values. Wrapper for Get-RMMJob -JobUid $Uid -Components.

**Returns:** `[DRMMJobComponent[]]`

```powershell
$job = Get-RMMJob -JobUid $JobUid
$components = $job.GetComponents()
foreach ($comp in $components) {
    Write-Host "$($comp.Name) with $($comp.Variables.Count) variable(s)"
}
```

#### GetResults([guid]$DeviceUid)

Retrieves detailed execution results for the job on a specific device. Wrapper for Get-RMMJob -JobUid $Uid -DeviceUid $DeviceUid -Results.

**Parameters:**
- `$DeviceUid` - Device unique identifier

**Returns:** `[DRMMJobResults]`

```powershell
$job = Get-RMMJob -JobUid $JobUid
$results = $job.GetResults($DeviceUid)
foreach ($compResult in $results.ComponentResults) {
    Write-Host "$($compResult.ComponentName): $($compResult.ComponentStatus)"
}
```

#### GetStdOut([guid]$DeviceUid)

Retrieves standard output from the job execution on a specific device. Wrapper for Get-RMMJob -JobUid $Uid -DeviceUid $DeviceUid -StdOut.

**Parameters:**
- `$DeviceUid` - Device unique identifier

**Returns:** `[DRMMJobStdData[]]`

```powershell
$job = Get-RMMJob -JobUid $JobUid
$output = $job.GetStdOut($DeviceUid)
$output | ForEach-Object {Write-Host $_.StdData}
```

#### GetStdErr([guid]$DeviceUid)

Retrieves error output from the job execution on a specific device. Wrapper for Get-RMMJob -JobUid $Uid -DeviceUid $DeviceUid -StdErr.

**Parameters:**
- `$DeviceUid` - Device unique identifier

**Returns:** `[DRMMJobStdData[]]`

```powershell
$job = Get-RMMJob -JobUid $JobUid
if ($job.IsCompleted()) {
    $errors = $job.GetStdErr($DeviceUid)
    if ($errors) {
        Write-Warning "Job produced errors"
        $errors | ForEach-Object {Write-Host $_.StdData}
    }
}
```

#### Refresh()

Updates the job object with current status from the API. Modifies the current object rather than returning a new one.

**Returns:** `[void]`

```powershell
$job = Get-RMMJob -JobUid $JobUid
while ($job.IsActive()) {
    Start-Sleep -Seconds 60
    $job.Refresh()
    Write-Host "Current status: $($job.Status)"
}
```

### Utility Methods

#### GetSummary()

Returns a formatted summary string of the job including name, status, and age.

**Returns:** `[string]`

```powershell
$jobs = @($Job1, $Job2, $Job3)
foreach ($job in $jobs) {
    Write-Host $job.GetSummary()
}
# Output examples:
# System Check - completed (5m ago)
# Disk Cleanup - active (2h ago)
# Windows Update - completed (1d ago)
```

### Output Parsing Methods

#### GetStdOutAsJson([guid]$DeviceUid)

Retrieves job stdout and parses it as JSON. Useful when components output structured JSON data for consumption by automation workflows.

**Parameters:**
- `$DeviceUid` - Device unique identifier

**Returns:** `[pscustomobject[]]`

```powershell
$job = Get-RMMJob -JobUid $JobUid
$data = $job.GetStdOutAsJson($DeviceUid)
foreach ($item in $data) {
    Write-Host "Item: $($item.Name) - Status: $($item.Status)"
}
```

#### GetStdOutAsCsv([guid]$DeviceUid)

Retrieves job stdout and parses it as CSV with the first row as headers. Default overload assumes standard CSV format with header row.

**Parameters:**
- `$DeviceUid` - Device unique identifier

**Returns:** `[pscustomobject[]]`

```powershell
$job = Get-RMMJob -JobUid $JobUid
$data = $job.GetStdOutAsCsv($DeviceUid)
$data | Format-Table
```

#### GetStdOutAsCsv([guid]$DeviceUid, [bool]$FirstRowAsHeader)

Retrieves job stdout and parses it as CSV, treating the first row as headers. This overload requires CSV data with a header row.

**Parameters:**
- `$DeviceUid` - Device unique identifier
- `$FirstRowAsHeader` - Must be $true; if $false without custom headers, throws error

**Returns:** `[pscustomobject[]]`

```powershell
# CSV with header row
$data = $job.GetStdOutAsCsv($DeviceUid, $true)
```

#### GetStdOutAsCsv([guid]$DeviceUid, [bool]$FirstRowAsHeader, [string[]]$Headers)

Retrieves job stdout and parses it as CSV with custom header definitions. Useful when the CSV data doesn't have headers or you want to override them.

**Parameters:**
- `$DeviceUid` - Device unique identifier
- `$FirstRowAsHeader` - If true, skips first row (original headers); if false, includes it
- `$Headers` - Custom header names to use for the columns

**Returns:** `[pscustomobject[]]`

```powershell
# Define custom headers for CSV without header row
$headers = @('Hostname', 'IPAddress', 'Status', 'LastSeen')
$data = $job.GetStdOutAsCsv($DeviceUid, $false, $headers)

# Or replace existing headers with custom names
$headers = @('ComputerName', 'IP', 'State', 'Timestamp')
$data = $job.GetStdOutAsCsv($DeviceUid, $true, $headers)
```

## JOB STATUS VALUES

Jobs can have the following status values:

- **active** - Job is currently executing or queued for execution
- **completed** - Job has finished execution on all target devices

**Note:** The Status property only indicates whether the job has completed execution, not whether it succeeded or failed. Use Get-RMMJob -Results to check component execution status and results.

## RELATED CLASSES

### DRMMJobResults

Contains detailed execution results for a job on a specific device.

**Properties:**
- JobUid `[guid]` - Job unique identifier
- DeviceUid `[guid]` - Device unique identifier
- RanOn `[datetime]` - Execution timestamp
- JobDeploymentStatus `[string]` - Deployment status
- ComponentResults `[DRMMJobComponentResult[]]` - Per-component results

### DRMMJobComponentResult

Represents the execution result of a single component within a job.

**Properties:**
- ComponentUid `[guid]` - Component unique identifier
- ComponentName `[string]` - Component name
- ComponentStatus `[string]` - Component execution status
- NumberOfWarnings `[int]` - Warning count
- HasStdOut `[bool]` - Whether component produced stdout
- HasStdErr `[bool]` - Whether component produced stderr

### DRMMJobStdData

Contains standard output or error output from component execution.

**Properties:**
- JobUid `[guid]` - Job unique identifier
- DeviceUid `[guid]` - Device unique identifier
- ComponentUid `[guid]` - Component unique identifier
- ComponentName `[string]` - Component name
- StdData `[string]` - Output data (stdout or stderr)

### DRMMJobComponent

Represents a component and its variable values as executed in a job.

**Properties:**
- Uid `[guid]` - Component unique identifier
- Name `[string]` - Component name
- Variables `[DRMMJobComponentVariable[]]` - Variable name/value pairs

### DRMMComponent

Component objects can be executed to create jobs.

### DRMMDevice

Device objects have RunQuickJob() method to create jobs.

## QUERYING JOBS

Jobs are queried using Get-RMMJob with various parameter combinations:

```powershell
# Basic job information
$job = Get-RMMJob -JobUid $JobUid

# Job execution results
$results = Get-RMMJob -JobUid $JobUid -DeviceUid $DeviceUid -Results

# Job standard output
$stdout = Get-RMMJob -JobUid $JobUid -DeviceUid $DeviceUid -StdOut

# Job error output
$stderr = Get-RMMJob -JobUid $JobUid -DeviceUid $DeviceUid -StdErr

# Job components and variables
$components = Get-RMMJob -JobUid $JobUid -Components
```

## EXAMPLES

### Example 1: Create and monitor a job using Refresh()

```powershell
$device = Get-RMMDevice -Hostname "SERVER01"
$component = Get-RMMComponent | Where-Object {$_.Name -eq "System Check"}

# Create job
$job = $device.RunQuickJob($component.Uid)
Write-Host "Job created: $($job.GetSummary())"

# Poll for completion using Refresh()
while ($job.IsActive()) {
    Start-Sleep -Seconds 60
    $job.Refresh()
    Write-Host $job.GetSummary()
}

Write-Host "Job completed after $([int]$job.GetAge().TotalMinutes) minutes"
```

### Example 2: Check job results using wrapper methods

```powershell
$job = Get-RMMJob -JobUid $JobUid

if ($job.IsCompleted()) {
    $results = $job.GetResults($DeviceUid)
    
    foreach ($compResult in $results.ComponentResults) {
        Write-Host "$($compResult.ComponentName): $($compResult.ComponentStatus)"
        
        if ($compResult.HasStdErr) {
            Write-Warning "Component has errors, retrieving stderr..."
            $errors = $job.GetStdErr($DeviceUid)
            $errors | Where-Object {$_.ComponentUid -eq $compResult.ComponentUid} |
                ForEach-Object {Write-Host $_.StdData}
        }
    }
}
```

### Example 3: Export job output to file using wrapper methods

```powershell
$job = Get-RMMJob -JobUid $JobUid
$device = Get-RMMDevice -DeviceUid $DeviceUid

# Wait for completion using Refresh()
while ($job.IsActive()) {
    Start-Sleep -Seconds 60
    $job.Refresh()
}

# Export stdout to file
$output = $job.GetStdOut($device.Uid)
$fileName = "$($device.Hostname)_$($job.Name)_$(Get-Date -Format 'yyyyMMdd').log"
$output.StdData -join "`n" | Out-File -FilePath $fileName
```

### Example 4: Review job execution variables using GetComponents()

```powershell
$job = Get-RMMJob -JobUid $JobUid
$components = $job.GetComponents()

foreach ($comp in $components) {
    Write-Host "Component: $($comp.Name)"
    if ($comp.Variables) {
        foreach ($var in $comp.Variables) {
            Write-Host "  $($var.Name) = $($var.Value)"
        }
    } else {
        Write-Host "  (No variables)"
    }
}
```

### Example 5: Find recently completed jobs

```powershell
# Note: This requires querying through New-RMMQuickJob job objects or
# tracking job UIDs as jobs are created. There is no "list all jobs" API.

$trackedJobs = @(
    "12067610-8504-48e3-b5de-60e48416aaad"
    "8f71dc24-1b4e-4e8d-9c73-8a2e4d5f6c89"
)

$recentJobs = $trackedJobs | ForEach-Object {
    Get-RMMJob -JobUid $_
} | Where-Object {
    $_.Status -eq 'completed' -and
    $_.DateCreated -gt (Get-Date).AddHours(-1)
}

$recentJobs | Format-Table Name, Status, DateCreated
```

### Example 6: Parallel job execution with result tracking

```powershell
$filter = Get-RMMFilter -Name "Production Servers"
$devices = $filter.GetDevices()
$component = Get-RMMComponent | Where-Object {$_.Name -eq "Update Agent"}

# Create jobs on all devices
$jobs = foreach ($device in $devices) {
    [PSCustomObject]@{
        Device = $device
        Job = $device.RunQuickJob($component.Uid)
    }
}

Write-Host "Started $($jobs.Count) job(s). Monitoring..."

# Wait for all jobs to complete
$allComplete = $false
while (-not $allComplete) {
    Start-Sleep -Seconds 60
    
    # Refresh all jobs and check status
    $jobs | ForEach-Object {$_.Job.Refresh()}
    
    $statuses = $jobs | ForEach-Object {
        [PSCustomObject]@{
            Device = $_.Device.Hostname
            JobName = $_.Job.Name
            Status = $_.Job.Status
        }
    }
    
    $activeCount = ($jobs | Where-Object {$_.Job.IsActive()}).Count
    Write-Host "Active: $activeCount | Completed: $($jobs.Count - $activeCount)"
    
    $allComplete = ($activeCount -eq 0)
}

# Review results using wrapper methods
foreach ($jobInfo in $jobs) {
    $results = $jobInfo.Job.GetResults($jobInfo.Device.Uid)
    Write-Host "$($jobInfo.Device.Hostname): $($results.JobDeploymentStatus)"
}
```

### Example 7: Job execution audit report

```powershell
# Track job UIDs over a period (e.g., stored in a file or database)
$jobLog = Import-Csv "job_tracking.csv"  # Contains: JobUid, DeviceName, StartTime

$report = foreach ($entry in $jobLog) {
    $job = Get-RMMJob -JobUid $entry.JobUid -ErrorAction SilentlyContinue
    
    if ($job) {
        [PSCustomObject]@{
            JobName = $job.Name
            DeviceName = $entry.DeviceName
            StartTime = $entry.StartTime
            Status = $job.Status
            CompletedAt = if ($job.Status -eq 'completed') {
                (Get-Date).ToString('yyyy-MM-dd HH:mm')
            } else {
                'Still Running'
            }
        }
    }
}

$report | Export-Csv "job_audit_report.csv" -NoTypeInformation
```

### Example 8: Parse component output as JSON

```powershell
# Component outputs JSON data for structured consumption
$device = Get-RMMDevice -Hostname "SERVER01"
$component = Get-RMMComponent | Where-Object {$_.Name -eq "Get Installed Software"}

$job = $device.RunQuickJob($component.Uid)

# Wait for completion
while ($job.IsActive()) {
    Start-Sleep -Seconds 60
    $job.Refresh()
}

# Parse JSON output
$software = $job.GetStdOutAsJson($device.Uid)
$software | Where-Object {$_.Vendor -like "*Microsoft*"} |
    Sort-Object InstallDate -Descending |
    Select-Object Name, Version, InstallDate
```

### Example 9: Parse component output as CSV with custom headers

```powershell
# Component outputs CSV without headers
$device = Get-RMMDevice -Hostname "WKS01"
$component = Get-RMMComponent | Where-Object {$_.Name -eq "Network Connections Report"}

$job = $device.RunQuickJob($component.Uid)

while ($job.IsActive()) {
    Start-Sleep -Seconds 60
    $job.Refresh()
}

# Define custom headers since component doesn't output them
$headers = @('Protocol', 'LocalAddress', 'LocalPort', 'RemoteAddress', 'RemotePort', 'State')
$connections = $job.GetStdOutAsCsv($device.Uid, $false, $headers)

# Analyze connections
$listening = $connections | Where-Object {$_.State -eq 'LISTENING'}
Write-Host "Listening ports: $($listening.Count)"
$listening | Group-Object Protocol, LocalPort | Format-Table Count, Name
```

### Example 10: Aggregate CSV data from multiple devices

```powershell
# Run inventory component on multiple devices and aggregate results
$filter = Get-RMMFilter -Name "All Servers"
$devices = $filter.GetDevices()
$component = Get-RMMComponent | Where-Object {$_.Name -eq "Disk Space Report"}

# Create jobs
$jobs = foreach ($device in $devices) {
    [PSCustomObject]@{
        Device = $device
        Job = $device.RunQuickJob($component.Uid)
    }
}

# Wait for all to complete
while ($jobs | Where-Object {$_.Job.IsActive()}) {
    Start-Sleep -Seconds 60
    $jobs | ForEach-Object {$_.Job.Refresh()}
}

# Aggregate CSV results from all devices
$allDiskData = foreach ($jobInfo in $jobs) {
    $csvData = $jobInfo.Job.GetStdOutAsCsv($jobInfo.Device.Uid)
    $csvData | ForEach-Object {
        $_ | Add-Member -NotePropertyName 'Hostname' -NotePropertyValue $jobInfo.Device.Hostname -PassThru
    }
}

# Find low disk space
$lowSpace = $allDiskData | Where-Object {[int]$_.FreePercent -lt 20}
$lowSpace | Format-Table Hostname, Drive, FreePercent, TotalGB, FreeGB
```

## BEST PRACTICES

1. Always store job UIDs when creating jobs if you need to query them later. There is no API endpoint to list all jobs:
   ```powershell
   $job = $device.RunQuickJob($componentUid)
   $jobUid = $job.Uid  # Store this for later queries
   ```

2. Use Refresh() method to update job status without creating new objects:
   ```powershell
   while ($job.IsActive()) {
       Start-Sleep -Seconds 60
       $job.Refresh()  # Updates existing object
   }
   ```

3. Poll job status at reasonable intervals (60 seconds or more). Jobs can take several minutes to deploy and execute on remote devices.

4. Use IsCompleted() instead of checking Status directly for better readability:
   ```powershell
   if ($job.IsCompleted()) {
       $results = $job.GetResults($deviceUid)
   }
   ```

5. Use wrapper methods (GetResults, GetStdOut, GetStdErr) for cleaner code:
   ```powershell
   # Instead of: Get-RMMJob -JobUid $job.Uid -DeviceUid $deviceUid -Results
   $results = $job.GetResults($deviceUid)
   ```

6. Check component-level results to determine success/failure rather than relying on the basic Status property:
   ```powershell
   $results = $job.GetResults($deviceUid)
   $failed = $results.ComponentResults | Where-Object {$_.ComponentStatus -ne 'success'}
   ```

7. Retrieve stdout and stderr only when needed for troubleshooting. These can be large text outputs:
   ```powershell
   if ($componentResult.HasStdErr) {
       $errors = $job.GetStdErr($deviceUid)
   }
   ```

8. When executing jobs on multiple devices, track both device and job objects together to simplify result retrieval:
   ```powershell
   $jobs = foreach ($device in $devices) {
       [PSCustomObject]@{
           Device = $device
           Job = $device.RunQuickJob($componentUid)
       }
   }
   ```

9. Use GetAge() to identify long-running or stuck jobs:
   ```powershell
   $oldJobs = $trackedJobs | Where-Object {
       $_.Job.IsActive() -and $_.Job.GetAge().TotalHours -gt 2
   }
   ```

10. Job names are set at creation time and cannot be changed. Use descriptive names that include date/time or ticket numbers for easier tracking:
    ```powershell
    $jobName = "Patch $ServerName - Ticket #12345 - $(Get-Date -Format 'yyyy-MM-dd')"
    ```

11. Use parsing methods (GetStdOutAsJson, GetStdOutAsCsv) when components output structured data rather than manually parsing stdout strings:
    ```powershell
    # Instead of: ($job.GetStdOut($deviceUid).StdData -join "`n") | ConvertFrom-Json
    $data = $job.GetStdOutAsJson($deviceUid)
    ```

12. When designing components that output data for automation, prefer JSON for complex nested structures and CSV for tabular data. Document the output format in component descriptions.

13. For CSV output without headers, use custom header arrays to make data more readable and self-documenting:
    ```powershell
    $headers = @('Name', 'Value', 'Status')
    $data = $job.GetStdOutAsCsv($deviceUid, $false, $headers)
    ```

## NOTES

- Job UIDs are globally unique and remain constant throughout the job lifecycle.

- Jobs in "active" status may be queued, deploying, or executing. This includes time waiting for the device to come online or for agent communication.

- There is no API endpoint to list all jobs or search jobs by criteria. Job UIDs must be obtained from New-RMMQuickJob responses or tracked externally.

- Job history retention varies by Datto RMM account configuration. Very old jobs may no longer be queryable.

- Results, stdout, and stderr require both JobUid and DeviceUid parameters as jobs can execute on multiple devices.

- The basic DRMMJob object (from Get-RMMJob -JobUid) does not include device information. Track device associations when creating jobs.

- ComponentStatus values in DRMMJobComponentResult depend on the component's exit code and execution behavior. Common values include "success" and "failed".

## SEE ALSO

- [Get-RMMJob](Get-RMMJob.md)
- New-RMMQuickJob
- [about_DRMMComponent](about_DRMMComponent.md)
- [about_DRMMDevice](about_DRMMDevice.md)
