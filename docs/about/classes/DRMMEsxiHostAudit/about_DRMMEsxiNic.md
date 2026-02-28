# about_DRMMEsxiNic

## SHORT DESCRIPTION

Represents a network interface card (NIC) on an ESXi host, including its name, IP addresses, MAC address, speed, and type.

## LONG DESCRIPTION

The DRMMEsxiNic class models the information about a network interface card (NIC) on an ESXi host. It includes properties such as Name, Ipv4, Ipv6, MacAddress, Speed, and Type, which provide details about the NIC's configuration and capabilities. This class is typically used as part of the DRMMEsxiHostAudit to represent the network interfaces of the ESXi host being audited.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMEsxiNic class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Name       | string | The name of the network interface card (NIC). |
| Ipv4       | string | The IPv4 address of the network interface card (NIC). |
| Ipv6       | string | The IPv6 address of the network interface card (NIC). |
| MacAddress | string | The MAC address of the network interface card (NIC). |
| Speed      | string | The speed of the network interface card (NIC). |
| Type       | string | The type of the network interface card (NIC). |

## METHODS

The DRMMEsxiNic class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMEsxiHostAudit/about_DRMMEsxiNic.md)
