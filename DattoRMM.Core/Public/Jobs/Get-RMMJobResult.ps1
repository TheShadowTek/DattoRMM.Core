<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMJobResult {
    <#
    .SYNOPSIS
        Retrieves job execution results and output for a specific device from the Datto RMM API.

    .DESCRIPTION
        Retrieves execution results, standard output, and error output for a job on a specific device in the Datto RMM
        system. You can specify JobUid and DeviceUid directly, or pipe ActivityLog objects (from Get-RMMActivityLog)
        with Entity: Device, Category: Job, and Action: Deployment. The -UseExperimentalDetailClasses switch must be
        used with Get-RMMActivityLog to provide the required detail type (DRMMActivityLogDetailsDeviceJobDeployment).
        Non-deployment activity logs are safely skipped with a warning.

    .PARAMETER JobUid
        The unique identifier (GUID) of the job.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of the device associated with the job results.

    .PARAMETER ActivityLog
        An activity log object (from Get-RMMActivityLog -Entity Device -Category Job -Action Deployment -UseExperimentalDetailClasses)
        containing job deployment details. Can be piped to this function. Non-deployment
        activity logs are skipped with a warning.

    .PARAMETER IncludeOutput
        Switch to retrieve standard output and error output for the job result, if available.

    .EXAMPLE
        Get-RMMJobResult -JobUid $JobUid -DeviceUid $DeviceUid

        Retrieves the execution results for a job on a specific device.

    .EXAMPLE
        Get-RMMJobResult -JobUid $JobUid -DeviceUid $DeviceUid -IncludeOutput

        Retrieves the execution results and includes standard output and error output for the job.

    .EXAMPLE
        Get-RMMActivityLog -Entity Device -Category Job -Action Deployment -UseExperimentalDetailClasses | Get-RMMJobResult

        Retrieves job results for all deployment job activity logs for devices. The -UseExperimentalDetailClasses
        switch is required to provide the correct detail type for piping.

    .INPUTS
        System.Guid, DRMMActivityLog. You can pipe ActivityLog objects to this function.

    .OUTPUTS
        DRMMJobResults. Returns job result objects. If -IncludeOutput is used, includes standard output and error output.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.
        For details on -UseExperimentalDetailClasses, see Get-RMMActivityLog help.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Jobs/Get-RMMJobResult.md
    .LINK
        about_DRMMJobResult
    .LINK
        Get-RMMActivityLog
    #>
    [CmdletBinding(DefaultParameterSetName = 'JobUid')]
    param (
        # Unique identifier for the Datto RMM job.
        [Parameter(
            ParameterSetName = 'JobUid',
            Mandatory = $true
        )]
        [guid]
        $JobUid,

        # Unique identifier for the device associated with the job results.
        [Parameter(
            ParameterSetName = 'JobUid',
            Mandatory = $true
        )]
        [guid]
        $DeviceUid,

        # Activity log object containing details about the job.
        [Parameter(
            ParameterSetName = 'ActivityLog',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMActivityLog]
        $ActivityLog,

        # Parameter help description
        [Parameter(
            Mandatory = $false
        )]
        [switch]
        $IncludeOutput
    )
    begin {

        Write-Debug "Getting RMM job results with parameter set: $($PSCmdlet.ParameterSetName)"

    }

    process {

        switch ($PSCmdlet.ParameterSetName) {

            'ActivityLog' {
                
                if ($ActivityLog.Details -isnot [DRMMActivityLogDetailsDeviceJobDeployment]) {

                    Write-Warning "The provided ActivityLog object is not of type DRMMActivityLogDetailsDeviceJobDeployment. Only job deployment logs are supported. Entity: Device, Category: Job, Action: Deployment."
                    return

                } else {

                    $APIResultsPath = "job/$($ActivityLog.Details.JobUid)/results/$($ActivityLog.Details.DeviceUid)"
                    $JobUid = $ActivityLog.Details.JobUid
                    $DeviceUid = $ActivityLog.Details.DeviceUid

                }
            }

            'JobUid' {
                
                $APIResultsPath = "job/$JobUid/results/$DeviceUid"

            }
        }

        $APIMethod = @{
            Path = $APIResultsPath
            Method = 'Get'
        }

        $JobResult = Invoke-ApiMethod @APIMethod | ForEach-Object {[DRMMJobResults]::FromAPIMethod($_)}

        if ($IncludeOutput) {

            if ($JobResult.HasStdOut) {

                $StdOutAPIMethod = @{
                    Path = "$APIResultsPath/stdout"
                    Method = 'Get'
                }

                $JobResult.StdOut = Invoke-ApiMethod @StdOutAPIMethod | ForEach-Object {[DRMMJobStdData]::FromAPIMethod($_, $JobUid, $DeviceUid, 'StdOut')}

            }

            if ($JobResult.HasStdErr) {

                $StdErrAPIMethod = @{
                    Path = "$APIResultsPath/stderr"
                    Method = 'Get'
                }

                $JobResult.StdErr = Invoke-ApiMethod @StdErrAPIMethod | ForEach-Object {[DRMMJobStdData]::FromAPIMethod($_, $JobUid, $DeviceUid, 'StdErr')}

            }
        }

        return $JobResult

    }
}
# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA9VhklcgOXUin6
# 7q1izwiM8fY/CrVE/UatAjyMb+OuF6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKYBPaiyLoHOpBKIoSv/Z17+Nten
# VzROHTFrWOc7KetQMA0GCSqGSIb3DQEBAQUABIIBAH/fZxXWTKPBxfuVh0szhT0D
# Sqttos4zLlGEOTngXNMc3wQgYh8T5dPD1xZRkQQHEsGrr79Hoe/APjoFohiWhfQk
# VwDga1B76uK+xsrW05dHnl8ahxG9E8pqDT2fqW1wTjvDX8mkABE+XZbF8DcbTikw
# 0rN99lwRj66mc5EYIPQ/BV7zkcVbv4UfxwIOLnydn/RkvyAw7CtbuttMpzZZ8SyD
# C9z6RhUM5SdiexaSywvdviK0HcDw/hrHUaV2ih+xAo2S6XbDoNGDsvpEts0jKq3g
# g6LilOxVlynvHyrb5q4/m5Glyuxkq3D6QGMRWXQDqHqzKhieZCaYep4mPKwb0X8=
# SIG # End signature block
