# about_DRMMObject

## SHORT DESCRIPTION

region DRMMObject - Base Class

## LONG DESCRIPTION

The DRMMObject class serves as the base class for all domain model classes in the DattoRMM.Core module. It provides shared utility methods for safely extracting values from API response objects, validating response structures, converting epoch timestamps to DateTime values, parsing various API date formats, and masking sensitive string values. All domain classes inherit from DRMMObject to gain access to these foundational capabilities.



## PROPERTIES

The DRMMObject class exposes the following properties:

No public properties defined.\n
## METHODS

The DRMMObject class provides the following methods:

### static GetValue([PSObject]$InputObject, [String]$Key)

Safely retrieves the value of a specified property from a PSCustomObject, returning null if the property does not exist.

**Returns:** `object` - The value associated with the specified key in the input object, or null if the key does not exist.

**Parameters:**
- `[PSObject]$InputObject` - The object from which to retrieve the value.
- `[String]$Key` - The key or property name whose value is to be retrieved from the input object.

### static ValidateShape([PSObject]$Sample, [String[]]$RequiredProperties)

Validates that a PSCustomObject contains all specified required properties, used to verify API response structures before processing.

**Returns:** `bool` - A boolean value indicating whether the sample object contains all the required properties.

**Parameters:**
- `[PSObject]$Sample` - The sample object to validate against the required properties.
- `[String[]]$RequiredProperties` - An array of property names that are required to be present in the input object.

### static ConvertEpochToDateTime([Int64]$Epoch)

Converts a Unix epoch timestamp (in seconds or milliseconds) to a UTC DateTime value.

**Returns:** `datetime` - The DateTime representation of the given epoch timestamp.

**Parameters:**
- `[Int64]$Epoch` - The epoch timestamp to convert, which can be an integer, long, double, or numeric string representing the number of seconds since January 1, 1970.

### static ParseApiDate([Object]$Value)

Handle numeric epoch timestamps (int, long, double, or numeric strings)

**Returns:** `hashtable` - The DateTime representation of the given API date value, or null if the value cannot be parsed as a date.

**Parameters:**
- `[Object]$Value` - The value to parse as an API date, which can be a numeric epoch timestamp or a date string.

### static MaskString([String]$Value, [Int32]$VisibleChars, [String]$MaskChar)

Masks a string value by replacing characters beyond a specified visible count with a mask character, used to obscure sensitive data such as API keys or secrets.

**Returns:** `string` - The masked string with the specified number of visible characters at the start.

**Parameters:**
- `[String]$Value` - The string value to be masked.
- `[Int32]$VisibleChars` - The number of characters to leave visible at the start of the string.
- `[String]$MaskChar` - The character to use for masking the string (e.g., "*").

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/about/classes/DRMMObject/about_DRMMObject.md)
