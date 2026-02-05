# Test-RegexPropertyParse.ps1
# Test script for property regex used in ConvertFrom-MdAboutDocs.ps1

$testClass = @'
class DRMMEsxiHostAudit : DRMMObject {
    [guid]$DeviceUid
    [string]$PortalUrl
    [DRMMEsxiSystemInfo]$SystemInfo
    [DRMMEsxiGuest[]]$Guests
    [DRMMEsxiProcessor[]]$Processors
    [DRMMEsxiNic[]]$Nics
    [DRMMEsxiPhysicalMemory[]]$PhysicalMemory
    [DRMMEsxiDatastore[]]$Datastores
}
'@


# Improved regex: match nested brackets and array types
$regex = '^[ \t]*\[([\w\[\]]+)\]\s*\$(\w+)' # Accepts [Type[]] and [Type]

$matches = [regex]::Matches($testClass, $regex, 'Multiline')

Write-Host "Properties found:"
foreach ($m in $matches) {
    $type = $m.Groups[1].Value
    $name = $m.Groups[2].Value
    Write-Host "  $name [$type]"
}

Write-Host "Total: $($matches.Count)"
