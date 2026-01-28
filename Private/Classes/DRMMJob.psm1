<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '.\DRMMObject.psm1'

class DRMMJob : DRMMObject {

    [long]$Id
    [guid]$Uid
    [string]$Name
    [Nullable[datetime]]$DateCreated
    [string]$Status

    DRMMJob() : base() {

    }

    static [DRMMJob] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Job = [DRMMJob]::new()
        $Job.Id = [DRMMObject]::GetValue($Response, 'id')
        $Job.Uid = [DRMMObject]::GetValue($Response, 'uid')
        $Job.Name = [DRMMObject]::GetValue($Response, 'name')
        $Job.Status = [DRMMObject]::GetValue($Response, 'status')

        $DateCreatedValue = [DRMMObject]::GetValue($Response, 'dateCreated')

        if ($null -ne $DateCreatedValue) {

            try {

                $Job.DateCreated = [datetime]::Parse($DateCreatedValue)

            } catch {

                $Job.DateCreated = $null

            }
        }

        return $Job

    }

    # Status Check Methods
    [bool] IsActive() {

        return $this.Status -eq 'active'

    }

    [bool] IsCompleted() {

        return $this.Status -eq 'completed'

    }

    # Time-based Methods
    [timespan] GetAge() {

        if ($this.DateCreated) {

            return (Get-Date) - $this.DateCreated

        }

        return [timespan]::Zero

    }

    # API Wrapper Methods
    [DRMMJobComponent[]] GetComponents() {

        return (Get-RMMJob -JobUid $this.Uid -Components)

    }

    [DRMMJobResults] GetResults([guid]$DeviceUid) {

        return (Get-RMMJob -JobUid $this.Uid -DeviceUid $DeviceUid -Results)

    }

    [DRMMJobStdData[]] GetStdOut([guid]$DeviceUid) {

        return (Get-RMMJob -JobUid $this.Uid -DeviceUid $DeviceUid -StdOut)

    }

    [DRMMJobStdData[]] GetStdErr([guid]$DeviceUid) {

        return (Get-RMMJob -JobUid $this.Uid -DeviceUid $DeviceUid -StdErr)

    }

    # Refresh Method
    [void] Refresh() {

        $Updated = Get-RMMJob -JobUid $this.Uid

        if ($Updated) {

            $this.Status = $Updated.Status
            $this.Name = $Updated.Name
            $this.DateCreated = $Updated.DateCreated

        }

    }

    # Utility Methods
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

        return "$JobName - $($this.Status)$Age"

    }

    # Output Parsing Methods
    [pscustomobject[]] GetStdOutAsJson([guid]$DeviceUid) {

        $StdOutData = $this.GetStdOut($DeviceUid)

        if (-not $StdOutData -or $StdOutData.Count -eq 0) {

            return @()

        }

        # Combine all stdout lines into single string
        $JsonText = ($StdOutData | ForEach-Object {$_.StdData}) -join "`n"

        try {

            return (ConvertFrom-Json -InputObject $JsonText)

        } catch {

            Write-Error "Failed to parse stdout as JSON: $_"
            return @()

        }

    }

    [pscustomobject[]] GetStdOutAsCsv([guid]$DeviceUid) {

        # Default: treat first row as header
        return $this.GetStdOutAsCsv($DeviceUid, $true, $null)

    }

    [pscustomobject[]] GetStdOutAsCsv([guid]$DeviceUid, [bool]$FirstRowAsHeader) {

        return $this.GetStdOutAsCsv($DeviceUid, $FirstRowAsHeader, $null)

    }

    [pscustomobject[]] GetStdOutAsCsv([guid]$DeviceUid, [bool]$FirstRowAsHeader, [string[]]$Headers) {

        $StdOutData = $this.GetStdOut($DeviceUid)

        if (-not $StdOutData -or $StdOutData.Count -eq 0) {

            return @()

        }

        # Combine all stdout lines into single string
        $CsvText = ($StdOutData | ForEach-Object {$_.StdData}) -join "`n"

        try {

            if ($Headers -and $Headers.Count -gt 0) {

                # Custom headers provided
                if ($FirstRowAsHeader) {

                    # Original CSV has headers, skip that first line before parsing
                    $CsvText = ($CsvText -split "`n" | Select-Object -Skip 1) -join "`n"

                }

                # Parse with custom headers (all remaining rows are data)
                return (ConvertFrom-Csv -InputObject $CsvText -Header $Headers)

            } elseif ($FirstRowAsHeader) {

                # Standard CSV with header row
                return (ConvertFrom-Csv -InputObject $CsvText)

            } else {

                # FirstRowAsHeader = false but no custom headers provided
                throw "When FirstRowAsHeader is false, you must provide custom headers via the Headers parameter"

            }

        } catch {

            Write-Error "Failed to parse stdout as CSV: $_"
            return @()

        }

    }
}

