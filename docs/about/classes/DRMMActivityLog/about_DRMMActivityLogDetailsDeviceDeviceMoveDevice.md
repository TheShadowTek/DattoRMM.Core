# about_DRMMActivityLogDetailsDeviceDeviceMoveDevice

## SHORT DESCRIPTION

Represents an activity log of entity DEVICE, category device, and action move

## LONG DESCRIPTION

The DRMMActivityLogDetailsDeviceDeviceMoveDevice class models the details of a device site movement activity log entry. It inherits common device properties from DRMMActivityLogDetailsDeviceDevice and adds movement-specific properties including source and destination site information (IDs, names, UIDs), site name, and user information (email, first name, last name, username, user ID) related to the device move operation.

This class inherits from [DRMMActivityLogDetailsDeviceDevice](./about_DRMMActivityLogDetailsDeviceDevice.md).

## PROPERTIES

The DRMMActivityLogDetailsDeviceDeviceMoveDevice class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataFromSiteId   | long   | Add description |
| DataFromSiteName | string | Add description |
| DataFromSiteUid  | guid   | Add description |
| DataToSiteId     | long   | Add description |
| DataToSiteName   | string | Add description |
| DataToSiteUid    | guid   | Add description |
| SiteName         | string | Add description |
| UserEmail        | string | Add description |
| UserFirstName    | string | Add description |
| UserId           | long   | Add description |
| UserLastName     | string | Add description |
| UserUsername     | string | Add description |

## METHODS

The DRMMActivityLogDetailsDeviceDeviceMoveDevice class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsDeviceDeviceMoveDevice.md)
