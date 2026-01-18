# about_DRMMSite

## SHORT DESCRIPTION

Describes the DRMMSite class and its methods for managing sites in Datto RMM.

## LONG DESCRIPTION

The DRMMSite class represents a site (customer) within Datto RMM. Sites are organisational containers that hold devices, filters, variables, and settings.

DRMMSite objects are returned by [Get-RMMSite](Get-RMMSite.md) and provide a rich object-oriented interface for interacting with site resources through instance methods.

## PROPERTIES

The DRMMSite class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id | long | Numeric site identifier |
| Uid | string | Site GUID |
| AccountUid | string | Account GUID the site belongs to |
| Name | string | Site name |
| Description | string | Site description |
| Notes | string | Site notes |
| OnDemand | bool | Whether site is on-demand |
| SplashtopAutoInstall | bool | Auto-install Splashtop remote control |
| ProxySettings | DRMMSiteProxySettings | Proxy configuration |
| DevicesStatus | DRMMDevicesStatus | Device status summary |
| SiteSettings | DRMMSiteSettings | Site settings object |
| Variables | DRMMVariable[] | Site variables array |
| Filters | object | Site filters (placeholder) |
| AutotaskCompanyName | string | Autotask company name |
| AutotaskCompanyId | string | Autotask company ID |
| PortalUrl | string | Portal URL for the site |

## METHODS

### Alert Management

#### GetAlerts()

Retrieves all alerts for the site.

**Returns:** `[DRMMAlert[]]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$alerts = $site.GetAlerts()
```

#### GetAlerts([string]$Status)

Retrieves alerts filtered by status.

**Parameters:**
- `$Status` - Alert status: 'Open', 'Resolved', or 'All'

**Returns:** `[DRMMAlert[]]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$openAlerts = $site.GetAlerts('Open')
```

### Device Management

#### GetDevices()

Retrieves all devices in the site.

**Returns:** `[DRMMDevice[]]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$devices = $site.GetDevices()
```

#### GetDevices([long]$FilterId)

Retrieves devices matching the specified filter.

**Parameters:**
- `$FilterId` - The numeric ID of the device filter to apply

**Returns:** `[DRMMDevice[]]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$servers = $site.GetDevices(12345)
```

#### GetDeviceCount()

Returns the number of devices in the site without fetching device objects. This is a quick count using the DevicesStatus property.

**Returns:** `[int]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$count = $site.GetDeviceCount()
Write-Host "Site has $count devices"
```

### Variable Management

#### GetVariables()

Retrieves all site variables.

**Returns:** `[DRMMVariable[]]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$variables = $site.GetVariables()
```

#### GetVariable([string]$Name)

Retrieves a specific site variable by name.

**Parameters:**
- `$Name` - The variable name to retrieve

**Returns:** `[DRMMVariable]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$apiKey = $site.GetVariable("API_KEY")
```

#### NewVariable([string]$Name, [string]$Value)

Creates a new site variable with the specified name and value.

**Parameters:**
- `$Name` - The variable name
- `$Value` - The variable value

**Returns:** `[DRMMVariable]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$var = $site.NewVariable("BackupPath", "\\server\backup")
```

#### NewVariable([string]$Name, [string]$Value, [bool]$Masked)

Creates a new site variable with optional masking for sensitive data.

**Parameters:**
- `$Name` - The variable name
- `$Value` - The variable value
- `$Masked` - Whether to mask the variable value (for passwords, keys)

**Returns:** `[DRMMVariable]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$secret = $site.NewVariable("DB_PASSWORD", "P@ssw0rd!", $true)
```

### Filter Management

#### GetFilters()

Retrieves all device filters configured for the site.

**Returns:** `[DRMMFilter[]]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$filters = $site.GetFilters()
$filters | Format-Table Name, FilterId
```

#### GetFilter([string]$Name)

Retrieves a specific device filter by name.

**Parameters:**
- `$Name` - The filter name to retrieve

**Returns:** `[DRMMFilter]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$filter = $site.GetFilter("Windows Servers")
```

