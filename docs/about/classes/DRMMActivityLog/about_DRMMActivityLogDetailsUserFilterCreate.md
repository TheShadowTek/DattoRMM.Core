# about_DRMMActivityLogDetailsUserFilterCreate

## SHORT DESCRIPTION

Represents an activity log of entity USER, category filter, and action create, which captures the details of a newly created device filter.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserFilterCreate class models the details of a filter creation activity log entry. It inherits the 12 common USER filter properties from DRMMActivityLogDetailsUserFilter and adds seven properties describing the new filter's configuration: DataAllSites, DataAssociation, DataDeviceFilterCriterionInputs, DataFilterType, DataRoleIds, DataSharedRoles, and DataSiteIds.

This class inherits from [DRMMActivityLogDetailsUserFilter](./about_DRMMActivityLogDetailsUserFilter.md).

## PROPERTIES

The DRMMActivityLogDetailsUserFilterCreate class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataAllSites                    | string | Indicates whether the filter applies to all sites. |
| DataAssociation                 | string | The association setting of the filter. |
| DataDeviceFilterCriterionInputs | string | The device filter criterion inputs defining the filter conditions. |
| DataFilterType                  | string | The type of the filter being created. |
| DataRoleIds                     | string | The role identifiers associated with the filter. |
| DataSharedRoles                 | string | The roles with which the filter is shared. |
| DataSiteIds                     | string | The site identifiers the filter is restricted to. |

## METHODS

The DRMMActivityLogDetailsUserFilterCreate class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserFilterCreate.md)

