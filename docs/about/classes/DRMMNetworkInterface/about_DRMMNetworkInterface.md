# about_DRMMNetworkInterface

## SHORT DESCRIPTION

region DRMMNetworkInterface class

## LONG DESCRIPTION

The DRMMNetworkInterface class models a network interface card (NIC) associated with a device in the Datto RMM platform. It includes properties such as Instance, Ipv4, Ipv6, MacAddress, and Type, which describe the configuration and identity of the network interface. The class provides a constructor and a static method to create an instance from API response data. This class is used as a property within device audit and device network interface classes to represent individual NICs.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMNetworkInterface class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Instance   | string | region DRMMNetworkInterface class |
| Ipv4       | string | The IPv4 address of the network interface. |
| Ipv6       | string | The IPv6 address of the network interface. |
| MacAddress | string | The MAC address of the network interface. |
| Type       | string | The type of the network interface. |

## METHODS

The DRMMNetworkInterface class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMNetworkInterface/about_DRMMNetworkInterface.md)
