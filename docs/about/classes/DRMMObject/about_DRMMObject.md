# about_DRMMObject

## SHORT DESCRIPTION

region DRMMObject - Base Class

## LONG DESCRIPTION

Add a detailed description of what this class represents and its purpose



## PROPERTIES

The DRMMObject class exposes the following properties:

No public properties defined.\n
## METHODS

The DRMMObject class provides the following methods:

### static GetValue([PSObject]$InputObject, [String]$Key)

Add method description explaining what this method does

**Returns:** `object` - The value associated with the specified key in the input object, or null if the key does not exist.

**Parameters:**
- `[PSObject]$InputObject` - The object from which to retrieve the value.
- `[String]$Key` - The key or property name whose value is to be retrieved from the input object.

### static ValidateShape([PSObject]$Sample, [String[]]$RequiredProperties)

Add method description explaining what this method does

**Returns:** `bool` - A boolean value indicating whether the sample object contains all the required properties.

**Parameters:**
- `[PSObject]$Sample` - The sample object to validate against the required properties.
- `[String[]]$RequiredProperties` - An array of property names that are required to be present in the input object.

### static ConvertEpochToDateTime([Int64]$Epoch)

Add method description explaining what this method does

**Returns:** `datetime` - The DateTime representation of the given epoch timestamp.

**Parameters:**
- `[Int64]$Epoch` - The epoch timestamp to convert, which can be an integer, long, double, or numeric string representing the number of seconds since January 1, 1970.

### static ParseApiDate([Object]$Value)

Handle numeric epoch timestamps (int, long, double, or numeric strings)

**Returns:** `hashtable` - The DateTime representation of the given API date value, or null if the value cannot be parsed as a date.

**Parameters:**
- `[Object]$Value` - The value to parse as an API date, which can be a numeric epoch timestamp or a date string.

### static MaskString([String]$Value, [Int32]$VisibleChars, [String]$MaskChar)

Add method description explaining what this method does

**Returns:** `string` - The masked string with the specified number of visible characters at the start.

**Parameters:**
- `[String]$Value` - The string value to be masked.
- `[Int32]$VisibleChars` - The number of characters to leave visible at the start of the string.
- `[String]$MaskChar` - The character to use for masking the string (e.g., "*").

## USAGE EXAMPLES

### Example 1: Basic usage

```powershell
# TODO: Add comprehensive usage example
```

### Example 2: Advanced usage

```powershell
# TODO: Add advanced usage example
```

## NOTES

This class is defined in the DattoRMM.Core module's Classes.psm1 file.

TODO: Add any additional notes about this class.

## RELATED LINKS

- [Online Documentation](https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs//about/classes/DRMMObject/about_DRMMObject.md)
