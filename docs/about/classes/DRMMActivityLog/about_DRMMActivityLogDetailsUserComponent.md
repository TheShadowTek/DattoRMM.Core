# about_DRMMActivityLogDetailsUserComponent

## SHORT DESCRIPTION

Base class for USER component-related activity log details, containing properties common to all component actions.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserComponent class serves as a base class for USER entity component category activity logs. All observed component actions share three category-level properties — DataComponentId, DataComponentName, and DataComponentUid — in addition to the 10 entity-level properties inherited from DRMMActivityLogEntityUser. Specific component action types inherit from this class and add their unique properties.

This class inherits from [DRMMActivityLogEntityUser](./about_DRMMActivityLogEntityUser.md).

## PROPERTIES

The DRMMActivityLogDetailsUserComponent class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataComponentId   | string | The numeric identifier of the component subject to the activity. |
| DataComponentName | string | The display name of the component subject to the activity. |
| DataComponentUid  | string | The unique identifier (UID) of the component subject to the activity. |

## METHODS

The DRMMActivityLogDetailsUserComponent class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserComponent.md)

