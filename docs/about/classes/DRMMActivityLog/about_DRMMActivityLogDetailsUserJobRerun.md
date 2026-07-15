# about_DRMMActivityLogDetailsUserJobRerun

## SHORT DESCRIPTION

Represents an activity log of entity USER, category job, and action rerun, which captures the details of a job that was re-executed against a set of devices.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserJobRerun class models the details of a job rerun activity log entry. It inherits the 12 common USER job properties from DRMMActivityLogDetailsUserJob and adds three properties: DataDeviceUids, the list of device UIDs the job was re-run against; DataJobUid, the unique identifier of the re-run job; and DataType, the type classification of the job.

This class inherits from [DRMMActivityLogDetailsUserJob](./about_DRMMActivityLogDetailsUserJob.md).

## PROPERTIES

The DRMMActivityLogDetailsUserJobRerun class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataDeviceUids | string | The list of device UIDs the job was re-run against. |
| DataJobUid     | guid   | The unique identifier (UID) of the job that was re-run. |
| DataType       | string | The type classification of the job (e.g., script, patch). |

## METHODS

The DRMMActivityLogDetailsUserJobRerun class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserJobRerun.md)

