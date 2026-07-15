# about_DRMMActivityLogDetailsUserUser

## SHORT DESCRIPTION

Base class for USER user-related activity log details, containing properties common to all user management actions.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserUser class serves as a base class for USER entity user category activity logs. It encapsulates two properties common to all observed user management actions — DataUserId and DataUserName — in addition to the 10 entity-level properties inherited from DRMMActivityLogEntityUser. Specific user action types inherit from this class and add their unique properties.

This class inherits from [DRMMActivityLogEntityUser](./about_DRMMActivityLogEntityUser.md).

## PROPERTIES

The DRMMActivityLogDetailsUserUser class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataUserId   | string | The identifier of the user account that is the subject of the activity. |
| DataUserName | string | The username of the user account that is the subject of the activity. |

## METHODS

The DRMMActivityLogDetailsUserUser class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserUser.md)

