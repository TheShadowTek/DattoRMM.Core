# about_DRMMActivityLogEntityUser

## SHORT DESCRIPTION

Base class for USER entity activity log details, containing properties common to all USER activities.

## LONG DESCRIPTION

The DRMMActivityLogEntityUser class serves as a base class for all USER entity activity logs. As of this implementation, USER entity activities have not been observed in the wild, so this class is a placeholder for future expansion. It will likely contain properties such as UserId, UserUsername, Entity, EventAction, EventCategory, and Uid once USER activities are documented.

This class inherits from [DRMMActivityLogDetails](./about_DRMMActivityLogDetails.md).

## PROPERTIES

The DRMMActivityLogEntityUser class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Entity        | string | The entity type of the activity log entry (e.g., USER). |
| EventAction   | string | The specific action that was performed in the user activity. |
| EventCategory | string | The category of the user event. |
| Uid           | guid   | The unique identifier of the activity log detail entry. |

## METHODS

The DRMMActivityLogEntityUser class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogEntityUser.md)

