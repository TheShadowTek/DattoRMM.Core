<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Resolves an API path and HTTP method to a rate-limit operation name.
.DESCRIPTION
    Uses the explicit operation mapping table to classify an API request. If no explicit
    match is found, infers an operation name from the path structure and HTTP method using
    Datto RMM naming conventions. Returns $null for GET requests, which are not write-limited.
    Unknown write operations emit a debug trace indicating inference.
#>
function Resolve-ThrottleOperationName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method
    )

    # GET requests are never write-limited — no operation name needed
    if ($Method -eq 'Get') {

        return $null

    }

    # Normalise: strip query parameters and any leading api/v2/ or v2/ prefix
    $NormPath = ($Path -replace '\?.*$', '') -replace '^(api/)?v2/', '' -replace '^/', ''

    # Replace GUIDs and numeric IDs in path segments with {id} placeholder for mapping lookup
    $TemplatePath = $NormPath -replace '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}', '{id}' -replace '(?<=(/|^))\d+(?=(/|$))', '{id}'

    # Try explicit mapping first
    $MapKey = "$($Method.ToString().ToUpper()):$TemplatePath"

    if ($Script:OperationMapping.ContainsKey($MapKey)) {

        Write-Debug "Throttle: Operation classified via mapping — $MapKey → $($Script:OperationMapping[$MapKey])"
        
        return $Script:OperationMapping[$MapKey]

    }

    # Fallback: infer operation name from path segments and HTTP method
    $Segments = ($TemplatePath -replace '/{id}', '' -replace '{id}/', '' -replace '{id}', '') -split '/' | Where-Object {$_}

    $MethodSuffix = switch ($Method.ToString().ToUpper()) {

        'POST' {'update'}
        'PUT' {'create'}
        'DELETE' {'delete'}
        'PATCH' {'update'}
        default {'unknown'}

    }

    $InferredName = ($Segments -join '-') + "-$MethodSuffix"
    Write-Debug "Throttle: Operation name inferred (no explicit mapping) — $MapKey → $InferredName"

    return $InferredName

}
