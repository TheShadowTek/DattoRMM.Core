# about_DRMMJobStdData

## SHORT DESCRIPTION

Represents standard output or error data associated with a DRMM job component, including job, device, and component identifiers, component name, and the standard data itself.

## LONG DESCRIPTION

The DRMMJobStdData class models the standard output or error data produced by a component during the execution of a DRMM job. It includes properties such as JobUid, DeviceUid, ComponentUid, ComponentName, and StdData, which provide details about the source and content of the standard data. The class also includes a static method to create an instance of DRMMJobStdData from API response data.

This class inherits from [DRMMObject](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMJobStdData class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| JobUid        | guid   | The unique identifier (UID) of the job. |
| DeviceUid     | guid   | The unique identifier (UID) of the device. |
| ComponentUid  | guid   | The unique identifier (UID) of the job component. |
| ComponentName | string | The name of the job component. |
| StdData       | string | The standard data output of the job component. |

## METHODS

The DRMMJobStdData class provides the following methods:

No public methods defined.

## USAGE EXAMPLES

### Example 1: Basic usage

```powershell
# TODO: Add comprehensive usage example
```

### Example 2: Advanced usage

```powershell
# TODO: Add advanced usage example
```

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

TODO: Add any additional notes about this class.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMJob/about_DRMMJobStdData.md)
