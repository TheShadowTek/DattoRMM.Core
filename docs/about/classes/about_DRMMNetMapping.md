# about_DRMMNetMapping

## SHORT DESCRIPTION
Describes the DRMMNetMapping class for representing Datto RMM network mapping objects.

## LONG DESCRIPTION
The DRMMNetMapping class models a network mapping within Datto RMM, including identifiers, descriptive fields, and portal access.

DRMMNetMapping objects are returned by [Get-RMMNetMapping](Get-RMMNetMapping.md), which retrieves Datto Networking site mappings for the account. The function may return one or more DRMMNetMapping objects depending on the query and account configuration.

Use Get-RMMNetMapping to correlate RMM sites with their Datto Networking infrastructure and manage network mappings programmatically.

## PROPERTIES
| Property                     | Type                | Description                                      |
|------------------------------|---------------------|--------------------------------------------------|
| Id                           | int                 | Internal network mapping ID                      |
| Uid                          | string              | Unique identifier (GUID)                         |
| AccountUid                   | string              | Account unique identifier (GUID)                 |
| Name                         | string              | Network mapping name                             |
| Description                  | string              | Description of the network mapping               |
| DatatoNetworkingNetworkIds   | int[]               | Related Datto Networking network IDs             |
| PortalUrl                    | string              | URL to open the mapping in the Datto portal      |

## METHODS

### Methods

#### OpenPortal()

Opens the network mapping in the Datto portal.

## EXAMPLES
```powershell
$mapping = Get-RMMNetMapping -Id 12345
$mapping.OpenPortal()
```

## NOTES
- DRMMNetMapping is used for managing and integrating network mappings.
- PortalUrl provides direct access to the mapping in the Datto portal.

## SEE ALSO
* [Get-RMMNetMapping](Get-RMMNetMapping.md)
* [about_DattoRMM.Core](about_DattoRMM.Core.md)
