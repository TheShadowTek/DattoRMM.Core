# about_DRMMStatus

## SHORT DESCRIPTION

Represents the status of the DRMM system, including properties such as version, status, and start time.

## LONG DESCRIPTION

The DRMMStatus class models the status of the DRMM system, encapsulating properties such as Version, Status, and Started. The class provides a constructor and a static method to create an instance from API response data. The FromAPIMethod static method takes a response object, extracts the relevant information, and populates the properties of the DRMMStatus instance accordingly. The class serves as a representation of the current status of the DRMM system, allowing for easy access to version information, overall status, and the time when the system started.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMStatus class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Version | string             | The version information. |
| Status  | string             | The current status. |
| Started | Nullable[datetime] | The start time of the status. |

## METHODS

The DRMMStatus class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMStatus/about_DRMMStatus.md)

