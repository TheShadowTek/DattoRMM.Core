# about_DRMMActivityLogDetailsUserDeviceMoveDevice

## SHORT DESCRIPTION

Represents an activity log of entity USER, category device, and action move

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserDeviceMoveDevice class models the details of a user-initiated device site move activity log entry. It inherits the 10 common USER entity properties from DRMMActivityLogDetailsUserDevice and adds properties identifying the device and destination site involved in the move.

This class inherits from [DRMMActivityLogDetailsUserDevice](./about_DRMMActivityLogDetailsUserDevice.md).

## PROPERTIES

The DRMMActivityLogDetailsUserDeviceMoveDevice class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataDeviceHostname | string | The hostname of the device that was moved. |
| DataDeviceId       | string | The identifier of the device that was moved. |
| DataDeviceUid      | string | The unique identifier (UID) of the device that was moved. |
| DataSiteId         | string | The identifier of the site the device was moved to. |
| DataSiteName       | string | The name of the site the device was moved to. |
| DataSiteUid        | string | The unique identifier (UID) of the site the device was moved to. |

## METHODS

The DRMMActivityLogDetailsUserDeviceMoveDevice class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserDeviceMoveDevice.md)

