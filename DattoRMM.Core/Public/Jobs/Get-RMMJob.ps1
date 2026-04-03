<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMJob {
    <#
    .SYNOPSIS
        Retrieves job information from the Datto RMM API by JobUid or from an ActivityLog object.

    .DESCRIPTION
        Retrieves information about jobs (component executions) in the Datto RMM system. You can specify a JobUid
        directly, or pipe ActivityLog objects (from Get-RMMActivityLog) to retrieve job details for each log entry.
        When piping ActivityLog objects, the -UseExperimentalDetailClasses switch must be used with Get-RMMActivityLog
        to provide the required detail type. Non-job activity logs are safely skipped with a warning. This function
        supports retrieving jobs for actions such as Deployment (execution), Create (new job), and Generic (unknown action).

    .PARAMETER JobUid
        The unique identifier (GUID) of the job to retrieve.

    .PARAMETER ActivityLog
        An activity log object (from Get-RMMActivityLog -UseExperimentalDetailClasses) containing job details. Can be
        piped to this function. Non-job activity logs are skipped with a warning.

    .EXAMPLE
        Get-RMMJob -JobUid "12067610-8504-48e3-b5de-60e48416aaad"

        Retrieves basic information about a specific job by its unique identifier.

    .EXAMPLE
        Get-RMMActivityLog -Entity Device -UseExperimentalDetailClasses | Get-RMMJob

        Retrieves job details for all job-related activity logs for devices. The -UseExperimentalDetailClasses switch
        is required to provide the correct detail type for piping.

    .EXAMPLE
        Get-RMMActivityLog -Entity Device -Category Job -UseExperimentalDetailClasses | Where-Object { $_.Details.JobName -eq 'Patch Critical Servers' } | Get-RMMJob

        Retrieves job details for all jobs named 'Patch Critical Servers' from device activity logs.

    .INPUTS
        System.Guid, DRMMActivityLog. You can pipe ActivityLog objects to this function.

    .OUTPUTS
        DRMMJob. Returns job objects with status, timestamps, and execution details.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.
        For details on -UseExperimentalDetailClasses, see Get-RMMActivityLog help.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Jobs/Get-RMMJob.md
    .LINK
        about_DRMMJob
    .LINK
        Get-RMMActivityLog
    #>
    [CmdletBinding(DefaultParameterSetName = 'JobUid')]
    param (
        [Parameter(
            ParameterSetName = 'JobUid',
            Mandatory = $true
        )]
        [guid]
        $JobUid,

        # Parameter help description
        [Parameter(
            ParameterSetName = 'ActivityLog',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMActivityLog]
        $ActivityLog
    )
    begin {

        Write-Debug "Initializing Get-RMMJobV2 with parameter set: $($PSCmdlet.ParameterSetName)"
    
    }

    process {

        switch ($PSCmdlet.ParameterSetName) {

            'ActivityLog' {
                
                if ($ActivityLog.Details -isnot [DRMMActivityLogDetailsDeviceJob]) {

                    Write-Warning "The provided ActivityLog object is not of type DRMMActivityLogDetailsDeviceJob. Only job activity logs are supported."
                    return

                } else {

                    $APIPath = "job/$($ActivityLog.Details.JobUid)"

                }
            }

            'JobUid' {
                
                $APIPath = "job/$JobUid"

            }
        }

        $APIMethod = @{
            Path = $APIPath
            Method = 'Get'
        }

        Invoke-ApiMethod @APIMethod | ForEach-Object {[DRMMJob]::FromAPIMethod($_)}

    }
}
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBpRbH2yPK5vABl
# +SloFotFjHC51OLj6E5Outyqh3SlDKCCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMuD9AIxxt7ZkmyOSSTT6fzaVECB
# qyX9vpCZ4JVL8TbHMA0GCSqGSIb3DQEBAQUABIIBABN+SZ09OHi1he0S0EZPpvjK
# DbkHRPS7n+M8pvAOZZyzN6AZ4ZbL4KK+QPDb+fDJ+N+NDpz/aviPUO4StLa1QncF
# 0Aq6iSARziG66qho9KMoizeIFglC7K62f1MNxRrud4zUZ1sp+R37un/r6B04Qiw9
# 6EbAS+EaWa2g7060MMjZxz6IIBJhZjEwMFSWroNMLUSPSAUOJBpgdqSetDkdF8lX
# m9A7P+5WmY7E2bpAqeH+6zXyU2x5c0Z7le++mJrepNvj2t3KqhJh/BixT5bKUC/8
# xsrP59vFpvTBf+BsUyufu7UFd3PH7icIkoARA0FjkBbngrdGnd9Z9K4DdNvP+uY=
# SIG # End signature block
