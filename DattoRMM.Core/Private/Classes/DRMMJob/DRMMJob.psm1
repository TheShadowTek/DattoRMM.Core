<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '..\DRMMObject\DRMMObject.psm1'
<#
.SYNOPSIS
    Represents a job in the DRMM system, including its ID, unique identifier, name, creation date, and status.
.DESCRIPTION
    The DRMMJob class models a job within the DRMM platform. It includes properties such as Id, Uid, Name, DateCreated, and Status. This class provides methods to interact with job components, results, standard output, and error data. It also includes utility methods to check the job's status, calculate its age, refresh its data, and generate a summary string. The class is used to represent and manage jobs in the DRMM system.
#>
class DRMMJob : DRMMObject {

    # The unique identifier of the job.
    [long]$Id
    # The unique identifier (UID) of the job.
    [guid]$Uid
    # The name of the job.
    [string]$Name
    # The date and time when the job was created.
    [Nullable[datetime]]$DateCreated
    # The current status of the job.
    [string]$Status

    DRMMJob() : base() {

    }

    static [DRMMJob] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Job = [DRMMJob]::new()
        $Job.Id = $Response.id
        $Job.Uid = $Response.uid
        $Job.Name = $Response.name
        $Job.Status = $Response.status
        $Job.DateCreated = [DRMMObject]::ParseApiDate($Response.dateCreated).DateTime

        return $Job

    }

    <#
    .SYNOPSIS
        Checks if the job is currently active.
    .DESCRIPTION
        The IsActive method returns a boolean value indicating whether the job's status is 'active'. This can be used to determine if the job is currently running or in progress.
    .OUTPUTS
        Indicates whether the job is currently active (true/false).
    #>
    [bool] IsActive() {

        return $this.Status -eq 'active'

    }

    <#
    .SYNOPSIS
        Checks if the job is completed.
    .DESCRIPTION
        The IsCompleted method returns a boolean value indicating whether the job's status is 'completed'. This can be used to determine if the job has finished its execution.
    .OUTPUTS
        Indicates whether the job is completed (true/false).
    #>
    [bool] IsCompleted() {

        return $this.Status -eq 'completed'

    }

    <#
    .SYNOPSIS
        Calculates the age of the job based on its creation date.
    .DESCRIPTION
        The GetAge method returns a TimeSpan object representing the age of the job, calculated as the difference between the current UTC time and the job's DateCreated property. If DateCreated is null, it returns a TimeSpan of zero.
    .OUTPUTS
        The age of the job as a TimeSpan object, representing the time elapsed since the job was created.
    #>
    [timespan] GetAge() {

        if ($this.DateCreated) {

            return [datetime]::UtcNow - $this.DateCreated

        }

        return [timespan]::Zero

    }

    <#
    .SYNOPSIS
        Retrieves the components associated with the job.
    .DESCRIPTION
        The GetComponents method returns an array of DRMMJobComponent objects representing the components of the job. It uses the Get-RMMJob cmdlet with the -Components parameter to fetch this information.
    .OUTPUTS
        A list of components associated with the job.
    #>
    [DRMMJobComponent[]] GetComponents() {

        return (Get-RMMJob -JobUid $this.Uid -Components)

    }

    <#
    .SYNOPSIS
        Generates a summary string for the job.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the job's name, status, and age. The age is calculated based on the job's creation date and is formatted to show days, hours, or minutes ago.
    .OUTPUTS
        A summary string representing the job.
    #>
    [string] GetSummary() {

        $Age = ''

        if ($this.DateCreated) {

            $Span = $this.GetAge()

            if ($Span.TotalDays -ge 1) {

                $Age = " ($([int]$Span.TotalDays)d ago)"

            } elseif ($Span.TotalHours -ge 1) {

                $Age = " ($([int]$Span.TotalHours)h ago)"

            } else {

                $Age = " ($([int]$Span.TotalMinutes)m ago)"

            }

        }

        $JobName = if ($this.Name) {$this.Name} else {'Unknown Job'}

        return "$JobName - $($this.Status)$Age - $($this.Status)"

    }
}

