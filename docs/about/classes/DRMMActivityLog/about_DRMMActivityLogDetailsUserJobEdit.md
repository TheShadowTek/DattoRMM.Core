# about_DRMMActivityLogDetailsUserJobEdit

## SHORT DESCRIPTION

Represents an activity log of entity USER, category job, and action edit, which captures the details of an edited job.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserJobEdit class models the details of a job edit activity log entry. It inherits the 12 common USER job properties from DRMMActivityLogDetailsUserJob and adds two properties: DataJobUid, the unique identifier of the edited job; and DataType, the type classification of the job.

This class inherits from [DRMMActivityLogDetailsUserJob](./about_DRMMActivityLogDetailsUserJob.md).

## PROPERTIES

The DRMMActivityLogDetailsUserJobEdit class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataJobUid | guid   | The unique identifier (UID) of the job that was edited. |
| DataType   | string | The type classification of the job (e.g., script, patch). |

## METHODS

The DRMMActivityLogDetailsUserJobEdit class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserJobEdit.md)

