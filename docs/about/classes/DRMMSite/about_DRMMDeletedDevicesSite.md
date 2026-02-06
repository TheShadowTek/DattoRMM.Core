# about_DRMMDeletedDevicesSite

## SHORT DESCRIPTION

Represents a deleted site in the DRMM system, with properties similar to DRMMSite but with a string type for Uid to handle invalid GUIDs.

## LONG DESCRIPTION

The DRMMDeletedDevicesSite class models a deleted site within the DRMM platform. It includes properties similar to the DRMMSite class, but the Uid property is defined as a string to accommodate cases where the GUID may be invalid or not properly formatted. The class provides a constructor and a static method to create an instance from API response data, allowing for the handling of deleted site information without strict GUID validation.

This class inherits from [DRMMSite](./about_DRMMSite.md).

## PROPERTIES

The DRMMDeletedDevicesSite class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Uid | string | Shadow the base Uid property with string type to handle invalid GUIDs |

## METHODS

The DRMMDeletedDevicesSite class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMSite/about_DRMMDeletedDevicesSite.md)
