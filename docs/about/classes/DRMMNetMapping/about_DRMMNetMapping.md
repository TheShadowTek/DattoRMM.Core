# about_DRMMNetMapping

## SHORT DESCRIPTION

Represents a network mapping in the DRMM system, including properties such as name, unique identifier, description, associated network IDs, and portal URL.

## LONG DESCRIPTION

The DRMMNetMapping class models a network mapping within the DRMM platform. It includes properties such as Id, Uid, AccountUid, Name, Description, DatatoNetworkingNetworkIds, and PortalUrl. The class provides a constructor and a static method to create an instance from API response data. Additionally, it includes a method to open the portal URL associated with the network mapping in the default web browser. The class serves as a representation of network mappings within the DRMM system, allowing for easy access and management of network mapping information.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMNetMapping class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Id                         | long   | The identifier of the network mapping. |
| Uid                        | guid   | The unique identifier (UID) of the network mapping. |
| AccountUid                 | string | The unique identifier (UID) of the account. |
| Name                       | string | The name of the network mapping. |
| Description                | string | The description of the network mapping. |
| DatatoNetworkingNetworkIds | long[] | The network IDs associated with Datto Networking. |
| PortalUrl                  | string | The URL of the portal. |

## METHODS

The DRMMNetMapping class provides the following methods:

### OpenPortal()

Opens the portal URL associated with the network mapping in the default web browser.

**Returns:** `void` - This method does not return a value. It performs an action to open the portal URL in the default web browser.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMNetMapping/about_DRMMNetMapping.md)