class DRMMJobComponent : DRMMObject {

    [guid]$Uid
    [string]$Name
    [DRMMJobComponentVariable[]]$Variables

    DRMMJobComponent() : base() {

    }

    static [DRMMJobComponent] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Component = [DRMMJobComponent]::new()
        $Component.Uid = [DRMMObject]::GetValue($Response, 'uid')
        $Component.Name = [DRMMObject]::GetValue($Response, 'name')
        
        if ($Response.variables) {

            $Component.Variables = $Response.variables | ForEach-Object {

                [DRMMJobComponentVariable]::FromAPIMethod($_)

            }
        }

        return $Component

    }
}

class DRMMJobComponentResult : DRMMObject {

    [guid]$ComponentUid
    [string]$ComponentName
    [string]$ComponentStatus
    [int]$NumberOfWarnings
    [bool]$HasStdOut
    [bool]$HasStdErr

    DRMMJobComponentResult() : base() {

    }

    static [DRMMJobComponentResult] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Result = [DRMMJobComponentResult]::new()
        $Result.ComponentUid = [DRMMObject]::GetValue($Response, 'componentUid')
        $Result.ComponentName = [DRMMObject]::GetValue($Response, 'componentName')
        $Result.ComponentStatus = [DRMMObject]::GetValue($Response, 'componentStatus')
        $Result.NumberOfWarnings = [DRMMObject]::GetValue($Response, 'numberOfWarnings')
        $Result.HasStdOut = [DRMMObject]::GetValue($Response, 'hasStdOut')
        $Result.HasStdErr = [DRMMObject]::GetValue($Response, 'hasStdErr')

        return $Result

    }
}

class DRMMJobComponentVariable : DRMMObject {

    [string]$Name
    [string]$Value

    DRMMJobComponentVariable() : base() {

    }

    static [DRMMJobComponentVariable] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Variable = [DRMMJobComponentVariable]::new()
        $Variable.Name = [DRMMObject]::GetValue($Response, 'name')
        $Variable.Value = [DRMMObject]::GetValue($Response, 'value')

        return $Variable

    }
}

class DRMMJobResults : DRMMObject {

    [guid]$JobUid
    [guid]$DeviceUid
    [Nullable[datetime]]$RanOn
    [string]$JobDeploymentStatus
    [DRMMJobComponentResult[]]$ComponentResults

    DRMMJobResults() : base() {

    }

    static [DRMMJobResults] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Results = [DRMMJobResults]::new()
        $Results.JobUid = [DRMMObject]::GetValue($Response, 'jobUid')
        $Results.DeviceUid = [DRMMObject]::GetValue($Response, 'deviceUid')
        $Results.JobDeploymentStatus = [DRMMObject]::GetValue($Response, 'jobDeploymentStatus')

        $RanOnValue = [DRMMObject]::GetValue($Response, 'ranOn')
        $Results.RanOn = ([DRMMObject]::ParseApiDate($RanOnValue)).DateTime

        if ($Response.componentResults) {

            $Results.ComponentResults = $Response.componentResults | ForEach-Object {

                [DRMMJobComponentResult]::FromAPIMethod($_)

            }

        }

        return $Results

    }
}

class DRMMJobStdData : DRMMObject {

    [guid]$JobUid
    [guid]$DeviceUid
    [guid]$ComponentUid
    [string]$ComponentName
    [string]$StdData

    DRMMJobStdData() : base() {

    }

    static [DRMMJobStdData] FromAPIMethod([pscustomobject]$Response, [guid]$JobUid, [guid]$DeviceUid) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Result = [DRMMJobStdData]::new()
        $Result.JobUid = $JobUid
        $Result.DeviceUid = $DeviceUid
        $Result.ComponentUid = [DRMMObject]::GetValue($Response, 'componentUid')
        $Result.ComponentName = [DRMMObject]::GetValue($Response, 'componentName')
        $Result.StdData = [DRMMObject]::GetValue($Response, 'stdData')

        return $Result

    }
}


