<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
using module '..\DRMMObject\DRMMObject.psm1'
<#
.SYNOPSIS
    Represents a user in the DRMM system, including properties such as first name, last name, username, email, telephone, status, creation date, last access date, and disabled status.
.DESCRIPTION
    The DRMMUser class models a user within the DRMM platform, encapsulating properties such as FirstName, LastName, Username, Email, Telephone, Status, Created, LastAccess, and Disabled. The class provides a constructor and a static method to create an instance from API response data. The FromAPIMethod static method takes a response object, extracts the relevant information, and populates the properties of the DRMMUser instance accordingly. The class also includes methods to generate a full name for the user and to provide a summary of the user's information, including their username and disabled status. The DRMMUser class serves as a representation of users within the DRMM system, allowing for easy access to user information and status details.
#>
class DRMMUser : DRMMObject {

    # The first name of the user.
    [string]$FirstName
    # The last name of the user.
    [string]$LastName
    # The username of the user.
    [string]$Username
    # The email address of the user.
    [string]$Email
    # The telephone number of the user.
    [string]$Telephone
    # The current status of the user.
    [string]$Status
    # The creation date of the user.
    [Nullable[datetime]]$Created
    # The last access date of the user.
    [Nullable[datetime]]$LastAccess
    # Indicates whether the user is disabled.
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

    <#
    .SYNOPSIS
        Generates the full name of the user by combining the first name and last name.
    .DESCRIPTION
        The GetFullName method returns a string that combines the FirstName and LastName properties of the user to create a full name. The method trims any extra whitespace to ensure a clean output, even if one of the name components is missing.
    .OUTPUTS
        The full name of the user, which is a combination of the first name and last name.
    #>
    [string] GetFullName() {

        return "$($this.FirstName) $($this.LastName)".Trim()

    }

    <#
    .SYNOPSIS
        Generates a summary string for the user, including their full name, username, and disabled status.
    .DESCRIPTION
        The GetSummary method returns a string summarizing the user's information, including their full name (constructed from the first and last name), username, and an indication of whether the user is disabled. If the user is disabled, the summary will include "(Disabled)" next to the username for clarity.
    .OUTPUTS
        A summary string that includes the full name, username, and disabled status of the user.
    #>
    [string] GetSummary() {

        $FullName = $this.GetFullName()
        $StatusText = if ($this.Disabled) {" (Disabled)"} else {""}

        return "$FullName ($($this.Username))$StatusText"

    }
}