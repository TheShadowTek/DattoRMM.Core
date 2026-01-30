# about_DRMMVariable

## SHORT DESCRIPTION

Describes the DRMMVariable class and its methods for working with variables in Datto RMM.

## LONG DESCRIPTION

The DRMMVariable class represents a variable within Datto RMM. Variables are used to store values that can be referenced in jobs, scripts, or device/site configuration. Variables can be scoped globally or to a specific site, and may be masked (secret) for sensitive data.

DRMMVariable objects are returned by [Get-RMMVariable](Get-RMMVariable.md) and provide methods for inspecting and summarising variable details.

## PROPERTIES

The DRMMVariable class exposes the following properties:

| Property   | Type             | Description                                 |
|------------|------------------|---------------------------------------------|
| Id         | long             | Numeric variable identifier                  |
| Name       | string           | Variable name                               |
| Value      | object           | Variable value (masked if secret)           |
| Scope      | string           | Variable scope: 'Global' or 'Site'          |
| SiteUid    | Nullable[guid]   | Site GUID (null for global variables)       |
| IsSecret   | bool             | True if variable is masked/secret           |

## METHODS

### Scope Checks

#### IsGlobal()
Returns true if the variable is global in scope.

**Returns:** `[bool]`

#### IsSite()
Returns true if the variable is site-scoped.

**Returns:** `[bool]`

### Summary

#### GetSummary()
Returns a string summary of the variable, including name, scope, and value (masked if secret).

**Returns:** `[string]`

```powershell
$var = Get-RMMVariable -Name "APIKey"
Write-Host $var.GetSummary()
```
