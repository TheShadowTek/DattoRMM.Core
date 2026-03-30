# Get-RMMRequestRate

## SYNOPSIS
Retrieves the current API request rate information for the Datto RMM account.

## SYNTAX

```
Get-RMMRequestRate [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get-RMMRequestRate connects to the Datto RMM API and retrieves information about the current request rate limits for the account.
This includes details such as the maximum allowed requests per minute, the number of requests currently used, and the time until the request count resets.

This information is useful for monitoring API usage and ensuring that your applications stay within the allowed limits to avoid throttling.

## EXAMPLES

EXAMPLE 1
```powershell
Get-RMMRequestRate
```

Retrieves the current API request rate information for the connected Datto RMM account.

## PARAMETERS

## INPUTS

## OUTPUTS

## NOTES
This function requires an active connection to the Datto RMM API.
Use Connect-DattoRMM to authenticate before calling this function.

The request rate information is returned as a custom object with properties such as MaxRequestsPerMinute, RequestsUsed, and TimeUntilReset.

For more details on the API request rate limits, refer to the Datto RMM API documentation.

## RELATED LINKS


- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMRequestRate.md](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Account/Get-RMMRequestRate.md))
