<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
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
function Get-RMMJobResult {
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