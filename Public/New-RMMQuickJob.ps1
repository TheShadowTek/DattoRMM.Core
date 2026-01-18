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

        $Response = Invoke-APIMethod @APIMethod

        # Parse and return the job object from the response
        if ($Response -and $Response.job) {

            [DRMMJob]::FromAPIMethod($Response.job)

        } else {

            Write-Warning "Quick job created but no job details returned from API"

        }
    }
}

