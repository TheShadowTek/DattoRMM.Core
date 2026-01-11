# PSScriptAnalyzerSuppressMessage('PSUseDeclaredTypeInAttribute', 'TypeNotFound')
class DRMMActivityLog : DRMMObject {

    [string]$Id
    [string]$Entity
    [string]$Category
    [string]$Action
    [Nullable[datetime]]$Date
    [DRMMActivityLogSite]$Site
    [Nullable[long]]$DeviceId
    [string]$Hostname
    [DRMMActivityLogUser]$User
    [PSCustomObject]$Details
    [bool]$HasStdOut
    [bool]$HasStdErr

    DRMMActivityLog() : base() {

    }

    static [DRMMActivityLog] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Log = [DRMMActivityLog]::new()
        $Log.Id = $Response.id
        $Log.Entity = $Response.entity
        $Log.Category = $Response.category
        $Log.Action = $Response.action
        $Log.DeviceId = $Response.deviceId
        $Log.Hostname = $Response.hostname
        $Log.HasStdOut = $Response.hasStdOut
        $Log.HasStdErr = $Response.hasStdErr

        # Parse details from JSON
        if ($null -ne $Response.details -and $Response.details -ne '') {

            try {

                $ParsedDetail = $Response.details | ConvertFrom-Json

                # Check for date properties and parse them
                foreach ($Property in $ParsedDetail.PSObject.Properties) {

                    if ($Property.Name -match 'date' -and $null -ne $Property.Value) {

                        try {

                            $DateResult = [DRMMObject]::ParseApiDate($Property.Value)
                            $ParsedDetail.$($Property.Name) = $DateResult.DateTime

                        } catch {

                            # Leave the original value if date parsing fails
                            Write-Debug "Failed to parse date property '$($Property.Name)' with value '$($Property.Value)'"

                        }
                    }
                }

                $Log.Details = @($ParsedDetail)

            } catch {

                # If JSON parsing fails, store as a PSCustomObject with the raw string
                $Log.Details = @([PSCustomObject]@{ RawDetails = $Response.details })

            }

        }

        # Parse the date
        $DateValue = [DRMMObject]::ParseApiDate($Response.date)
        $Log.Date = $DateValue.DateTime

        # Parse nested objects
        if ($null -ne $Response.site) {

            $Log.Site = [DRMMActivityLogSite]::FromAPIMethod($Response.site)

        }

        if ($null -ne $Response.user) {

            $Log.User = [DRMMActivityLogUser]::FromAPIMethod($Response.user)

        }

        return $Log

    }

    [string] GetSummary() {

        $EntityStr = if ($this.Entity) { $this.Entity } else { 'Unknown' }
        $CategoryStr = if ($this.Category) { $this.Category } else { 'Unknown' }
        $ActionStr = if ($this.Action) { $this.Action } else { 'Unknown' }
        $TargetStr = if ($this.Hostname) { $this.Hostname } elseif ($this.User) { $this.User.UserName } else { '' }

        return "[$EntityStr] ${CategoryStr}: ${ActionStr} - $TargetStr"

    }
}

class DRMMActivityLogSite : DRMMObject {

    [long]$Id
    [string]$Name

    DRMMActivityLogSite() : base() {

    }

    static [DRMMActivityLogSite] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $Site = [DRMMActivityLogSite]::new()
        $Site.Id = $Response.id
        $Site.Name = $Response.name

        return $Site

    }
}

class DRMMActivityLogUser : DRMMObject {

    [long]$Id
    [string]$UserName
    [string]$FirstName
    [string]$LastName

    DRMMActivityLogUser() : base() {

    }

    static [DRMMActivityLogUser] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $User = [DRMMActivityLogUser]::new()
        $User.Id = $Response.id
        $User.UserName = $Response.userName
        $User.FirstName = $Response.firstName
        $User.LastName = $Response.lastName

        return $User

    }

    [string] GetSummary() {

        if ($this.FirstName -and $this.LastName) {

            return "$($this.FirstName) $($this.LastName) ($($this.UserName))"

        } elseif ($this.UserName) {

            return $this.UserName

        } else {

            return "User $($this.Id)"

        }
    }
}