### Settings Management

#### GetSettings()

Retrieves the complete site settings object including general settings, proxy configuration, and other site-level configuration.

**Returns:** `[DRMMSiteSettings]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$settings = $site.GetSettings()
Write-Host "Site: $($settings.GeneralSettings.Name)"
```

#### SetProxy([string]$Host, [int]$Port, [string]$Type)

Configures a proxy server for the site without authentication.

**Parameters:**
- `$Host` - Proxy server hostname or IP address
- `$Port` - Proxy server port number
- `$Type` - Proxy type: 'HTTP', 'SOCKS4', or 'SOCKS5'

**Returns:** `[DRMMSiteSettings]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$site.SetProxy("proxy.contoso.com", 8080, "HTTP")
```

#### SetProxy([string]$Host, [int]$Port, [string]$Type, [string]$Username, [SecureString]$Password)

Configures an authenticated proxy server for the site.

**Parameters:**
- `$Host` - Proxy server hostname or IP address
- `$Port` - Proxy server port number
- `$Type` - Proxy type: 'HTTP', 'SOCKS4', or 'SOCKS5'
- `$Username` - Proxy authentication username
- `$Password` - Proxy authentication password (SecureString)

**Returns:** `[DRMMSiteSettings]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$pass = Read-Host -AsSecureString -Prompt "Proxy Password"
$site.SetProxy("proxy.contoso.com", 8080, "HTTP", "proxyuser", $pass)
```

#### RemoveProxy()

Removes proxy configuration from the site.

**Returns:** `[DRMMSiteSettings]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$site.RemoveProxy()
```

### Utility Methods

#### OpenPortal()

Opens the site's portal URL in the default browser.

**Returns:** `[void]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$site.OpenPortal()
```

#### Set([hashtable]$Properties)

Updates site properties using a hashtable of property names and values.

**Parameters:**
- `$Properties` - Hashtable containing properties to update:
  - Name `[string]` - Site name
  - Description `[string]` - Site description
  - Notes `[string]` - Site notes
  - OnDemand `[bool]` - On-demand status
  - SplashtopAutoInstall `[bool]` - Auto-install Splashtop

**Returns:** `[DRMMSite]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$site.Set(@{Name = "Contoso Limited"})
```

```powershell
$site = Get-RMMSite -Name "Test Site"
$site.Set(@{
    Description = "Updated description"
    Notes = "Migrated to new infrastructure"
    OnDemand = $true
})
```

#### GetSummary()

Returns a formatted summary string of the site.

**Returns:** `[string]`

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
Write-Host $site.GetSummary()
# Output: Contoso Ltd (abc-123-def) - Devices: 42
```

## RELATED CLASSES

### DRMMSiteSettings

Contains site configuration including general settings and proxy settings. Returned by GetSettings() and SetProxy() methods.

**Properties:**
- GeneralSettings `[DRMMSiteGeneralSettings]`
- ProxySettings `[DRMMSiteProxySettings]`

### DRMMSiteGeneralSettings

Contains general site configuration.

**Properties:**
- Name `[string]` - Site name
- Uid `[string]` - Site unique identifier
- Description `[string]` - Site description
- OnDemand `[bool]` - On-demand status

### DRMMSiteProxySettings

Contains proxy configuration for the site.

**Properties:**
- Host `[string]` - Proxy hostname
- Port `[int]` - Proxy port
- Type `[string]` - Proxy type (HTTP, SOCKS4, SOCKS5)
- Username `[string]` - Proxy username (if authenticated)

### DRMMDevicesStatus

Summary of device statuses for the site.

**Properties:**
- NumberOfDevices `[int]` - Total device count
- Online `[int]` - Online devices
- Offline `[int]` - Offline devices
- (Additional status properties available)

## METHOD CHAINING

DRMMSite methods return typed objects that support method chaining, enabling fluent API patterns:

```powershell
# Get filter, then get devices matching that filter
$site = Get-RMMSite -Name "Contoso Ltd"
$windowsServers = $site.GetFilter("Windows Servers").GetDevices()
```

```powershell
# Get all open alerts for filtered devices
$site = Get-RMMSite -Name "Contoso Ltd"
$criticalDevices = $site.GetFilter("Critical Infrastructure").GetDevices()
$alerts = $criticalDevices | ForEach-Object { $_.GetAlerts('Open') }
```

```powershell
# Chain multiple operations
$site = Get-RMMSite -Name "Contoso Ltd"
$settings = $site.GetSettings()
if ($settings.ProxySettings) {
    Write-Host "Proxy configured: $($settings.ProxySettings.Host)"
} else {
    $site.SetProxy("proxy.contoso.com", 8080, "HTTP")
}
```

## EXAMPLES

### Example 1: Get all devices and their alert counts

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$devices = $site.GetDevices()
foreach ($device in $devices) {
    $alertCount = ($device.GetAlerts('Open')).Count
    Write-Host "$($device.Hostname): $alertCount open alerts"
}
```

