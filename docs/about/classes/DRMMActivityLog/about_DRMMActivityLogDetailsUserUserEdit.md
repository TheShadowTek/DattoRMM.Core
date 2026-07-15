# about_DRMMActivityLogDetailsUserUserEdit

## SHORT DESCRIPTION

Represents an activity log of entity USER, category user, and action edit, which includes specific properties related to user account edit activities.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserUserEdit class models the details of a user account edit activity log entry. It inherits the 12 common USER user management properties from DRMMActivityLogDetailsUserUser and adds typed properties for the 6 observed edit fields (roles changed, email, enabled state, first name, last name). Any additional properties not covered by the known typed fields are dynamically added as members, as the edit payload may vary depending on what was changed.

This class inherits from [DRMMActivityLogDetailsUserUser](./about_DRMMActivityLogDetailsUserUser.md).

## PROPERTIES

The DRMMActivityLogDetailsUserUserEdit class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataDeletedRoles  | string | The roles that were removed from the user account during the edit. |
| DataNewRoles      | string | The roles that were added to the user account during the edit. |
| DataUserEmail     | string | The email address of the user account that was edited. |
| DataUserEnabled   | string | Indicates whether the user account is enabled after the edit. |
| DataUserFirstname | string | The first name of the user account that was edited. |
| DataUserLastname  | string | The last name of the user account that was edited. |

## METHODS

The DRMMActivityLogDetailsUserUserEdit class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserUserEdit.md)

