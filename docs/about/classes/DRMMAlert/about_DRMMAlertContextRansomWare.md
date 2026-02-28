# about_DRMMAlertContextRansomWare

## SHORT DESCRIPTION

Represents the context of a ransomware alert in the DRMM system, including state, confidence factor, affected directories, watch paths, ransomware extension, and alert times.

## LONG DESCRIPTION

The DRMMAlertContextRansomWare class models the context information specific to ransomware alerts in the DRMM platform. It encapsulates properties such as state, confidence factor, affected directories, watch paths, ransomware extension, and alert times that provide detailed context about the ransomware alert.

This class inherits from [DRMMAlertContext](./about_DRMMAlertContext.md).

## PROPERTIES

The DRMMAlertContextRansomWare class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| State               | int                | The current state of the ransomware alert. |
| ConfidenceFactor    | int                | The confidence factor indicating the likelihood of a ransomware event. |
| AffectedDirectories | string[]           | The directories affected by the ransomware. |
| WatchPaths          | string[]           | The paths being watched for ransomware activity. |
| Rwextension         | string             | The ransomware extension associated with the alert. |
| MetaAlertTime       | Nullable[datetime] | The time when the meta alert related to the ransomware was generated. |
| AlertTime           | Nullable[datetime] | The time when the ransomware alert was generated. |

## METHODS

The DRMMAlertContextRansomWare class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMAlert/about_DRMMAlertContextRansomWare.md)
- [DRMMAlert](./about_DRMMAlert.md)
- [DRMMAlertContext](./about_DRMMAlertContext.md)

