<#
.SYNOPSIS
    Generates comprehensive class documentation from the domain class files.

.DESCRIPTION
    Build-ClassDocs.ps1 scans all domain-specific .psm1 files under
    Private\Classes\ and generates detailed markdown documentation for each
    class, organized by #region folders.
    
    This script runs rarely (when class structure changes significantly) and generates
    comprehensive documentation including:
    - Class overview and purpose
    - Properties with types and descriptions (placeholders for manual completion)
    - Methods with signatures, parameters, return types, and examples (placeholders)
    - Related links
    
    The folder structure mirrors the #region organization in each domain file:
    - #region Enums -> docs/about/classes/Enums/
    - #region DRMMDevice and related classes -> docs/about/classes/DRMMDevice/
    
    The first word after #region becomes the folder name.

.PARAMETER OutputFolder
    Root folder for class documentation. Defaults to .\docs\about\classes

.PARAMETER Force
    Force regeneration of all class documentation.

.EXAMPLE
    .\Build\Build-ClassDocs.ps1
    Generates class documentation organized by region.

.EXAMPLE
    .\Build\Build-ClassDocs.ps1 -Force
    Regenerates all class documentation.

.NOTES
    Author: Robert Faddes
    This script is meant to be run infrequently when class structure changes.
    All *.psm1 files under Private\Classes\ are scanned (excluding _Archive).
    Generated files contain TODO placeholders for descriptions and examples.
#>
[CmdletBinding()]
param(
    [string]$OutputFolder = "$PSScriptRoot\..\docs\about\classes",
    [bool]$Force = $true
)

$ErrorActionPreference = 'Continue'

