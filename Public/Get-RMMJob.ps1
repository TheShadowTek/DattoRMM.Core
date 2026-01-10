function Get-RMMJob {
    <#
    .SYNOPSIS
        Retrieves job information from the Datto RMM API.

    .DESCRIPTION
        The Get-RMMJob function retrieves information about jobs (component executions) in the
        Datto RMM system. It supports multiple query modes:

        - Job details by JobUid
        - Job results for a specific device
        - Job stdout (standard output) for a specific device
        - Job stderr (error output) for a specific device
        - Components associated with a job

        Jobs in Datto RMM represent executions of components (scripts/monitors) and can be
        queried to get execution status, results, and output logs.

    .PARAMETER JobUid
        The unique identifier (GUID) of the job to retrieve. Required for all parameter sets.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of the device. Required when retrieving job results,
        stdout, or stderr.

    .PARAMETER Results
        Switch to retrieve job results for a specific device. Requires both JobUid and DeviceUid.

    .PARAMETER StdOut
        Switch to retrieve job standard output for a specific device. Requires both JobUid
        and DeviceUid.

    .PARAMETER StdErr
        Switch to retrieve job error output for a specific device. Requires both JobUid
        and DeviceUid.

    .PARAMETER Components
        Switch to retrieve all components associated with a job. Requires JobUid.

    .EXAMPLE
        Get-RMMJob -JobUid "12067610-8504-48e3-b5de-60e48416aaad"

        Retrieves basic information about a specific job.

    .EXAMPLE
        Get-RMMJob -JobUid $JobUid -DeviceUid $DeviceUid -Results

        Retrieves the execution results for a job on a specific device.

    .EXAMPLE
        Get-RMMJob -JobUid $JobUid -DeviceUid $DeviceUid -StdOut

        Retrieves the standard output from a job execution on a specific device.

    .EXAMPLE
        Get-RMMJob -JobUid $JobUid -DeviceUid $DeviceUid -StdErr

        Retrieves the error output from a job execution on a specific device.

    .EXAMPLE
        Get-RMMJob -JobUid $JobUid -Components

        Retrieves all components that are part of the specified job.

    .EXAMPLE
        $Job = Get-RMMJob -JobUid $JobUid
        PS > if ($Job.Status -eq "Failed") {
        >>     Get-RMMJob -JobUid $JobUid -DeviceUid $Job.DeviceUid -StdErr
        >> }

        Retrieves job details and checks for errors if the job failed.

    .EXAMPLE
        $JobUid = "12067610-8504-48e3-b5de-60e48416aaad"
        PS > Get-RMMDevice -FilterId 100 | Get-RMMJob -JobUid $JobUid -StdOut | ConvertFrom-Csv

        Gets devices from filter 100, retrieves the stdout from a specific job execution on each device,
        and parses the output as CSV data for further processing.

    .INPUTS
        System.Guid. You can pipe JobUid and DeviceUid from other functions.

    .OUTPUTS
        DRMMJob. Returns job objects with status, timestamps, and execution details.
        DRMMJobResults. Returns job result objects when using -Results.
        DRMMJobStdData. Returns standard output/error lines when using -StdOut or -StdErr.
        DRMMJobComponent. Returns component objects when using -Components.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Job output (stdout/stderr) is typically used for troubleshooting component execution issues.

    .LINK
        about_DRMMJob

    .LINK
        New-RMMQuickJob

    .LINK
        Get-RMMComponent

    .LINK
        about_DRMMJob

    .LINK
        New-RMMQuickJob

    .LINK
        Get-RMMComponent
    #>
    [CmdletBinding(DefaultParameterSetName = 'JobByUid')]
    param (
        [Parameter(
            ParameterSetName = 'JobByUid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'JobResults',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'JobStdOut',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'JobStdErr',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'JobComponents',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [guid]
        $JobUid,

        [Parameter(
            ParameterSetName = 'JobResults',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'JobStdOut',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'JobStdErr',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [guid]
        $DeviceUid,

        [Parameter(
            ParameterSetName = 'JobResults',
            Mandatory = $true
        )]
        [switch]
        $Results,

        [Parameter(
            ParameterSetName = 'JobStdOut',
            Mandatory = $true
        )]
        [switch]
        $StdOut,

        [Parameter(
            ParameterSetName = 'JobStdErr',
            Mandatory = $true
        )]
        [switch]
        $StdErr,

        [Parameter(
            ParameterSetName = 'JobComponents',
            Mandatory = $true
        )]
        [switch]
        $Components
    )

    process {

        Write-Debug "Getting RMM job data using parameter set: $($PSCmdlet.ParameterSetName)"

        switch ($PSCmdlet.ParameterSetName) {

            'JobByUid' {

                $APIMethod = @{
                    Path = "job/$JobUid"
                    Method = 'Get'
                }

                Write-Debug "Getting job by UID: $JobUid"
                $Response = Invoke-APIMethod @APIMethod

                [DRMMJob]::FromAPIMethod($Response)

            }

            'JobResults' {

                $APIMethod = @{
                    Path = "job/$JobUid/results/$DeviceUid"
                    Method = 'Get'
                }

                Write-Debug "Getting job results for job UID: $JobUid, device UID: $DeviceUid"
                $Response = Invoke-APIMethod @APIMethod

                [DRMMJobResults]::FromAPIMethod($Response)

            }

            'JobStdOut' {

                $APIMethod = @{
                    Path = "job/$JobUid/results/$DeviceUid/stdout"
                    Method = 'Get'
                }

                Write-Debug "Getting job stdout for job UID: $JobUid, device UID: $DeviceUid"
                $Response = Invoke-APIMethod @APIMethod

                if ($Response) {

                    $Response | ForEach-Object {

                        [DRMMJobStdData]::FromAPIMethod($_, $JobUid, $DeviceUid)

                    }

                }

            }

            'JobStdErr' {

                $APIMethod = @{
                    Path = "job/$JobUid/results/$DeviceUid/stderr"
                    Method = 'Get'
                }

                Write-Debug "Getting job stderr for job UID: $JobUid, device UID: $DeviceUid"
                $Response = Invoke-APIMethod @APIMethod

                if ($Response) {

                    $Response | ForEach-Object {

                        [DRMMJobStdData]::FromAPIMethod($_, $JobUid, $DeviceUid)

                    }

                }

            }

            'JobComponents' {

                $APIMethod = @{
                    Path = "job/$JobUid/components"
                    Method = 'Get'
                    Paginate = $true
                    PageElement = 'jobComponents'
                }

                Write-Debug "Getting job components for job UID: $JobUid"
                Invoke-APIMethod @APIMethod | ForEach-Object {

                    [DRMMJobComponent]::FromAPIMethod($_)

                }
            }
        }
    }
}
