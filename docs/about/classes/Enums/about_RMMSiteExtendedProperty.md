# about_RMMSiteExtendedProperty

## SHORT DESCRIPTION

Defines the extended property types that can be requested when retrieving site information.

## LONG DESCRIPTION

The RMMSiteExtendedProperty enum defines the types of extended properties that can be requested for a site in the Datto RMM platform. These extended properties allow callers to request additional related data when fetching site information, such as the site's settings, variables, or filters.

## VALUES

The following values are defined for RMMSiteExtendedProperty:

| Value | Description |
|-------|-------------|
| `Settings` | Include the settings associated with the site. |
| `Variables` | Include the variables associated with the site. |
| `Filters` | Include the filters associated with the site. |
## NOTES

This enum is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/Enums/about_RMMSiteExtendedProperty.md)

