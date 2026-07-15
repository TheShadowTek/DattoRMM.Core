# about_DRMMActivityLogDetailsDevicePatch

## SHORT DESCRIPTION

Base class for DEVICE patch-related activity log details, containing properties common to all patch actions.

## LONG DESCRIPTION

The DRMMActivityLogDetailsDevicePatch class serves as a base class for DEVICE entity patch category activity logs. It encapsulates properties that are common across different patch actions, including patch activity result, status, run date, site information, and source forwarding details, in addition to the entity-level DEVICE properties inherited from DRMMActivityLogEntityDevice. Specific patch action types inherit from this class and add their unique properties.

This class inherits from [DRMMActivityLogEntityDevice](./about_DRMMActivityLogEntityDevice.md).

## PROPERTIES

The DRMMActivityLogDetailsDevicePatch class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| PatchActivityInfo    | string             | Informational message associated with the patch activity. |
| PatchActivityResult  | string             | The result description of the patch activity. |
| PatchActivityRunDate | nullable[datetime] | The date and time when the patch activity ran. |
| PatchActivitySuccess | bool               | Indicates whether the patch activity completed successfully. |
| SiteName             | string             | The name of the site where the patch activity occurred. |
| SourceForwardedIp    | string             | The forwarded IP address of the source that initiated the patch activity. |

## METHODS

The DRMMActivityLogDetailsDevicePatch class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsDevicePatch.md)

