# about_DRMMEsxiProcessor

## SHORT DESCRIPTION

Represents the processor information of an ESXi host, including its frequency, name, and number of cores.

## LONG DESCRIPTION

The DRMMEsxiProcessor class models the information about the processor(s) of an ESXi host. It includes properties such as Frequency, Name, and NumberOfCores, which provide details about the CPU configuration of the ESXi host. This class is typically used as part of the DRMMEsxiHostAudit to represent the processor information of the ESXi host being audited.

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMEsxiProcessor class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Frequency     | Nullable[double] | The frequency of the processor. |
| Name          | string           | The name of the processor. |
| NumberOfCores | Nullable[int]    | The number of cores in the processor. |

## METHODS

The DRMMEsxiProcessor class provides the following methods:

No public methods defined.

## NOTES

This class is defined in the DattoRMM.Core module's class system.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMEsxiHostAudit/about_DRMMEsxiProcessor.md)

