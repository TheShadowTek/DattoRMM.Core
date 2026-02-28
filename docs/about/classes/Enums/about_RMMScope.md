# about_RMMScope

## SHORT DESCRIPTION

Defines the scope levels available within the Datto RMM platform.

## LONG DESCRIPTION

The RMMScope enum defines the scope levels available within the Datto RMM platform. Scope determines whether a resource such as a variable or filter applies globally across all sites or is restricted to a specific site.

## VALUES

The following values are defined for RMMScope:

| Value | Description |
|-------|-------------|
| `Global` | The resource applies globally across all sites in the account. |
| `Site` | The resource is scoped to a specific site. |
## NOTES

This enum is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/Enums/about_RMMScope.md)

