function Get-RMMJob {
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

        [Parameter(ParameterSetName = 'JobResults', Mandatory = $true)]
        [switch]
        $Results,

        [Parameter(ParameterSetName = 'JobStdOut', Mandatory = $true)]
        [switch]
        $StdOut,

        [Parameter(ParameterSetName = 'JobStdErr', Mandatory = $true)]
        [switch]
        $StdErr,

        [Parameter(ParameterSetName = 'JobComponents', Mandatory = $true)]
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

                        [DRMMJobStdData]::FromAPIMethod($_)

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

                        [DRMMJobStdData]::FromAPIMethod($_)

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
