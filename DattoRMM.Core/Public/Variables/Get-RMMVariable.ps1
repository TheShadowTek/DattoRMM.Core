<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMVariable {
    <#
    .SYNOPSIS
        Retrieves variables from the Datto RMM API.

    .DESCRIPTION
        The Get-RMMVariable function retrieves variables at different scopes: global
        (account-level) or site-level. Variables can be retrieved by ID, name, or all
        variables at a given scope.

        Variables in Datto RMM are used by components (scripts/monitors) to store and
        retrieve configuration values and data. They can be defined globally for the
        entire account or at the site level.

    .PARAMETER Site
        A DRMMSite object to retrieve variables for. Accepts pipeline input from Get-RMMSite.

    .PARAMETER SiteUid
        The unique identifier (GUID) of a site to retrieve variables for.

    .PARAMETER Id
        Retrieve a specific variable by its numeric ID.

    .PARAMETER Name
        Retrieve a variable by its name (exact match).

    .EXAMPLE
        Get-RMMVariable

        Retrieves all global (account-level) variables.

    .EXAMPLE
        Get-RMMVariable -Id 12345

        Retrieves a specific global variable by its ID.

    .EXAMPLE
        Get-RMMVariable -Name "CompanyAPIKey"

        Retrieves a global variable by exact name match.

    .EXAMPLE
        Get-RMMSite -Name "Contoso" | Get-RMMVariable

        Gets all variables for the "Contoso" site.

    .EXAMPLE
        Get-RMMVariable -SiteUid $SiteUid -Name "ServerPassword"

        Retrieves a specific site variable by name.

    .EXAMPLE
        $Variables = Get-RMMSite | Get-RMMVariable
        PS > $Variables | Group-Object SiteUid | Select-Object Name, Count

        Retrieves variables for all sites and groups by site.

    .EXAMPLE
        Get-RMMVariable | Where-Object {$_.Name -like "*Password*"}

        Retrieves all global variables with "Password" in the name.

    .EXAMPLE
        $Var = Get-RMMVariable -Name "ConfigSetting"
        PS > $Var.Value

        Retrieves a variable and displays its value.

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite.
        System.Guid. You can pipe SiteUid values.

    .OUTPUTS
        DRMMVariable. Returns variable objects with the following properties:
        - Id: Variable numeric ID
        - Name: Variable name
        - Value: Variable value
        - Scope: 'Global' or 'Site'
        - SiteUid: Site identifier (for site-scoped variables)
        - Type: Variable data type
        - Masked: Whether value is masked/hidden
        - Description: Variable description

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Variables can be referenced in components using the variable name.
        Site-level variables override global variables with the same name.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Variables/Get-RMMVariable.md
    #>
    [CmdletBinding(DefaultParameterSetName = 'GlobalAll')]
    param (
        [Parameter(
            ParameterSetName = 'SiteAll',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteById',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteByName',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMSite]
        $Site,

        [Parameter(
            ParameterSetName = 'SiteAllUid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteUidById',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteUidByName',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Uid')]
        [guid]
        $SiteUid,

        [Parameter(
            ParameterSetName = 'GlobalById',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteById',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteUidById',
            Mandatory = $true
        )]
        [int]
        $Id,

        [Parameter(
            ParameterSetName = 'GlobalByName',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteByName',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteUidByName',
            Mandatory = $true
        )]
        [string]
        $Name
    )

    process {

        Write-Debug "Getting RMM variable(s) using parameter set: $($PSCmdlet.ParameterSetName)"

        if ($PSCmdlet.ParameterSetName -match '^Site') {

            if ($Site) {

                $SiteUid = $Site.Uid

            }

            $APIMethod = @{
                Path = "site/$SiteUid/variables"
                Method = 'Get'
                Paginate = $true
                PageElement = 'variables'
            }

            switch ($PSCmdlet.ParameterSetName) {

                {$_ -in 'SiteAll','SiteAllUid'} {

                    Write-Debug "Getting all variables for site UID: $SiteUid"
                    Invoke-ApiMethod @APIMethod | ForEach-Object {[DRMMVariable]::FromAPIMethod($_, 'Site', $SiteUid)}

                }

                {$_ -in 'SiteById','SiteUidById'} {

                    Write-Debug "Getting site variable by ID: $Id for site UID: $SiteUid"
                    $Results = Invoke-ApiMethod @APIMethod | Where-Object {$_.id -eq $Id}
                    
                    if ($Results) {

                        $Results | ForEach-Object {[DRMMVariable]::FromAPIMethod($_, 'Site', $SiteUid)}

                    } else {

                        Write-Debug "No site variable found with ID: $Id for site UID: $SiteUid"

                    }
                }

                {$_ -in 'SiteByName','SiteUidByName'} {

                    Write-Debug "Getting site variable by Name: $Name for site UID: $SiteUid"
                    $Results = Invoke-ApiMethod @APIMethod | Where-Object {$_.name -eq $Name}
                    
                    if ($Results) {

                        $Results | ForEach-Object {[DRMMVariable]::FromAPIMethod($_, 'Site', $SiteUid)}

                    } else {

                        Write-Debug "No site variable found with Name: $Name for site UID: $SiteUid"

                    }
                }
            }

        } else {

            $APIMethod = @{
                Path = 'account/variables'
                Method = 'Get'
                Paginate = $true
                PageElement = 'variables'
            }

            switch ($PSCmdlet.ParameterSetName) {

                'GlobalAll' {

                    Write-Debug "Getting all global variables"
                    Invoke-ApiMethod @APIMethod | ForEach-Object {[DRMMVariable]::FromAPIMethod($_, 'Global', $null)}

                }

                'GlobalById' {

                    Write-Debug "Getting global variable by ID: $Id"
                    $Results = Invoke-ApiMethod @APIMethod | Where-Object {$_.id -eq $Id}
                    
                    if ($Results) {

                        $Results | ForEach-Object {[DRMMVariable]::FromAPIMethod($_, 'Global', $null)}

                    } else {

                        Write-Debug "No global variable found with ID: $Id"

                    }
                }

                'GlobalByName' {

                    Write-Debug "Getting global variable by Name: $Name"
                    $Results = Invoke-ApiMethod @APIMethod | Where-Object {$_.name -eq $Name}
                    
                    if ($Results) {

                        $Results | ForEach-Object {[DRMMVariable]::FromAPIMethod($_, 'Global', $null)}

                    } else {

                        Write-Debug "No global variable found with Name: $Name"

                    }
                }
            }
        }
    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC2SxyHRSd+r7DA
# c5Ydvo648xGTTqFkqpEDGkg8Z7hou6CCA04wggNKMIICMqADAgECAhB464iXHfI6
# gksEkDDTyrNsMA0GCSqGSIb3DQEBCwUAMD0xFjAUBgNVBAoMDVJvYmVydCBGYWRk
# ZXMxIzAhBgNVBAMMGkRhdHRvUk1NLkNvcmUgQ29kZSBTaWduaW5nMB4XDTI2MDMz
# MTAwMTMzMFoXDTI4MDMzMTAwMjMzMFowPTEWMBQGA1UECgwNUm9iZXJ0IEZhZGRl
# czEjMCEGA1UEAwwaRGF0dG9STU0uQ29yZSBDb2RlIFNpZ25pbmcwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQChn1EpMYQgl1RgWzQj2+wp2mvdfb3UsaBS
# nxEVGoQ0gj96tJ2MHAF7zsITdUjwaflKS1vE6wAlOg5EI1V79tJCMxzM0bFpOdR1
# L5F2HE/ovIAKNkHxFUF5qWU8vVeAsOViFQ4yhHpzLen0WLF6vhmc9eH23dLQy5fy
# tELZQEc2WbQFa4HMAitP/P9kHAu6CUx5s4woLIOyyR06jkr3l9vk0sxcbCxx7+dF
# RrsSLyPYPH+bUAB8+a0hs+6qCeteBuUfLvGzpMhpzKAsY82WZ3Rd9X38i32dYj+y
# dYx+nx+UEMDLjDJrZgnVa8as4RojqVLcEns5yb/XTjLxDc58VatdAgMBAAGjRjBE
# MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU
# H+B0vf97dYXqdUX1YMcWhFsY6fcwDQYJKoZIhvcNAQELBQADggEBAJmD4EEGNmcD
# 1JtFoRGxuLJaTHxDwBsjqcRQRE1VPZNGaiwIm8oSQdHVjQg0oIyK7SEb02cs6n6Y
# NZbwf7B7WZJ4aKYbcoLug1k1x9SoqwBmfElECeJTKXf6dkRRNmrAodpGCixR4wMH
# KXqwqP5F+5j7bdnQPiIVXuMesxc4tktz362ysph1bqKjDQSCBpwi0glEIH7bv5Ms
# Ey9Gl3fe+vYC5W06d2LYVebEfm9+7766hsOgpdDVgdtnN+e6uwIJjG/6PTG6TMDP
# y+pr5K6LyUVYJYcWWUTZRBqqwBHiLGekPbxrjEVfxUY32Pq4QfLzUH5hhUCAk4HN
# XpF9pOzFLMUxggIDMIIB/wIBATBRMD0xFjAUBgNVBAoMDVJvYmVydCBGYWRkZXMx
# IzAhBgNVBAMMGkRhdHRvUk1NLkNvcmUgQ29kZSBTaWduaW5nAhB464iXHfI6gksE
# kDDTyrNsMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKEC
# gAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwG
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDB9x6MZnYbs4L6DRyOq+VEx85gu
# YjZSV6j9IRkyd2BgMA0GCSqGSIb3DQEBAQUABIIBACGawZgqSERIvOYwwRuUXe5M
# nL8NKlk0lF0ibBg+T4rhP6UMTmiw5cze0dWwAexwvqjkY75Eubgb6XZ8BYDAqpiO
# YgCI6cKcKdWPzMXRs1lqU4yXtLWk8XfShHrBIo44gPoKa6+kmMDP4uC278886YQ5
# WHcGHn8wYAyOTnNt6Wx3NKBo+1yJpiEaSKj4GpKY6rqM6WJ5MGeHv0WmHSXj5Y/H
# IW3ygUlLbtrx/zaVQLeWyT55mwDM1m5lHmzMZAdeGUZpwvGDalThzq1rb4lxdwVy
# 6oE4K/uDfSPbX6MPmBPcflDMDdDUtumYZ8jv6eyIpeYFm68Xg9f9bObGRf2QAGE=
# SIG # End signature block
