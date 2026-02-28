# about_DRMMToken

## SHORT DESCRIPTION

Represents an OAuth access token response from the Datto RMM API.

## LONG DESCRIPTION

The DRMMToken class encapsulates the OAuth token information returned by the Datto RMM authentication endpoint. It includes the access token (stored as a secure string), token type, expiration date, scope, and JWT identifier. This class provides a static method to create an instance from the API response object, ensuring the access token is securely stored and the expires_in value is converted to a DateTime for easier time-based operations.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMToken class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| AccessToken | securestring | The OAuth access token, stored as a secure string to protect sensitive credential data. |
| TokenType   | string       | The type of the access token (e.g., Bearer). |
| Expires     | datetime     | The expiration date and time of the access token, calculated from the token lifetime at the point of creation. |
| Scope       | string       | The OAuth scope granted by the access token. |
| Jti         | string       | The unique JWT identifier for the access token. |

## METHODS

The DRMMToken class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMToken/about_DRMMToken.md)
