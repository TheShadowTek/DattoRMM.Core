# about_DRMMActivityLogDetailsDeviceJobDeployment

## SHORT DESCRIPTION

Represents an activity log of entity DEVICE, category job, and action deployment, which includes specific properties related to job deployment activities.

## LONG DESCRIPTION

The DRMMActivityLogDetailsDeviceJobDeployment class models the details of a job deployment activity log entry. It inherits common job properties from DRMMActivityLogDetailsDeviceJob and adds deployment-specific properties such as deployment ID, scheduled job information, and notes.

This class inherits from [DRMMActivityLogDetailsDeviceJob](./about_DRMMActivityLogDetailsDeviceJob.md).

## PROPERTIES

The DRMMActivityLogDetailsDeviceJobDeployment class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| JobDeploymentId    | long   | The identifier of the job deployment. |
| JobScheduledJobId  | long   | The identifier of the scheduled job associated with the deployment. |
| JobScheduledJobUid | guid   | The unique identifier (UID) of the scheduled job associated with the deployment. |
| Note               | string | An optional note or comment associated with the job deployment. |

## METHODS

The DRMMActivityLogDetailsDeviceJobDeployment class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsDeviceJobDeployment.md)

