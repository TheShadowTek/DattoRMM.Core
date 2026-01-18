# about_DRMMComponent

## SHORT DESCRIPTION

Describes the DRMMComponent class for managing automation components in Datto RMM.

## LONG DESCRIPTION


The DRMMComponent class represents an automation component (script or monitor) in Datto RMM. Components are reusable automation scripts that can be executed on devices through quick jobs or scheduled tasks.

DRMMComponent objects are returned by [Get-RMMComponent](Get-RMMComponent.md), which retrieves component objects for inspection and execution. Use Get-RMMComponent to list, filter, and manage automation components programmatically.

## PROPERTIES

| Property | Type | Description |
|----------|------|-------------|
| Id | [int] | Numeric component identifier |
| Uid | [guid] | Component unique identifier |
| Name | [string] | Component name |
| Description | [string] | Component description |
| CategoryCode | [string] | Component category code |
| CredentialsRequired | [bool] | Whether component requires credentials |
| Variables | [DRMMComponentVariable[]] | Component input/output variables |

## METHODS

### Variable Inspection

#### GetVariable([string]$Name)

Retrieves a specific variable by name from the component.

**Parameters:**
- `$Name` - Variable name to search for

**Returns:** [DRMMComponentVariable]

**Example:**
```powershell
$component = Get-RMMComponent | Where-Object {$_.Name -eq "Restart Service"}
$serviceVar = $component.GetVariable("serviceName")
Write-Host "Variable type: $($serviceVar.Type)"
```

#### GetInputVariables()

Retrieves all input variables (Direction = true) for the component. Input variables are parameters that must be provided when executing the component.

**Returns:** [DRMMComponentVariable[]]

**Example:**
```powershell
$component = Get-RMMComponent -Name "Custom Script"
$inputs = $component.GetInputVariables()
foreach ($input in $inputs) {
    Write-Host "$($input.Name) - $($input.Type) - $($input.Description)"
}
```

#### GetOutputVariables()

Retrieves all output variables (Direction = false) for the component. Output variables are values returned by the component after execution.

**Returns:** [DRMMComponentVariable[]]

**Example:**
```powershell
$component = Get-RMMComponent -Name "System Check"
$outputs = $component.GetOutputVariables()
Write-Host "This component returns $($outputs.Count) output variable(s)"
```

### Utility Methods

#### GetSummary()

Returns a formatted summary string of the component including name, credential requirements, variable count, and category.

**Returns:** [string]

**Example:**
```powershell
$components = Get-RMMComponent
foreach ($component in $components) {
    Write-Host $component.GetSummary()
}
# Output examples:
# Restart Service [Credentials Required] - 1 variable(s) - System
# Windows Update - 3 variable(s) - Patch Management
# PowerShell Script - 5 variable(s) - Custom
```

## RELATED CLASSES

### DRMMComponentVariable

Represents an input or output variable for a component.

**Properties:**
- Name [string] - Variable name
- DefaultValue [string] - Default value for the variable
- Type [string] - Variable data type
- Direction [bool] - true = Input, false = Output
- Description [string] - Variable description
- Index [int] - Variable index/position

**Methods:**
- GetSummary() - Returns formatted variable summary

### DRMMJob

Represents a job execution instance. Jobs are created when components are executed on devices.

### DRMMDevice

Device objects have RunQuickJob() method to execute components.

## COMPONENT EXECUTION

Components are executed using the New-RMMQuickJob function or the DRMMDevice.RunQuickJob() method. Components with input variables require those variables to be provided as a hashtable:

**Example: Execute component with variables**
```powershell
$device = Get-RMMDevice -Hostname "SERVER01"
$component = Get-RMMComponent | Where-Object {$_.Name -eq "Restart Service"}

# Check required input variables
$inputs = $component.GetInputVariables()
foreach ($var in $inputs) {
    Write-Host "Required: $($var.Name) ($($var.Type))"
}

# Execute with variables
$variables = @{serviceName = 'W32Time'}
$job = $device.RunQuickJob($component.Uid, $variables)
```

## EXAMPLES

### Example 1: Find components by category

```powershell
$components = Get-RMMComponent
$grouped = $components | Group-Object -Property CategoryCode

foreach ($group in $grouped | Sort-Object Name) {
    Write-Host "$($group.Name): $($group.Count) component(s)"
}
```

### Example 2: List components requiring credentials

```powershell
$credComponents = Get-RMMComponent | Where-Object {$_.CredentialsRequired}
foreach ($comp in $credComponents) {
    Write-Host $comp.GetSummary()
}
```

### Example 3: Inspect component variables

```powershell
$component = Get-RMMComponent | Where-Object {$_.Name -like "*PowerShell*"} | 
    Select-Object -First 1

Write-Host "Component: $($component.Name)"
Write-Host "Input Variables:"
foreach ($var in $component.GetInputVariables()) {
    $default = if ($var.DefaultValue) {" (Default: $($var.DefaultValue))"} else {''}
    Write-Host "  $($var.Name) [$($var.Type)]$default"
    Write-Host "    $($var.Description)"
}
```

### Example 4: Execute component on multiple devices

