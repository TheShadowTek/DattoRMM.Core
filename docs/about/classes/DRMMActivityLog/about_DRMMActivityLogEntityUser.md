# about_DRMMActivityLogEntityUser

## SHORT DESCRIPTION

Base class for USER entity activity log details, containing properties common to all USER activities.

## LONG DESCRIPTION

The DRMMActivityLogEntityUser class serves as a base class for all USER entity activity logs, regardless of category. It encapsulates the 10 core properties that appear in all USER activities: Entity, EventAction, EventCategory, Uid, SourceForwardedIp, UserEmail, UserFirstName, UserId, UserLastName, and UserUsername. These properties are common across all observed USER entity combinations. Category-specific classes (account, agent, component, device, monitor, policy, site, user) inherit from this class and add their category-specific properties.

This class inherits from [DRMMActivityLogDetails](./about_DRMMActivityLogDetails.md).

## PROPERTIES

The DRMMActivityLogEntityUser class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Entity            | string | The entity type of the activity log entry (e.g., USER). |
| EventAction       | string | The specific action that was performed in the user activity. |
| EventCategory     | string | The category of the user event (e.g., account, agent, policy, site). |
| Uid               | guid   | The unique identifier of the activity log detail entry. |
| SourceForwardedIp | string | The forwarded IP address of the source that performed the user activity. |
| UserEmail         | string | The email address of the user who performed the activity. |
| UserFirstName     | string | The first name of the user who performed the activity. |
| UserId            | long   | The identifier of the user who performed the activity. |
| UserLastName      | string | The last name of the user who performed the activity. |
| UserUsername      | string | The username of the user who performed the activity. |

## METHODS

The DRMMActivityLogEntityUser class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogEntityUser.md)

