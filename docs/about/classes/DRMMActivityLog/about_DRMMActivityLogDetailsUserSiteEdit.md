# about_DRMMActivityLogDetailsUserSiteEdit

## SHORT DESCRIPTION

Represents an activity log of entity USER, category site, and action edit, with known site properties and dynamic overflow for additional fields.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserSiteEdit class models the details of a site edit activity log entry. It inherits the 10 common USER entity properties from DRMMActivityLogDetailsUserSite and provides typed properties for the four observed edit fields (DataSiteDescription, DataSiteId, DataSiteName, DataSiteUid). Additional properties beyond these known fields are dynamically added as members, as site edit payloads may include other fields depending on what was changed.

This class inherits from [DRMMActivityLogDetailsUserSite](./about_DRMMActivityLogDetailsUserSite.md).

## PROPERTIES

The DRMMActivityLogDetailsUserSiteEdit class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataSiteDescription | string | The description of the site after the edit. |
| DataSiteId          | string | The numeric identifier of the site that was edited. |
| DataSiteName        | string | The display name of the site that was edited. |
| DataSiteUid         | string | The unique identifier (UID) of the site that was edited. |

## METHODS

The DRMMActivityLogDetailsUserSiteEdit class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserSiteEdit.md)

