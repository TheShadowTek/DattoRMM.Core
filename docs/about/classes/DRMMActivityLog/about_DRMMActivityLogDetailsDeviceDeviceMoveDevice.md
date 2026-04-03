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
| DataFromSiteId   | long   | The identifier of the site the device was moved from. |
| DataFromSiteName | string | The name of the site the device was moved from. |
| DataFromSiteUid  | guid   | The unique identifier (UID) of the site the device was moved from. |
| DataToSiteId     | long   | The identifier of the site the device was moved to. |
| DataToSiteName   | string | The name of the site the device was moved to. |
| DataToSiteUid    | guid   | The unique identifier (UID) of the site the device was moved to. |
| SiteName         | string | The name of the site associated with the device move operation. |
| UserEmail        | string | The email address of the user who performed the device move. |
| UserFirstName    | string | The first name of the user who performed the device move. |
| UserId           | long   | The identifier of the user who performed the device move. |
| UserLastName     | string | The last name of the user who performed the device move. |
| UserUsername     | string | The username of the user who performed the device move. |

## METHODS

The DRMMActivityLogDetailsDeviceDeviceMoveDevice class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsDeviceDeviceMoveDevice.md)

