# about_DRMMActivityLogDetailsUserAgent

## SHORT DESCRIPTION

Base class for USER agent-related activity log details, containing properties common to all agent session actions.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserAgent class serves as a base class for USER entity agent category activity logs. It encapsulates 6 properties common to all observed agent session actions — DataDeviceId, DataDeviceName, DataDeviceUid, DataDirect, DataEnd, and DataStart — in addition to the 10 entity-level properties inherited from DRMMActivityLogEntityUser. Specific agent action types inherit from this class and add their unique properties.

This class inherits from [DRMMActivityLogEntityUser](./about_DRMMActivityLogEntityUser.md).

## PROPERTIES

The DRMMActivityLogDetailsUserAgent class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataDeviceId   | string | The identifier of the device the agent session was performed on. |
| DataDeviceName | string | The display name of the device the agent session was performed on. |
| DataDeviceUid  | string | The unique identifier (UID) of the device the agent session was performed on. |
| DataDirect     | string | Indicates whether the agent session was a direct connection. |
| DataEnd        | string | The end time or timestamp of the agent session. |
| DataStart      | string | The start time or timestamp of the agent session. |

## METHODS

The DRMMActivityLogDetailsUserAgent class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserAgent.md)

