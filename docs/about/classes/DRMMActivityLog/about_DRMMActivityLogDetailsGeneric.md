# about_DRMMActivityLogDetailsGeneric

## SHORT DESCRIPTION

Represents a generic implementation of the DRMMActivityLogDetails class, which can handle arbitrary key-value pairs from the API response.

## LONG DESCRIPTION

The DRMMActivityLogDetailsGeneric class is a flexible implementation of the DRMMActivityLogDetails class that can accommodate any structure of details returned by the API. It takes a PSCustomObject as input and dynamically adds its properties to the class instance. The class also includes logic to attempt parsing any properties that contain "date" in their name as date values, while retaining the original value if parsing fails. This allows it to handle a wide variety of detail structures without requiring predefined properties.

This class inherits from [DRMMActivityLogDetails](./about_DRMMActivityLogDetails.md).

## PROPERTIES

The DRMMActivityLogDetailsGeneric class exposes the following properties:

No public properties defined.\n
## METHODS

The DRMMActivityLogDetailsGeneric class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsGeneric.md)
