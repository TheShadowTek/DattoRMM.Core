# Get-RMMNetMapping

## SYNOPSIS
Retrieves Datto Networking site mappings.

## SYNTAX

```
Get-RMMNetMapping [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMNetMapping function retrieves the mapping between Datto RMM sites and
Datto Networking sites.
This mapping is used to associate RMM-managed devices with
their corresponding Datto Networking configurations.

Datto Networking provides network management capabilities, and this function helps
correlate RMM sites with their network infrastructure.

## EXAMPLES

EXAMPLE 1
```
Get-RMMNetMapping
```

Retrieves all Datto Networking site mappings for the account.

EXAMPLE 2
```
$Mappings = Get-RMMNetMapping
$Mappings | Select-Object SiteName, NetworkSiteName
```

Retrieves all mappings and displays the site names from both systems.

EXAMPLE 3
```
Get-RMMNetMapping | Where-Object {$_.SiteUid -eq $MySiteUid}
```

Retrieves the Datto Networking mapping for a specific RMM site.

EXAMPLE 4
```
Get-RMMNetMapping | Format-Table SiteName, NetworkSiteName, Status
```

Retrieves all mappings and displays them in a formatted table.

## PARAMETERS

## INPUTS

None. You cannot pipe objects to Get-RMMNetMapping.
## OUTPUTS

DRMMNetMapping. Returns mapping objects with the following properties:
- Uid: Mapping unique identifier
- SiteUid: Datto RMM site identifier
- SiteName: Datto RMM site name
- NetworkSiteUid: Datto Networking site identifier
- NetworkSiteName: Datto Networking site name
- Status: Mapping status
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

This function is only relevant if your account uses Datto Networking.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMNetMapping.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMNetMapping.md))
- [about_DRMMNetMapping](../../about/classes/DRMMNetMapping/about_DRMMNetMapping.md)
