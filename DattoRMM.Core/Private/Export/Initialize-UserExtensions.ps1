<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Loads user-supplied Format.ps1xml and Types.ps1xml files from the module profile folder.
.DESCRIPTION
    Scans $HOME/.DattoRMM.Core/ for files matching the naming conventions:

        DattoRMM.Core.<name>.Format.ps1xml
        DattoRMM.Core.<name>.Types.ps1xml

    Matching files are loaded using Update-FormatData and Update-TypeData with -PrependPath,
    allowing user definitions to take precedence over module-shipped defaults.

    Files are loaded in alphabetical order by filename, giving the user a deterministic
    load sequence through naming (e.g., 10-Base before 20-Custom).

    No error is raised if the profile folder does not exist or contains no matching files.
    A malformed file generates a warning and processing continues with remaining files.
#>
function Initialize-UserExtensions {
    [CmdletBinding()]
    param ()

    $ProfileFolder = Join-Path $HOME '.DattoRMM.Core'

    if (-not (Test-Path $ProfileFolder)) {

        Write-Debug "Profile folder not found — no user extensions to load."
        return

    }

    # Load Format extensions
    $FormatFiles = Get-ChildItem -Path $ProfileFolder -Filter 'DattoRMM.Core.*.Format.ps1xml' -ErrorAction SilentlyContinue | Sort-Object Name

    foreach ($File in $FormatFiles) {

        try {

            Update-FormatData -PrependPath $File.FullName
            Write-Verbose "Loaded user format extension: $($File.Name)"

        } catch {

            Write-Warning "Failed to load user format extension '$($File.Name)': $($_.Exception.Message)"

        }
    }

    # Load Types extensions
    $TypeFiles = Get-ChildItem -Path $ProfileFolder -Filter 'DattoRMM.Core.*.Types.ps1xml' -ErrorAction SilentlyContinue |
        Sort-Object Name

    foreach ($File in $TypeFiles) {

        try {

            Update-TypeData -PrependPath $File.FullName
            Write-Verbose "Loaded user type extension: $($File.Name)"

        } catch {

            Write-Warning "Failed to load user type extension '$($File.Name)': $($_.Exception.Message)"

        }
    }
}
