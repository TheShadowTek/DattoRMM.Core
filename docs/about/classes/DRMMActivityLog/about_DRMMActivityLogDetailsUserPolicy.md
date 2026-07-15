# about_DRMMActivityLogDetailsUserPolicy

## SHORT DESCRIPTION

Base class for USER policy-related activity log details, containing properties common to all policy actions.

## LONG DESCRIPTION

The DRMMActivityLogDetailsUserPolicy class serves as a base class for USER entity policy category activity logs. It encapsulates 3 properties common to all observed policy actions — DataPolicyId, DataPolicyName, and DataType — in addition to the 10 entity-level properties inherited from DRMMActivityLogEntityUser. Specific policy action types inherit from this class and add their unique properties.

This class inherits from [DRMMActivityLogEntityUser](./about_DRMMActivityLogEntityUser.md).

## PROPERTIES

The DRMMActivityLogDetailsUserPolicy class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| DataPolicyId   | string | The identifier of the policy that was affected. |
| DataPolicyName | string | The display name of the policy that was affected. |
| DataType       | string | The type of the policy that was affected. |

## METHODS

The DRMMActivityLogDetailsUserPolicy class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsUserPolicy.md)

