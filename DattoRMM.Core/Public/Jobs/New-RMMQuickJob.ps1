<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function New-RMMQuickJob {
    <#
    .SYNOPSIS
        Creates a quick job on a device in Datto RMM.

    .DESCRIPTION
        The New-RMMQuickJob function creates and executes a quick (ad-hoc) job on a specific
        device using a component from your account. Quick jobs are useful for running one-off
        scripts or automation tasks on devices without creating a scheduled job.

        Component variables can be provided as a hashtable where keys are variable names and
        values are the variable values. Only provide variables that the component requires.

    .PARAMETER Device
        A DRMMDevice object to run the job on. Accepts pipeline input from Get-RMMDevice.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of the device to run the job on.

    .PARAMETER JobName
        A descriptive name for this job instance. This helps identify the job in job history.

    .PARAMETER Component
        A DRMMComponent object from Get-RMMComponent. The job will execute this component.

    .PARAMETER ComponentUid
        The unique identifier (GUID) of the component to execute. Use Get-RMMComponent to find
        available components and their UIDs.

    .PARAMETER Variables
        A hashtable of component variables. Keys are variable names, values are the values to
        pass to the component. Example: @{computerName='SERVER01'; port='3389'}
        
        Only provide variables that the component requires. Variable names must match the
        component's input variable names exactly (case-sensitive).

    .PARAMETER Force
        Bypasses the confirmation prompt.

    .EXAMPLE
        New-RMMQuickJob -DeviceUid $DeviceUid -JobName "Get System Info" -ComponentUid $ComponentUid

        Creates a quick job on a device using a component that requires no variables.

    .EXAMPLE
        $Device = Get-RMMDevice -Hostname "SERVER01"
        PS > $Component = Get-RMMComponent | Where-Object {$_.Name -eq "Restart Service"}
        PS > New-RMMQuickJob -Device $Device -JobName "Restart IIS" -Component $Component -Variables @{serviceName='W3SVC'}

        Creates a quick job to restart a service, passing the service name as a variable.

    .EXAMPLE
        Get-RMMDevice -FilterId 100 | New-RMMQuickJob -JobName "Update Windows" -ComponentUid $CompUid -Force

        Creates quick jobs on all devices in a filter without confirmation.

    .EXAMPLE
        $Vars = @{
            path = 'C:\Logs'
            days = '30'
            recurse = 'true'
        }
        PS > New-RMMQuickJob -DeviceUid $DeviceUid -JobName "Clean Old Logs" -ComponentUid $CompUid -Variables $Vars

        Creates a quick job with multiple variables passed as a hashtable.

    .EXAMPLE
        $Component = Get-RMMComponent | Where-Object {$_.Name -like "*PowerShell*"} | Select-Object -First 1
        PS > $Component.GetInputVariables() | Select-Object Name, Type
        PS > Get-RMMDevice -Hostname "WKS*" | New-RMMQuickJob -JobName "Run PowerShell" -Component $Component

        Gets a component, checks its required input variables, then creates jobs on multiple devices.

    .INPUTS
        DRMMDevice. You can pipe device objects from Get-RMMDevice.
        You can also pipe objects with DeviceUid or Uid properties.

    .OUTPUTS
        DRMMJob. Returns the created job object with its status and unique identifier.

    .LINK
        about_DRMMDevice

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMComponent

    .LINK
        Get-RMMJob

    .LINK
        about_DRMMJob

    .LINK
        Get-RMMComponent

    .LINK
        about_DRMMComponent

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Best practices:
        - Use descriptive job names to identify jobs in history
        - Check component input variables with Component.GetInputVariables()
        - Test components on a single device before running on multiple devices
        - Monitor job status with Get-RMMJob to verify completion
        - Use -WhatIf to preview job creation without executing

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Jobs/New-RMMQuickJob.md
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByDeviceUidWithComponentUid', SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(
            ParameterSetName = 'ByDeviceObjectWithComponent',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceObjectWithComponentUid',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMDevice]
        $Device,

        [Parameter(
            ParameterSetName = 'ByDeviceUidWithComponent',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceUidWithComponentUid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Uid')]
        [guid]
        $DeviceUid,

        [Parameter(Mandatory = $true)]
        [string]
        $JobName,

        [Parameter(
            ParameterSetName = 'ByDeviceObjectWithComponent',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceUidWithComponent',
            Mandatory = $true
        )]
        [DRMMComponent]
        $Component,

        [Parameter(
            ParameterSetName = 'ByDeviceObjectWithComponentUid',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceUidWithComponentUid',
            Mandatory = $true
        )]
        [guid]
        $ComponentUid,

        [Parameter()]
        [hashtable]
        $Variables,

        [Parameter()]
        [switch]
        $Force
    )

    process {

        if ($Device) {

            $DeviceUid = $Device.Uid
            $DeviceName = $Device.Hostname

        } else {

            $DeviceName = "device $DeviceUid"
        }

        if ($Component) {

            $ComponentUid = $Component.Uid
            $ComponentName = $Component.Name

        } else {

            $ComponentName = "component $ComponentUid"
        }

        $Target = "device '$DeviceName' (UID: $DeviceUid)"
        $Action = "Create quick job '$JobName' using $ComponentName"

        if (-not $PSCmdlet.ShouldProcess($Target, $Action)) {

            return
        }

        Write-Debug "Creating quick job '$JobName' on device $DeviceUid using component $ComponentUid"

        # Build job component object
        $JobComponent = @{
            componentUid = $ComponentUid.ToString()
        }

        # Add variables if provided
        if ($Variables -and $Variables.Count -gt 0) {

            $JobComponent.variables = @()
            foreach ($key in $Variables.Keys) {

                $JobComponent.variables += @{
                    name = $key
                    value = $Variables[$key]
                }
            }
        }

        # Build request body
        $Body = @{
            jobName = $JobName
            jobComponent = $JobComponent
        }

        $APIMethod = @{
            Path = "device/$DeviceUid/quickjob"
            Method = 'Put'
            Body = $Body
        }

        $Response = Invoke-ApiMethod @APIMethod

        # Parse and return the job object from the response
        if ($Response -and $Response.job) {

            [DRMMJob]::FromAPIMethod($Response.job)

        } else {

            Write-Warning "Quick job created but no job details returned from API"

        }
    }
}


# SIG # Begin signature block
# MIIF+wYJKoZIhvcNAQcCoIIF7DCCBegCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBK5jPMSeHHx1ew
# 6T43HLXOm42CVlqZPhSFzkJfVrxPG6CCA04wggNKMIICMqADAgECAhB464iXHfI6
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
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKQnHkYbu9l1qzC3Ly/5yiDVuOHJ
# erchpkeZdOd5QchwMA0GCSqGSIb3DQEBAQUABIIBAIOYFQchGKxz5yDs9nP9pEzi
# F705h0Ndcd3V7BWRkEu4e2x18GJIqO9xYXF+2q+PmV7aqkHd5yV3HttcXIbDKKSq
# 9+zzO6F83GUM4cQMa2caY+NX5quEtfJhccHwx/qr0fn7MrtGG+eE88BR2a8wfwsS
# 0Xbo883z3xQnt2n0R/6pKSkAnkmf67mMt1Z+jqgk+1mmAN2M7uG6J5dBdX07izp0
# f1X7PJTkgo8p1Te9IiVjH+3L7bmkPJzIl86y41B1ojDOTS8/pHEpg0O05FTspmsP
# nfHlb2aQx6HlZrG+opJqOqwpIVbpMWo9r624u6bKJl0ivHVWLV1jGsl6KWLPIKQ=
# SIG # End signature block
