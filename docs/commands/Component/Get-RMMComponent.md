# Get-RMMComponent

## SYNOPSIS
Retrieves all components (scripts/jobs) from the Datto RMM account.

## SYNTAX

```
Get-RMMComponent [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RMMComponent function retrieves all components available in the authenticated
user's Datto RMM account.
Components are reusable scripts or automation jobs that can
be executed on managed devices.

Each component includes information about its variables (inputs and outputs), category,
and whether it requires credentials to run.

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMComponent
```

Retrieves all components in the account.

EXAMPLE 2
```powershell
Get-RMMComponent | Where-Object {$_.Name -like "*PowerShell*"}
```

Retrieves all components with "PowerShell" in the name.

EXAMPLE 3
```powershell
Get-RMMComponent | Where-Object {$_.CredentialsRequired -eq $true}
```

Retrieves all components that require credentials to execute.

EXAMPLE 4
```powershell
$Component = Get-RMMComponent | Where-Object {$_.Name -eq "Get System Info"}
$Component.GetInputVariables()
```

Gets a specific component and displays its input variables.

EXAMPLE 5
```powershell
Get-RMMComponent | Select-Object Name, Description, CategoryCode | Format-Table
```

Retrieves all components and displays their name, description, and category in a table.

## PARAMETERS

## INPUTS

None. This function does not accept pipeline input.
## OUTPUTS

DRMMComponent. Returns component objects with the following notable properties:
- Uid: Unique identifier for the component
- Name: Display name of the component
- Description: Description of what the component does
- CategoryCode: Category the component belongs to
- CredentialsRequired: Whether credentials are required
- Variables: Array of input and output variables
The component object also includes helper methods:
- GetVariable(name): Get a specific variable by name
- GetInputVariables(): Get all input variables
- GetOutputVariables(): Get all output variables
## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Component/Get-RMMComponent.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Component/Get-RMMComponent.md))
- [about_DRMMComponent](../../about/classes/DRMMComponent/about_DRMMComponent.md)
- [New-RMMQuickJob](../Jobs/New-RMMQuickJob.md)
- [Get-RMMJob](../Jobs/Get-RMMJob.md)
