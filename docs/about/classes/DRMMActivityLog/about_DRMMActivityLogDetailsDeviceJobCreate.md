# about_DRMMActivityLogDetailsDeviceJobCreate

## SHORT DESCRIPTION

Represents an activity log of entity DEVICE, category job, and action create, which includes specific properties related to job creation activities.

## LONG DESCRIPTION

The DRMMActivityLogDetailsDeviceJobCreate class models the details of a job creation activity log entry. It inherits common job properties from DRMMActivityLogDetailsDeviceJob and adds creation-specific properties such as the job creation date and user information (email, first name, last name, username, user ID).

This class inherits from [DRMMActivityLogDetailsDeviceJob](./about_DRMMActivityLogDetailsDeviceJob.md).

## PROPERTIES

The DRMMActivityLogDetailsDeviceJobCreate class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| JobDateCreated | nullable[datetime] | Add description |
| UserEmail      | string             | Add description |
| UserFirstName  | string             | Add description |
| UserId         | long               | Add description |
| UserLastName   | string             | Add description |
| UserUsername   | string             | Add description |

## METHODS

The DRMMActivityLogDetailsDeviceJobCreate class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsDeviceJobCreate.md)