<#
.SYNOPSIS
    Represents a component of a DRMM job, including its unique identifier, name, and associated variables.
.DESCRIPTION
    The DRMMJobComponent class models a component within a DRMM job. It includes properties such as Uid, Name, and Variables, which provide details about the component's identity and configuration. The class also includes a static method to create an instance of DRMMJobComponent from API response data.
#>
class DRMMJobComponent : DRMMObject {

    # The unique identifier (UID) of the job component.
    [guid]$Uid
    # The name of the job component.
    [string]$Name
    # The variables associated with the job component.
    [DRMMJobComponentVariable[]]$Variables

    DRMMJobComponent() : base() {

    }

    static [DRMMJobComponent] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Component = [DRMMJobComponent]::new()
        $Component.Uid = $Response.uid
        $Component.Name = $Response.name
        
        if ($Response.variables) {

            $Component.Variables = $Response.variables | ForEach-Object {

                [DRMMJobComponentVariable]::FromAPIMethod($_)

            }
        }

        return $Component

    }
}

<#
.SYNOPSIS
    Represents the result of a DRMM job component, including its unique identifier, name, status, number of warnings, and whether it has standard output or error data.
.DESCRIPTION
    The DRMMJobComponentResult class models the result of a component within a DRMM job. It includes properties such as ComponentUid, ComponentName, ComponentStatus, NumberOfWarnings, HasStdOut, and HasStdErr, which provide details about the outcome of the component's execution. The class also includes a static method to create an instance of DRMMJobComponentResult from API response data.
#>
class DRMMJobComponentResult : DRMMObject {

    # The unique identifier (UID) of the job component.
    [guid]$ComponentUid
    # The name of the job component.
    [string]$ComponentName
    # The status of the job component.
    [string]$ComponentStatus
    # The number of warnings generated by the job component.
    [int]$NumberOfWarnings
    # Indicates if the job component has standard output.
    [bool]$HasStdOut
    # Indicates if the job component has standard error output.
    [bool]$HasStdErr

    DRMMJobComponentResult() : base() {

    }

    static [DRMMJobComponentResult] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Result = [DRMMJobComponentResult]::new()
        $Result.ComponentUid = $Response.componentUid
        $Result.ComponentName = $Response.componentName
        $Result.ComponentStatus = $Response.componentStatus
        $Result.NumberOfWarnings = $Response.numberOfWarnings
        $Result.HasStdOut = $Response.hasStdOut
        $Result.HasStdErr = $Response.hasStdErr

        return $Result

    }
}

<#
.SYNOPSIS
    Represents a variable associated with a DRMM job component, including its name and value.
.DESCRIPTION
    The DRMMJobComponentVariable class models a variable within a DRMM job component. It includes properties such as Name and Value, which provide details about the variable's identity and configuration. The class also includes a static method to create an instance of DRMMJobComponentVariable from API response data.
#>
class DRMMJobComponentVariable : DRMMObject {

    # The name of the job component variable.
    [string]$Name
    # The value of the job component variable.
    [string]$Value

    DRMMJobComponentVariable() : base() {

    }

    static [DRMMJobComponentVariable] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Variable = [DRMMJobComponentVariable]::new()
        $Variable.Name = $Response.name
        $Variable.Value = $Response.value

        return $Variable

    }
}

<#
.SYNOPSIS
    Represents the results of a DRMM job, including job and device identifiers, the time the job ran, deployment status, and component results.
.DESCRIPTION
    The DRMMJobResults class models the outcome of a DRMM job execution. It includes properties such as JobUid, DeviceUid, RanOn, JobDeploymentStatus, and an array of ComponentResults, which provide detailed information about the job's execution and its components. The class also includes a static method to create an instance of DRMMJobResults from API response data.
#>
class DRMMJobResults : DRMMObject {

