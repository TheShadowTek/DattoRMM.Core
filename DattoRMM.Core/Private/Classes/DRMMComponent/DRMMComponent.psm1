<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '..\DRMMObject\DRMMObject.psm1'
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
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDkgZ09mo6RkYmR
# Lbzp5nc+dbVUIR6yAL9fDxNyHKyydKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFQWlCJTlVGvrfkmyuUiOZcT0A8H
# uGFe7TbZTFE4C2QSMA0GCSqGSIb3DQEBAQUABIIBAALrIepwF1B/NpcL9G4777hw
# wz5VkJ99Ly3/N+g/lya9xqvFMDPh7UuFbACyYff34ss9JLPeqPZGaW+dzWbJGxHN
# Kki4XnjPnt9rqmg/ZV0qI7/gc1v7r5hCH19myXIiL9Hfww9kn/NYyDWAIeDTqcfb
# ALIeYMV9RdssycBVuUzI8bVBtR7uRqnkCthElYt1EMB6OH2YK2H3ECYiQ8H+6fsC
# hvB/u5gbsMBxqYXuxOUUem2upiReOE+5UmFhEKROHiHXQk7rTcVTaQajG6kIBB6Y
# GcXaVU9ZWU1Jbxg741dI6yfe/Yr3sjO6/X+skWp4i1Cee82ClLEIx/UK1R29E8Y=
# SIG # End signature block
