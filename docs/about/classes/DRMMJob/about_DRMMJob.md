# about_DRMMJob

## SHORT DESCRIPTION

Represents a job in the DRMM system, including its ID, unique identifier, name, creation date, and status.

## LONG DESCRIPTION

The DRMMJob class models a job within the DRMM platform. It includes properties such as Id, Uid, Name, DateCreated, and Status. This class provides methods to interact with job components, results, standard output, and error data. It also includes utility methods to check the job's status, calculate its age, refresh its data, and generate a summary string. The class is used to represent and manage jobs in the DRMM system.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMJob class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id          | long               | The unique identifier of the job. |
| Uid         | guid               | The unique identifier (UID) of the job. |
| Name        | string             | The name of the job. |
| DateCreated | Nullable[datetime] | The date and time when the job was created. |
| Status      | string             | The current status of the job. |

## METHODS

The DRMMJob class provides the following methods:

### IsActive()

Checks if the job is currently active.

**Returns:** `bool` - Indicates whether the job is currently active (true/false).

### IsCompleted()

Checks if the job is completed.

**Returns:** `bool` - Indicates whether the job is completed (true/false).

### GetAge()

Calculates the age of the job based on its creation date.

**Returns:** `timespan` - The age of the job as a TimeSpan object, representing the time elapsed since the job was created.

### GetComponents()

Retrieves the components associated with the job.

**Returns:** `DRMMJobComponent[]` - A list of components associated with the job.

### GetSummary()

Generates a summary string for the job.

**Returns:** `string` - A summary string representing the job.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMJob/about_DRMMJob.md)
