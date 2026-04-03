<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '..\DRMMObject\DRMMObject.psm1'
<#
.SYNOPSIS
    Represents a variable in the DRMM system, including its name, value, scope, and other attributes.
.DESCRIPTION
    The DRMMVariable class models a variable within the DRMM platform, encapsulating properties such as Id, Name, Value, Scope, SiteUid, and IsSecret. It provides a constructor and a static method to create an instance from API response data. The class also includes methods to determine if the variable is global or site-specific, as well as a method to generate a summary string of the variable's information.
#>
class DRMMVariable : DRMMObject {

    # The unique identifier of the variable.
    [long]$Id
    # The name of the variable.
    [string]$Name
    # The value of the variable.
    [object]$Value
    # The scope of the variable.
    [string]$Scope
    # The unique identifier (UID) of the site associated with the variable.
    [Nullable[guid]]$SiteUid
    # Indicates whether the variable is a secret variable.
    [bool]$IsSecret

    DRMMVariable() : base() {

    }

    static [DRMMVariable] FromAPIMethod([pscustomobject]$Response, [string]$Scope, [Nullable[guid]]$SiteUid) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Variable = [DRMMVariable]::new()
        $Variable.Id = $Response.id
        $Variable.Name = $Response.name
        $Variable.Value = $Response.value
        $Variable.IsSecret = $Response.masked
        $Variable.Scope = $Scope
        $Variable.SiteUid = $SiteUid

        return $Variable

    }

    <#
    .SYNOPSIS
        Determines if the variable is global in scope.
    .DESCRIPTION
        The IsGlobal method checks the Scope property of the variable to determine if it is global in scope. It returns true if the Scope is equal to 'Global', and false otherwise.
    .OUTPUTS
        True if the variable is global in scope; otherwise, false.
    #>
    [bool] IsGlobal() { return ($this.Scope -eq 'Global') }

    <#
    .SYNOPSIS
        Determines if the variable is site-specific in scope.
    .DESCRIPTION
        The IsSite method checks the Scope property of the variable to determine if it is site-specific in scope. It returns true if the Scope is equal to 'Site', and false otherwise.
    .OUTPUTS
        True if the variable is site-specific in scope; otherwise, false.
    #>
    [bool] IsSite()   { return ($this.Scope -eq 'Site') }


    <#
    .SYNOPSIS
        Generates a summary string for the variable, including its name, scope, and value.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the variable's name, scope, and value. If the Scope property is not set, it defaults to 'Global'. The method also accounts for secret variables, which are masked in the API response.
    .OUTPUTS
        A summary string that includes the name, scope, and value of the variable.
    #>
    [string] GetSummary() {

        # API already returns masked values for secret variables
        $ScopeValue = if ($this.Scope) { $this.Scope } else { 'Global' }

        return "$($this.Name) [$ScopeValue] = $($this.Value)"

    }
}