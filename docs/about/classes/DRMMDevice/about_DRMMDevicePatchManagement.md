# about_DRMMDevicePatchManagement

## SHORT DESCRIPTION

Represents patch management information for a device in the DRMM system.

## LONG DESCRIPTION

The DRMMDevicePatchManagement class models the patch management status for a device in the DRMM platform. It includes properties such as PatchStatus, PatchesApprovedPending, PatchesNotApproved, and PatchesInstalled, which provide insights into the device's patch management state. The class provides a constructor and a static method to create an instance from API response data.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMDevicePatchManagement class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| PatchStatus            | string         | The current status of patch management on the device. |
| PatchesApprovedPending | Nullable[long] | The number of patches that are approved but pending installation. |
| PatchesNotApproved     | Nullable[long] | The number of patches that are not approved for installation. |
| PatchesInstalled       | Nullable[long] | The number of patches that have been installed on the device. |

## METHODS

The DRMMDevicePatchManagement class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMDevice/about_DRMMDevicePatchManagement.md)
