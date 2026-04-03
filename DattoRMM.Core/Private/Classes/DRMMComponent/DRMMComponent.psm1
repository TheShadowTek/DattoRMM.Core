using module '..\DRMMObject\DRMMObject.psm1'

<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
<#
.SYNOPSIS
    Represents a component in the DRMM system, including its properties and associated variables.
.DESCRIPTION
    The DRMMComponent class models a component within the DRMM platform, encapsulating properties such as Id, Uid, Name, Description, CategoryCode, CredentialsRequired, and an array of associated variables (DRMMComponentVariable). It provides methods to retrieve specific variables and generate summaries of the component's properties.
.LINK
    Get-RMMComponent
.LINK
    New-RMMQuickJob
#>
class DRMMComponent : DRMMObject {

    # The unique identifier of the component.
    [int]$Id
    # The unique identifier string of the component.
    [string]$Uid
    # The name of the component.
    [string]$Name
    # A description of the component.
    [string]$Description
    # The category code that classifies the component within the DRMM system.
    [string]$CategoryCode
    # Indicates whether the component requires credentials.
    [bool]$CredentialsRequired
    # An array of variables associated with the component.
    [DRMMComponentVariable[]]$Variables
    # The URL to access the component in the Datto RMM web portal.
    [string]$PortalUrl

    DRMMComponent() : base() {

    }

    static [DRMMComponent] FromAPIMethod([pscustomobject]$Response, [string]$Platform) {

        $Component = [DRMMComponent]::new()

        $Component.Id = $Response.id
        $Component.Uid = $Response.uid
        $Component.Name = $Response.name
        $Component.Description = $Response.description
        $Component.CategoryCode = $Response.categoryCode
        $Component.CredentialsRequired = $Response.credentialsRequired
        $Component.PortalUrl = "https://$($Platform.ToLower()).rmm.datto.com/component/$($Component.Id)"

        # Parse variables array
        $Component.Variables = @()
        $VariablesArray = $Response.variables
        if ($null -ne $VariablesArray -and $VariablesArray.Count -gt 0) {

            foreach ($VarItem in $VariablesArray) {

                $Component.Variables += [DRMMComponentVariable]::FromAPIMethod($VarItem)

            }
        }

        return $Component

    }

    <#
    .SYNOPSIS
        Retrieves a specific variable from the component by name.
    .DESCRIPTION
        The GetVariable method of the DRMMComponent class allows you to retrieve a specific variable associated with the component by providing the variable's name. It searches through the component's Variables array and returns the first variable that matches the specified name. If no matching variable is found, it returns $null.
    .OUTPUTS
        The DRMMComponentVariable object that matches the specified name, or null if not found.
    #>
    [DRMMComponentVariable] GetVariable([string]$Name) {

        return $this.Variables | Where-Object {$_.Name -eq $Name} | Select-Object -First 1

    }

    <#
    .SYNOPSIS
        Retrieves all input variables associated with the component.
    .DESCRIPTION
        The GetInputVariables method of the DRMMComponent class returns an array of all variables that are designated as input variables (where Direction is $true) associated with the component.
    .OUTPUTS
        An array of DRMMComponentVariable objects that are designated as input variables for the component.
    #>
    [DRMMComponentVariable[]] GetInputVariables() {

        return $this.Variables | Where-Object {$_.Direction -eq $true}

    }

    <#
    .SYNOPSIS
        Retrieves all output variables associated with the component.
    .DESCRIPTION
        The GetOutputVariables method of the DRMMComponent class returns an array of all variables that are designated as output variables (where Direction is $false) associated with the component.
    .OUTPUTS
        An array of DRMMComponentVariable objects that are designated as output variables for the component.
    #>
    [DRMMComponentVariable[]] GetOutputVariables() {

        return $this.Variables | Where-Object {$_.Direction -eq $false}

    }

    <#
    .SYNOPSIS
        Opens the component's portal URL in the default web browser.
    .DESCRIPTION
        The OpenPortal method of the DRMMComponent class checks if the PortalUrl property is set and, if so, opens it in the default web browser using Start-Process. If the PortalUrl is not available, it writes a warning message to the console indicating that the portal URL is not available for the component's site.
    .OUTPUTS
        This method does not return a value. It performs an action to open the portal URL in the default web browser.
    #>
    [void] OpenPortal() {

        if ($this.PortalUrl) {

            Start-Process $this.PortalUrl

        } else {

            Write-Warning "Portal URL is not available for site $($this.Name)"

        }
    }

    <#
    .SYNOPSIS
        Generates a summary string for the component, including its name, variable count, credentials requirement, and category.
    .DESCRIPTION
        The GetSummary method returns a string summarizing key information about the component, such as its name, the number of variables it contains, whether credentials are required, and its category code.
    .OUTPUTS
        A summary string for the component, including its name, variable count, credentials requirement, and category.
    #>
    [string] GetSummary() {

        $ComponentName = if ($this.Name) {$this.Name} else {'Unknown Component'}
        $VarCount = if ($this.Variables) {$this.Variables.Count} else {0}
        $CredText = if ($this.CredentialsRequired) {' [Credentials Required]'} else {''}
        $Category = if ($this.CategoryCode) {" - $($this.CategoryCode)"} else {''}
        
        return "$ComponentName$CredText - $VarCount variable(s)$Category"

    }
}

<#
.SYNOPSIS
    Represents a variable associated with a DRMM component, including its name, type, direction, and other metadata.
.DESCRIPTION
    The DRMMComponentVariable class models a variable that can be used as input or output for a DRMM component. It includes properties for the variable's name, default value, type, direction (input/output), description, and index within the component's variable list. Methods allow for instantiation from API responses and for generating a summary string describing the variable.
#>
class DRMMComponentVariable : DRMMObject {

    # The name of the variable.
    [string]$Name
    # The default value of the variable.
    [string]$DefaultValue
    # The data type of the variable.
    [string]$Type
    # The direction of the variable (input or output).
    [bool]$Direction
    # A description of the variable.
    [string]$Description
    # The index of the variable within the component's variable list.
    [int]$Index

    DRMMComponentVariable() : base() {

    }

    static [DRMMComponentVariable] FromAPIMethod([pscustomobject]$Response) {

        $Variable = [DRMMComponentVariable]::new()

        $Variable.Name = $Response.name
        $Variable.DefaultValue = $Response.defaultVal
        $Variable.Type = $Response.type
        $Variable.Direction = $Response.direction
        $Variable.Description = $Response.description
        $Variable.Index = $Response.variablesIdx

        return $Variable

    }

    <#
    .SYNOPSIS
        Generates a summary string for the component variable.
    .DESCRIPTION
        The GetSummary method returns a string describing the variable, including its direction (input/output), name, and type.
    .OUTPUTS
        A summary string for the component variable.
    #>
    [string] GetSummary() {

        $DirectionText = if ($this.Direction) { 'Input' } else { 'Output' }
        return "[$DirectionText] $($this.Name) ($($this.Type))"

    }
}