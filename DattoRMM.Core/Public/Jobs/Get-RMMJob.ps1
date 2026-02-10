<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
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
function Get-RMMJob {
    [CmdletBinding(DefaultParameterSetName = 'JobUid')]
    param (
        # Parameter help description
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

        Invoke-APIMethod @APIMethod | ForEach-Object {[DRMMJob]::FromAPIMethod($_)}

    }
}