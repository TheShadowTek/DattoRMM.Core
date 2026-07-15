# about_DRMMActivityLogDetailsUserComponentUpdate

## SHORT DESCRIPTION

Represents an activity log of entity USER, category component, and action update, which includes an additional security level property.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserComponentUpdate class models the details of a component update activity log entry. It inherits the 13 common USER component properties from DRMMActivityLogDetailsUserComponent (10 entity-level plus DataComponentId, DataComponentName, and DataComponentUid) and adds one update-specific property: DataSecurityLevel, which records the security level assigned during the update.

This class inherits from [DRMMActivityLogDetailsUserComponent](./about_DRMMActivityLogDetailsUserComponent.md).

## PROPERTIES

The DRMMActivityLogDetailsUserComponentUpdate class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataSecurityLevel | string | The security level assigned to the component during the update. |

## METHODS

The DRMMActivityLogDetailsUserComponentUpdate class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserComponentUpdate.md)

