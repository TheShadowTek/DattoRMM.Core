# about_DRMMActivityLogDetailsUserJobCreate

## SHORT DESCRIPTION

Represents an activity log of entity USER, category job, and action create, which captures the details of a newly created job.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserJobCreate class models the details of a job creation activity log entry. It inherits the 12 common USER job properties from DRMMActivityLogDetailsUserJob and adds three properties: DataJobUid, the unique identifier of the new job; DataType, the type classification of the job; and DataJobStatus, the initial status of the job.

This class inherits from [DRMMActivityLogDetailsUserJob](./about_DRMMActivityLogDetailsUserJob.md).

## PROPERTIES

The DRMMActivityLogDetailsUserJobCreate class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataJobUid | guid   | The unique identifier (UID) of the job that was created. |
| DataType   | string | The type classification of the job (e.g., script, patch). |

## METHODS

The DRMMActivityLogDetailsUserJobCreate class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserJobCreate.md)

