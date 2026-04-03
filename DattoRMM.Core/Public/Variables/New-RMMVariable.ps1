<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function New-RMMVariable {
    <#
    .SYNOPSIS
        Creates a new variable in the Datto RMM account or site.

    .DESCRIPTION
        The New-RMMVariable function creates a new variable at either the account (global) level
        or at a specific site level. Variables can store configuration data that can be referenced
        in scripts and automation.

        Variables can optionally be masked to hide sensitive values in the Datto RMM UI.

    .PARAMETER Site
        A DRMMSite object to create the variable in. Accepts pipeline input from Get-RMMSite.

    .PARAMETER SiteUid
        The unique identifier (GUID) of a site to create the variable in.

    .PARAMETER Name
        The name of the variable to create.

    .PARAMETER Value
        The value to assign to the variable. Accepts both string and SecureString.
        
        When a SecureString is provided:
        - The value is securely converted for the API call
        - Plaintext is cleared from memory immediately after use
        - The variable is NOT automatically masked (use -Masked if desired)

    .PARAMETER Masked
        Whether the variable value should be masked (hidden) in the Datto RMM UI. Use this for
        sensitive values like passwords or API keys.
        
        This must be explicitly specified and is independent of whether you use SecureString.

    .PARAMETER Force
        Bypasses the confirmation prompt.

    .EXAMPLE
        New-RMMVariable -Name "CompanyName" -Value "Contoso Ltd"

        Creates an account-level variable named "CompanyName".

    .EXAMPLE
        New-RMMVariable -Name "APIKey" -Value "secret123" -Masked

        Creates a masked account-level variable for sensitive data.

    .EXAMPLE
        $Secret = Read-Host -AsSecureString -Prompt "Enter API Key"
        PS > New-RMMVariable -Name "APIKey" -Value $Secret -Masked

        Creates a masked variable using SecureString for secure input and transport.

    .EXAMPLE
        Get-RMMSite -Name "Main Office" | New-RMMVariable -Name "SiteCode" -Value "MO001"

        Creates a site-level variable via pipeline.

    .EXAMPLE
        New-RMMVariable -SiteUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -Name "BackupPath" -Value "\\server\backup"

        Creates a site-level variable by specifying the site UID.

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite.
        You can also pipe objects with SiteUid or Uid properties.

    .OUTPUTS
        DRMMVariable. Returns the newly created variable object (fetched via Get-RMMVariable).

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Variable names must be unique within their scope (account or site).
        The Masked property can only be set during creation and cannot be changed later.

        API Behavior: The Datto API does not return the created variable object, so this
        function fetches it using Get-RMMVariable by name.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Variables/New-RMMVariable.md
    #>
    [CmdletBinding(DefaultParameterSetName = 'Global', SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(
            ParameterSetName = 'BySiteObject',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMSite]
        $Site,

        [Parameter(
            ParameterSetName = 'BySiteUid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Uid')]
        [guid]
        $SiteUid,

        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter()]
        [object]
        $Value,

        [Parameter()]
        [switch]
        $Masked,

        [Parameter()]
        [switch]
        $Force
    )

    process {

        if ($Site) {

            $SiteUid = $Site.Uid

        }

        $Scope = if ($PSCmdlet.ParameterSetName -match 'Site') {'Site'} else {'Global'}
        $Target = if ($Scope -eq 'Site') {"site $SiteUid"} else {"account"}

        if (-not $PSCmdlet.ShouldProcess($Target, "Create variable '$Name'") -and -not $Force) {

            return

        }

        Write-Debug "Creating new RMM variable '$Name' at $Scope scope"

        # Handle SecureString value conversion
        $PlainValue = $null

        if ($PSBoundParameters.ContainsKey('Value')) {

            if ($Value -is [SecureString]) {

                $PlainValue = ConvertFrom-SecureStringToPlaintext -SecureString $Value
                Write-Verbose "SecureString detected - converting securely for API call"

            } else {

                $PlainValue = $Value

            }
        }

        # Build request body
        $Body = @{}

        switch ($PSBoundParameters.Keys) {

            'Name' { $Body.name = $Name }
            'Value' { $Body.value = $PlainValue }
            'Masked' { $Body.masked = $true }

        }

        # Determine API path based on scope
        $Path = if ($Scope -eq 'Site') {

            "site/$SiteUid/variable"

        } else {

            'account/variable'

        }

        $APIMethod = @{
            Path = $Path
            Method = 'Put'
            Body = $Body
        }

        # Invoke-ApiMethod does not throw on 400 errors by default, so use try/catch, throw on warnings
        try {

            Invoke-ApiMethod @APIMethod -WarningAction Stop | Out-Null

            
        } catch {

            Write-Warning "Failed to create variable '$Name' at $Scope scope.$(if ($Scope -eq 'Site') {" Site UID: $SiteUid."})"
            return

        }

        # API doesn't return the created variable, so fetch it by name
        $GetParams = @{
            Name = $Name
        }
        
        if ($Scope -eq 'Site') {

            $GetParams.SiteUid = $SiteUid

        }

        Get-RMMVariable @GetParams

    }

    end {

        # Clear plaintext value from memory
        $PlainValue = $null

    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDv0D+7Zos+2D/i
# Ko2HMvYflcKaZa0nPR5siRLqHYxeGaCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJdb/dyLGb2FJ4d4jcSCna0JXshN
# /4w+PW0Q/VmH6MGNMA0GCSqGSIb3DQEBAQUABIIBAFEbJqc48anqpcF1EN37sIKg
# MNDYlYonJevjVwyfIBIdvLEELxUcrmf8Qkoyz6dk43fES2CgWQVB7fxtH33/4DAR
# RxdPbRqMqu5pGN71fiYYBlQ2F1hXb6edo2ZR6ev+gskw4Mq/wJFwGcGjbQgJ9FNg
# nEzOq08n/2WbmeeTHQDM5fceCPClRquVKmPpV+Eczf74reyJcECTfwDlpuZHqzq8
# yA/j/Wki5pIIFIWfgHrjeHSSEpXKStdE9Nc/7FqLKJM+fyyir0QaCuUrxTH4vFo8
# 5ViSzlyLFCAWqnI/n/sgl/ig3uAFp86hmsf0WP/52WZ1ipwMXMCWf/xBI2Vh61U=
# SIG # End signature block
