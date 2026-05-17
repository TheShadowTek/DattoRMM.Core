# about_DattoRMM.CoreFormatExtensions

## SHORT DESCRIPTION

Describes how to supply custom `Format.ps1xml` files from the module profile folder to extend or override the default display views for DattoRMM.Core objects.

## LONG DESCRIPTION

DattoRMM.Core ships with built-in `Format.ps1xml` definitions that control how typed objects (`DRMMDevice`, `DRMMSite`, `DRMMAlert`, etc.) are displayed in the PowerShell console. These definitions are loaded automatically when the module imports.

The module also supports a user-owned extension point: any `Format.ps1xml` files you place in the module profile folder are detected and loaded after the module-shipped definitions, allowing you to override or extend default views without modifying module files.

### Why custom format files

- Add columns to a default table view without modifying module files
- Reorder or rename displayed properties for your environment
- Create additional named views for objects that only have a default view
- Persist display customisations across module updates

### Profile folder and naming convention

Place custom format files in:

```
$HOME/.DattoRMM.Core/
```

Files must match the naming convention:

```
DattoRMM.Core.<name>.Format.ps1xml
```

Files that do not match this pattern are silently ignored. The `<name>` segment is freeform — use it to describe the file's purpose or scope (e.g., `DattoRMM.Core.DeviceTable.Format.ps1xml`).

### Load order and precedence

Module-shipped format definitions are loaded first via the module manifest. User-supplied files are loaded second using `Update-FormatData -PrependPath`, which places your definitions at higher precedence than the module defaults.

When a type has matching view definitions in both a module-shipped file and a user-supplied file, PowerShell uses the user-supplied view.

### Multiple files

Multiple matching files are supported. Files are loaded in alphabetical order by filename. To control load order explicitly, prefix filenames with a numeric segment:

```
DattoRMM.Core.10-Base.Format.ps1xml
DattoRMM.Core.20-Custom.Format.ps1xml
```

### Scaffolding a new file

Use `Get-FormatData` and `Export-FormatData` to extract an existing view as a starting scaffold:

```powershell
# Extract the current built-in view for DRMMDevice as XML
Get-FormatData -TypeName 'DRMMDevice' | Export-FormatData -Path .\DattoRMM.Core.DeviceTable.Format.ps1xml
```

Edit the exported file to add, remove, or reorder columns, then move it to `$HOME/.DattoRMM.Core/`. The file will be loaded the next time the module imports.

### Example: adding a column to the DRMMDevice table view

Scaffold the built-in view, then add a new `<TableColumnHeader>` and `<TableColumnItem>` pair for the property you want to include:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Configuration>
  <ViewDefinitions>
    <View>
      <Name>DRMMDevice</Name>
      <ViewSelectedBy>
        <TypeName>DRMMDevice</TypeName>
      </ViewSelectedBy>
      <TableControl>
        <TableHeaders>
          <TableColumnHeader><Label>Hostname</Label></TableColumnHeader>
          <TableColumnHeader><Label>Site</Label></TableColumnHeader>
          <TableColumnHeader><Label>OS</Label></TableColumnHeader>
          <TableColumnHeader><Label>Online</Label></TableColumnHeader>
          <TableColumnHeader><Label>Last Seen</Label></TableColumnHeader>
        </TableHeaders>
        <TableRowEntries>
          <TableRowEntry>
            <TableColumnItems>
              <TableColumnItem><PropertyName>Hostname</PropertyName></TableColumnItem>
              <TableColumnItem><PropertyName>SiteName</PropertyName></TableColumnItem>
              <TableColumnItem><PropertyName>OperatingSystem</PropertyName></TableColumnItem>
              <TableColumnItem><PropertyName>Online</PropertyName></TableColumnItem>
              <TableColumnItem><PropertyName>LastSeen</PropertyName></TableColumnItem>
            </TableColumnItems>
          </TableRowEntry>
        </TableRowEntries>
      </TableControl>
    </View>
  </ViewDefinitions>
</Configuration>
```

Save this as `DattoRMM.Core.DeviceTable.Format.ps1xml` in `$HOME/.DattoRMM.Core/`. On the next module import the new column layout replaces the default.

### Debugging

Use `Trace-Command` to diagnose view binding and load errors:

```powershell
Trace-Command -Name FormatFileLoading,FormatViewBinding -Expression {
    Import-Module DattoRMM.Core -Force
} -PSHost
```

This outputs detailed trace information about which format files are loaded and which view is selected for each type.

### Signing

User-supplied files in `$HOME/.DattoRMM.Core/` are user-owned and are not expected to be code-signed. Module-shipped format files are signed as part of the module release process and are unaffected by user extension loading.

---

## SEE ALSO

- [about_DattoRMM.CoreTypeExtensions](about_DattoRMM.CoreTypeExtensions.md)
- [about_DattoRMM.CoreExport](about_DattoRMM.CoreExport.md)
- [about_DattoRMM.Core](about_DattoRMM.Core.md)
- [PII-Safe Output Pack](../examples/PII-Safe-Output-Pack/README.md) — worked example overriding default views with masked properties
- [about_Format.ps1xml](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_format.ps1xml)
