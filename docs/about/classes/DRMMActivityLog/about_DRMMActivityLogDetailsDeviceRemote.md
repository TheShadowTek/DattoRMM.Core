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
| RemoteSessionDetails   | DRMMActivityLogDetailsRemoteSessionDetail[] | An array of DRMMActivityLogDetailsRemoteSessionDetail objects describing individual events or steps within the remote session. |
| RemoteSessionId        | long                                        | The numeric identifier of the remote session. |
| RemoteSessionStartDate | nullable[datetime]                          | The date and time when the remote session started. |
| RemoteSessionType      | string                                      | The type of remote session (e.g., chat, jrto). |
| SiteName               | string                                      | The name of the site associated with the remote session. |
| SourceForwardedIp      | string                                      | The forwarded IP address of the source that initiated the remote session. |
| UserEmail              | string                                      | The email address of the user who initiated the remote session. |
| UserFirstName          | string                                      | The first name of the user who initiated the remote session. |
| UserId                 | long                                        | The identifier of the user who initiated the remote session. |
| UserLastName           | string                                      | The last name of the user who initiated the remote session. |
| UserUsername           | string                                      | The username of the user who initiated the remote session. |

## METHODS

The DRMMActivityLogDetailsDeviceRemote class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsDeviceRemote.md)
