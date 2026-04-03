# about_DRMMActivityLogEntityDevice

## SHORT DESCRIPTION

Base class for DEVICE entity activity log details, containing properties common to all DEVICE activities.

## LONG DESCRIPTION

The DRMMActivityLogEntityDevice class serves as a base class for all DEVICE entity activity logs, regardless of category. It encapsulates the 6 core properties that appear in all DEVICE activities: DeviceHostname, DeviceUid, Entity, EventAction, EventCategory, and Uid. Category-specific classes (job, remote, device) inherit from this class and add their category-specific properties.

This class inherits from [DRMMActivityLogDetails](./about_DRMMActivityLogDetails.md).

## PROPERTIES

The DRMMActivityLogEntityDevice class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DeviceHostname | string | The hostname of the device associated with the activity. |
| DeviceUid      | guid   | The unique identifier (UID) of the device associated with the activity. |
| Entity         | string | The entity type of the activity log entry (e.g., DEVICE). |
| EventAction    | string | The specific action that was performed (e.g., deployment, create, move.device). |
| EventCategory  | string | The category of the event (e.g., job, remote, device). |
| Uid            | guid   | The unique identifier of the activity log detail entry. |

## METHODS

The DRMMActivityLogEntityDevice class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogEntityDevice.md)

