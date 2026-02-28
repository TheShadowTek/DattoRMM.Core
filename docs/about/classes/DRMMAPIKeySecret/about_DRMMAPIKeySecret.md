# about_DRMMAPIKeySecret

## SHORT DESCRIPTION

Represents API key and secret information for authenticating with the DRMM API.

## LONG DESCRIPTION

The DRMMAPIKeySecret class encapsulates the API key, API secret, and associated username for a DRMM account. It provides a static method to create an instance of the class from a typical API response object that contains these credentials. The API secret is stored as a secure string to enhance security when handling sensitive information.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMAPIKeySecret class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| ApiKey    | string       | API authentication key. |
| ApiSecret | securestring | API authentication secret. |
| Username  | string       | Username associated with the API key and secret. |

## METHODS

The DRMMAPIKeySecret class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMAPIKeySecret/about_DRMMAPIKeySecret.md)
- [Reset-RMMAPIKeySecret](../../../commands/Reset-RMMAPIKeySecret.md)

