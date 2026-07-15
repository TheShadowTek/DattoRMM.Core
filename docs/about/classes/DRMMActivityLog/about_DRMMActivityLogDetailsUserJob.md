# about_DRMMActivityLogDetailsUserJob

## SHORT DESCRIPTION

Base class for USER job-related activity log details, containing properties common to all job actions.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserJob class serves as a base class for USER entity job category activity logs. It encapsulates two properties common to most observed job actions — DataJobId and DataJobName — in addition to the 10 entity-level properties inherited from DRMMActivityLogEntityUser. Specific job action types inherit from this class and add their unique properties.

This class inherits from [DRMMActivityLogEntityUser](./about_DRMMActivityLogEntityUser.md).

## PROPERTIES

The DRMMActivityLogDetailsUserJob class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataJobId   | long   | The numeric identifier of the job associated with the activity. |
| DataJobName | string | The display name of the job associated with the activity. |

## METHODS

The DRMMActivityLogDetailsUserJob class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserJob.md)