# Get module root
$ModuleRoot = Split-Path $PSScriptRoot -Parent
Push-Location $ModuleRoot
# Resolve OutputFolder to absolute path
$OutputFolder = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFolder)
try {
    Write-Host "`n=== Build-ClassDocs.ps1 ===" -ForegroundColor Cyan
    Write-Host "Generating comprehensive class documentation from domain class files..." -ForegroundColor Cyan
    # Read manifest for DocsBaseUrl
    Write-Host "`nReading module manifest..." -ForegroundColor Yellow
    $ManifestPath = Join-Path $ModuleRoot 'DattoRMM.Core\DattoRMM.Core.psd1'
    $Manifest = Import-PowerShellDataFile -Path $ManifestPath
    $DocsBaseUrl = $Manifest.PrivateData.PSData.DocsBaseUrl
    if (-not $DocsBaseUrl) {
        Write-Warning "DocsBaseUrl not found in manifest. Using default."
        $DocsBaseUrl = 'https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs'
    }
    Write-Host "  DocsBaseUrl: $DocsBaseUrl" -ForegroundColor Gray
        # Helper function to extract AST comments (returns synopsis only)
    function Get-ASTComment {
        param(
            [Parameter(Mandatory)]
            $MemberAst,
            [Parameter(Mandatory)]
            [string]$ScriptContent
        )
        
        # Tokenize the full script
        $tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptContent, [ref]$null)
        
        # Find the token at the member's start line
        $memberStartLine = $MemberAst.Extent.StartLineNumber
        
        # Look backwards from the member for a comment block
        $relevantTokens = $tokens | Where-Object { 
            $_.StartLine -lt $memberStartLine 
        } | Sort-Object StartLine -Descending
        
        # Find the first comment before the member (could be multi-line)
        foreach ($token in $relevantTokens) {
            if ($token.Type -eq 'Comment') {
                # Check if this comment is immediately before the member (with possible blank lines)
                $gapLines = $memberStartLine - $token.EndLine
                if ($gapLines -le 2) {  # Allow up to 1 blank line between comment and member
                    # Extract and clean the comment
                    $commentText = $token.Content
                    
                    # Parse PowerShell help comment blocks
                    if ($commentText -match '(?s)<#(.*?)#>') {
                        $helpContent = $matches[1]
                        
                        # Extract .SYNOPSIS
                        if ($helpContent -match '(?s)\.SYNOPSIS\s+(.*?)(?=\s*\.[A-Z]|\s*#>|$)') {
                            $synopsis = $matches[1].Trim()
                            # Clean up multi-line synopsis
                            $synopsis = $synopsis -replace '\s+', ' '
                            return $synopsis
                        }
                    } elseif ($commentText -match '^#\s*(.+)') {
                        # Simple # comment
                        return $matches[1].Trim()
                    }
                }
                break
            }
        }
        
        return $null
    }
    
    # Helper function to extract full help comment (Synopsis and Description)
    function Get-ASTHelpComment {
        param(
            [Parameter(Mandatory)]
            $MemberAst,
            [Parameter(Mandatory)]
            [string]$ScriptContent
        )
        
        # Tokenize the full script
        $tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptContent, [ref]$null)
        
        # Find the token at the member's start line
        $memberStartLine = $MemberAst.Extent.StartLineNumber
        
        # Look backwards from the member for a comment block
        $relevantTokens = $tokens | Where-Object { 
            $_.StartLine -lt $memberStartLine 
        } | Sort-Object StartLine -Descending
        
        $result = @{
            Synopsis    = $null
            Description = $null
            Links       = @()
        }
        
        # Find the first comment before the member (could be multi-line)
        foreach ($token in $relevantTokens) {
            if ($token.Type -eq 'Comment') {
                # Check if this comment is immediately before the member (with possible blank lines)
                $gapLines = $memberStartLine - $token.EndLine
                if ($gapLines -le 2) {  # Allow up to 1 blank line between comment and member
                    # Extract and clean the comment
                    $commentText = $token.Content
                    
                    # Parse PowerShell help comment blocks
                    if ($commentText -match '(?s)<#(.*?)#>') {
                        $helpContent = $matches[1]
                        
                        # Extract .SYNOPSIS
                        if ($helpContent -match '(?s)\.SYNOPSIS\s+(.*?)(?=\s*\.[A-Z]|\s*#>|$)') {
                            $synopsis = $matches[1].Trim()
                            # Clean up multi-line synopsis
                            $result.Synopsis = $synopsis -replace '\s+', ' '
                        }
                        
                        # Extract .DESCRIPTION
                        if ($helpContent -match '(?s)\.DESCRIPTION\s+(.*?)(?=\s*\.[A-Z]|\s*#>|$)') {
                            $description = $matches[1].Trim()
                            # Clean up multi-line description
                            $result.Description = $description -replace '\s+', ' '
                        }

                        # Extract .LINK entries (one per line, each on its own .LINK keyword)
                        $linkMatches = [regex]::Matches($helpContent, '(?m)\.LINK\s+([^\r\n]+)')
                        foreach ($lm in $linkMatches) {
                            $linkVal = $lm.Groups[1].Value.Trim()
                            if ($linkVal) { $result.Links += $linkVal }
                        }
                    } elseif ($commentText -match '^#\s*(.+)') {
                        # Simple # comment - use as synopsis
                        $result.Synopsis = $matches[1].Trim()
                    }
                }
                break
            }
        }
        
        return $result
    }
    
    # Helper function to get doc content with fallback
    function Get-DocContent {
        param(
            [object]$Value,
            [string]$Default = "TODO: Add description"
        )
        
        if ($null -ne $Value -and $Value -ne '') {
            return $Value
        }
        return $Default
    }
        # Parse domain class files
    Write-Host "`nScanning domain class files..." -ForegroundColor Yellow
    $ClassesRoot = Join-Path $ModuleRoot 'DattoRMM.Core\Private\Classes'
    $DomainFiles = Get-ChildItem -Path $ClassesRoot -Recurse -Filter '*.psm1' |
        Where-Object { $_.FullName -notmatch '_Archive' -and $_.Directory.FullName -ne $ClassesRoot } |
        Sort-Object FullName

    if ($DomainFiles.Count -eq 0) {
        Write-Error "No domain class files found under: $ClassesRoot"
        return
    }

    Write-Host "  Found $($DomainFiles.Count) domain file(s)" -ForegroundColor Gray
    $DomainFiles | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor Gray }

    $NewestClassFile = $DomainFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    # Build Regions by processing each domain file independently.
    # The folder name comes from the file's parent directory, not from #region markers.
    Write-Host "`nParsing domain files..." -ForegroundColor Yellow
    $Regions = [System.Collections.Generic.List[object]]::new()

    foreach ($DomainFile in $DomainFiles) {

        $FolderName = $DomainFile.Directory.Name
        $DomainContent = Get-Content $DomainFile.FullName -Raw

        $DomainAST = [System.Management.Automation.Language.Parser]::ParseInput(
            $DomainContent,
            [ref]$null,
            [ref]$null
        )

        $TypeDefinitions = $DomainAST.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.TypeDefinitionAst]
        }, $true)

        if ($TypeDefinitions.Count -eq 0) {
            Write-Host "  $($FolderName) - no types found, skipping" -ForegroundColor Yellow
            continue
        }

        # Find or create the region entry for this domain
        $Region = $Regions | Where-Object { $_.FolderName -eq $FolderName }

        if (-not $Region) {
            $Region = [PSCustomObject]@{
                Name      = $FolderName
                FolderName = $FolderName
                StartLine = 0
                Classes   = [System.Collections.Generic.List[object]]::new()
            }
            $Regions.Add($Region)
        }

        Write-Host "  $FolderName ($($TypeDefinitions.Count) type(s))" -ForegroundColor Cyan

        foreach ($TypeDef in $TypeDefinitions) {

            $TypeName = $TypeDef.Name
            $IsEnum   = $TypeDef.IsEnum
            $IsClass  = $TypeDef.IsClass

            Write-Host "    $TypeName ($(if($IsEnum){'enum'}else{'class'}))" -ForegroundColor Gray

            $TypeInfo = [PSCustomObject]@{
                Name       = $TypeName
                IsEnum     = $IsEnum
                IsClass    = $IsClass
                Properties = @()
                Methods    = @()
                EnumValues = @()
                BaseType   = $null
                ClassComment = $null
            }

            # Extract class/enum-level comment using this file's content
            $HelpComment = Get-ASTHelpComment $TypeDef $DomainContent
            $TypeInfo | Add-Member -NotePropertyName 'Synopsis'     -NotePropertyValue $HelpComment.Synopsis     -Force
            $TypeInfo | Add-Member -NotePropertyName 'Description'  -NotePropertyValue $HelpComment.Description  -Force
            $TypeInfo | Add-Member -NotePropertyName 'Links'        -NotePropertyValue $HelpComment.Links        -Force

            if ($IsEnum) {

                $TypeInfo.EnumValues = $TypeDef.Members | ForEach-Object { $_.Name }

            } elseif ($IsClass) {

                if ($TypeDef.BaseTypes.Count -gt 0) {
                    $TypeInfo.BaseType = $TypeDef.BaseTypes[0].TypeName.Name
                }

                $Properties = $TypeDef.Members | Where-Object {
                    $_ -is [System.Management.Automation.Language.PropertyMemberAst]
                }

                $TypeInfo.Properties = foreach ($Prop in $Properties) {
                    $Comment = Get-ASTComment $Prop $DomainContent
                    [PSCustomObject]@{
                        Name     = $Prop.Name
                        Type     = $Prop.PropertyType.TypeName.FullName
                        IsHidden = $Prop.IsHidden
                        Comment  = $Comment
                    }
                }
                
                # Extract methods (excluding static FromAPIMethod and constructors)
                $Methods = $TypeDef.Members | Where-Object { 
                    $_ -is [System.Management.Automation.Language.FunctionMemberAst] 
                }
                
                $TypeInfo.Methods = foreach ($Method in $Methods) {
                    # Skip static FromAPIMethod (internal constructor)
                    if ($Method.IsStatic -and $Method.Name -in 'FromAPIMethod', 'FromActivityLogDetail', 'PopulateEntityProperties', 'PopulateCategoryProperties') {
                        continue
                    }
                    
                    # Skip constructors (methods with same name as class)
                    if ($Method.Name -eq $TypeInfo.Name) {
                        continue
                    }
                    
                    $Comment = Get-ASTComment $Method $DomainContent
                    
                    # Get parameters
                    $Params = $Method.Parameters | ForEach-Object {
                        $ParamType = if ($_.StaticType) { 
                            $_.StaticType.Name 
                        } else { 
                            'object' 
                        }
                        $ParamName = $_.Name.VariablePath.UserPath
                        [PSCustomObject]@{
                            Name = $ParamName
                            Type = $ParamType
                        }
                    }
                    
                    $ReturnType = if ($Method.ReturnType) { 
                        $Method.ReturnType.TypeName.FullName 
                    } else { 
                        'void' 
                    }
                    
                    [PSCustomObject]@{
                        Name = $Method.Name
                        IsStatic = $Method.IsStatic
                        Parameters = $Params
                        ReturnType = $ReturnType
                        IsHidden = $Method.IsHidden
                        Comment = $Comment
                    }
                }
            }

            $Region.Classes.Add($TypeInfo)
        }
    }

        # Build class-to-folder lookup for inheritance links
    Write-Host "`nBuilding class-to-folder lookup..." -ForegroundColor Yellow
    $ClassFolderMap = @{}
    # Workaround: if $Region was previously bound as [string] in this session (from a prior run using
    # $Regions += which coerces PSCustomObjects to strings), foreach will silently coerce the loop
    # variable to that type. Remove-Variable clears the binding so foreach assigns the correct type.
    Remove-Variable Region -ErrorAction SilentlyContinue
    foreach ($Region in $Regions) {
        foreach ($TypeInfo in $Region.Classes) {
            $ClassFolderMap[$TypeInfo.Name] = $Region.FolderName
            Write-Host "  $($TypeInfo.Name) -> $($Region.FolderName)" -ForegroundColor Gray
        }
    }
    Write-Host "  Mapped $($ClassFolderMap.Count) classes to folders" -ForegroundColor Gray
    
    # Build function-to-subfolder lookup for command links
    Write-Host "`nBuilding function-to-subfolder lookup..." -ForegroundColor Yellow
    $FunctionLookup = @{}
    $PublicPath = Join-Path $ModuleRoot 'DattoRMM.Core\Public'
    if (Test-Path $PublicPath) {
        $PublicFunctions = Get-ChildItem -Path $PublicPath -Filter *.ps1 -Recurse | 
            Where-Object { $_.Name -notlike '*.Tests.ps1' }
        foreach ($FuncFile in $PublicFunctions) {
            $FuncName = $FuncFile.BaseName
            $RelPath = $FuncFile.DirectoryName.Replace((Join-Path $ModuleRoot 'DattoRMM.Core\Public'), '').TrimStart('\','/')
            if ($RelPath) {
                $FunctionLookup[$FuncName] = $RelPath
            } else {
                $FunctionLookup[$FuncName] = ''
            }
        }
    }
    Write-Host "  Mapped $($FunctionLookup.Count) functions to subfolders" -ForegroundColor Gray

    # Generate markdown files organized by region
    Write-Host "`nGenerating markdown documentation..." -ForegroundColor Yellow
    
    $TotalGenerated = 0
    $TotalSkipped = 0
    # Workaround: clear any stale type-binding on $Region from a prior session run. See first instance above.
    Remove-Variable Region -ErrorAction SilentlyContinue
    foreach ($Region in $Regions) {
        if ($Region.Classes.Count -eq 0) {
            Write-Host "`n  Region '$($Region.FolderName)' has no classes, skipping..." -ForegroundColor Yellow
            continue
        }
        
        Write-Host "`n  Region: $($Region.Name)" -ForegroundColor Cyan
        Write-Host "  Folder: $($Region.FolderName)" -ForegroundColor Gray
        
        # Create region folder
        $RegionFolder = Join-Path $OutputFolder $Region.FolderName
        if (-not (Test-Path $RegionFolder)) {
            New-Item -Path $RegionFolder -ItemType Directory -Force | Out-Null
            Write-Host "    Created folder: $RegionFolder" -ForegroundColor Gray
        }
        
        foreach ($TypeInfo in $Region.Classes) {
            $TypeName = $TypeInfo.Name
            $MarkdownFile = Join-Path $RegionFolder "about_$TypeName.md"
            
            # Check if regeneration needed
            $ShouldGenerate = $Force
            if (-not $ShouldGenerate) {
                if (-not (Test-Path $MarkdownFile)) {
                    $ShouldGenerate = $true
                    $Reason = "new file"
                } elseif ($NewestClassFile.LastWriteTime -gt (Get-Item $MarkdownFile).LastWriteTime) {
                    $ShouldGenerate = $true
                    $Reason = "source modified"
                }
            } else {
                $Reason = "forced"
            }
            
            if ($ShouldGenerate) {
                Write-Host "    Generating: about_$TypeName.md ($Reason)" -ForegroundColor Green

                # Build markdown content based on type
                if ($TypeInfo.IsEnum) {
                    # === ENUM DOCUMENTATION ===
                    $ShortDesc = Get-DocContent $TypeInfo.Synopsis "Describes the $TypeName enumeration used in DattoRMM.Core module"
                    $LongDesc  = Get-DocContent $TypeInfo.Description "The $TypeName enum defines valid values for TODO: describe what this enum represents"
                    
                    $Content = @"
# about_$TypeName

## SHORT DESCRIPTION

$ShortDesc

## LONG DESCRIPTION

$LongDesc

## VALUES

The following values are defined for $TypeName`:

| Value | Description |
|-------|-------------|
"@
                    foreach ($Value in $TypeInfo.EnumValues) {
                        $Content += "`n| ``$Value`` | TODO: Describe this value |"
                    }

                    $OnlineDocUrl = "$DocsBaseUrl/about/classes/$($Region.FolderName)/about_$TypeName.md"

                    $Content += "`n`n## NOTES`n`nThis enum is defined in the DattoRMM.Core module's class system.`n`n"
                    $Content += "## RELATED LINKS`n`n"
                    $Content += "- [Online Documentation]($OnlineDocUrl)`n"
                    foreach ($LinkTarget in $TypeInfo.Links) {
                        $LinkName = $LinkTarget -replace '^about_', ''
                        if ($FunctionLookup.ContainsKey($LinkTarget)) {
                            $FuncSub = $FunctionLookup[$LinkTarget] -replace '\\', '/'
                            $LinkHref = if ($FuncSub) { "../../../commands/$FuncSub/$LinkTarget.md" } else { "../../../commands/$LinkTarget.md" }
                            $Content += "- [$LinkTarget]($LinkHref)`n"
                        } elseif ($ClassFolderMap.ContainsKey($LinkName)) {
                            $TargetFolder = $ClassFolderMap[$LinkName]
                            $LinkHref = if ($TargetFolder -eq $Region.FolderName) { "./about_$LinkName.md" } else { "../$TargetFolder/about_$LinkName.md" }
                            $Content += "- [$LinkName]($LinkHref)`n"
                        } else {
                            $Content += "- $LinkTarget`n"
                        }
                    }
                    $Content += "`n"
                } else {
                    # === CLASS DOCUMENTATION ===
                    $ShortDesc = Get-DocContent $TypeInfo.Synopsis "Add a brief description of this class"
                    $LongDesc  = Get-DocContent $TypeInfo.Description "Add a detailed description of what this class represents and its purpose"
                    
                    $BaseTypeText = if ($TypeInfo.BaseType) {
                        # Look up the folder for the base class
                        $BaseFolder = $ClassFolderMap[$TypeInfo.BaseType]
                        if ($BaseFolder) {
                            # Generate relative path to base class
                            if ($BaseFolder -eq $Region.FolderName) {
                                # Same folder - use relative path
                                "This class inherits from [$($TypeInfo.BaseType)](./about_$($TypeInfo.BaseType).md)."
                            } else {
                                # Different folder - go up one level then into target folder
                                "This class inherits from [$($TypeInfo.BaseType)](../$BaseFolder/about_$($TypeInfo.BaseType).md)."
                            }
                        } else {
                            # Fallback if base class not found in map
                            "This class inherits from $($TypeInfo.BaseType)."
                        }
                    } else {
                        ""
                    }
                    
                    $Content = @"
# about_$TypeName

## SHORT DESCRIPTION

$ShortDesc

## LONG DESCRIPTION

$LongDesc

$BaseTypeText

## PROPERTIES

The $TypeName class exposes the following properties:

"@
                    if ($TypeInfo.Properties.Count -gt 0) {
                        $Content += @"

| Property | Type | Description |
|----------|------|-------------|

"@
                        # Calculate consistent column widths (property name column)
                        $MaxPropNameLen = ($TypeInfo.Properties | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum
                        $MaxTypeLen = ($TypeInfo.Properties | ForEach-Object { $_.Type.Length } | Measure-Object -Maximum).Maximum
                        
                        foreach ($Prop in $TypeInfo.Properties | Where-Object { -not $_.IsHidden }) {
                            $PropName = $Prop.Name.PadRight($MaxPropNameLen)
                            $PropType = $Prop.Type.PadRight($MaxTypeLen)
                            $PropDesc = Get-DocContent $Prop.Comment "Add description"
                            $Content += "| $PropName | $PropType | $PropDesc |`n"
                        }
                    } else {
                        $Content += "`nNo public properties defined.\n"
                    }
                    
                    $Content += @"

## METHODS

The $TypeName class provides the following methods:

"@
                    
                    if ($TypeInfo.Methods.Count -gt 0) {
                        foreach ($Method in $TypeInfo.Methods | Where-Object { -not $_.IsHidden }) {
                            $ParamList  = ($Method.Parameters | ForEach-Object { "[$($_.Type)]`$$($_.Name)" }) -join ', '
                            $StaticText = if ($Method.IsStatic) { "static " } else { "" }
                            $Signature  = "$StaticText$($Method.Name)($ParamList)"
                            $MethodDesc = Get-DocContent $Method.Comment "Add method description explaining what this method does"

                            # Return type description: look up the return type's synopsis if it's a known class
                            $ReturnTypeName = $Method.ReturnType -replace '\[\]$', '' -replace '<.*>', ''
                            $ReturnDesc = if ($ClassFolderMap.ContainsKey($ReturnTypeName)) {
                                $ReturnTypeInfo = ($Regions | Where-Object { $_.FolderName -eq $ClassFolderMap[$ReturnTypeName] }).Classes |
                                    Where-Object { $_.Name -eq $ReturnTypeName } | Select-Object -First 1
                                if ($ReturnTypeInfo -and $ReturnTypeInfo.Synopsis) { $ReturnTypeInfo.Synopsis } else { $null }
                            } else { $null }

                            if (-not $ReturnDesc) { $ReturnDesc = "Returns $($Method.ReturnType)" }

                            $Content += "`n### $Signature`n`n$MethodDesc`n`n**Returns:** ``$($Method.ReturnType)`` - $ReturnDesc`n"

                            if ($Method.Parameters.Count -gt 0) {
                                $Content += "`n**Parameters:**`n"
                                foreach ($Param in $Method.Parameters) {
                                    $Content += "- ``[$($Param.Type)]`$$($Param.Name)`` - TODO: Describe this parameter`n"
                                }
                            }
                        }
                    } else {
                        $Content += "`nNo public methods defined.`n"
                    }

                    $OnlineDocUrl = "$DocsBaseUrl/about/classes/$($Region.FolderName)/about_$TypeName.md"

                    $Content += "`n## NOTES`n`nThis class is defined in the DattoRMM.Core module's class system.`n`n"
                    $Content += "## RELATED LINKS`n`n"
                    $Content += "- [Online Documentation]($OnlineDocUrl)`n"
                    foreach ($LinkTarget in $TypeInfo.Links) {
                        $LinkName = $LinkTarget -replace '^about_', ''
                        if ($FunctionLookup.ContainsKey($LinkTarget)) {
                            $FuncSub = $FunctionLookup[$LinkTarget] -replace '\\', '/'
                            $LinkHref = if ($FuncSub) { "../../../commands/$FuncSub/$LinkTarget.md" } else { "../../../commands/$LinkTarget.md" }
                            $Content += "- [$LinkTarget]($LinkHref)`n"
                        } elseif ($ClassFolderMap.ContainsKey($LinkName)) {
                            $TargetFolder = $ClassFolderMap[$LinkName]
                            $LinkHref = if ($TargetFolder -eq $Region.FolderName) { "./about_$LinkName.md" } else { "../$TargetFolder/about_$LinkName.md" }
                            $Content += "- [$LinkName]($LinkHref)`n"
                        } else {
                            $Content += "- $LinkTarget`n"
                        }
                    }
                    $Content += "`n"
                }
                
                # Save markdown file
                Set-Content -Path $MarkdownFile -Value $Content -NoNewline
                $TotalGenerated++
                
            } else {
                Write-Host "    Skipped: about_$TypeName.md (up to date)" -ForegroundColor Yellow
                $TotalSkipped++
            }
        }
    }
    
    # Generate class index document
    Write-Host "`nGenerating class index document..." -ForegroundColor Yellow
    $IndexLines = [System.Collections.Generic.List[string]]::new()
    $IndexLines.Add('# DattoRMM.Core Class Reference')
    $IndexLines.Add('')
    $IndexLines.Add('A reference index of all classes and enums defined in the DattoRMM.Core module, organised by domain.')
    $IndexLines.Add('')

    # Skip the catch-all Classes/Enums domains — list domain-specific regions first, then Enums
    $DomainRegions  = $Regions | Where-Object { $_.FolderName -notin @('Classes','Enums') } | Sort-Object FolderName
    $EnumsRegions   = $Regions | Where-Object { $_.FolderName -eq 'Enums' }
    $IndexRegionOrder = @($DomainRegions) + @($EnumsRegions)

    # Table of contents
    $IndexLines.Add('## Contents')
    $IndexLines.Add('')
    foreach ($TocRegion in $IndexRegionOrder) {
        $Anchor = $TocRegion.FolderName.ToLower()
        $IndexLines.Add("- [$($TocRegion.FolderName)](#$Anchor)")
    }
    $IndexLines.Add('')

    foreach ($IndexRegion in $IndexRegionOrder) {

        $IndexLines.Add("## $($IndexRegion.FolderName)")
        $IndexLines.Add('')
        $IndexLines.Add('| Class | Synopsis |')
        $IndexLines.Add('| ----- | -------- |')

        foreach ($IndexType in $IndexRegion.Classes) {
            $Synopsis = if ($IndexType.Synopsis) { $IndexType.Synopsis } else { '' }
            $DocPath  = "$($IndexRegion.FolderName)/about_$($IndexType.Name).md"
            $IndexLines.Add("| [``$($IndexType.Name)``]($DocPath) | $Synopsis |")
        }

        $IndexLines.Add('')
    }

    $IndexPath = Join-Path $OutputFolder 'about_ClassIndex.md'
    Set-Content -Path $IndexPath -Value ($IndexLines -join "`n") -Encoding UTF8
    Write-Host "  Written: $IndexPath" -ForegroundColor Green

    # Summary
    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "  Regions:   $($Regions.Count)" -ForegroundColor Gray
    Write-Host "  Generated: $TotalGenerated" -ForegroundColor Green
    Write-Host "  Skipped:   $TotalSkipped" -ForegroundColor Yellow
    Write-Host "  Total:     $($TotalGenerated + $TotalSkipped)" -ForegroundColor Gray
    
    Write-Host "`nNOTE: Generated files contain TODO placeholders." -ForegroundColor Yellow
    Write-Host "      Review and complete descriptions and examples manually." -ForegroundColor Yellow
    Write-Host "`n=== Complete ===" -ForegroundColor Cyan
    
} finally {
    Pop-Location
}
