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
| DeviceHostname | string | Add description |
| DeviceUid      | guid   | Add description |
| Entity         | string | Add description |
| EventAction    | string | Add description |
| EventCategory  | string | Add description |
| Uid            | guid   | Add description |

## METHODS

The DRMMActivityLogEntityDevice class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMActivityLog/about_DRMMActivityLogEntityDevice.md)
