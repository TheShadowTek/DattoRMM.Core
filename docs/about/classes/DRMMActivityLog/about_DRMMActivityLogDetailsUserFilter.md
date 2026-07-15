# about_DRMMActivityLogDetailsUserFilter

## SHORT DESCRIPTION

Base class for USER filter-related activity log details, containing properties common to all filter actions.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserFilter class serves as a base class for USER entity filter category activity logs. It encapsulates two properties common to all observed filter actions — DataFilterId and DataFilterName — in addition to the 10 entity-level properties inherited from DRMMActivityLogEntityUser. Specific filter action types inherit from this class and add their unique properties.

This class inherits from [DRMMActivityLogEntityUser](./about_DRMMActivityLogEntityUser.md).

## PROPERTIES

The DRMMActivityLogDetailsUserFilter class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataFilterId   | long   | The numeric identifier of the filter associated with the activity. |
| DataFilterName | string | The display name of the filter associated with the activity. |

## METHODS

The DRMMActivityLogDetailsUserFilter class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserFilter.md)

