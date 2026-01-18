<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Set-RMMDeviceUDF {
    <#
    .SYNOPSIS
        Sets user-defined fields on a device in Datto RMM.

    .DESCRIPTION
        The Set-RMMDeviceUDF function updates one or more user-defined fields (UDF1-UDF30) on a
        device in the Datto RMM system. UDFs are custom fields that can store additional metadata
        about devices for organizational and reporting purposes.

        Important behaviors:
        - Fields included in the request with empty values will be cleared (set to null)
        - Fields not included in the request will retain their current values
        - You only need to specify the fields you want to update

    .PARAMETER Device
        A DRMMDevice object to update. Accepts pipeline input from Get-RMMDevice.

    .PARAMETER DeviceUid
        The unique identifier (GUID) of the device to update.

    .PARAMETER UDF1 through UDF30
        User-defined field values (1-30). Each UDF parameter is optional.
        Set to empty string to clear a field, or omit to leave unchanged.
        Cannot be used with -UDFFields parameter.

    .PARAMETER UDFFields
        A hashtable of UDF fields to update. Keys should be in the format 'udf1', 'udf2', etc.
        Example: @{udf1='Value1'; udf5='Value5'; udf10=''}
        Cannot be used with individual UDF parameters.

    .PARAMETER Force
        Bypasses the confirmation prompt.

    .EXAMPLE
        Set-RMMDeviceUDF -DeviceUid "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -UDF1 "Department: IT" -UDF2 "Owner: John"

        Sets UDF1 and UDF2 on a device, leaving other UDFs unchanged.

    .EXAMPLE
        Get-RMMDevice -Hostname "SERVER01" | Set-RMMDeviceUDF -UDF5 "Production" -UDF10 "Critical"

        Updates UDF5 and UDF10 via pipeline.

    .EXAMPLE
        Set-RMMDeviceUDF -DeviceUid $DeviceUid -UDF1 "" -Force

        Clears UDF1 (sets to null) without confirmation.

    .EXAMPLE
        Get-RMMDevice -FilterId 100 | Set-RMMDeviceUDF -UDF3 "Datacenter: East"

        Updates UDF3 for all devices in filter 100.

    .EXAMPLE
        Set-RMMDeviceUDF -DeviceUid $DeviceUid -UDFFields @{udf1='IT Department'; udf2='John Smith'; udf5=''}

        Updates multiple UDF fields using a hashtable. UDF5 is cleared.

    .EXAMPLE
        $UDFs = @{udf10='Production'; udf15='Critical'; udf20='Datacenter: West'}
        PS > Get-RMMDevice -Hostname "SERVER*" | Set-RMMDeviceUDF -UDFFields $UDFs -Force

        Updates multiple UDF fields on all servers matching the hostname pattern without confirmation.

    .INPUTS
        DRMMDevice. You can pipe device objects from Get-RMMDevice.
        You can also pipe objects with DeviceUid or Uid properties.

    .OUTPUTS
        None. This function does not return any output.

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Best practices for UDF usage:
        - Establish consistent naming conventions across your organization
        - Document which UDFs are used for what purpose
        - Use UDFs for data that doesn't fit standard device properties
        - Consider using UDFs for: location, department, owner, cost center, project codes, etc.

    .LINK
        about_DRMMDevice

    .LINK
        Get-RMMDevice
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByDeviceUidIndividual', SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(
            ParameterSetName = 'ByDeviceObjectIndividual',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceObjectHashtable',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMDevice]
        $Device,

        [Parameter(
            ParameterSetName = 'ByDeviceUidIndividual',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceUidHashtable',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Uid')]
        [guid]
        $DeviceUid,

        [Parameter(
            ParameterSetName = 'ByDeviceObjectHashtable',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'ByDeviceUidHashtable',
            Mandatory = $true
        )]
        [hashtable]
        $UDFFields,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF1,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF2,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF3,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF4,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF5,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF6,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF7,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF8,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF9,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF10,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF11,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF12,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF13,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF14,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF15,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF16,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF17,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF18,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF19,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF20,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF21,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF22,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF23,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF24,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF25,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF26,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF27,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF28,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF29,

        [Parameter(ParameterSetName = 'ByDeviceObjectIndividual')]
        [Parameter(ParameterSetName = 'ByDeviceUidIndividual')]
        [string]
        $UDF30,

        [Parameter()]
        [switch]
        $Force
    )

    process {

        if ($Device) {

            $DeviceUid = $Device.Uid
            $DeviceName = $Device.Hostname
        }
        else {

            $DeviceName = "device $DeviceUid"
        }

        $Target = "device '$DeviceName' (UID: $DeviceUid)"

        if (-not $PSCmdlet.ShouldProcess($Target, "Update user-defined fields")) {

            return
        }

        Write-Debug "Updating UDF fields for device $DeviceUid"

        # Build request body based on parameter set
        $Body = @{}

        if ($PSCmdlet.ParameterSetName -match 'Hashtable') {

            # Validate hashtable keys
            $validUDFs = 1..30 | ForEach-Object {"udf$_"}

            foreach ($key in $UDFFields.Keys) {

                if ($key -notin $validUDFs) {

                    Write-Error "Invalid UDF key: $key. Valid keys are udf1 through udf30."
                    return

                }
            }

            # Add UDF fields from hashtable
            foreach ($key in $UDFFields.Keys) {

                $Body[$key.ToLower()] = $UDFFields[$key]

            }

        } else {

            # Add UDF fields from individual parameters
            for ($i = 1; $i -le 30; $i++) {

                $ParamName = "UDF$i"

                if ($PSBoundParameters.ContainsKey($ParamName)) {

                    $Body["udf$i"] = $PSBoundParameters[$ParamName]

                }
            }
        }

        if ($Body.Count -eq 0) {

            Write-Warning "No UDF fields were specified for update"
            return
        }

        $APIMethod = @{
            Path = "device/$DeviceUid/udf"
            Method = 'Post'
            Body = $Body
        }

        Invoke-APIMethod @APIMethod | Out-Null
    }
}

