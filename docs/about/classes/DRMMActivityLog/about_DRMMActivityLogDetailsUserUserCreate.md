# about_DRMMActivityLogDetailsUserUserCreate

## SHORT DESCRIPTION

Represents an activity log of entity USER, category user, and action create, which includes properties describing the user account that was created.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserUserCreate class models the details of a user account creation activity log entry. It inherits the 12 common USER user management properties from DRMMActivityLogDetailsUserUser (10 entity-level plus DataUserId and DataUserName) and adds six properties describing the new user account: DataDeletedRoles, DataNewRoles, DataUserEmail, DataUserEnabled, DataUserFirstname, and DataUserLastname.

This class inherits from [DRMMActivityLogDetailsUserUser](./about_DRMMActivityLogDetailsUserUser.md).

## PROPERTIES

The DRMMActivityLogDetailsUserUserCreate class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataDeletedRoles  | string | The roles that were removed from the user account at creation (typically empty). |
| DataNewRoles      | string | The roles assigned to the newly created user account. |
| DataUserEmail     | string | The email address of the newly created user account. |
| DataUserEnabled   | string | Whether the newly created user account is enabled. |
| DataUserFirstname | string | The first name of the newly created user account. |
| DataUserLastname  | string | The last name of the newly created user account. |

## METHODS

The DRMMActivityLogDetailsUserUserCreate class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserUserCreate.md)

