# about_DRMMActivityLogDetailsUserSiteCreate

## SHORT DESCRIPTION

Represents an activity log of entity USER, category site, and action create, which includes specific properties related to site creation activities.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserSiteCreate class models the details of a site creation activity log entry. It inherits the 10 common USER entity properties from DRMMActivityLogDetailsUserSite and adds four properties describing the newly created site: its description, numeric identifier, display name, and unique identifier.

This class inherits from [DRMMActivityLogDetailsUserSite](./about_DRMMActivityLogDetailsUserSite.md).

## PROPERTIES

The DRMMActivityLogDetailsUserSiteCreate class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataSiteDescription | string | The description provided for the newly created site. |
| DataSiteId          | string | The numeric identifier assigned to the newly created site. |
| DataSiteName        | string | The display name of the newly created site. |
| DataSiteUid         | string | The unique identifier (UID) assigned to the newly created site. |

## METHODS

The DRMMActivityLogDetailsUserSiteCreate class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserSiteCreate.md)

