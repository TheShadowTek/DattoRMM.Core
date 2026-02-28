# about_RMMThrottleProfile

## SHORT DESCRIPTION

Defines the API request throttling profiles for controlling request rate limits.

## LONG DESCRIPTION

The RMMThrottleProfile enum defines the available API request throttling profiles for the Datto RMM module. Each profile controls the rate at which API requests are sent, balancing between performance and API rate limit compliance. Selecting a more cautious profile reduces the risk of hitting API rate limits at the cost of slower execution.

## VALUES

The following values are defined for RMMThrottleProfile:

| Value | Description |
|-------|-------------|
| `Medium` | A moderate throttling profile that balances request speed with rate limit awareness. |
| `Aggressive` | Sends requests at a faster rate with minimal delay between calls, prioritising speed over rate limit safety. |
| `Cautious` | Sends requests at a slower rate with longer delays between calls, prioritising rate limit safety over speed. |
| `DefaultProfile` | The default throttling profile, providing a balanced rate between speed and rate limit compliance. |
## NOTES

This enum is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/Enums/about_RMMThrottleProfile.md)

