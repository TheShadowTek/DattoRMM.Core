# about_DRMMActivityLogDetailsDeviceRemote

## SHORT DESCRIPTION

Base class for DEVICE remote-related activity log details, containing properties common to all remote session actions.

## LONG DESCRIPTION

The DRMMActivityLogDetailsDeviceRemote class serves as a base class for DEVICE entity remote category activity logs. It encapsulates properties that are common across different remote session actions (chat, jrto, etc.), including remote session details, site information, user information, and source forwarding details, in addition to the entity-level DEVICE properties inherited from DRMMActivityLogEntityDevice. Specific remote action types inherit from this class and add their unique properties if needed.

This class inherits from [DRMMActivityLogEntityDevice](./about_DRMMActivityLogEntityDevice.md).

## PROPERTIES

The DRMMActivityLogDetailsDeviceRemote class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| RemoteSessionDetails   | DRMMActivityLogDetailsRemoteSessionDetail[] | Add description |
| RemoteSessionId        | long                                        | Add description |
| RemoteSessionStartDate | nullable[datetime]                          | Add description |
| RemoteSessionType      | string                                      | Add description |
| SiteName               | string                                      | Add description |
| SourceForwardedIp      | string                                      | Add description |
| UserEmail              | string                                      | Add description |
| UserFirstName          | string                                      | Add description |
| UserId                 | long                                        | Add description |
| UserLastName           | string                                      | Add description |
| UserUsername           | string                                      | Add description |

## METHODS

The DRMMActivityLogDetailsDeviceRemote class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsDeviceRemote.md)