```powershell
$component = Get-RMMComponent | Where-Object {$_.Name -eq "Disk Cleanup"}
$filter = Get-RMMDeviceFilter -Name "Windows Servers"
$devices = $filter.GetDevices()

$variables = @{days = '30'; path = 'C:\Temp'}

foreach ($device in $devices) {
    Write-Host "Running cleanup on $($device.Hostname)"
    $job = $device.RunQuickJob($component.Uid, $variables)
    Write-Host "  Job UID: $($job.Uid)"
}
```

### Example 5: Find components with no input variables

```powershell
$simpleComponents = Get-RMMComponent | Where-Object {
    ($_.GetInputVariables()).Count -eq 0
}

Write-Host "Found $($simpleComponents.Count) components with no input variables"
$simpleComponents | ForEach-Object {Write-Host "  $($_.Name)"}
```

### Example 6: Build variable hashtable from user input

```powershell
$component = Get-RMMComponent -Name "Custom Deployment"
$variables = @{}

foreach ($var in $component.GetInputVariables()) {
    $prompt = "$($var.Name) [$($var.Type)]"
    if ($var.DefaultValue) {
        $prompt += " (Default: $($var.DefaultValue))"
    }
    
    $value = Read-Host $prompt
    if ($value) {
        $variables[$var.Name] = $value
    } elseif ($var.DefaultValue) {
        $variables[$var.Name] = $var.DefaultValue
    }
}

# Execute with collected variables
$device = Get-RMMDevice -Hostname "TARGET01"
$job = $device.RunQuickJob($component.Uid, $variables)
```

### Example 7: Export component inventory to CSV

```powershell
Get-RMMComponent | Select-Object `
    Name,
    CategoryCode,
    CredentialsRequired,
    @{N='InputCount';E={($_.GetInputVariables()).Count}},
    @{N='OutputCount';E={($_.GetOutputVariables()).Count}},
    Description |
Export-Csv -Path "component_inventory.csv" -NoTypeInformation
```

## BEST PRACTICES

1. **Always inspect input variables** before executing a component to ensure you provide all required parameters:
   ```powershell
   $inputs = $component.GetInputVariables()
   ```

2. Use `GetVariable()` to check for specific variable properties like Type and DefaultValue when building variable hashtables programmatically.

3. Components with `CredentialsRequired=true` may need additional authentication context when executed in certain scenarios.

4. **Cache component objects** when executing on multiple devices rather than repeatedly calling Get-RMMComponent:
   ```powershell
   $component = Get-RMMComponent -Name "My Script"
   foreach ($device in $devices) {
       $device.RunQuickJob($component.Uid, $variables)
   }
   ```

5. Use descriptive variable names that match the component's expected input exactly.

6. **Test components on a single device** before deploying to multiple devices:
   ```powershell
   # Test first
   $testDevice = Get-RMMDevice -Hostname "TEST-VM"
   $job = $testDevice.RunQuickJob($component.Uid, $variables)
   
   # Poll for completion (jobs can take several minutes)
   Write-Host "Waiting for job completion (Job UID: $($job.Uid))..."
   do {
       Start-Sleep -Seconds 60
       $status = Get-RMMJob -JobUid $job.Uid
       Write-Host "Status: $($status.Status)"
   } while ($status.Status -eq 'active')
   
   # Deploy if successful
   if ($status.Status -eq 'completed') {
       Write-Host "Test successful, deploying to production devices"
       # Run on production devices
   } else {
       Write-Warning "Job status: $($status.Status)"
   }
   ```

7. Group components by CategoryCode for better organization and reporting.

8. Document custom components with clear descriptions and variable names to aid future maintenance and usage.

## SECURITY CONSIDERATIONS

⚠️ **WARNING:** Component variable DefaultValue properties may contain sensitive data.

- Component variables can have default values configured, including passwords or other credentials.

- These default values are **NOT masked** and will be visible in API responses and through the DefaultValue property.

- When inspecting components or logging variable information, be cautious about exposing DefaultValue properties that may contain secrets.

- Avoid setting passwords or sensitive data as default values in component configurations. Use credential variables or prompt for sensitive input instead.

- When exporting or displaying component information, consider filtering or masking DefaultValue properties:
  ```powershell
  $component.GetInputVariables() | Select-Object Name, Type, Description
  # Intentionally omit DefaultValue to prevent exposure
  ```

## NOTES

- Component UIDs are globally unique and remain constant across API calls.

- Variable Direction property: `true` = Input (required from caller), `false` = Output (returned by component).

- Not all components have variables - check the Variables array before attempting to access variable properties.

- Component categories vary by Datto RMM configuration and may include custom categories defined by your organization.

- Components are account-level resources and available across all sites unless specifically restricted.

- The CredentialsRequired property indicates if the component needs stored credentials but doesn't specify which credentials are needed.

## SEE ALSO

- [Get-RMMComponent](Get-RMMComponent.md)
- [New-RMMQuickJob](New-RMMQuickJob.md)
- [Get-RMMJob](Get-RMMJob.md)
- [about_DRMMDevice](about_DRMMDevice.md)
- [about_DRMMJob](about_DRMMJob.md)
