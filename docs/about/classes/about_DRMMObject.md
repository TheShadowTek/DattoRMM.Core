# about_DRMMObject

## NAME
DRMMObject

## SYNOPSIS
Base class for all Datto RMM API v2 objects. Provides common properties and methods for derived classes.

## DESCRIPTION
The `DRMMObject` class is the foundational class for all Datto RMM API v2 objects. It defines shared properties, constructors, and utility methods used by all derived classes in the module. This class is not intended to be used directly, but rather as a base for other API object classes.

## PROPERTIES
- Id: [string] Unique identifier for the object.
- Created: [datetime] Creation timestamp.
- Modified: [datetime] Last modification timestamp.
- (Other common properties as defined in DRMMObject.psm1)

## METHODS
- Constructor: Initializes a new instance of the object.
- ToString(): Returns a string representation of the object.
- Equals(): Compares two objects for equality.
- (Other shared methods as defined in DRMMObject.psm1)

## EXAMPLES
```
# Example: Inheriting from DRMMObject
class DRMMDevice : DRMMObject {
    # ... device-specific properties and methods ...
}
```

## RELATED LINKS


## NOTES
This class is defined in Private/Classes/DRMMObject.psm1 and is loaded first to ensure all derived types function correctly.
