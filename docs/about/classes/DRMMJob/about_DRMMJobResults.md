# about_DRMMJobResults

## SHORT DESCRIPTION

Represents the results of a DRMM job, including job and device identifiers, the time the job ran, deployment status, and component results.

## LONG DESCRIPTION

The DRMMJobResults class models the outcome of a DRMM job execution. It includes properties such as JobUid, DeviceUid, RanOn, JobDeploymentStatus, and an array of ComponentResults, which provide detailed information about the job's execution and its components. The class also includes a static method to create an instance of DRMMJobResults from API response data.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMJobResults class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| JobUid                | guid                     | The unique identifier (UID) of the job. |
| DeviceUid             | guid                     | The unique identifier (UID) of the device. |
| RanOn                 | Nullable[datetime]       | The date and time when the job was run. |
| JobDeploymentStatus   | string                   | The deployment status of the job. |
| ComponentResults      | DRMMJobComponentResult[] | The results of the job components. |
| TotalNumberOfWarnings | int                      | The total number of warnings across all component results. |
| HasStdOut             | bool                     | Indicates whether any component result produced standard output data. |
| HasStdErr             | bool                     | Indicates whether any component result produced standard error data. |
| StdOut                | DRMMJobStdData[]         | The standard output data collected from job components that produced output. |
| StdErr                | DRMMJobStdData[]         | The standard error data collected from job components that produced error output. |

## METHODS

The DRMMJobResults class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMJob/about_DRMMJobResults.md)
