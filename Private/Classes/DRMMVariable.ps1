using module '.\DRMMObject.psm1'


class DRMMVariable : DRMMObject {

    [long]$Id
    [string]$Name
    [object]$Value
    [string]$Scope
    [Nullable[guid]]$SiteUid
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

    [bool] IsGlobal() { return ($this.Scope -eq 'Global') }
    [bool] IsSite()   { return ($this.Scope -eq 'Site') }

    [string] GetSummary() {

        # API already returns masked values for secret variables
        $ScopeValue = if ($this.Scope) { $this.Scope } else { 'Global' }

        return "$($this.Name) [$ScopeValue] = $($this.Value)"

    }
}