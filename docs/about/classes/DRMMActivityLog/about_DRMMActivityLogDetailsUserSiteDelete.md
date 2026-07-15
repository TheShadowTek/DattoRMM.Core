# about_DRMMActivityLogDetailsUserSiteDelete

## SHORT DESCRIPTION

Represents an activity log of entity USER, category site, and action delete, which identifies the site that was deleted.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserSiteDelete class models the details of a site deletion activity log entry. It inherits the 10 common USER entity properties from DRMMActivityLogDetailsUserSite and adds three properties identifying the deleted site: DataSiteId, DataSiteName, and DataSiteUid.

This class inherits from [DRMMActivityLogDetailsUserSite](./about_DRMMActivityLogDetailsUserSite.md).

## PROPERTIES

The DRMMActivityLogDetailsUserSiteDelete class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataSiteId   | string | The numeric identifier of the site that was deleted. |
| DataSiteName | string | The display name of the site that was deleted. |
| DataSiteUid  | string | The unique identifier (UID) of the site that was deleted. |

## METHODS

The DRMMActivityLogDetailsUserSiteDelete class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserSiteDelete.md)

