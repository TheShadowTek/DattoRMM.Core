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
                    Invoke-APIMethod @APIMethod | ForEach-Object {[DRMMVariable]::FromAPIMethod($_, 'Site', $SiteUid)}

                }

                {$_ -in 'SiteById','SiteUidById'} {

                    Write-Debug "Getting site variable by ID: $Id for site UID: $SiteUid"
                    $Results = Invoke-APIMethod @APIMethod | Where-Object {$_.id -eq $Id}
                    
                    if ($Results) {

                        $Results | ForEach-Object {[DRMMVariable]::FromAPIMethod($_, 'Site', $SiteUid)}

                    } else {

                        Write-Debug "No site variable found with ID: $Id for site UID: $SiteUid"

                    }
                }

                {$_ -in 'SiteByName','SiteUidByName'} {

                    Write-Debug "Getting site variable by Name: $Name for site UID: $SiteUid"
                    $Results = Invoke-APIMethod @APIMethod | Where-Object {$_.name -eq $Name}
                    
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
                    Invoke-APIMethod @APIMethod | ForEach-Object {[DRMMVariable]::FromAPIMethod($_, 'Global', $null)}

                }

                'GlobalById' {

                    Write-Debug "Getting global variable by ID: $Id"
                    $Results = Invoke-APIMethod @APIMethod | Where-Object {$_.id -eq $Id}
                    
                    if ($Results) {

                        $Results | ForEach-Object {[DRMMVariable]::FromAPIMethod($_, 'Global', $null)}

                    } else {

                        Write-Debug "No global variable found with ID: $Id"

                    }
                }

                'GlobalByName' {

                    Write-Debug "Getting global variable by Name: $Name"
                    $Results = Invoke-APIMethod @APIMethod | Where-Object {$_.name -eq $Name}
                    
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
