# about_DRMMActivityLogDetailsDeviceDevice

## SHORT DESCRIPTION

Base class for DEVICE device-related activity log details, containing properties common to all device actions.

## LONG DESCRIPTION

The DRMMActivityLogDetailsDeviceDevice class serves as a base class for DEVICE entity device category activity logs. It encapsulates properties that are common across different device actions (move, etc.), including source forwarding information, in addition to the entity-level DEVICE properties inherited from DRMMActivityLogEntityDevice. Specific device action types inherit from this class and add their unique properties.

This class inherits from [DRMMActivityLogEntityDevice](./about_DRMMActivityLogEntityDevice.md).

## PROPERTIES

The DRMMActivityLogDetailsDeviceDevice class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| SourceForwardedIp | string | Add description |

## METHODS

The DRMMActivityLogDetailsDeviceDevice class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMActivityLog/about_DRMMActivityLogDetailsDeviceDevice.md)