    # The unique identifier (UID) of the job.
    [guid]$JobUid
    # The unique identifier (UID) of the device.
    [guid]$DeviceUid
    # The date and time when the job was run.
    [Nullable[datetime]]$RanOn
    # The deployment status of the job.
    [string]$JobDeploymentStatus
    # The results of the job components.
    [DRMMJobComponentResult[]]$ComponentResults
    # The total number of warnings across all component results.
    [int]$TotalNumberOfWarnings
    # Indicates whether any component result produced standard output data.
    [bool]$HasStdOut
    # Indicates whether any component result produced standard error data.
    [bool]$HasStdErr
    # The standard output data collected from job components that produced output.
    [DRMMJobStdData[]]$StdOut
    # The standard error data collected from job components that produced error output.
    [DRMMJobStdData[]]$StdErr

    DRMMJobResults() : base() {

    }

    static [DRMMJobResults] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Results = [DRMMJobResults]::new()
        $Results.JobUid = $Response.jobUid
        $Results.DeviceUid = $Response.deviceUid
        $Results.JobDeploymentStatus = $Response.jobDeploymentStatus
        $Results.RanOn = ([DRMMObject]::ParseApiDate($Response.ranOn)).DateTime
        $Results.StdOut = @()
        $Results.StdErr = @()

        if ($Response.componentResults) {

            $Results.ComponentResults = $Response.componentResults | ForEach-Object {

                [DRMMJobComponentResult]::FromAPIMethod($_)

            }
        }

        $Results.TotalNumberOfWarnings = ($Results.ComponentResults | Measure-Object -Property NumberOfWarnings -Sum).Sum

        if ($Results.ComponentResults.HasStdOut -contains $true) {

            $Results.HasStdOut = $true

        } else {

            $Results.HasStdOut = $false

        }

        if ($Results.ComponentResults.HasStdErr -contains $true) {

            $Results.HasStdErr = $true

        } else {

            $Results.HasStdErr = $false

        }

        return $Results

    }
}

<#
.SYNOPSIS
    Represents standard output or error data associated with a DRMM job component, including job, device, and component identifiers, component name, and the standard data itself.
.DESCRIPTION
    The DRMMJobStdData class models the standard output or error data produced by a component during the execution of a DRMM job. It includes properties such as JobUid, DeviceUid, ComponentUid, ComponentName, and StdData, which provide details about the source and content of the standard data. The class also includes a static method to create an instance of DRMMJobStdData from API response data.
#>
class DRMMJobStdData : DRMMObject {

    # The unique identifier (UID) of the job.
    [guid]$JobUid
    # The unique identifier (UID) of the device.
    [guid]$DeviceUid
    # The unique identifier (UID) of the job component.
    [guid]$ComponentUid
    # The name of the job component.
    [string]$ComponentName
    # The standard data output of the job component.
    [string]$StdData
    # The type of standard data, indicating whether it is standard output (StdOut) or standard error (StdErr).
    [string]$StdType

    DRMMJobStdData() : base() {

    }

    static [DRMMJobStdData] FromAPIMethod([pscustomobject]$Response, [guid]$JobUid, [guid]$DeviceUid, [string]$StdType) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Result = [DRMMJobStdData]::new()
        $Result.JobUid = $JobUid
        $Result.DeviceUid = $DeviceUid
        $Result.ComponentUid = $Response.componentUid
        $Result.ComponentName = $Response.componentName
        $Result.StdData = $Response.stdData
        $Result.StdType = $StdType

