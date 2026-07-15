# about_DRMMActivityLogDetailsUserGeneric

## SHORT DESCRIPTION

Represents a generic USER entity activity log for unknown categories, with entity-level properties and dynamic additional properties.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserGeneric class is used for USER entity activity logs where the category is not yet mapped to a dedicated class. It inherits the 10 base properties common to all USER activities (Entity, EventAction, EventCategory, Uid, SourceForwardedIp, UserEmail, UserFirstName, UserId, UserLastName, UserUsername) and dynamically adds any additional properties found in the response. This ensures type safety for known entity-level properties while maintaining flexibility for unknown categories.

This class inherits from [DRMMActivityLogEntityUser](./about_DRMMActivityLogEntityUser.md).

## PROPERTIES

The DRMMActivityLogDetailsUserGeneric class exposes the following properties:

No public properties defined.\n
## METHODS

The DRMMActivityLogDetailsUserGeneric class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserGeneric.md)

