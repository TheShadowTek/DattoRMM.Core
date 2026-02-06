# Disconnect-DattoRMM

## SYNOPSIS
Disconnects from the Datto RMM API and clears authentication information.

## SYNTAX

```
Disconnect-DattoRMM
```

## DESCRIPTION
The Disconnect-DattoRMM function clears the stored authentication token and credentials from the module's script scope, effectively ending the current API session.

This function should be called when you are finished working with the Datto RMM API to ensure credentials are removed from memory.

## EXAMPLES

EXAMPLE 1
```powershell
Disconnect-DattoRMM
```

Disconnects from the Datto RMM API and clears stored authentication.

EXAMPLE 2
```powershell
Connect-DattoRMM -Key "your-api-key" -Secret $Secret
Get-RMMDevice
Disconnect-DattoRMM
```

Connects to the API, performs operations, then disconnects and clears credentials.

## PARAMETERS

## INPUTS

None. You cannot pipe objects to Disconnect-DattoRMM.
## OUTPUTS

None. This function does not generate output but clears authentication information from module scope.
## NOTES
After disconnecting, you will need to run Connect-DattoRMM again to re-authenticate
before making additional API calls.

The module also automatically clears authentication information when the module is removed
from the session.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Disconnect-DattoRMM.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Auth/Disconnect-DattoRMM.md))
- [Connect-DattoRMM](./Connect-DattoRMM.md)
