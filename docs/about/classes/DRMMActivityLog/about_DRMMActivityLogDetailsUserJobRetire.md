# about_DRMMActivityLogDetailsUserJobRetire

## SHORT DESCRIPTION

Represents an activity log of entity USER, category job, and action retire, which captures the details of one or more retired jobs.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserJobRetire class models the details of a job retirement activity log entry. It inherits the 10 entity-level USER properties from DRMMActivityLogDetailsUserJob and adds the DataRetiredJobsIds property, which contains the identifiers of the jobs that were retired. Note that retire actions do not populate the category-level DataJobId or DataJobName fields.

This class inherits from [DRMMActivityLogDetailsUserJob](./about_DRMMActivityLogDetailsUserJob.md).

## PROPERTIES

The DRMMActivityLogDetailsUserJobRetire class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataRetiredJobsIds | string | The identifiers of the jobs that were retired. |

## METHODS

The DRMMActivityLogDetailsUserJobRetire class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserJobRetire.md)

