# about_DRMMAlertContextAction

## SHORT DESCRIPTION

Represents the context of an action alert in the DRMM system, including package name, action type, and version information.

## LONG DESCRIPTION

The DRMMAlertContextAction class models the context information specific to software action alerts in the DRMM platform. It encapsulates properties such as the package name, action type (installed, uninstalled, or version changed), previous version, and current version that provide detailed context about the software action that triggered the alert.

This class inherits from [DRMMAlertContext](./about_DRMMAlertContext.md).

## PROPERTIES

The DRMMAlertContextAction class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| PackageName | string | The name of the software package associated with the action alert. |
| ActionType  | string | The type of action that triggered the alert (e.g., INSTALLED, UNINSTALLED, VERSION_CHANGED). |
| PrevVersion | string | The previous version of the software package before the action. |
| Version     | string | The current version of the software package after the action. |

## METHODS

The DRMMAlertContextAction class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMAlert/about_DRMMAlertContextAction.md)
- [DRMMAlert](./about_DRMMAlert.md)
- [DRMMAlertContext](./about_DRMMAlertContext.md)

