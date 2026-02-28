# about_DRMMJobComponent

## SHORT DESCRIPTION

Represents a component of a DRMM job, including its unique identifier, name, and associated variables.

## LONG DESCRIPTION

The DRMMJobComponent class models a component within a DRMM job. It includes properties such as Uid, Name, and Variables, which provide details about the component's identity and configuration. The class also includes a static method to create an instance of DRMMJobComponent from API response data.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMJobComponent class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Uid       | guid                       | The unique identifier (UID) of the job component. |
| Name      | string                     | The name of the job component. |
| Variables | DRMMJobComponentVariable[] | The variables associated with the job component. |

## METHODS

The DRMMJobComponent class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMJob/about_DRMMJobComponent.md)
