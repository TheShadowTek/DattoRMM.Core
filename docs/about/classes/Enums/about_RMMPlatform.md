# about_RMMPlatform

## SHORT DESCRIPTION

Defines the available Datto RMM platform instances used for API and portal URL construction.

## LONG DESCRIPTION

The RMMPlatform enum defines the available Datto RMM platform instances. Each value represents a specific regional or deployment platform endpoint identified by its codename. The platform value is used internally to construct API base URLs and portal URLs for the correct Datto RMM instance.

## VALUES

The following values are defined for RMMPlatform:

| Value | Description |
|-------|-------------|
| `Pinotage` | The Pinotage platform instance. |
| `Concord` | The Concord platform instance. |
| `Vidal` | The Vidal platform instance. |
| `Merlot` | The Merlot platform instance. |
| `Zinfandel` | The Zinfandel platform instance. |
| `Syrah` | The Syrah platform instance. |
## NOTES

This enum is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/Enums/about_RMMPlatform.md)