### Example 2: Create variables for a site

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$site.NewVariable("BackupServer", "\\backup01\share")
$site.NewVariable("AdminEmail", "admin@contoso.com")
$site.NewVariable("APIKey", "secret123", $true)
```

### Example 3: Configure site proxy with authentication

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$password = Read-Host -AsSecureString -Prompt "Proxy Password"
$site.SetProxy("proxy.contoso.com", 3128, "HTTP", "proxyuser", $password)
```

### Example 4: Get devices by filter name

```powershell
$site = Get-RMMSite -Name "Contoso Ltd"
$servers = $site.GetFilter("Windows Servers").GetDevices()
Write-Host "Found $($servers.Count) servers"
```

### Example 5: Bulk operations on all sites

```powershell
$sites = Get-RMMSite
foreach ($site in $sites) {
    $deviceCount = $site.GetDeviceCount()
    $openAlerts = ($site.GetAlerts('Open')).Count
    [PSCustomObject]@{
        Site    = $site.Name
        Devices = $deviceCount
        Alerts  = $openAlerts
    }
}
```

## BEST PRACTICES

1. Use GetDeviceCount() instead of GetDevices() when you only need the count, as it's significantly faster.

2. Always use Read-Host -AsSecureString for proxy passwords to avoid exposing credentials in scripts or console history.

3. When creating masked variables, set the $Masked parameter to $true for any sensitive data like passwords, API keys, or tokens.

4. Use method chaining to create readable, fluent code:
   ```powershell
   $site.GetFilter("name").GetDevices()
   ```
   Instead of:
   ```powershell
   $filter = Get-RMMDeviceFilter -SiteUid $site.Uid -Name "name"
   $devices = Get-RMMDevice -SiteUid $site.Uid -FilterId $filter.FilterId
   ```

5. Store site objects in variables when performing multiple operations to avoid repeated API calls:
   ```powershell
   $site = Get-RMMSite -Name "Contoso Ltd"
   $devices = $site.GetDevices()
   $alerts = $site.GetAlerts('Open')
   $variables = $site.GetVariables()
   ```

## NOTES

- All write operations (SetProxy, RemoveProxy, NewVariable) use the -Force parameter internally to bypass confirmation prompts, making them suitable for automation and batch operations.

- Methods that call module functions include error checking to ensure the required commands are available.

- The DRMMSite class inherits from DRMMObject, providing common functionality across all Datto RMM object types.

## SEE ALSO

- [Get-RMMSite](Get-RMMSite.md)
- Get-RMMSiteSettings
- Set-RMMSiteProxy
- Remove-RMMSiteProxy
- [Get-RMMDevice](Get-RMMDevice.md)
- [Get-RMMDeviceFilter](Get-RMMDeviceFilter.md)
- [Get-RMMVariable](Get-RMMVariable.md)
- New-RMMVariable
- [Get-RMMAlert](Get-RMMAlert.md)
- [about_DRMMDevice](about_DRMMDevice.md)
- [about_DRMMFilter](about_DRMMFilter.md)
- [about_DRMMAlert](about_DRMMAlert.md)
