# Set-RMMDeviceWarranty

## SYNOPSIS
Sets the warranty expiration date on a device in Datto RMM.

## SYNTAX

ByDeviceUid (Default)
```
Set-RMMDeviceWarranty -DeviceUid <Guid> -WarrantyDate <DateTime> [-Force] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

ByDeviceObject
```
Set-RMMDeviceWarranty -Device <DRMMDevice> -WarrantyDate <DateTime> [-Force]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Set-RMMDeviceWarranty function updates the warranty expiration date for a device
in the Datto RMM system.
The warranty date is used for asset management, tracking
hardware support coverage, and planning device refresh cycles.

The warranty date can be set to a specific date or cleared by passing $null.

## EXAMPLES

EXAMPLE 1
```
Set-RMMDeviceWarranty -DeviceUid $DeviceUid -WarrantyDate (Get-Date "2027-12-31")
```

Sets the warranty expiration date to December 31, 2027.

EXAMPLE 2
```
Get-RMMDevice -Hostname "SERVER01" | Set-RMMDeviceWarranty -WarrantyDate (Get-Date).AddYears(3)
```

Sets the warranty date to 3 years from today via pipeline.

EXAMPLE 3
```
Set-RMMDeviceWarranty -DeviceUid $DeviceUid -WarrantyDate $null -Force
```

Clears the warranty date without confirmation.

EXAMPLE 4
```
$Site = Get-RMMSite -Name "Chicago Office"
$Filter = Get-RMMDeviceFilter -SiteUid $Site.Uid | Where-Object {$_.Name -eq "Dell Latitude 7490"}
Get-RMMDevice -FilterId $Filter.FilterId | Set-RMMDeviceWarranty -WarrantyDate (Get-Date "2026-06-30")
```

Sets the warranty date for all Dell Latitude 7490 laptops at the Chicago Office site.

EXAMPLE 5
```
# Bulk update warranties from a CSV file
$Warranties = Import-Csv -Path "device_warranties.csv"
# CSV format: DeviceUid,WarrantyDate
# Example row: a1b2c3d4-e5f6-7890-abcd-ef1234567890,2027-12-31
```

foreach ($Item in $Warranties) {
    Set-RMMDeviceWarranty -DeviceUid $Item.DeviceUid -WarrantyDate (\[datetime\]$Item.WarrantyDate) -Force
}

Imports warranty dates from a CSV and updates devices in bulk.

EXAMPLE 6
```
# Set warranty dates from CSV using serial number matching
$Warranties = Import-Csv -Path "warranty_imports.csv"
# CSV format: SerialNumber,WarrantyDate
# Example row: ABC123456,2028-03-15
```

$Site = Get-RMMSite -Name "Boston Office"
$Devices = Get-RMMDevice -SiteUid $Site.Uid

foreach ($Item in $Warranties) {
    $Device = $Devices | Where-Object {$_.SerialNumber -eq $Item.SerialNumber}
    if ($Device) {
        $Device | Set-RMMDeviceWarranty -WarrantyDate (\[datetime\]$Item.WarrantyDate) -Force
        Write-Host "Updated warranty for $($Device.Hostname) (SN: $($Item.SerialNumber))"
    }
}

Imports warranties from a CSV and matches devices by serial number at a specific site.

## PARAMETERS

### -Device
A DRMMDevice object to update.
Accepts pipeline input from Get-RMMDevice.

```yaml
Type: DRMMDevice
Parameter Sets: ByDeviceObject
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -DeviceUid
The unique identifier (GUID) of the device to update.

```yaml
Type: Guid
Parameter Sets: ByDeviceUid
Aliases: Uid

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -WarrantyDate
The warranty expiration date as a DateTime object.
Set to $null to clear the warranty date.
The date will be formatted as ISO 8601 (yyyy-MM-dd) when sent to the API.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Bypasses the confirmation prompt.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

DRMMDevice. You can pipe device objects from Get-RMMDevice.
You can also pipe objects with DeviceUid or Uid properties.
## OUTPUTS

None. This function does not return any output.
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

Best practices for warranty management:
- Update warranty dates when purchasing new devices
- Use filters to identify devices with expired warranties
- Track warranty dates to plan device refresh cycles
- Set reminders to review warranties quarterly
- Clear warranty dates for devices that are no longer under warranty

## RELATED LINKS

[about_DRMMDevice](https://github.com/boabf/Datto-RMM/blob/main/docs/about_DRMMDevice.md)

[Get-RMMDevice](https://github.com/boabf/Datto-RMM/blob/main/docs/Get-RMMDevice.md)