        return $Result

    }

    <#
    .SYNOPSIS
        Retrieves the standard data associated with a completed job component, parsed from JSON format.
    .DESCRIPTION
        The GetStdDataAsJson method returns a PSCustomObject representing the standard data of the job component, parsed from JSON format. This method is only applicable if the StdType is 'StdOut' and there is standard data available.
    .OUTPUTS
        A PSCustomObject representing the parsed JSON data, or null if the standard type is not StdOut or the data is empty.
    #>
    [pscustomobject] GetStdDataAsJson() {

        if ($this.StdType -ne 'StdOut' -or -not $this.StdData) {

            return $null

        }

        try {

            return (ConvertFrom-Json -InputObject $this.StdData)

        } catch {

            Write-Error "Failed to parse standard data as JSON: $_"
            return $null

        }
    }

    <#
    .SYNOPSIS
        Retrieves the standard data associated with a completed job component, parsed from CSV format.
    .DESCRIPTION
        The GetStdDataAsCsv method returns an array of PSCustomObject representing the standard data of the job component, parsed from CSV format. The first row is treated as a header by default. This method is only applicable if the StdType is 'StdOut' and there is standard data available.
    .OUTPUTS
        An array of PSCustomObject instances representing the parsed CSV data, or an empty array if the standard type is not StdOut or the data is empty.
    #>
    [pscustomobject[]] GetStdDataAsCsv() {

        return $this.GetStdDataAsCsv($null, $false)

    }

    <#
    .SYNOPSIS
        Retrieves the standard data associated with a completed job component, parsed from CSV format.
    .DESCRIPTION
        The GetStdDataAsCsv method returns an array of PSCustomObject representing the standard data of the job component, parsed from CSV format. Csv header values must be provided as a parameter. This method is only applicable if the StdType is 'StdOut' and there is standard data available.
    #>
    [pscustomobject[]] GetStdDataAsCsv([string[]]$Headers) {

        return $this.GetStdDataAsCsv($Headers, $false)

    }

    <#
    .SYNOPSIS
        Retrieves the standard data associated with a completed job component, parsed from CSV format.
    .DESCRIPTION
        The GetStdDataAsCsv method returns an array of PSCustomObject representing the standard data of the job component, parsed from CSV format. It has parameters to specify custom headers and whether to remove the first row. This method is only applicable if the StdType is 'StdOut' and there is standard data available.
    #>
    [pscustomobject[]] GetStdDataAsCsv([string[]]$Headers, [bool]$RemoveFirstRow) {

        if ($this.StdType -ne 'StdOut' -or -not $this.StdData) {

            return @()

        }

        try {

            if ($Headers) {

                if ($Headers.Count -eq 0) {

                    throw "Headers array cannot be empty when provided"

                }

                if ($RemoveFirstRow) {

                    $CsvText = ($this.StdData -split "`n" | Select-Object -Skip 1) -join "`n"

                } else {

                    $CsvText = $this.StdData

                }

                return (ConvertFrom-Csv -InputObject $CsvText -Header $Headers)

            } else {

                return (ConvertFrom-Csv -InputObject $this.StdData)

            }

        } catch {

            Write-Error "Failed to parse standard data as CSV: $_"
            return @()

        }
    }
}
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCA89lZS2Zxy1M8
# m5rJ8KhRMMIdoV7OeUOgnNdqArsNjaCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJSS7cVzU6/m/lWH7sUmSJKU3JO8
# 6tG7eWr3PjhSzH+2MA0GCSqGSIb3DQEBAQUABIIBABQO3UscQC1sth0VbEKM0qn1
# kj1mrhpu3ZbjS6D+z6138WnB7k5FEDsiJA28WisekrT0uxcE4bZi9+/lAmVth0L7
# WDlZ7FYvetv1F8ercdKOV1im29o3Dt6cYrQOimqLRBYGTaGDQgQZ+OuZ/uRZimpd
# xxExkWQAwENBw+nmCvMDxp1LL9Gh7X35p6B8slcG8KmLy8tyJu+hwcfQ7JpdRoI9
# +7CMScYZsEvhpYGxF3kawESeukA08+hMD9dFOZnNouRYC3T6EpQibtX5WpwyBwCY
# 60MWA62D3bmKoHxEwslwx1z9cvX5sRJLHHf/6CxlofNUV6UuKDtYe/6d5wiCVkk=
# SIG # End signature block
