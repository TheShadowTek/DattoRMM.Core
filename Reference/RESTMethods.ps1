function Invoke-APIMethod {
    [CmdletBinding()]
    param (
        # Invoke-RESTMethod splatting object
        [Parameter(
            Mandatory = $true
        )]
        [hashtable]
        $RESTMethod
    )

    # Test connected to Datto RMM API Service
    if ($null -eq $APIHeaders) {

        throw "'Connect-RMMService' must be run before commands can be executed on Datto RMM API service."

    }

    Write-Debug "RequestRateCheck: $RequestRateCheck RequestRateReview: $RequestRateReview"
    # Set throttle if required and pause if necessary
    if ($Script:RequestRateCheck -gt $RequestRateReview) {

        $Script:RequestRateCheck = 0
        $TotalWait = 0
        Update-RequestRate
        Write-Information "Review current request rate.`nUtilisation: $RequestRatePercent%`nDelay: $RequestRateDelay`nRequestRateCheck: $RequestRateCheck`nRequestRateReview: $RequestRateReview"

        # Pause requests if triggered
        while ($RequestRateDelay -eq 'Pause' -and $TotalWait -lt $RequestThrottleTimeoutSeconds) {

            $Message = "$((Get-Date).ToString("HH:mm:ss")) Current request rate high, pausing requests for $RequestThrottleWaitSeconds seconds."
            Write-Host $Message -ForegroundColor Magenta
            Write-Information $Message
            Start-Sleep -Seconds $RequestThrottleWaitSeconds
            $TotalWait += $RequestThrottleWaitSeconds
            Update-RequestRate

        }

        # Timeout waiting for request rate to reduce
        if ($TotalWait -ge $RequestThrottleTimeoutSeconds) {

            throw "$((Get-Date).ToString("dd/MM/yyyy HH:mm:ss"))`tRequest rate throttle timed out after $($TotalWait) seconds."

        }

    } else {

        $Script:RequestRateCheck++

    }

    # Delay requests if required
    if ($RequestRateDelay -gt 0) {

        Write-Information "Request delay: Utilisation $RequestRatePercent% - Delay $RequestRateDelay"
        Start-Sleep -Milliseconds $RequestRateDelay

    }

    # Call REST API method
    try {
    
        Invoke-RestMethod @RESTMethod

    }

    catch {

        $HttpResponseCode = $_.Exception.Response.StatusCode.value__
        $HttpResponseDescription = $_.Exception.Response.StatusDescription.value__
        Write-Warning "Failed REST $($RESTMethod.Method)! Response: $HttpResponseCode $HttpResponseDescription Url : $($RESTMethod.Uri)"

    }
}

function Invoke-GetRESTMethod {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        # API Uri
        [Parameter(
            Mandatory = $true
        )]
        [string]
        $Uri,

        # API method parameters
        [Parameter(
            Mandatory = $false
        )]
        [string[]]
        $Parameters = $null,

        # Does response paginate
        [Parameter(
            ParameterSetName = 'Paginate',
            Mandatory = $true
        )]
        [switch]
        $Paginate,

        # Json page element name
        [Parameter(
            ParameterSetName = 'Paginate',
            Mandatory = $true
        )]
        [string]
        $PageElementName,

        # Maximum number of objects per page
        [Parameter(
            ParameterSetName = 'Paginate',
            Mandatory = $false
        )]
        [int]
        $Max = $PageMax,

        # Starting page number
        [Parameter(
            ParameterSetName = 'Paginate',
            Mandatory = $false
        )]
        [int]
        $Page = 0,

        # Maximum number of pages to return
        [Parameter(
            ParameterSetName = 'Paginate',
            Mandatory = $false
        )]
        [int]
        $MaxPages = 0
    )
    
    # API get method
    $GetRESTMethod = @{
        Method = 'Get'
        Uri = $null
        Headers = $APIHeaders
    }

    # Initialise Uri
    switch ($PSCmdlet.ParameterSetName) {

        {$_ -eq 'Default' -and $null -ne $Parameters} {$GetRESTMethod.Uri = "$Uri`?$($Parameters -join '&')"}
        {$_ -eq 'Default'} {$GetRESTMethod.Uri = $Uri}
        #{$_ -eq 'Paginate' -and $null -ne $Parameters} {$GetRESTMethod.Uri = "$Uri`?max=$Max&page=$Page&$($Parameters -join '&')"}
        #{$_ -eq 'Paginate' -and $null -eq $Parameters} {$GetRESTMethod.Uri = "$Uri`?max=$Max&page=$Page"}
        {$_ -eq 'Paginate' -and $null -ne $Parameters} {$GetRESTMethod.Uri = "$Uri`?$($Parameters -join '&')"}
        {$_ -eq 'Paginate' -and $null -eq $Parameters} {$GetRESTMethod.Uri = "$Uri"}

    }
    
    # Invoke API request
    if ($Paginate) {

        $CurrentPage = Invoke-APIMethod -RESTMethod $GetRESTMethod
        $CurrentPage.$PageElementName
        $PageCount = 1

        if ($MaxPages -eq 0 -or $PageCount -lt $MaxPages) {
            
            while ($CurrentPage.pageDetails.nextPageUrl -and ($MaxPages -eq 0 -or $PageCount -lt $MaxPages)) {

                $GetRESTMethod.Uri = $CurrentPage.pageDetails.nextPageUrl
                $CurrentPage = Invoke-APIMethod -RESTMethod $GetRESTMethod
                $CurrentPage.$PageElementName
                $PageCount++

            }
        }

    } else {

        Invoke-APIMethod -RESTMethod $GetRESTMethod

    }
}

function Invoke-PostRESTMethod {
    [CmdletBinding()]
    param (
        #API uri
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false
        )]
        [string]
        $Uri,

        # API method parameters
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [string]
        $Parameters = $null,
        
        # REST post body
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [hashtable]
        $Body
    )

    $PostRESTMethod = @{
        Method = 'Post'
        Uri = $null
        Body = $Body | ConvertTo-Json -Depth 99
        Headers = $APIHeaders
        ContentType = 'application/json'
    }

    switch ($MyInvocation.BoundParameters.Parameters) {

        $null {$PostRESTMethod.Uri = $Uri}
        default {$PostRESTMethod.Uri = "$Uri`?$($Parameters -join '&')"}

    }

    Invoke-APIMethod -RESTMethod $PostRESTMethod

}

function Invoke-PutRESTMethod {
    [CmdletBinding()]
    param (
        # API uri
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false
        )]
        [string]
        $Uri,

        # API method parameters
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [string]
        $Parameters = $null,
        
        # REST post body
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [hashtable]
        $Body
    )
    
    $PutRESTMethod = @{
        Method = 'Put'
        Uri = $null
        Body = $Body | ConvertTo-Json -Depth 99
        Headers = $APIHeaders
        ContentType = 'application/json'
    }

    switch ($MyInvocation.BoundParameters.Parameters) {

        $null {$PutRESTMethod.Uri = $Uri}
        default {$PutRESTMethod.Uri = "$Uri`?$($Parameters -join '&')"}

    }

    Invoke-APIMethod -RESTMethod $PutRESTMethod

}

function Invoke-DeleteRESTMethod {
    [CmdletBinding()]
    param (
        # API uri
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false
        )]
        [string]
        $Uri
    )

    $DeleteRESTMethod = @{
        Method = 'Delete'
        Uri = $Uri
        Headers = $APIHeaders
        ContentType = 'application/json'
    }
    
    Invoke-APIMethod -RESTMethod $DeleteRESTMethod

}