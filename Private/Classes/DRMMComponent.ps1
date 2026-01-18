<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '.\DRMMObject.psm1'

class DRMMComponent : DRMMObject {

    [int]$Id
    [string]$Uid
    [string]$Name
    [string]$Description
    [string]$CategoryCode
    [bool]$CredentialsRequired
    [DRMMComponentVariable[]]$Variables

    DRMMComponent() : base() {

    }

    static [DRMMComponent] FromAPIMethod([pscustomobject]$Response) {

        $Component = [DRMMComponent]::new()

        $Component.Id = [DRMMObject]::GetValue($Response, 'id')
        $Component.Uid = [DRMMObject]::GetValue($Response, 'uid')
        $Component.Name = [DRMMObject]::GetValue($Response, 'name')
        $Component.Description = [DRMMObject]::GetValue($Response, 'description')
        $Component.CategoryCode = [DRMMObject]::GetValue($Response, 'categoryCode')
        $Component.CredentialsRequired = [DRMMObject]::GetValue($Response, 'credentialsRequired')

        # Parse variables array
        $Component.Variables = @()
        $VariablesArray = [DRMMObject]::GetValue($Response, 'variables')
        if ($null -ne $VariablesArray -and $VariablesArray.Count -gt 0) {

            foreach ($VarItem in $VariablesArray) {

                $Component.Variables += [DRMMComponentVariable]::FromAPIMethod($VarItem)

            }
        }

        return $Component

    }

    [DRMMComponentVariable] GetVariable([string]$Name) {

        return $this.Variables | Where-Object {$_.Name -eq $Name} | Select-Object -First 1

    }

    [DRMMComponentVariable[]] GetInputVariables() {

        return $this.Variables | Where-Object {$_.Direction -eq $true}

    }

    [DRMMComponentVariable[]] GetOutputVariables() {

        return $this.Variables | Where-Object {$_.Direction -eq $false}

    }

    [string] GetSummary() {

        $ComponentName = if ($this.Name) {$this.Name} else {'Unknown Component'}
        $VarCount = if ($this.Variables) {$this.Variables.Count} else {0}
        $CredText = if ($this.CredentialsRequired) {' [Credentials Required]'} else {''}
        $Category = if ($this.CategoryCode) {" - $($this.CategoryCode)"} else {''}
        
        return "$ComponentName$CredText - $VarCount variable(s)$Category"

    }
}

class DRMMComponentVariable : DRMMObject {

    [string]$Name
    [string]$DefaultValue
    [string]$Type
    [bool]$Direction
    [string]$Description
    [int]$Index

    DRMMComponentVariable() : base() {

    }

    static [DRMMComponentVariable] FromAPIMethod([pscustomobject]$Response) {

        $Variable = [DRMMComponentVariable]::new()

        $Variable.Name = [DRMMObject]::GetValue($Response, 'name')
        $Variable.DefaultValue = [DRMMObject]::GetValue($Response, 'defaultVal')
        $Variable.Type = [DRMMObject]::GetValue($Response, 'type')
        $Variable.Direction = [DRMMObject]::GetValue($Response, 'direction')
        $Variable.Description = [DRMMObject]::GetValue($Response, 'description')
        $Variable.Index = [DRMMObject]::GetValue($Response, 'variablesIdx')

        return $Variable

    }

    [string] GetSummary() {

        $DirectionText = if ($this.Direction) { 'Input' } else { 'Output' }
        return "[$DirectionText] $($this.Name) ($($this.Type))"

    }
}

