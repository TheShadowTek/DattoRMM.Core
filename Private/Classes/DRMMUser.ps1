using module '.\DRMMObject.psm1'

class DRMMUser : DRMMObject {

    [string]$FirstName
    [string]$LastName
    [string]$Username
    [string]$Email
    [string]$Telephone
    [string]$Status
    [Nullable[datetime]]$Created
    [Nullable[datetime]]$LastAccess
    [bool]$Disabled

    DRMMUser() : base() {

    }

    static [DRMMUser] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {

            return $null

        }

        $User = [DRMMUser]::new()
        $User.FirstName = $Response.firstName
        $User.LastName = $Response.lastName
        $User.Username = $Response.username
        $User.Email = $Response.email
        $User.Telephone = $Response.telephone
        $User.Status = $Response.status
        $User.Disabled = $Response.disabled

        $User.Created = ([DRMMObject]::ParseApiDate($Response.created)).DateTime
        $User.LastAccess = ([DRMMObject]::ParseApiDate($Response.lastAccess)).DateTime

        return $User

    }

    [string] GetFullName() {

        return "$($this.FirstName) $($this.LastName)".Trim()

    }

    [string] GetSummary() {

        $FullName = $this.GetFullName()
        $StatusText = if ($this.Disabled) {" (Disabled)"} else {""}

        return "$FullName ($($this.Username))$StatusText"

    }
}
