function Get-RMMDeviceAudit {
    [CmdletBinding(DefaultParameterSetName = 'ByDeviceUid')]
    param (
        [Parameter(
            ParameterSetName = 'ByDeviceUid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [guid]
        $DeviceUid,

        [Parameter(
            ParameterSetName = 'ByMacAddress',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateScript({
            $Normalized = $_ -replace '[:\-\.]', ''
            
            if ($Normalized -match '^[0-9A-Fa-f]{12}$') {

                $true

            } else {

                throw "Invalid MAC address format. Expected 12 hexadecimal characters (e.g., 001122334455, 00:11:22:33:44:55, or 00-11-22-33-44-55)"

            }
        })]
        [string]
        $MacAddress,

        [Parameter(ParameterSetName = 'ByDeviceUid')]
        [Parameter(ParameterSetName = 'ByMacAddress')]
        [switch]
        $Software
    )

    process {

        Write-Debug "Getting RMM device audit using parameter set: $($PSCmdlet.ParameterSetName)"

        # If MacAddress is provided, check if we need to resolve to DeviceUid
        if ($PSCmdlet.ParameterSetName -eq 'ByMacAddress') {

            Write-Debug "Looking up device by MAC address: $MacAddress"
            $Device = Get-RMMDevice -MacAddress $MacAddress

            if (-not $Device) {

                Write-Error "No device found with MAC address: $MacAddress"
                return

            }

            # Handle multiple devices with same MAC address
            if ($Device -is [array] -and $Device.Count -gt 1) {

                Write-Warning "Multiple devices found with MAC address $MacAddress. Using MAC address API endpoint."
                $UseMacAddressApi = $true

            } else {

                $DeviceUid = $Device.Uid
                $UseMacAddressApi = $false

            }

        }

        # Get the device audit data
        if ($UseMacAddressApi) {

            # Normalize MAC address by removing separators
            $NormalizedMacAddress = $MacAddress -replace '[:\-\.]', ''
            
            $APIMethod = @{
                Path = "audit/device/macAddress/$NormalizedMacAddress"
                Method = 'Get'
            }

            Write-Debug "Getting device audit for MAC address: $NormalizedMacAddress"
            $Response = Invoke-APIMethod @APIMethod

            $Audit = [DRMMDeviceAudit]::FromAPIMethod($Response)
            # DeviceUid remains null when using MAC address API

        } else {

            $APIMethod = @{
                Path = "audit/device/$DeviceUid"
                Method = 'Get'
            }

            Write-Debug "Getting device audit for DeviceUid: $DeviceUid"
            $Response = Invoke-APIMethod @APIMethod

            $Audit = [DRMMDeviceAudit]::FromAPIMethod($Response)
            $Audit.DeviceUid = $DeviceUid

        }

        # If Software switch is present, get software data
        if ($Software) {

            if ($UseMacAddressApi) {

                Write-Warning "Cannot retrieve software data when multiple devices share the same MAC address. DeviceUid is required."

            } else {

                Write-Debug "Getting software data for DeviceUid: $DeviceUid"
                $SoftwareData = Get-RMMDeviceSoftware -DeviceUid $DeviceUid
                $Audit.Software = $SoftwareData

            }

        }

        return $Audit

    }
}
