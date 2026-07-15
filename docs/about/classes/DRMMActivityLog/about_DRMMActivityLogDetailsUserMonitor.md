# about_DRMMActivityLogDetailsUserMonitor

## SHORT DESCRIPTION

Base class for USER monitor-related activity log details, containing properties common to all monitor actions.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserMonitor class serves as a base class for USER entity monitor category activity logs. It encapsulates two properties common to all observed monitor actions — DataIsDeviceMonitor and DataMonitorId — in addition to the 10 entity-level properties inherited from DRMMActivityLogEntityUser. Specific monitor action types inherit from this class and add their unique properties.

This class inherits from [DRMMActivityLogEntityUser](./about_DRMMActivityLogEntityUser.md).

## PROPERTIES

The DRMMActivityLogDetailsUserMonitor class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataIsDeviceMonitor | string | Indicates whether the monitor is a device-level monitor rather than a policy-level monitor. |
| DataMonitorId       | string | The identifier of the monitor that was created or edited. |

## METHODS

The DRMMActivityLogDetailsUserMonitor class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserMonitor.md)

