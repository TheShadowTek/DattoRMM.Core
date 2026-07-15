# about_DRMMActivityLogDetailsUserSiteChangeSettings

## SHORT DESCRIPTION

Represents an activity log of entity USER, category site, and action change

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserSiteChangeSettings class models the details of a site settings change activity log entry. It inherits the 10 common USER entity properties from DRMMActivityLogDetailsUserSite and provides typed properties for the five observed fields (DataAction, DataSiteId, DataSiteName, DataSiteUid, DataVariable). Additional properties beyond these known fields are dynamically added as members, as the change

This class inherits from [DRMMActivityLogDetailsUserSite](./about_DRMMActivityLogDetailsUserSite.md).

## PROPERTIES

The DRMMActivityLogDetailsUserSiteChangeSettings class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataAction   | string | The action describing the type of settings change performed. |
| DataSiteId   | string | The numeric identifier of the site whose settings were changed. |
| DataSiteName | string | The display name of the site whose settings were changed. |
| DataSiteUid  | string | The unique identifier (UID) of the site whose settings were changed. |
| DataVariable | string | The specific site variable or setting that was changed. |

## METHODS

The DRMMActivityLogDetailsUserSiteChangeSettings class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserSiteChangeSettings.md)

