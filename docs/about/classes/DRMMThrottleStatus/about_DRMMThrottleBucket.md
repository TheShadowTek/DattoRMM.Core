# about_DRMMThrottleBucket

## SHORT DESCRIPTION

Represents a single rate-limit bucket in the DRMM throttle system, covering account, write, or per-operation buckets.

## LONG DESCRIPTION

The DRMMThrottleBucket class models one rate-limit bucket from the combined view of API-reported and locally tracked throttle state. Each bucket has a Type (Account, Write, or Operation), a Name that identifies it (e

This class inherits from [DRMMObject](../DRMMObject/about_DRMMObject.md).

## PROPERTIES

The DRMMThrottleBucket class exposes the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Type        | string | The bucket type: Account (global account requests), Write (global write operations), or Operation (per-operation write buckets). |
| Name        | string | The name that identifies the bucket. For Account and Write buckets, this is the bucket type name. For Operation buckets, this is the operation name (e.g., site-create, device-move). |
| Limit       | int    | The configured rate limit for this bucket, indicating the maximum number of requests allowed within the rolling window. |
| ApiCount    | int    | The current request count reported by the Datto RMM API for this bucket. |
| LocalCount  | int    | The number of requests tracked locally in the sliding-window model for this bucket. |
| Utilisation | double | The computed utilisation ratio for this bucket, calculated as the higher of API-reported utilisation or local-tracked utilisation. Ratio ranges from 0.0 (empty) to 1.0 or higher (over-limit). |

## METHODS

The DRMMThrottleBucket class provides the following methods:

### GetSummary()

Generates a summary string for the throttle bucket, including type, name, utilisation, and counts.

**Returns:** `string` - Describe what this method returns

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMThrottleStatus/about_DRMMThrottleBucket.md)
