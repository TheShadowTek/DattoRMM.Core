# about_DRMMActivityLogDetailsDeviceJob

## SHORT DESCRIPTION

Base class for DEVICE job-related activity log details, containing properties common to all job actions.

## LONG DESCRIPTION

The DRMMActivityLogDetailsDeviceJob class serves as a base class for DEVICE entity job category activity logs. It encapsulates properties that are common across different job actions (deployment, create, etc.), including job identifiers and site information, in addition to the entity-level DEVICE properties inherited from DRMMActivityLogEntityDevice. Specific job action types inherit from this class and add their unique properties.

This class inherits from [DRMMActivityLogEntityDevice](./about_DRMMActivityLogEntityDevice.md).

## PROPERTIES

The DRMMActivityLogDetailsDeviceJob class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| JobId     | long   | The numeric identifier of the job associated with the activity. |
| JobName   | string | The name of the job associated with the activity. |
| JobStatus | string | The status of the job at the time of the activity (e.g., completed, failed). |
| JobUid    | guid   | The unique identifier (UID) of the job associated with the activity. |
| SiteName  | string | The name of the site where the job was executed. |

## METHODS

The DRMMActivityLogDetailsDeviceJob class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsDeviceJob.md)

